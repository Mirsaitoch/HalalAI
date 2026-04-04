# Backend Context

Инструкции для разработки backend сервисов (папка `HalalAI-backend/`).

## Структура

Backend состоит из двух сервисов:
- **HalalAI-backend-main** — Spring Boot REST API
- **LLM-service** — Python FastAPI сервис для LLM + RAG

## Развертывание

### Docker Compose
```bash
docker-compose up -d
```

Стартует PostgreSQL и оба сервиса.

### Environment

Скопируйте `.env.example` в `.env`:
```bash
cp .env.example .env
```

### инициализация БД

SQL скрипты в папке `init-db/` запускаются автоматически при старте PostgreSQL.

## Spring Boot Backend (`HalalAI-backend-main/`)

### Сборка и запуск

```bash
# Локальная сборка (без Docker)
cd HalalAI-backend-main
mvn clean package
java -jar target/HalalAI-*.jar

# Или через Maven
mvn spring-boot:run
```

### Структура проекта

```
src/main/java/
├── controller/       # REST контроллеры
├── service/         # Бизнес-логика
├── repository/      # JPA репозитории
├── model/           # Сущности (JPA entities)
├── dto/             # Data Transfer Objects
├── security/        # JWT, аутентификация
└── config/          # Конфигурация Spring
```

### API Endpoints

- **Auth:** `POST /api/auth/register`, `/api/auth/login`, `/api/auth/refresh`
- **Chat:** `POST /api/chat`, `GET /api/chat/history`
- **Users:** `GET /api/users/profile`, `PUT /api/users/profile`

### Технологии

- Java 17+
- Spring Boot 3.x
- Spring Security (JWT)
- Spring Data JPA
- PostgreSQL

### Конфигурация

- **Production URL:** укажите в `application-prod.properties`
- **Dev Server:** `http://localhost:8080` (по умолчанию в iOS при DEBUG)
- **JWT Secret:** в `.env` или `application.properties`

## LLM Service (`LLM-service/`)

### Запуск

```bash
# Локально (без Docker)
cd LLM-service
pip install -r requirements.txt
python main.py

# Или через Docker (автоматически через docker-compose)
```

### Структура

```
├── main.py              # FastAPI приложение
├── services/            # Локальная LLM логика
├── rag/                 # RAG Pipeline
├── data/                # Vector Store (vector_store.pt)
├── requirements.txt     # Python зависимости
```

### API Endpoints

- **Chat:** `POST /chat` — отправить вопрос с RAG
- **Models:** `GET /models` — список доступных моделей
- **Settings:** `GET /settings`, `POST /settings` — конфиг LLM

### Технологии

- Python 3.10+
- FastAPI
- PyTorch
- Sentence Transformers (embeddings)
- Transformers (локальная LLM)

### Режимы работы

1. **Local LLM** (default) — Qwen/Qwen3-1.7B
2. **Remote LLM** — OpenRouter API (GPT-4, DeepSeek, etc.)

Выбор через `settings` endpoint или env переменная.

### RAG Pipeline

- Файловое хранилище векторов: `data/vector_store.pt`
- Семантический поиск по исламским источникам
- Обогащение промпта релевантным контекстом перед генерацией ответа

## Интеграция сервисов

```
iOS App
  ↓ (REST API)
Spring Boot Backend
  ├─ Auth & User Management
  ├─ Database (PostgreSQL)
  └─ LLM Service Call
    ↓ (HTTP)
    Python LLM Service
      ├─ RAG Pipeline
      ├─ Vector Store
      └─ Local/Remote LLM
```

iOS отправляет запросы на Backend, Backend оркестрирует LLM Service.

## Git & Коммиты

- Коммиты на русском/английском
- **Пользователь сам создает коммиты** — не создавайте их автоматически

## Правила кода

### Java (Spring Boot)
- JPA entities в `model/`
- Services содержат бизнес-логику
- Controllers только для HTTP обработки
- DTO для API responses/requests

### Python (FastAPI)
- Структурированные файлы по функциональности
- Type hints везде
- Docstrings для основных функций
- Async функции для I/O операций

## Требования к окружению

- **Java:** JDK 17+
- **Python:** 3.10+
- **PostgreSQL:** 13+
- **Maven:** 3.8+
- **pip:** свежая версия

## Логирование и Debug

### Spring Boot
- Логи по умолчанию в консоль
- Уровень: `application.properties` → `logging.level.root=INFO`

### Python FastAPI
- Uvicorn логирует в консоль
- Debug режим: `python main.py` с `debug=True`

## Полезные ссылки

- см. основной `README.md` в корне проекта для полной архитектуры
- `.env.example` для всех переменных окружения
- `docker-compose.yml` для контейнеризации
