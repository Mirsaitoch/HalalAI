# HalalAI iOS — Полная структура проекта

## 📦 Обзор всех диаграмм

| Диаграмма | Файл | Назначение | Аудитория |
|-----------|------|-----------|----------|
| 🏗️ **Полная архитектура** | `HalalAI_Architecture.puml` | Обзор всех слоев и компонентов | Диплом, презентация, новые разработчики |
| 🧭 **Навигация** | `Navigation_Architecture.puml` | Система маршрутизации и координаторы | Разработчики, работающие с навигацией |
| 🔧 **App & DI** | `Application_Core.puml` | Инициализация и инъекция зависимостей | Разработчики, работающие с инфраструктурой |
| 🛠️ **Сервисы** | `Services_Layer.puml` | Все бизнес-логика и сервисы | Разработчики, работающие с функциями |
| 🎨 **UI & ViewModels** | `Features_UI_Layer.puml` | Все экраны и компоненты | Разработчики UI |
| 📊 **Модели данных** | `Models_DTOs.puml` | Структуры и типы данных | Все разработчики, архитекторы |

---

## 🏛️ Архитектура по слоям

```
┌─────────────────────────────────────────────────┐
│        Presentation Layer (UI)                  │
│  Views, ViewModels, Components                  │
│  (Features_UI_Layer.puml)                       │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│        Navigation Layer                         │
│  Coordinator Pattern, Routes                    │
│  (Navigation_Architecture.puml)                 │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│        Business Logic Layer (Services)          │
│  Auth, Chat, Prayer, Scanner, etc.             │
│  (Services_Layer.puml)                          │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│        Network Layer                            │
│  APIClient, Endpoints, HTTP                     │
│  (Application_Core.puml)                        │
└─────────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────────┐
│        Data Layer (Models)                      │
│  DTOs, Entities, Value Objects                  │
│  (Models_DTOs.puml)                             │
└─────────────────────────────────────────────────┘
```

---

## 📁 Структура папок проекта

```
HalalAI-ios/
├── HalalAI/
│   ├── App/
│   │   ├── HalalAIApp.swift         (entry point)
│   │   ├── RootView.swift           (auth/main switch)
│   │   └── ScreenFactory.swift      (DI container & factory)
│   │
│   ├── Navigation/
│   │   ├── Coordinator.swift        (main navigation)
│   │   ├── RouterView.swift         (navigation container)
│   │   ├── HomeCoordinator.swift
│   │   ├── ChatCoordinator.swift
│   │   ├── SettingsCoordinator.swift
│   │   ├── AuthCoordinator.swift
│   │   └── TabBar/
│   │       ├── TabBarItem.swift
│   │       └── TabBarView.swift
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── Chat/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── Home/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── Prayer/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── Scanner/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── Quran/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   ├── HalalMap/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   └── Settings/
│   │       └── UI/
│   │
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── NetworkClient.swift
│   │   │   ├── APIRequest.swift
│   │   │   ├── Endpoint.swift
│   │   │   ├── APIConfiguration.swift
│   │   │   └── NetworkError.swift
│   │   ├── Location/
│   │   │   └── LocationService.swift
│   │   ├── Components/
│   │   │   ├── GuestBannerView.swift
│   │   │   ├── ErrorView.swift
│   │   │   └── ...
│   │   └── Extensions/
│   │       ├── View+HideKeyboard.swift
│   │       ├── View+AdditionalPadding.swift
│   │       └── HapticFeedback+Modes.swift
│   │
│   ├── Models/
│   │   ├── User.swift
│   │   ├── ChatMessage.swift
│   │   ├── Verse.swift
│   │   ├── Prayer.swift
│   │   ├── Ingredient.swift
│   │   ├── Sura.swift
│   │   ├── HalalPlace.swift
│   │   └── ...
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Colors.xcassets
│   │   ├── Images.xcassets
│   │   └── Info.plist
│   │
│   └── HalalAI.xcodeproj
│
├── HalalAITests/        (unit tests)
├── HalalAIUITests/      (UI tests)
│
├── README.md            (основная документация)
├── NAVIGATION_ARCHITECTURE.md
├── UML_DIAGRAMS_GUIDE.md
└── PROJECT_STRUCTURE.md (этот файл)
```

---

## 🎯 8 основных функций (Features)

### 1. **Authentication** 🔐
- Вход в аккаунт
- Регистрация
- Гостевой режим
- JWT токены
- **Диаграмма:** Services_Layer, Features_UI_Layer

### 2. **Chat with AI** 💬
- Диалог с LLM
- RAG интеграция (поиск по Корану)
- Выбор модели
- История сообщений
- **Диаграмма:** Services_Layer, Features_UI_Layer

### 3. **Home Screen** 🏠
- Аят дня
- Карточка времени молитв
- Быстрые ссылки на функции
- Гостевой баннер
- **Диаграмма:** Features_UI_Layer

### 4. **Prayer Times** 🕌
- Расчет 5 времен молитв
- GPS-based локализация
- Уведомления о молитвах
- Настройки по методу расчета
- **Диаграмма:** Services_Layer, Models_DTOs

