# Fine-tuning Status & Instructions

**Дата**: 17 апреля 2026
**Статус**: ⏳ Ожидание fine-tuning на мощном компьютере
**Причина**: MPS на Mac не хватает памяти для обучения (даже batch_size=2)

---

## Что уже готово

### ✅ Training Data (финализировано)
- **Файл**: `tests/fixtures/quranic_pairs.json`
- **Количество пар**: ~330+ пар
- **Формат**: JSON с полями: `id`, `query`, `relevant`, `irrelevant`, `source`
- **Проверка**: ✓ Все вопросы верные, тестовые вопросы изолированы от training

### ✅ Chunk Data (готово)
- **Файл**: `data/quran_chunks.jsonl`
- **Количество**: 3113 chunks (chunk_size=3, overlap=1)
- **Использование**: Для конфигураций C6-C9

### ✅ Scripts (готовы к запуску)
- `scripts/finetune_embeddings.py` → обучает paraphrase-multilingual-mpnet
- `scripts/finetune_sbert_embeddings.py` → обучает ai-forever/sbert_large_nlu_ru
- `scripts/run_experiments.py` → запускает все 9 конфигураций

### ✅ Experiment Infrastructure (готово)
- `docs/experiment_tracker.md` → таблица для оценок
- `docs/EXPERIMENTS_SETUP.md` → полная документация
- `docs/FINETUNING_STATUS.md` → этот файл

---

## Что нужно сделать

### 1️⃣ Fine-tuning обеих моделей (НА МОЩНОМ КОМПЕ)

**Параметры:**
```
Модель 1: paraphrase-multilingual-mpnet-base-v2
- Batch size: 2 (или 4 на мощном компе)
- Epochs: 10 (или 20 на мощном)
- Learning rate: 2e-5
- Warmup steps: 25 (или 50)
- Training examples: 344 пары (из quranic_pairs.json)

Модель 2: ai-forever/sbert_large_nlu_ru
- Batch size: 2 (или 4 на мощном компе)
- Epochs: 10 (или 20 на мощном)
- Learning rate: 2e-5
- Warmup steps: 25 (или 50)
- Device: CPU (по умолчанию)
```

**Запуск:**
```bash
cd HalalAI-backend/LLM-service
python scripts/finetune_embeddings.py      # ~30-60 минут на мощном компе
python scripts/finetune_sbert_embeddings.py # ~20-40 минут на мощном компе
```

**Результаты:**
- `models/quranic-embeddings/` → fine-tuned paraphrase-multilingual
- `models/sbert-quranic-embeddings/` → fine-tuned sbert

### 2️⃣ Запуск экспериментов (ПОСЛЕ fine-tuning)

```bash
python scripts/run_experiments.py
```

**Выходные данные:** `results/C{1-9}/question_{1-5}.txt`
- Для каждой конфигурации (C1-C9)
- Для каждого вопроса (5 тестовых)
- Retrieved verses для оценки

### 3️⃣ Оценка результатов (РУЧНАЯ)

**Процесс:**
1. Читать retrieved verses в `results/`
2. Оценить по критериям (Accuracy, Groundedness, Completeness, Hallucination)
3. Заполнить таблицу в `docs/experiment_tracker.md`

**Критерии (0-5):**
- **A (Accuracy)**: Соответствие содержанию Корана
- **G (Groundedness)**: Опора на релевантные источники
- **C (Completeness)**: Полнота раскрытия вопроса
- **H (Hallucination)**: Недостоверная информация (штраф)

**Формула:** `Score = 0.4A + 0.3G + 0.2C − 0.3H`

---

## 9 конфигураций (C1-C9)

| ID | RAG | Model | Fine-tuned | Data |
|----|-----|-------|-----------|------|
| C1 | Нет | - | - | - |
| C2 | Да | paraphrase-multilingual | Нет | Verse |
| C3 | Да | paraphrase-multilingual | ✓ ДА | Verse |
| C4 | Да | sbert_large_nlu_ru | Нет | Verse |
| C5 | Да | sbert_large_nlu_ru | ✓ ДА | Verse |
| C6 | Да | paraphrase-multilingual | Нет | Chunk |
| C7 | Да | paraphrase-multilingual | ✓ ДА | Chunk |
| C8 | Да | sbert_large_nlu_ru | Нет | Chunk |
| C9 | Да | sbert_large_nlu_ru | ✓ ДА | Chunk |

---

## Тестовые вопросы (изолированы от training)

1. Что Коран говорит о запрете свинины?
2. Какие аяты в Коране говорят о запрете алкоголя?
3. Почему в исламе запрещен алкоголь?
4. Что говорится в Коране о молитве и её значении?
5. Как в Коране описывается поведение и скромность женщины?

---

## Файловая структура

```
HalalAI-backend/LLM-service/
├── data/
│   ├── quran_ru.jsonl (6175 аятов)
│   └── quran_chunks.jsonl (3113 chunks) ✓
├── models/
│   ├── quranic-embeddings/ (fine-tuned paraphrase-multilingual) ⏳
│   └── sbert-quranic-embeddings/ (fine-tuned sbert) ⏳
├── tests/fixtures/
│   └── quranic_pairs.json (344 training examples) ✓
├── scripts/
│   ├── finetune_embeddings.py ✓
│   ├── finetune_sbert_embeddings.py ✓
│   └── run_experiments.py ✓
├── docs/
│   ├── FINETUNING_STATUS.md (этот файл)
│   ├── EXPERIMENTS_SETUP.md ✓
│   ├── experiment_tracker.md (для результатов) ✓
│   └── ...
└── src/halal_rag/
    └── rag/ (RAG реализация) ✓
```

---

## Проблемы и решения

### Проблема: MPS на Mac не хватает памяти

**Причина:**
- MPS allocates ~5 ГБ из max_allowed 20 ГБ
- Остаток (~15 ГБ) занят другими процессами
- Для batch_size=4: нужно ~2.5 ГБ, а есть только ~1.5 ГБ свободной

**Решение:**
- ✅ Использовать CPU вместо MPS (медленнее, но работает)
- ✅ Запустить на мощном компьютере (GPU с 24+ ГБ памяти)

### Решение для CPU обучения:

`scripts/finetune_embeddings.py`:
```python
model = SentenceTransformer(..., device="cpu")
```

`scripts/finetune_sbert_embeddings.py`:
```python
model = SentenceTransformer(..., device="cpu")
```

Обучение на CPU займёт ~2-3 часа вместо 30 минут на GPU, но завершится успешно.

---

## Следующие шаги (для Claude на другом компе)

1. ✅ **Прочитать этот файл** (контекст проекта)
2. 🔄 **Запустить fine-tuning:**
   ```bash
   python scripts/finetune_embeddings.py
   python scripts/finetune_sbert_embeddings.py
   ```
3. ⏳ **Дождаться завершения** (30-120 минут в зависимости от компа)
4. ✅ **Запустить эксперименты:**
   ```bash
   python scripts/run_experiments.py
   ```
5. 📊 **Оценить результаты** (ручная оценка по формуле)
6. 📝 **Заполнить таблицу:** `docs/experiment_tracker.md`

---

## Контакт

Если возникнут проблемы:
- Проверить логи в stdout/stderr
- Убедиться что все зависимости установлены: `pip install -r requirements.txt`
- Проверить что `quranic_pairs.json` содержит валидный JSON
