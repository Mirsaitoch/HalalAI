# HalalAI iOS

Мобильное приложение для поиска исламской информации: проверка халяльности продуктов, чат с AI ассистентом, время молитвы и чтение Корана.

## 📋 Описание

**HalalAI** — iOS приложение на SwiftUI для:
- 🍽️ **Сканирование ингредиентов** — проверка халяльности состава продуктов с помощью камеры
- 💬 **Чат с AI** — ответы на исламские вопросы с интеграцией LLM и RAG по Корану
- 🕌 **Время молитвы** — расчет по текущей локации, уведомления о времени молитвы
- 📖 **Чтение Корана** — полный текст всех 114 сур с поиском
- 🗺️ **Карта халяльных ресторанов** — поиск мест для еды
- 📿 **Исламская информация** — случайные айаты Корана на главном экране

## 🏗️ Архитектура

### Стек технологий
- **UI:** SwiftUI (iOS 17+)
- **Паттерны:** Coordinator, Dependency Injection
- **State Management:** `@Observable` макрос (не ObservableObject)
- **Networking:** URLSession, async/await
- **Зависимости:** только Apple frameworks (нет SPM/CocoaPods)

### Ключевые паттерны

#### 1. Coordinator Pattern
```
RouterView
├─ Coordinator (управляет path и текущей вкладкой)
├─ HomeCoordinator (home, scanner, quran, sura, prayerSettings, halalMap)
├─ ChatCoordinator (chat)
└─ SettingsCoordinator (settings)
```

- Главная навигация в `RouterView` через `path: [Step]`
- Каждый шаг — enum case с ассоциированными значениями
- Горячие клавиши: `selectTab()`, `nextStep()`, `dismiss()`, `toRoot()`

#### 2. Dependency Injection
- `@MainActor let screenFactory = ScreenFactoryImpl()` — глобальный DI контейнер
- `DependencyContainer` в `ScreenFactory` создает все сервисы один раз
- Factory методы (`makeHomeView()`, `makeChatView()` и т.д.) внедряют зависимости

#### 3. @Observable ViewModels
```swift
struct SomeView: View {
    @State private var viewModel: ViewModel

    var body: some View {
        @Bindable var vm = viewModel
        // используйте $vm.property для bindings
    }
}

extension SomeView {
    @Observable final class ViewModel {
        var property: String = ""
    }
}
```

#### 4. Services
- Protocol + Implementation паттерн
- `@MainActor @Observable` для UI-bound сервисов
- Внедряются через factory

## 📁 Структура проекта

```
HalalAI-ios/
├── HalalAI/
│   ├── App/
│   │   ├── HalalAIApp.swift         # Entry point (@main)
│   │   ├── RootView.swift           # Auth / Main switch
│   │   └── ScreenFactory.swift      # DI + factory
│   │
│   ├── Navigation/
│   │   ├── Coordinator.swift        # Main coordinator (path, currentTab)
│   │   ├── RouterView.swift         # Root navigation stack
│   │   ├── HomeCoordinator.swift    # Home tab routes
│   │   ├── ChatCoordinator.swift    # Chat tab routes
│   │   ├── SettingsCoordinator.swift# Settings tab routes
│   │   ├── AuthCoordinator.swift    # Auth flows
│   │   └── TabBar/
│   │       ├── TabBarItem.swift     # Enum: home, chat, settings
│   │       └── TabBarView.swift     # TabBar UI
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       ├── Login/
│   │   │       └── Register/
│   │   ├── Home/                    # Main tab
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       ├── HomeView
│   │   │       └── VerseView
│   │   ├── Chat/                    # Chat with AI
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       ├── ChatView
│   │   │       ├── MessageBubble
│   │   │       └── InputBar
│   │   ├── Scanner/                 # Ingredient scanner
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       └── ScannerView
│   │   ├── Quran/                   # Quran reader
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       ├── QuranListView
│   │   │       └── SuraReaderView
│   │   ├── Prayer/                  # Prayer times
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       ├── PrayerTimesCardView
│   │   │       └── PrayerNotificationSettingsView
│   │   ├── HalalMap/                # Halal restaurants map
│   │   │   ├── Models/
│   │   │   ├── Service/
│   │   │   └── UI/
│   │   │       └── HalalMapView
│   │   └── Settings/
│   │       └── UI/
│   │           └── SettingsView
│   │
│   ├── Core/
│   │   ├── Network/
│   │   │   ├── NetworkClient.swift
│   │   │   ├── APIConfiguration.swift
│   │   │   ├── APIRequest.swift
│   │   │   ├── Endpoint.swift
│   │   │   └── NetworkError.swift
│   │   ├── Location/
│   │   │   └── LocationService.swift
│   │   ├── Components/               # Reusable UI
│   │   │   ├── GuestBannerView
│   │   │   ├── ErrorView
│   │   │   └── ...
│   │   └── Extensions/
│   │       ├── View+AdditionalPadding
│   │       ├── View+HideKeyboard
│   │       └── HapticFeedback+Modes
│   │
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   ├── Colors.xcassets
│   │   ├── Images.xcassets
│   │   └── Info.plist               # Permissions (camera, location)
│   │
│   └── Models/                      # Shared domain models
│       ├── Message.swift
│       ├── User.swift
│       ├── PrayerTime.swift
│       └── ...
│
├── HalalAITests/                    # Unit tests
├── HalalAIUITests/                  # UI tests
│   ├── LoginUITests.swift
│   └── RegisterUITests.swift
├── HalalAI.xcodeproj
└── README.md
```

