# iOS Context

Инструкции для разработки iOS приложения (папка `HalalAI-ios/`).

## Сборка и запуск

### Команды сборки
- **Debug сборка (Xcode):** `xcodebuild -project HalalAI-ios/HalalAI.xcodeproj -scheme HalalAI -configuration Debug`
- **Release сборка:** `xcodebuild -project HalalAI-ios/HalalAI.xcodeproj -scheme HalalAI -configuration Release`
- **Очистка:** `xcodebuild -project HalalAI-ios/HalalAI.xcodeproj -scheme HalalAI clean`

### Запуск в симуляторе
- **Открыть Xcode:** `open HalalAI-ios/HalalAI.xcodeproj`
- Собрать и запустить через кнопку Run в Xcode или использовать `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 15'`

### Тестирование
- **Запуск unit тестов:** `xcodebuild -project HalalAI-ios/HalalAI.xcodeproj -scheme HalalAI -target HalalAITests test`
- **Запуск UI тестов:** `xcodebuild -project HalalAI-ios/HalalAI.xcodeproj -scheme HalalAI -target HalalAIUITests test`

## Архитектура

**Паттерн:** SwiftUI + Coordinator pattern + Dependency Injection

### 1. Coordinator Pattern (`HalalAI-ios/HalalAI/Coordinators/`)
   - Единственный класс `Coordinator` управляет навигацией через `[Step]` path + `currentSelectedTab`
   - Per-tab координаторы (enums): `HomeCoordinator`, `ChatCoordinator`, `SettingsCoordinator`
   - Каждый координатор имеет cases и вычисляемое свойство `view`
   - Навигация: `coordinator.nextStep(step:)` добавляет в path; `coordinator.dismiss()` удаляет

### 2. Внедрение зависимостей (`HalalAI-ios/HalalAI/App/ScreenFactory.swift`)
   - Глобальный `@MainActor` instance: `let screenFactory = ScreenFactoryImpl()`
   - `ScreenFactoryImpl` оборачивает `DependencyContainer` (fileprivate)
   - Все сервисы инстанцируются один раз в `DependencyContainer.init()`
   - Factory методы создают views с внедренными зависимостями

### 3. Views & ViewModels (`HalalAI-ios/HalalAI/UI/Screens/`)
   - Views — это SwiftUI `struct View`, принимающие сервисы в `init()`
   - ViewModels определяются как `extension ViewName { @Observable final class ViewModel {...} }`
   - ViewModel хранится как `@State var viewModel: ViewModel`, инициализируется в `init()` view
   - Используйте `@Bindable var vm = viewModel` в body для `$vm.property` bindings

### 4. Сервисы (`HalalAI-ios/HalalAI/Services/`)
   - Паттерн Protocol + Impl: `protocol XService` + `@Observable final class XServiceImpl: XService`
   - Сервисы отмечены `@MainActor` (UI-bound операции)
   - Внедряются в ViewModels или Views через factory

### 5. Data Models (`HalalAI-ios/HalalAI/Models/`)
   - Codable structs для API/персистентности
   - Общие для всех сервисов и UI

## Ключевые компоненты

### TabBar (3 tabs)
- Home, Chat, Settings
- `TabBarItem` enum определяет tabs
- `TabBarView` отрисовывает capsule с offsets `[-100, 0, 100]`
- Добавление 4-го tab требует обновления offsets

### Prayer Time System
- Файлы: `PrayerTimeService.swift`, `PrayerNotificationService.swift`
- Чистый Swift алгоритм (без внешних пакетов)
- `LocationService`: оборачивает `CLLocationManager`, @MainActor с nonisolated делегат методы
- `PrayerSettingsStore`: сохраняет `PrayerSettings` JSON в UserDefaults (`HalalAI.prayerSettings`)
- Notifications: 5 молитв × 7 дней = 35 pending (в пределах iOS лимита 64)

### Аутентификация
- Сервисы: `AuthService`, `AuthManager`
- JWT токены, сохраняются безопасно
- Поддержка гостевого режима
- Backend: `http://localhost:8080` (DEBUG) / production URL (RELEASE)

