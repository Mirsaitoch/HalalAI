"""
Пример реализации гибридного поиска для улучшения RAG.

Комбинирует:
1. Semantic search (текущий подход с embeddings)
2. BM25 keyword search (для точных совпадений)
3. Reranking с cross-encoder моделью
"""

from typing import Any, Dict, List, Optional
import torch
from sentence_transformers import SentenceTransformer, CrossEncoder
from rank_bm25 import BM25Okapi
import numpy as np


class HybridRAGPipeline:
    """Продвинутый RAG pipeline с гибридным поиском и reranking."""
    
    def __init__(
        self,
        embedding_model: str = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
        reranker_model: str = "cross-encoder/ms-marco-MiniLM-L-6-v2",
        device: str = "cpu",
    ):
        self.embedder = SentenceTransformer(embedding_model, device=device)
        self.reranker = CrossEncoder(reranker_model, max_length=512)
        self.bm25_index = None
        self.documents = []
        
    def build_bm25_index(self, documents: List[Dict[str, Any]]):
        """Строит BM25 индекс для keyword поиска."""
        tokenized_corpus = [
            doc["text"].lower().split() for doc in documents
        ]
        self.bm25_index = BM25Okapi(tokenized_corpus)
        self.documents = documents
        
    def hybrid_search(
        self,
        query: str,
        top_k: int = 3,
        semantic_weight: float = 0.7,
        keyword_weight: float = 0.3,
    ) -> List[Dict[str, Any]]:
        """
        Гибридный поиск с комбинацией semantic и keyword подходов.
        
        Args:
            query: Поисковый запрос
            top_k: Количество результатов
            semantic_weight: Вес для semantic поиска (0-1)
            keyword_weight: Вес для keyword поиска (0-1)
            
        Returns:
            Список документов с комбинированными scores
        """
        # 1. Semantic search
        query_embedding = self.embedder.encode([query], convert_to_tensor=True)
        doc_embeddings = self.embedder.encode(
            [doc["text"] for doc in self.documents],
            convert_to_tensor=True,
        )
        semantic_scores = torch.nn.functional.cosine_similarity(
            query_embedding, doc_embeddings, dim=1
        ).cpu().numpy()
        
        # 2. BM25 keyword search
        tokenized_query = query.lower().split()
        bm25_scores = self.bm25_index.get_scores(tokenized_query)
        
        # 3. Нормализация и комбинирование scores
        semantic_scores_norm = (semantic_scores - semantic_scores.min()) / (
            semantic_scores.max() - semantic_scores.min() + 1e-6
        )
        bm25_scores_norm = (bm25_scores - bm25_scores.min()) / (
            bm25_scores.max() - bm25_scores.min() + 1e-6
        )
        
        combined_scores = (
            semantic_weight * semantic_scores_norm +
            keyword_weight * bm25_scores_norm
        )
        
        # 4. Выбираем топ кандидатов для reranking
        top_indices = np.argsort(combined_scores)[::-1][:top_k * 3]
        candidates = [self.documents[i] for i in top_indices]
        
        # 5. Reranking с cross-encoder
        if len(candidates) > top_k:
            pairs = [(query, doc["text"]) for doc in candidates]
            rerank_scores = self.reranker.predict(pairs)
            reranked_indices = np.argsort(rerank_scores)[::-1]
            candidates = [candidates[i] for i in reranked_indices]
        
        return candidates[:top_k]
    
    
class QueryRewriter:
    """Переписывает запросы для улучшения поиска."""
    
    @staticmethod
    def expand_with_synonyms(query: str, synonym_dict: Dict[str, List[str]]) -> List[str]:
        """Генерирует варианты запроса с синонимами."""
        variants = [query]
        
        for term, synonyms in synonym_dict.items():
            if term in query.lower():
                for synonym in synonyms[:3]:  # Ограничиваем количество
                    variant = query.lower().replace(term, synonym)
                    if variant not in variants:
                        variants.append(variant)
        
        return variants[:5]
    
    @staticmethod
    def decompose_question(query: str) -> List[str]:
        """
        Разбивает сложный вопрос на подвопросы.
        Например: "Что говорится о свинине и алкоголе?" →
        ["Что говорится о свинине?", "Что говорится об алкоголе?"]
        """
        # Простая эвристика для "и"
        if " и " in query.lower():
            parts = query.lower().split(" и ")
            if len(parts) == 2:
                # Пытаемся создать два связных вопроса
                base_template = parts[0].rsplit(" ", 1)[0] if " " in parts[0] else ""
                if base_template:
                    return [
                        parts[0] + "?",
                        base_template + " " + parts[1] + "?"
                    ]
        
        return [query]


