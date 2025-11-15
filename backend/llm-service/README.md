# LLM Service (Python FastAPI)

Сервис для генерации ответов с использованием локальной модели Qwen/Qwen3-4B-Instruct-2507.

## Запуск

```bash
python main.py
```

Сервис будет доступен на `http://localhost:8000`

## API Endpoints

### POST /chat
Генерация ответа на основе промпта.

**Request:**
```json
{
  "prompt": "Что запрещено в исламе?",
  "max_tokens": 1024
}
```

**Response:**
```json
{
  "reply": "В исламе запрещено..."
}
```

### GET /health
Проверка здоровья сервиса.

**Response:**
```json
{
  "status": "healthy",
  "model": "Qwen/Qwen3-4B-Instruct-2507"
}
```