### Сетевые запросы
- `URLSession` для REST API вызовов
- Async/await везде (без Combine subscription chains)
- Localhost HTTP разрешен через `Info.plist` NSExceptionDomains

## Ключевые файлы

| Файл | Назначение |
|------|-----------|
| `HalalAI-ios/HalalAI/App/HalalAIApp.swift` | Точка входа (@main) |
| `HalalAI-ios/HalalAI/App/ScreenFactory.swift` | DI + factory |
| `HalalAI-ios/HalalAI/Coordinators/Coordinator.swift` | Главный coordinator навигации |
| `HalalAI-ios/HalalAI/Services/` | Бизнес-логика сервисов |
| `HalalAI-ios/HalalAI/UI/Screens/` | Иерархия views по features |
| `HalalAI-ios/HalalAI/Info.plist` | Права доступа (camera, location, photos) |
| `HalalAI-ios/HalalAI.xcodeproj` | Xcode проект |

## Паттерны разработки

### Добавление нового экрана

1. Создайте папку под `HalalAI-ios/HalalAI/UI/Screens/{FeatureName}/`
2. Добавьте `{FeatureName}View.swift`:
   ```swift
   import SwiftUI

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
   ```
3. Создайте `ViewModel/{FeatureName}ViewModel.swift`:
   ```swift
   extension MyView {
       @MainActor
       @Observable
       final class ViewModel {
           // State
           var someProperty = ""

           init(service: SomeService) {
               // Setup
           }
       }
   }
   ```
4. Добавьте factory метод в `ScreenFactory.swift`:
   ```swift
   func makeMyView() -> MyView {
       return MyView(someService: dc.someService)
   }
   ```
5. Добавьте case в релевантный coordinator enum + view builder
6. Обновите `Coordinator.swift` Step enum если нужно

### Добавление нового сервиса

1. Создайте протокол в `HalalAI-ios/HalalAI/Services/MyService.swift`
2. Создайте impl: `@MainActor @Observable final class MyServiceImpl: MyService`
3. Добавьте в `DependencyContainer.init()` в `ScreenFactory.swift`
4. Внедрите где нужно

### Навигация

- Между tabs: `coordinator.selectTab(item: .home)`
- Внутри tab: `coordinator.nextStep(step: .Home(.someCase))`
- Назад: `coordinator.dismiss()`
- В корень: `coordinator.toRoot()`

## Правила кода

### @Observable вместо ObservableObject
- **ВСЕГДА** используйте `@Observable` макрос (Swift 5.10+)
- НЕ используйте `ObservableObject` + `@Published`
- @Observable применяется ко всем ViewModels и сервисам

### @MainActor
- Все UI-related сервисы и ViewModels должны быть `@MainActor`
- Delegate методы в сервисах помечайте `nonisolated` если требуется

### Без внешних зависимостей
- Нет SPM пакетов (только Apple frameworks)
- Нет CocoaPods
- Нет сторонних LLM/ML фреймворков
- Весь networking через `URLSession`
- Весь state через `@Observable`

## Окружение

- **iOS Минимум:** iOS 16+ (использует @Observable)
- **Язык:** Swift 5.10+
- **Build System:** Xcode 15+
- **Возможности устройства:** Location, Camera (для scanner), Photo Library

## Права доступа (Info.plist)

- `NSLocationWhenInUseUsageDescription` — для расчета времени намаза
- `NSCameraUsageDescription` — для сканирования ингредиентов продуктов
- `NSPhotoLibraryUsageDescription` — для выбора фото состава в scanner
- Localhost HTTP разрешен для разработки (NSExceptionDomains)

## Git & Коммиты

- Main branch: `main`
- Коммиты на русском/английском
- Последние работы: Система молитв, интеграция карты, поддержка гостевого режима
- **Пользователь сам создает коммиты** — не создавайте их автоматически

## Интеграция с Backend

iOS приложение взаимодействует с:
1. **Backend API** (Spring Boot): `http://localhost:8080/api/auth`, `/api/chat`
2. **LLM Service** (Python FastAPI): Оркестрируется Backend

Используйте `AuthService` для auth endpoints и `ChatService` для chat запросов.
