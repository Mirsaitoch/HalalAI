# HalalAI LLM Service

Python-сервис на **FastAPI**: семантический поиск по аятам (RAG) и генерация ответов через **OpenRouter** (удалённые LLM).

## Требования

- Python **3.9+** (в Docker используется 3.11)
- Файл данных `data/quran_ru.jsonl` (загрузка при старте приложения)

## Установка и запуск (локально)

Из каталога `HalalAI-backend/LLM-service/`:

```bash
pip install -e ".[dev]"
```

Запуск API (по умолчанию в `main.py` указан порт **8001** на `localhost`):

```bash
python -m uvicorn halal_rag.api.main:app --reload --host 0.0.0.0 --port 8001
```

Интерактивная документация: [http://localhost:8001/docs](http://localhost:8001/docs)

## Docker

Сборка и запуск вместе с остальным стеком — из `HalalAI-backend/`:

```bash
docker compose up -d llm-service
```

Снаружи контейнера сервис доступен на порту **8001** (проброс `8001:8000`), внутри сети Compose — `http://llm-service:8000`.

## HTTP API (основное)

| Метод | Путь | Назначение |
|--------|------|------------|
| GET | `/llm/health` | Проверка готовности RAG и LLM-клиента |
| POST | `/llm/chat` | Диалог с учётом RAG |
| GET | `/llm/info` | Метаданные и список эндпоинтов |

Корень `GET /` возвращает подсказку перейти к `/llm/info` и `/docs`.

## Переменные окружения

Значения задаются в `HalalAI-backend/.env` (см. `.env.example` в том же каталоге), в том числе:

- `OPEN_ROUTER_KEY` — ключ OpenRouter для удалённых моделей
- `RAG_LOG_LEVEL` — уровень логов (например `INFO`)
- `LLM_MODEL`, `LLM_TEMPERATURE`, `LLM_MAX_TOKENS` — параметры генерации (если используются в конфигурации окружения)

В `docker-compose.yml` для сервиса `llm-service` также задаются `RAG_HOST` и `RAG_PORT` для процесса в контейнере.

## Структура кода

```
LLM-service/
├── src/halal_rag/
│   ├── api/           # FastAPI: main, DTO, зависимости
│   ├── rag/           # эмбеддинги, ретривер, векторное хранилище
│   └── llm/           # клиент OpenRouter и интерфейсы
├── data/              # quran_ru.jsonl и прочие данные для RAG
├── tests/             # pytest (unit + integration)
├── scripts/           # вспомогательные скрипты и эксперименты
├── Dockerfile
└── pyproject.toml
```

## Тесты

```bash
pytest
```

Опциональные зависимости для гибридного поиска описаны в `pyproject.toml` в секции `[project.optional-dependencies]` (`hybrid`).

## Связь с Spring Boot

Бэкенд обращается к сервису по URL из `rag.service.url` / `RAG_SERVICE_URL` (в Docker — `http://llm-service:8000`). iOS напрямую к LLM-сервису не ходит: только к REST API Spring Boot.
