# RAG Quality Experiments Setup

**Статус**: 🔄 Fine-tuning моделей в процессе

## Обзор

Проверка трёх гипотез о качестве RAG-системы для поиска по Корану:

1. **Гипотеза 1 — RAG vs No-RAG**: Использование retrieval повышает качество ответов
2. **Гипотеза 2 — Fine-tuning**: Обучение embedding на кораническом корпусе улучшает поиск
3. **Гипотеза 3 — Chunk vs Verse**: Использование чанков (несколько аятов) повышает полноту

## Подготовка данных

### Training Data
- **Источник**: `data.txt` (293 Q&A пары) → парсировано в 147 Q&A → 107 training pairs
- **Обогащение**: Добавлены дополнительные релевантные аяты из Корана для каждого вопроса
- **Финальный набор**: 189 training pairs (1.6 пары на вопрос)
- **Файл**: `tests/fixtures/quranic_pairs_expanded_multi.json`

### Тестовые вопросы (изолированы от training)
```
1. Что Коран говорит о запрете свинины?
2. Какие аяты в Коране говорят о запрете алкоголя?
3. Почему в исламе запрещен алкоголь?
4. Что говорится в Коране о молитве и её значении?
5. Как в Коране описывается поведение и скромность женщины?
```

### Chunk-представление
- `data/quran_chunks.jsonl` — 3113 chunks (chunk_size=3, overlap=1)
- Использование: конфигурации C6-C9

## 9 Конфигураций (C1–C9)

| ID | RAG | Model | Fine-tuned | Data |
|----|-----|-------|-----------|------|
| **C1** | Нет | - | - | - |
| **C2** | Да | paraphrase-multilingual-mpnet | Нет | Verse |
| **C3** | Да | paraphrase-multilingual-mpnet | **Да** | Verse |
| **C4** | Да | ai-forever/sbert_large_nlu_ru | Нет | Verse |
| **C5** | Да | ai-forever/sbert_large_nlu_ru | **Да** | Verse |
| **C6** | Да | paraphrase-multilingual-mpnet | Нет | Chunk |
| **C7** | Да | paraphrase-multilingual-mpnet | **Да** | Chunk |
| **C8** | Да | ai-forever/sbert_large_nlu_ru | Нет | Chunk |
| **C9** | Да | ai-forever/sbert_large_nlu_ru | **Да** | Chunk |

## Критерии оценки (0–5)

- **Accuracy (A)**: Соответствие ответа содержанию Корана (40%)
- **Groundedness (G)**: Опора на релевантные источники (30%)
- **Completeness (C)**: Полнота раскрытия вопроса (20%)
- **Hallucination (H)**: Наличие недостоверной информации (−30% штраф)

**Формула**: `Score = 0.4A + 0.3G + 0.2C − 0.3H`

## Файлы

### Скрипты
- `scripts/parse_training_data.py` — Парсинг data.txt в training pairs
- `scripts/expand_with_multiple_verses.py` — Расширение с дополнительными аятами
- `scripts/create_chunks.py` — Создание chunk-представления
- `scripts/finetune_embeddings.py` — Fine-tune paraphrase-multilingual
- `scripts/finetune_sbert_embeddings.py` — Fine-tune sbert_large_nlu_ru
- `scripts/run_experiments.py` — Запуск всех 9 конфигураций

### Data
- `data/quran_ru.jsonl` (6175 verses)
- `data/quran_chunks.jsonl` (3113 chunks)
- `tests/fixtures/quranic_pairs.json` (115 pairs — базовые)
- `tests/fixtures/quranic_pairs_expanded_multi.json` (189 pairs — для fine-tuning)

### Models
- `models/quranic-embeddings/` — Fine-tuned paraphrase-multilingual
- `models/sbert-quranic-embeddings/` — Fine-tuned sbert_large_nlu_ru

### Результаты
- `results/C{N}/question_{M}.txt` — Retrieved verses для оценки
- `docs/experiment_tracker.md` — Таблица оценок

## Инструкции

### 1. Fine-tuning (в процессе)
```bash
python scripts/finetune_embeddings.py      # paraphrase-multilingual
python scripts/finetune_sbert_embeddings.py # sbert_large_nlu_ru
```

**Параметры**: batch_size=4, epochs=20, 189 training pairs

### 2. Запуск экспериментов
```bash
python scripts/run_experiments.py
```

Выведет retrieved verses для каждой конфигурации и вопроса в `results/`.

### 3. Оценка результатов
1. Вручную прочитать retrieved verses для каждого вопроса
2. Оценить по критериям (A, G, C, H) на шкале 0–5
3. Заполнить таблицу в `docs/experiment_tracker.md`
4. Вычислить Score по формуле

## Результаты (будут заполнены после экспериментов)

Таблица оценок: [`docs/experiment_tracker.md`](experiment_tracker.md)
