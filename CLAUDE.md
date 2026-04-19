# CLAUDE.md

Этот файл обеспечивает руководство для Claude Code при работе с кодом в этом репозитории.

## Быстрый старт

### Локальная разработка

**Вся система (iOS + Backend + LLM Service):**
```bash
cd HalalAI-backend
docker-compose up -d
```

Это запустит:
- PostgreSQL (локальная БД на портах по умолчанию)
- LLM Service (Python FastAPI, порт 8001)
- Spring Boot Backend (порт 8080)

**iOS (отдельно):**
```bash
open HalalAI-ios/HalalAI.xcodeproj
```
Запустить в симуляторе Xcode или через `xcodebuild`.

**LLM Service (только):**
```bash
cd HalalAI-backend/LLM-service
pip install -r requirements.txt
python main.py
```

**Spring Boot Backend (только):**
```bash
cd HalalAI-backend/HalalAI-backend-main
mvn spring-boot:run
```

## Context Routing

Подробные инструкции для каждого компонента:

- **iOS приложение** (`HalalAI-ios/`) → см. [`docs/ios.md`](./docs/ios.md)
- **Backend** (`HalalAI-backend/`) → см. [`docs/backend.md`](./docs/backend.md)

## Архитектура системы

Это монорепо с тремя компонентами:

```
iOS App (SwiftUI)
    ↓ REST API
Spring Boot Backend (Java)
    ├─ Управление пользователями, auth, БД
    └─ Оркестрация → Python LLM Service
        ↓ HTTP
Python LLM Service (FastAPI)
    ├─ RAG Pipeline (семантический поиск)
    ├─ Vector Store (исламские источники)
    └─ LLM генерация (OpenRouter)
```

**Ключевые точки интеграции:**
- iOS ↔ Backend: `http://localhost:8080/api/` (REST API)
- Backend ↔ LLM Service: `http://llm-service:8000/` (Docker) или `http://localhost:8001/` (локально)
- Database: PostgreSQL (автоматически стартует через docker-compose)

## Общие правила для всего проекта

### Git
- **Пользователь сам управляет коммитами** — не создавайте их автоматически
- Не пушьте в remote без явного указания
- Коммиты на русском/английском языках допускаются

### Язык
- Все .md файлы пишите на русском языке
- Код (Swift, Java, Python) может быть на английском

### Зависимости
- **iOS**: только Apple frameworks (нет SPM, CocoaPods)
- **Backend**: Maven + Spring Boot (Java 17+)
- **LLM Service**: pip + requirements.txt (Python 3.9+)

### Состояние проекта
Для контекста о текущих инициативах, пройденных экспериментах и архитектурных решениях см. [`.claude/projects/MEMORY.md`](./.claude/projects/-Users-mirsaitsabirzanov-Documents-Dev-IOS-HalalAIMono/memory/MEMORY.md)

## Окружение

- **Docker Compose:** используется для полного стека (рекомендуется)
- **Java:** JDK 17+ (Spring Boot backend)
- **Python:** 3.9+ (LLM service)
- **iOS:** Xcode 26.3+, Swift 5.10+, iOS 17+
- **PostgreSQL:** 13+ (автоматически в Docker)

## Файлы конфигурации

- `.env.example` → копируйте в `.env` для локальной разработки
- `HalalAI-backend/docker-compose.yml` — полная конфигурация сервисов
- `HalalAI-ios/HalalAI/Info.plist` — права доступа (location, camera, photo library)
