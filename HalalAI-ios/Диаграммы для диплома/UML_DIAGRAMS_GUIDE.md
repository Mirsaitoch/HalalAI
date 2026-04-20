# HalalAI iOS Project — UML Диаграммы архитектуры

## 📊 Созданные диаграммы

### 1. **HalalAI_Architecture.puml** — Полная архитектура проекта
**Назначение:** High-level обзор всех компонентов и их взаимодействия

**Включает:**
- **App Layer** — точка входа, DI, factory
- **Navigation Layer** — координаторы и маршруты
- **Features** — 8 основных функций (Auth, Chat, Home, Prayer, Scanner, Quran, HalalMap, Settings)
- **Core Layer** — сетевой слой, локация, компоненты
- **Models & DTOs** — структуры данных

**Используется для:** Общего понимания архитектуры, представления на диплом/презентацию

---

### 2. **Navigation_Architecture.puml** — Навигационный слой (чистый)
**Назначение:** Детальное изучение системы навигации

**Включает:**
- `Coordinator` — главный контроллер
- `RouterView` — корневой view
- `Step`, `HomeCoordinator`, `ChatCoordinator`, `SettingsCoordinator` — маршруты
- `AuthCoordinator` — auth flow
- `TabBarItem`, `TabBarView` — управление вкладками

**Используется для:** Понимания как работает навигация в приложении

---

### 3. **Application_Core.puml** — Ядро приложения и DI
**Назначение:** Детально показать как работает инъекция зависимостей

**Включает:**
- `HalalAIApp` — entry point
- `RootView` — выбор между auth и main
- `ScreenFactory` + `ScreenFactoryImpl` — factory pattern
- `DependencyContainer` — IoC контейнер со всеми сервисами
- `NetworkClient` — сетевой клиент
- `APIRequest`, `Endpoint`, `HTTPMethod` — типизированные запросы

**Используется для:** Понимания как приложение инициализируется и как работает DI

---

### 4. **Services_Layer.puml** — Слой сервисов
**Назначение:** Показать все бизнес-логику сервисов

**Включает:**
- `AuthManager`, `AuthService` — аутентификация
- `ChatService` — чат с AI
- `VerseService` — аят дня
- `PrayerTimeService`, `PrayerNotificationService` — время молитв
- `LocationService` — геолокация
- `IngredientService` — сканирование ингредиентов
- `QuranStorageService` — хранилище Корана
- `HalalPlacesService` — поиск мест

**Используется для:** Понимания бизнес-логики и как сервисы взаимодействуют

---

### 5. **Features_UI_Layer.puml** — Слой UI и ViewModels
**Назначение:** Показать все экраны и их ViewModels

**Включает:**
- **Auth:** `LoginView`, `RegisterView` с ViewModels
- **Chat:** `ChatView`, `MessageBubble`, `InputBar` с ViewModel
- **Home:** `HomeView`, `VerseView`, `PrayerTimesCardView` с ViewModels
- **Prayer:** `PrayerNotificationSettingsView`
- **Scanner:** `ScannerView`, `CameraView`, `IngredientResultsView` с ViewModel
- **Quran:** `QuranListView`, `SuraReaderView` с ViewModels
- **HalalMap:** `HalalMapView` с ViewModel
- **Settings:** `SettingsView` с ViewModel
- **Components:** `GuestBannerView`, `ErrorView`

**Используется для:** Понимания структуры UI и связей между экранами и сервисами

---

### 6. **Models_DTOs.puml** — Модели данных
**Назначение:** Показать все структуры данных и их взаимосвязи

**Включает:**
- **Auth Models** — `User`, `AuthResponse`, `AuthState`, `AuthError`
- **Chat Models** — `ChatMessage`, `Role`, `ChatState`, `ConnectionState`, `ChatRequest/Response`
- **Verse Models** — `Verse`
- **Prayer Models** — `DailyPrayerTimes`, `Prayer`, `PrayerSettings`, `PrayerCalculationMethod`
- **Scanner Models** — `Ingredient`, `IngredientStatus`, `ProductAnalysis`, `DetectedIngredient`
- **Quran Models** — `Sura`, `QuranVerse`
- **HalalMap Models** — `HalalPlace`
- **Network/API Models** — `APIConfiguration`, `HTTPMethod`, `NetworkError`

**Используется для:** Понимания структуры данных и типов, используемых в приложении

---

## 🎯 Как использовать диаграммы