## 🎯 Основные вкладки (TabBar)

### 1. **Home** 🏠
Главный экран с:
- **Verse Card** — случайный айат из Корана
- **Guest Banner** — для гостей (неавторизованных пользователей)
- **Prayer Times Card** — время молитвы + обратный отсчет
- **Быстрые кнопки:**
  - Scanner — сканирование продуктов
  - Quran — читать весь Коран
  - Map — найти мечеть/ресторан
  - Prayer Settings — уведомления о молитве

### 2. **Chat** 💬
Диалог с LLM ассистентом:
- История сообщений
- Интеграция с Backend (REST API)
- Поддержка выбора модели (OpenRouter)
- RAG поиск по Корану

### 3. **Settings** ⚙️
- Профиль пользователя (авторизованные)
- Выбор LLM модели
- Настройки уведомлений
- Выход из аккаунта

## 🔐 Аутентификация

- **AuthManager** — управление состоянием авторизации
- **AuthService** — REST API auth (login/register)
- **Режимы:**
  - Гостевой (browse без функционала)
  - Полный (с auth через backend)
- **Хранение токенов** — безопасное (Keychain через backend)
- **Backend:** `http://localhost:8080/api/auth/` (dev) / production URL (release)

## 🙏 Система молитвы

### PrayerTimeService
- **Алгоритм:** чистый Swift (без внешних пакетов)
- **Расчет по:** GPS координаты + часовой пояс
- **5 молитв:** Fajr (рассвет), Dhuhr (полдень), Asr (полдник), Maghrib (закат), Isha (ночь)

### LocationService
- Обертка над `CLLocationManager` (с `@MainActor` изоляцией)
- Асинхронный запрос текущей локации

### PrayerSettingsStore
- Персистентность в `UserDefaults` (ключ: `HalalAI.prayerSettings`)
- JSON сериализация `PrayerSettings`
- Настройки: метод расчета, смещение времени

### Уведомления
- До 35 (5 молитв × 7 дней)
- В пределах лимита iOS (64 максимум)
- Настраиваются в `PrayerNotificationSettingsView`

## 🍽️ Scanner (Сканирование ингредиентов)

### ScannerView
- Камера для фотографирования состава продукта
- OCR обработка (распознавание текста)
- Интеграция с backend для проверки халяльности

### IngredientService
- REST API запросы к backend
- Проверка каждого ингредиента
- Кэширование результатов

## 📖 Quran Reader

### QuranStorage
- Полный текст 114 сур на памяти
- Fast lookup индексация

### QuranListView
- Список всех сур (сураhs)
- Поиск по названию/номеру

### SuraReaderView
- Full text surah с оформлением
- Аяты пронумерованы
- Возможность поиска внутри

## 🗺️ Halal Map

### HalalMapService
- Запрос к backend с координатами
- Поиск мечетей и халяльных ресторанов

### HalalMapView
- Map интеграция (MapKit)
- Фильтры по типам мест
- Детали места (контакты, рейтинг)

## 🌐 Сетевые запросы

### NetworkClient
- URLSession обертка
- Async/await везде (без Combine)
- Timeout, retry логика

### APIRequest / Endpoint
- Type-safe API requests
- Automatic JSON encoding/decoding
- Error handling

