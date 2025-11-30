# LLM Service (Python FastAPI)

Сервис для генерации ответов с использованием локальной модели Qwen/Qwen3-4B-Instruct-2507.

## Запуск

```bash
python main.py
```

Сервис будет доступен на `http://localhost:8000`

## API Endpoints

### POST /chat
Генерация ответа на основе промпта с поддержкой Retrieval-Augmented Generation (RAG).

**Request:**
```json
{
  "prompt": "Что запрещено в исламе?",
  "max_tokens": 512,
  "use_rag": true,
  "rag_top_k": 3,
  "api_key": "sk-***",          // опционально: пользовательский ключ удалённого провайдера
  "remote_model": "gpt-4o-mini" // опционально: переопределение модели провайдера
}
```

**Response:**
```json
{
  "reply": "В исламе запрещено..."
}
```

### GET /rag/status
Текущее состояние векторного индекса.

**Response:**
```json
{
  "enabled": true,
  "documents": 128,
  "embedding_model": "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
  "store_path": "HalalAI-backend/LLM-service/data/vector_store.pt"
}
```

### POST /rag/documents
Индексация новых документов в векторную БД.

**Request:**
```json
{
  "documents": [
    {
      "document_id": "fatwa_001",
      "text": "Полный текст фетвы...",
      "metadata": {
        "title": "Фетва №1",
        "source": "muftyat.ru",
        "lang": "ru"
      }
    }
  ],
  "chunk_size": 800,
  "chunk_overlap": 100
}
```

**Response:**
```json
{
  "chunks_indexed": 6,
  "total_chunks": 128,
  "chunk_size": 800,
  "chunk_overlap": 100
}
```

> **Примечание:** Для наполнения RAG необходимо подготовить набор текстов (фетвы, аяты, хадисы, статьи) в формате JSON, как показано выше. Каждый документ может содержать произвольные метаданные (название, источник, дата и т.д.), которые помогают объяснять источник в ответе модели.

### GET /health
Проверка здоровья сервиса.

**Response:**
```json
{
  "status": "healthy",
  "model": "Qwen/Qwen3-4B-Instruct-2507"
}
```

## Переменные окружения

- `LLM_MODEL_NAME` — локальная модель (по умолчанию `Qwen/Qwen3-1.7B`).
- `LLM_DEFAULT_MAX_TOKENS` / `LLM_MAX_TOKENS` — ограничения по длине генерации.
- `RAG_*` — параметры векторного поиска (см. `main.py`).
- `REMOTE_LLM_ENABLED` — разрешить использование внешнего API (по умолчанию `true`).
- `REMOTE_LLM_MODEL` — модель провайдера, если пользователь передаёт свой `api_key` (по умолчанию `tngtech/deepseek-r1t2-chimera:free` на OpenRouter).
- `REMOTE_LLM_BASE_URL` — кастомный endpoint. По умолчанию `https://openrouter.ai/api/v1`.
- `REMOTE_LLM_REFERER`, `REMOTE_LLM_APP_TITLE` — заголовки для OpenRouter (`HTTP-Referer`, `X-Title`).
- `LLM_LOG_PROMPT` и `LLM_LOG_PROMPT_MAX_CHARS` — логирование итогового промпта.