# Улучшенная версия Query Expander
class AdvancedQueryExpander:
    """Продвинутый expander с большим словарем и морфологией."""
    
    # Расширенный словарь синонимов
    EXTENDED_SYNONYMS = {
        # Еда
        "свинин": ["мясо свиньи", "свиное мясо", "хинзир"],
        "алкоголь": ["хамр", "спиртное", "вино", "опьяняющие напитки"],
        "мясо": ["дичь", "забой", "халяльное мясо"],
        
        # Молитва
        "намаз": ["молитва", "салят", "салат", "صلاة"],
        "дуа": ["молитва", "просьба к Аллаху", "دعاء"],
        
        # Пост
        "пост": ["ураза", "рамадан", "саум", "صوم"],
        "ифтар": ["разговение", "прекращение поста"],
        "сухур": ["предрассветная еда", "сахур"],
        
        # Закят и садака
        "закят": ["милостыня", "обязательная милостыня", "زكاة"],
        "садака": ["добровольная милостыня", "صدقة"],
        
        # Хадж
        "хадж": ["паломничество", "мекка", "حج"],
        "умра": ["малое паломничество", "عمرة"],
        "кааба": ["священная кааба", "الكعبة"],
        
        # Запреты и дозволения
        "харам": ["запрещено", "запретно", "грех", "حرام"],
        "халяль": ["дозволено", "разрешено", "позволено", "حلال"],
        "макрух": ["нежелательно", "مكروه"],
        "мустахаб": ["желательно", "рекомендуемо", "مستحب"],
        
        # Коран и сунна
        "коран": ["священный коран", "писание", "القرآن"],
        "сура": ["глава корана", "سورة"],
        "аят": ["стих корана", "آية"],
        "хадис": ["предание", "сунна", "حديث"],
        
        # Вера
        "иман": ["вера", "إيمان"],
        "такуа": ["богобоязненность", "تقوى"],
        "ширк": ["многобожие", "شرك"],
        "куфр": ["неверие", "كفر"],
    }
    
    @staticmethod
    def expand_with_morphology(query: str, max_variants: int = 5) -> List[str]:
        """
        Расширяет запрос с учетом морфологии русского языка.

        - Лемматизация: «свинину», «свинины» → «свинина» для лучшего совпадения с текстом.
        - Вариант запроса в форме лемм добавляется к вариантам поиска.

        Требует pymorphy3 (pip install pymorphy3) или pymorphy2. Без них возвращает [query].
        """
        variants = [query]

        try:
            import re
        except ImportError:
            return variants

        morph = None
        for module in ("pymorphy3", "pymorphy2"):
            try:
                if module == "pymorphy3":
                    from pymorphy3 import MorphAnalyzer
                else:
                    from pymorphy2 import MorphAnalyzer
                morph = MorphAnalyzer()
                break
            except (ImportError, Exception):
                continue
        if morph is None:
            return variants

        # Разбиваем на слова (кириллица, латиница, цифры), сохраняем разделители
        word_pattern = re.compile(r"(\b[а-яёА-ЯЁa-zA-Z0-9]+\b)")
        tokens = word_pattern.split(query)

        def lemmatize_word(w: str) -> str:
            if not w or not w[0].isalpha():
                return w
            p = morph.parse(w.lower())[0]
            lemma = p.normal_form
            return lemma.capitalize() if w and w[0].isupper() else lemma

        # Вариант: запрос из лемм (нормальная форма слов)
        lemma_parts = [lemmatize_word(t) if word_pattern.match(t) else t for t in tokens]
        lemma_query = "".join(lemma_parts)
        if lemma_query.strip() and lemma_query != query:
            variants.append(lemma_query)

        # Вариант: оригинал + через пробел все леммы (для BM25 — больше ключевых слов)
        lemmas_only = [lemmatize_word(t) for t in tokens if word_pattern.match(t)]
        if lemmas_only:
            extra = " ".join(lemmas_only)
            combined = f"{query} {extra}" if extra not in query else query
            if combined not in variants:
                variants.append(combined)

        seen = set()
        unique = []
        for v in variants:
            v_clean = v.strip()
            if v_clean and v_clean not in seen:
                seen.add(v_clean)
                unique.append(v_clean)

        return unique[:max_variants]
    
    @classmethod
    def expand_arabic_terms(cls, query: str) -> List[str]:
        """Добавляет арабские термины к русским."""
        variants = [query]
        
        for russian_term, synonyms in cls.EXTENDED_SYNONYMS.items():
            if russian_term in query.lower():
                # Добавляем варианты с арабскими терминами
                arabic_terms = [s for s in synonyms if any('\u0600' <= c <= '\u06FF' for c in s)]
                for arabic_term in arabic_terms[:2]:
                    variant = f"{query} ({arabic_term})"
                    variants.append(variant)
        
        return variants[:5]


# Кэширование для производительности
class QueryCache:
    """Кэш для часто задаваемых вопросов."""
    
    def __init__(self, max_size: int = 1000):
        self.cache: Dict[str, List[Dict[str, Any]]] = {}
        self.max_size = max_size
        self.hit_count = 0
        self.miss_count = 0
        
    def get(self, query: str) -> Optional[List[Dict[str, Any]]]:
        """Получает результаты из кэша."""
        normalized_query = query.lower().strip()
        if normalized_query in self.cache:
            self.hit_count += 1
            return self.cache[normalized_query]
        self.miss_count += 1
        return None
    
    def set(self, query: str, results: List[Dict[str, Any]]):
        """Сохраняет результаты в кэш."""
        normalized_query = query.lower().strip()
        
        if len(self.cache) >= self.max_size:
            # Простая LRU: удаляем первый элемент
            first_key = next(iter(self.cache))
            del self.cache[first_key]
        
        self.cache[normalized_query] = results
    
    def get_stats(self) -> Dict[str, Any]:
        """Возвращает статистику кэша."""
        total = self.hit_count + self.miss_count
        hit_rate = self.hit_count / total if total > 0 else 0
        
        return {
            "size": len(self.cache),
            "max_size": self.max_size,
            "hits": self.hit_count,
            "misses": self.miss_count,
            "hit_rate": hit_rate,
        }