### Примеры запросов
```swift
// Chat
POST /api/chat/send { message, modelId? }
GET /api/chat/history

// Scanner
POST /api/scanner/check { ingredients: [String] }

// Prayer settings
GET/POST /api/prayer/settings
```

## 🔧 Разработка

### Запуск приложения
```bash
# Открыть в Xcode
open HalalAI-ios/HalalAI.xcodeproj

# Или через xcodebuild
xcodebuild -project HalalAI-ios/HalalAI.xcodeproj \
  -scheme HalalAI \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Unit тесты
```bash
xcodebuild -project HalalAI-ios/HalalAI.xcodeproj \
  -scheme HalalAI \
  -target HalalAITests \
  test
```

### UI тесты
```bash
xcodebuild -project HalalAI-ios/HalalAI.xcodeproj \
  -scheme HalalAI \
  -target HalalAIUITests \
  test
```

### Отладка

#### Проверка сетевых запросов
- Xcode Network tab в Console
- Proxy tools (Charles, Proxyman)
- Backend logs: `docker-compose logs -f`

#### Проверка локации
- Simulator → Features → Location → Custom Location
- Попробуйте разные города для тестирования времени молитвы

#### Уведомления
- Simulator Settings → Notifications должны быть разрешены
- Проверьте `Info.plist` права

## 📋 Добавление нового экрана

1. Создайте папку: `Features/{FeatureName}/UI`
2. Создайте View:
   ```swift
   struct MyView: View {
       let someService: SomeService
       @State private var viewModel: ViewModel

       init(someService: SomeService) {
           self.someService = someService
           _viewModel = State(initialValue: ViewModel(service: someService))
       }

       var body: some View {
           @Bindable var vm = viewModel
           Text("Content")
       }
   }

   extension MyView {
       @Observable final class ViewModel {
           var property = ""
           init(service: SomeService) { }
       }
   }
   ```
3. Добавьте в ScreenFactory:
   ```swift
   func makeMyView() -> MyView {
       return MyView(someService: dc.someService)
   }
   ```
4. Добавьте case в релевантный Coordinator (enum)
5. Используйте: `coordinator.nextStep(step: .home(.myCase))`

## 📦 Зависимости

- **Нет SPM пакетов** (только Apple frameworks)
- **Нет CocoaPods**
- **Нет сторонних LLM/ML библиотек**

## 🔒 Права доступа (Info.plist)

| Право | Назначение |
|-------|-----------|
| `NSLocationWhenInUseUsageDescription` | Расчет времени молитвы |
| `NSCameraUsageDescription` | Сканирование ингредиентов |
| `NSPhotoLibraryUsageDescription` | Выбор фото для scanner |
| `NSLocalNetworkUsageDescription` | Локальный backend (dev) |

## 🌍 Интеграция с Backend

iOS ↔ Spring Boot Backend ↔ Python LLM Service

```
iOS
  ├─ REST API → Backend (port 8080)
  │   ├─ /api/auth/* (login/register)
  │   ├─ /api/chat/* (messages)
  │   ├─ /api/scanner/* (check ingredients)
  │   ├─ /api/prayer/* (settings)
  │   └─ /api/quran/* (search)
  │
  └─ Backend (внутренно)
      └─ Python LLM Service (port 8001)
```

## 📚 Дополнительная документация

- **Подробный контекст iOS:** [`docs/ios.md`](../docs/ios.md)
- **Backend интеграция:** [`docs/backend.md`](../docs/backend.md)
- **Проектное состояние:** [`CLAUDE.md`](../CLAUDE.md)

## 🚀 Последние изменения

- ✅ Система молитвы с уведомлениями
- ✅ Карта халяльных мест (HalalMap)
- ✅ Сканирование ингредиентов
- ✅ Чтение Корана
- ✅ Поддержка пользовательских LLM моделей
- ✅ Гостевой режим

## 👨‍💻 Стандарты кода

- **`@Observable`** (не `ObservableObject`)
- **Coordinator pattern** для навигации
- **Protocol + Implementation** для сервисов
- **`@MainActor`** для UI-bound кода
- **Async/await** везде (нет Combine)
- **No external dependencies** (только Apple frameworks)

## 📞 Контакты

Вопросы по кодовой базе? Смотрите `CLAUDE.md` в корне проекта.

---

**Последнее обновление:** 19 апреля 2026