### Просмотр онлайн
1. Перейти на [PlantUML Online Editor](http://www.plantuml.com/plantuml/uml/)
2. Скопировать содержимое `.puml` файла
3. Вставить в редактор
4. Увидеть визуальную диаграмму

### Генерирование изображения
```bash
# Установить PlantUML
brew install plantuml

# Генерировать PNG
plantuml HalalAI_Architecture.puml -o ./images

# Генерировать SVG (векторный)
plantuml -tsvg HalalAI_Architecture.puml -o ./images
```

### Интеграция в документацию
```markdown
![HalalAI Architecture](images/HalalAI_Architecture.png)
```

---

## 📋 Рекомендуемый порядок изучения

### Для новых разработчиков:
1. **Navigation_Architecture.puml** — понять как работает навигация
2. **Application_Core.puml** — понять DI и инициализацию
3. **Services_Layer.puml** — понять бизнес-логику
4. **Features_UI_Layer.puml** — понять структуру экранов
5. **Models_DTOs.puml** — понять структуру данных
6. **HalalAI_Architecture.puml** — общий обзор всего проекта

### Для apresentации/диплома:
- Использовать **HalalAI_Architecture.puml** как основную диаграмму
- Дополнить **Services_Layer.puml** для показа сервисов
- Показать **Models_DTOs.puml** для полноты

---

## 🏗️ Архитектурные паттерны, видные в диаграммах

### 1. **Layered Architecture (Многоуровневая архитектура)**
```
UI Layer (Views, ViewModels)
        ↓
Service Layer (сервисы, бизнес-логика)
        ↓
Network Layer (API клиент, эндпоинты)
        ↓
Data Layer (модели, DTOs)
```

### 2. **Dependency Injection**
- `DependencyContainer` создает все сервисы один раз
- `ScreenFactory` использует DI для создания экранов
- Все сервисы внедряются через конструкторы

### 3. **Coordinator Pattern**
- Единственный `Coordinator` управляет всей навигацией
- Per-feature координаторы (enums) управляют маршрутами в пределах функции
- `NavigationStack` + `path` для stack-based навигации

### 4. **Protocol-Oriented Design**
- Все сервисы имеют протоколы
- Реализации отделены от интерфейсов
- Легко подменять реализации для тестирования

### 5. **MVVM (Model-View-ViewModel)**
- ViewModels как вложенные классы в Views
- `@Observable` для реактивности
- Бизнес-логика отделена от UI

---

## 🔗 Связи между компонентами

### Основной data flow:
```
User Interaction
    ↓
View / ViewController
    ↓
ViewModel (обработка)
    ↓
Service (бизнес-логика)
    ↓
NetworkClient (API запрос)
    ↓
Server
```

### Reverse data flow:
```
Server Response
    ↓
NetworkClient (parse)
    ↓
Service (process)
    ↓
ViewModel (update state)
    ↓
View (re-render via @Observable)
    ↓
UI Update
```

---

## 📊 Статистика проекта

| Компонент | Количество |
|-----------|-----------|
| **Views** | 12 основных + 5 компонентов |
| **ViewModels** | 9 |
| **Services** | 11 (protocol + impl) |
| **Models/Structs** | 40+ |
| **Enums** | 15+ |
| **Features** | 8 |
| **API Endpoints** | 6+ |
| **Lines of Code** | ~5000+ (без комментариев) |

---

## 🎨 Легенда диаграмм

### Стрелки:
- `-->` (простая) — ассоциация/использование
- `*--` (композиция) — содержание/владение
- `o--` (агрегация) — слабая принадлежность
- `..|>` (пунктирная) — реализация интерфейса/протокола
- `..>` (пунктирная) — зависимость

### Элементы:
- `protocol` — протокол/интерфейс
- `class` — класс
- `struct` — структура
- `enum` — перечисление
- `interface` — протокол (в PlantUML)

---

## 🚀 Примеры использования диаграмм

### Пример 1: Добавление нового сервиса
Используя **Services_Layer.puml**, видно:
1. Нужно создать протокол `MyService`
2. Создать реализацию `MyServiceImpl`
3. Добавить в `DependencyContainer`
4. Внедрить в нужные ViewModels/Views

### Пример 2: Добавление нового экрана
Используя **Features_UI_Layer.puml**, видно:
1. Создать View с ViewModel (как вложенный класс)
2. Внедрить нужные сервисы
3. Добавить case в соответствующий Coordinator
4. Добавить factory метод в `ScreenFactory`

### Пример 3: Добавление нового API endpoint
Используя **Application_Core.puml**, видно:
1. Добавить case в `Endpoint` enum
2. Создать `APIRequest` реализацию
3. Использовать `NetworkClient.send()`

---

## 📝 Классификация диаграмм

### По уровню абстракции:
- **High-level** — HalalAI_Architecture.puml (все компоненты)
- **Mid-level** — Navigation, Services, Features (по слоям)
- **Low-level** — Models_DTOs.puml (детали данных)

### По назначению:
- **Архитектурные** — HalalAI_Architecture, Navigation, Application_Core
- **Бизнес-логики** — Services_Layer
- **UI** — Features_UI_Layer
- **Данных** — Models_DTOs

---

## 🔄 Актуальность диаграмм

Диаграммы созданы на основе актуального состояния проекта (апрель 2026) и отражают:
- Структуру проекта на данный момент
- Все реализованные функции
- Правильные зависимости между компонентами
- Паттерны разработки, используемые в проекте

**При добавлении новых функций важно обновлять диаграммы, чтобы они оставались актуальными!**

---

**Дата создания:** 19 апреля 2026
**Версия:** 1.0
**Автор:** Claude Code
