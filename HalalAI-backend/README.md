# HalalAI Backend

Каталог содержит **полный серверный стек**: PostgreSQL, **Spring Boot** API и **LLM-сервис** (FastAPI), собираемые через Docker Compose.

## Быстрый старт

Из этого каталога (`HalalAI-backend/`):

```bash
cp .env.example .env
# Заполните секреты (JWT, БД, OPEN_ROUTER_KEY и т.д.)

docker compose up -d
```

Поднимутся:

- **PostgreSQL** — порт зависит от хоста (стандартно проброс не всегда нужен; приложение ходит в `postgres:5432` внутри сети)
- **backend** — REST API: [http://localhost:8080](http://localhost:8080)
- **llm-service** — RAG + LLM: с хоста [http://localhost:8001](http://localhost:8001)

## Компоненты

| Путь | Описание |
|------|-----------|
| `HalalAI-backend-main/` | Spring Boot: JWT, пользователи, чат, вызовы к LLM-сервису |
| `LLM-service/` | FastAPI: RAG по Корану, OpenRouter |
| `init-db/` | SQL для первичной инициализации БД в контейнере PostgreSQL |
| `docker-compose.yml` | Оркестрация всех сервисов |

Подробности по Spring Boot и интеграции с LLM см. в репозитории: [`docs/backend.md`](../docs/backend.md).

Отдельно про Python-сервис: [`LLM-service/README.md`](./LLM-service/README.md).

## Локальный запуск без Docker

1. **PostgreSQL** — создайте БД `halalai`, пользователя и укажите `DB_URL` / `DB_USERNAME` / `DB_PASSWORD` в окружении или `application.properties`.
2. **LLM-service** — см. [LLM-service/README.md](./LLM-service/README.md); для Spring укажите `RAG_SERVICE_URL` (например `http://localhost:8001`).
3. **Spring Boot:**

```bash
cd HalalAI-backend-main
mvn spring-boot:run
```

## Переменные окружения

Общий шаблон — файл `.env` рядом с `docker-compose.yml`. Список переменных см. в `.env.example`.

## Связь с iOS

Клиент iOS в режиме отладки обычно обращается к `http://localhost:8080/api/...`. Подробности по экранам и сервисам — в [`docs/ios.md`](../docs/ios.md).