### 5. **Ingredient Scanner** 🍽️
- Сканирование состава продукта
- OCR обработка
- Проверка халяльности
- База ингредиентов
- **Диаграмма:** Services_Layer, Features_UI_Layer

### 6. **Quran Reader** 📖
- Полный текст 114 сур
- Чтение с сохранением прогресса
- Fast индексирование
- **Диаграмма:** Services_Layer, Features_UI_Layer

### 7. **Halal Places Map** 🗺️
- Поиск мечетей и ресторанов
- MapKit интеграция
- Фильтры по типам
- **Диаграмма:** Services_Layer, Features_UI_Layer

### 8. **Settings** ⚙️
- Профиль пользователя
- Выбор LLM модели
- Настройки уведомлений
- Выход из аккаунта
- **Диаграмма:** Features_UI_Layer

---

## 🔑 Ключевые компоненты

### Архитектурные паттерны:
- ✅ **Coordinator Pattern** — навигация
- ✅ **Dependency Injection** — управление зависимостями
- ✅ **Factory Pattern** — создание экранов
- ✅ **MVVM** — структура Views/ViewModels
- ✅ **Protocol-Oriented** — слабая связанность
- ✅ **Layered Architecture** — разделение ответственности

### Технологии:
- ✅ **SwiftUI** — UI framework
- ✅ **@Observable** — reactive state management
- ✅ **URLSession** — networking
- ✅ **CoreLocation** — GPS
- ✅ **MapKit** — карты
- ✅ **Vision** — OCR
- ✅ **UserNotifications** — уведомления
- ✅ **Adhan** — расчет молитв

---

## 📊 Размер проекта

| Метрика | Значение |
|---------|----------|
| **Views** | 17 основных |
| **ViewModels** | 9 |
| **Services** | 11 (protokol + impl) |
| **Models** | 40+ |
| **Features** | 8 |
| **Coordinators** | 4 |
| **API Endpoints** | 6+ |
| **Lines of Code** | ~5000+ |
| **Packages** | 0 (только Apple frameworks) |

---

## 🧭 Как навигировать в проекте

### Если нужно...

**Добавить новую функцию:**
1. Посмотреть `Features_UI_Layer.puml` как структурирован feature
2. Создать View + ViewModel (по существующему паттерну)
3. Добавить Service (Protocol + Impl)
4. Добавить case в Coordinator
5. Добавить factory метод

**Исправить навигацию:**
1. Посмотреть `Navigation_Architecture.puml`
2. Отредактировать соответствующий Coordinator enum
3. Обновить `Coordinator` logic если нужна

**Интегрировать новый API:**
1. Посмотреть `Application_Core.puml`
2. Добавить case в `Endpoint` enum
3. Создать `APIRequest` реализацию
4. Использовать в Service через `NetworkClient`

**Изменить структуру данных:**
1. Посмотреть `Models_DTOs.puml`
2. Обновить модель/DTO
3. Обновить Service если нужно
4. Обновить диаграмму

---

## 📚 Документация

| Документ | Содержание |
|----------|-----------|
| **README.md** | Обзор iOS приложения |
| **NAVIGATION_ARCHITECTURE.md** | Детали навигационной системы |
| **UML_DIAGRAMS_GUIDE.md** | Как использовать UML диаграммы |
| **PROJECT_STRUCTURE.md** | Этот документ |
| **CLAUDE.md** | Правила разработки |
| **docs/ios.md** | Техническая документация |

---

## 🚀 Начало работы

### Для новых разработчиков:
1. Прочитать `README.md` — общий обзор
2. Посмотреть `Navigation_Architecture.puml` — как устроена навигация
3. Посмотреть `Application_Core.puml` — как работает DI
4. Посмотреть `Services_Layer.puml` — какие сервисы есть
5. Посмотреть `Features_UI_Layer.puml` — как структурированы экраны
6. Открыть Xcode и начать экспериментировать

### Для архитекторов/лидов:
1. Посмотреть `HalalAI_Architecture.puml` — полный обзор
2. Посмотреть остальные диаграммы по слоям
3. Использовать как reference при планировании новых функций

### Для диплома/презентации:
1. Использовать `HalalAI_Architecture.puml` как основную
2. Добавить `Navigation_Architecture.puml` для деталей
3. Добавить `Services_Layer.puml` для бизнес-логики
4. Использовать `README.md` для описания

---

## 🔄 Workflow разработки

```
Feature Planning
    ↓
Design (using UML diagrams)
    ↓
Implement (following patterns)
    ↓
Test (unit + UI tests)
    ↓
Code Review
    ↓
Update Diagrams if needed
    ↓
Merge to main
```

---

## 🎨 Диаграммы как живую документацию

**Важно:** Диаграммы должны оставаться актуальными!

При добавлении новых компонентов:
1. ✅ Сначала обновляем код
2. ✅ Затем обновляем диаграммы
3. ✅ Затем обновляем README/документацию

Это гарантирует, что диаграммы остаются полезными и точными.

---

**Дата:** 19 апреля 2026
**Версия:** 1.0
**Статус:** ✅ Актуально
