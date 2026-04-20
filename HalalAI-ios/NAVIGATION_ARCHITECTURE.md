# HalalAI Navigation Architecture — UML диаграмма классов

## 📊 Структурная диаграмма модуля навигации

```
┌─────────────────────────────────────────────────────────────────┐
│                     Navigation Module                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    RouterView                            │   │
│  │ ─────────────────────────────────────────────────────── │   │
│  │  - coordinator: Coordinator                             │   │
│  │  - isKeyboardVisible: Bool                              │   │
│  │  - tabBarHeight: Int = 80                               │   │
│  │ ─────────────────────────────────────────────────────── │   │
│  │  - body: View                                           │   │
│  │  - tabRootView: ViewBuilder                             │   │
│  │  - shouldShowTabBar: Bool                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                            ▲                                     │
│                            │ contains                             │
│                            │                                     │
│  ┌─────────────────────────┴───────────────────────────┐        │
│  │                                                     │        │
│  │                                                     ▼        │
│  │  ┌──────────────────────────────────────────────────────┐   │
│  │  │           Coordinator (Main)                        │   │
│  │  │ @MainActor @Observable final class                 │   │
│  │  ├──────────────────────────────────────────────────────┤   │
│  │  │ Properties:                                          │   │
│  │  │  - path: [Step] = []                               │   │
│  │  │  - currentSelectedTab: TabBarItem = .home          │   │
│  │  ├──────────────────────────────────────────────────────┤   │
│  │  │ Methods:                                             │   │
│  │  │  + init()                                           │   │
│  │  │  + nextStep(step: Step) → Void                     │   │
│  │  │  + dismiss() → Void                                │   │
│  │  │  + toRoot() → Void                                 │   │
│  │  │  + selectTab(item: TabBarItem) → Void             │   │
│  │  │  + build(step: Step) → View                        │   │
│  │  └──────────────────────────────────────────────────────┘   │
│  │           ▲                    ▲                             │
│  │           │ manages            │ manages                     │
│  │           │                    │                             │
│  │  ┌────────┴────────────────────┴──────────┐               │
│  │  │                                        │                │
│  │  ▼                                        ▼                │
│  │ ┌──────────────┐              ┌─────────────────────┐    │
│  │ │ Step (enum)  │              │ TabBarItem (enum)   │    │
│  │ │──────────────│              │─────────────────────│    │
│  │ │ case chat    │──┐           │ case home           │    │
│  │ │ case settings│  │           │ case chat           │    │
│  │ │ case home    │  │           │ case settings       │    │
│  │ │──────────────│  │           │─────────────────────│    │
│  │ │ Associated: │  │           │ var model:          │    │
│  │ │ ChatCoordinator  │           │   TabBarItemModel  │    │
│  │ │ SettingsCoordinator          └─────────────────────┘    │
│  │ │ HomeCoordinator              ▲                          │
│  │ └──────────────┘               │ provides                 │
│  │      │    │                    │                          │
│  │      │    └────────────────┐   │                          │
│  │      │                     │   │                          │
│  │      └──────────────┐      │   │                          │
│  │                     │      │   │                          │
│  │                     ▼      ▼   ▼                          │
│  │  ┌─────────────────────────────────────────┐             │
│  │  │      TabBarItemModel                    │             │
│  │  ├─────────────────────────────────────────┤             │
│  │  │  + indexInTab: Int                      │             │
│  │  │  + name: String                         │             │
│  │  │  + image: UIImage                       │             │
│  │  └─────────────────────────────────────────┘             │
│  │                                                           │
│  └───────────────────────────────────────────────────────────┘
│
│  ┌─────────────────────────────────────────────────────────┐
│  │           TabBarView                                    │
│  ├─────────────────────────────────────────────────────────┤
│  │  - coordinator: Coordinator                             │
│  ├─────────────────────────────────────────────────────────┤
│  │  - body: View                                           │
│  │    ├─ HStack { ZStack { SelectedCapsule, [TabBarIcon] }}
│  │    └─ RoundedRectangle (background)                    │
│  └─────────────────────────────────────────────────────────┘
│            │                                                 │
│            ├─ contains ──────┐                              │
│            │                 ▼                              │
│            │        ┌──────────────────────┐                │
│            │        │ SelectedCapsule      │                │
│            │        ├──────────────────────┤                │
│            │        │ - selectedTab        │                │
│            │        │ - positions: [CGFloat]               │
│            │        ├──────────────────────┤                │
│            │        │ - body: View         │                │
│            │        └──────────────────────┘                │
│            │                                                 │
│            └─ contains ──────┐                              │
│                              ▼                              │
│                      ┌──────────────────────┐                │
│                      │ TabBarIcon           │                │
│                      ├──────────────────────┤                │
│                      │ - tab: TabBarItem    │                │
│                      │ - coordinator        │                │
│                      ├──────────────────────┤                │
│                      │ - body: View         │                │
│                      └──────────────────────┘                │
│
│  ┌─────────────────────────────────────────────────────────┐
│  │         Coordinator Enums                               │
│  ├─────────────────────────────────────────────────────────┤
│  │                                                          │
│  │  ┌─────────────────────┐  ┌──────────────┐  ┌───────┐ │
│  │  │ HomeCoordinator     │  │ChatCoordinator  │Settings  │ │
│  │  ├─────────────────────┤  ├──────────────┤  ├───────┤ │
│  │  │ case home           │  │ case chat    │  │case   │ │
│  │  │ case scanner        │  │──────────────┤  │settings
│  │  │ case quran          │  │ var view     │  │──────┤ │
│  │  │ case sura(Int)      │  └──────────────┘  │var   │ │
│  │  │ case prayerSettings │                    │view  │ │
│  │  │ case halalMap       │                    └───────┘ │
│  │  ├─────────────────────┤                              │
│  │  │ var view: View      │   AuthCoordinator            │
│  │  └─────────────────────┘   ├──────────────┤           │
│  │                            │ case login   │           │
│  │                            │ case register           │
│  │                            └──────────────┘           │
│  └─────────────────────────────────────────────────────────┘
│
└─────────────────────────────────────────────────────────────────┘
```

## 📋 Классы и структуры (детально)

### 1. **Coordinator** (Main Navigation Controller)
```swift
@MainActor @Observable final class Coordinator
```

|属性 | Тип | Описание |
|------|-----|----------|
| `path` | `[Step]` | Stack навигации для NavigationStack |
| `currentSelectedTab` | `TabBarItem` | Текущая выбранная вкладка |

| Метод | Сигнатура | Описание |
|-------|-----------|----------|
| `nextStep` | `(step: Step) → Void` | Добавить новый шаг в path |
| `dismiss` | `() → Void` | Удалить последний шаг из path |
| `toRoot` | `() → Void` | Очистить весь path |
| `selectTab` | `(item: TabBarItem) → Void` | Переключиться на другую вкладку (очищает path) |
| `build` | `(step: Step) → View` | Построить View для конкретного Step |

**Роль:** Основной контроллер навигации приложения. Управляет всеми переходами и состоянием пути навигации.

---

### 2. **RouterView** (Root Navigation View)
```swift
struct RouterView: View
```

| Свойство | Тип | Описание |
|----------|-----|----------|
| `coordinator` | `Coordinator` | @State: главный координатор |
| `isKeyboardVisible` | `Bool` | Состояние видимости клавиатуры |
| `tabBarHeight` | `Int` | Высота TabBar: 80 pt |

| Computed Property | Тип | Описание |
|------------------|-----|----------|
| `tabRootView` | `View` | ViewBuilder для текущей вкладки |
| `shouldShowTabBar` | `Bool` | Показывать ли TabBar (зависит от клавиатуры) |

**Роль:** Корневой View, который объединяет NavigationStack с TabBar. Отслеживает видимость клавиатуры и скрывает TabBar при вводе текста.

**Логика:**
1. Создает `NavigationStack` с path из coordinator
2. Отображает текущий tab через `tabRootView`
3. Отрисовывает `TabBarView` внизу (если не видна клавиатура)
4. Обрабатывает события клавиатуры через `NotificationCenter`

---

### 3. **TabBarView** (TabBar UI Component)
```swift
struct TabBarView: View
```

| Свойство | Тип | Описание |
|----------|-----|----------|
| `coordinator` | `Coordinator` | Environment: доступ к coordinator |

**Структура:**
```
HStack {
  ZStack {
    SelectedCapsule (背景)
    HStack(spacing: 50) {
      TabBarIcon (home)
      TabBarIcon (chat)
      TabBarIcon (settings)
    }
  }
}
.background(RoundedRectangle + shadow)
```

**Роль:** Отрисовывает 3 вкладки с анимированной capsule для выбранной вкладки.

---

### 4. **SelectedCapsule** (Animated Selection Background)
```swift
struct SelectedCapsule: View
```

| Свойство | Тип | Описание |
|----------|-----|----------|
| `selectedTab` | `TabBarItem` | Текущая вкладка |
| `positions` | `[CGFloat]` | X-offsets для capsule: [-77.0, 0, 77.0] |

**Анимация:** `bouncy(extraBounce: 0.017)` при смене вкладки

---

### 5. **TabBarIcon** (Tab Button)
```swift
struct TabBarIcon: View
```

| Свойство | Тип | Описание |
|----------|-----|----------|
| `tab` | `TabBarItem` | Какую вкладку этот icon представляет |
| `coordinator` | `Coordinator` | Для вызова selectTab |

**Действие:** При нажатии вызывает `coordinator.selectTab(item: tab)`

---

### 6. **Step** (Navigation Enum)
```swift
enum Step: Hashable, Equatable
```

```swift
case chat(_ val: ChatCoordinator)
case settings(_ val: SettingsCoordinator)
case home(_ val: HomeCoordinator)
```

**Роль:** Связывает navigation destination с конкретным coordinator. Используется в `NavigationStack(path:)`.

---

### 7. **HomeCoordinator** (Home Tab Routes)
```swift
enum HomeCoordinator: Hashable
```

| Case | Associated Value | Экран |
|------|-----------------|--------|
| `home` | — | HomeView (главный экран) |
| `scanner` | — | ScannerView (сканирование) |
| `quran` | — | QuranListView (список сур) |
| `sura` | `suraIndex: Int` | SuraReaderView (чтение суры) |
| `prayerSettings` | — | PrayerNotificationSettingsView |
| `halalMap` | — | HalalMapView (карта) |

| Property | Тип | Описание |
|----------|-----|----------|
| `view` | `View` | ViewBuilder для отрисовки экрана |

**Роль:** Управляет всеми экранами Home вкладки.

---

### 8. **ChatCoordinator** (Chat Tab Routes)
```swift
enum ChatCoordinator
```

| Case | Экран |
|------|--------|
| `chat` | ChatView (чат с AI) |

**Роль:** Простой coordinator для Chat вкладки (всего один экран).

---

### 9. **SettingsCoordinator** (Settings Tab Routes)
```swift
enum SettingsCoordinator
```

| Case | Экран |
|------|--------|
| `settings` | SettingsView (настройки) |

**Роль:** Простой coordinator для Settings вкладки.

---

### 10. **AuthCoordinator** (Authentication Flow)
```swift
enum AuthCoordinator: Hashable
```

| Case | Экран |
|------|--------|
| `login` | LoginView |
| `register` | RegisterView |

**Роль:** Управляет auth flow (используется в RootView для первоначальной авторизации).

---

### 11. **TabBarItem** (Tab Definitions)
```swift
enum TabBarItem
```

| Case | Index | Icon | Name |
|------|-------|------|------|
| `home` | 0 | house.fill | "Homepage" |
| `chat` | 1 | brain.head.profile.fill | "Chat" |
| `settings` | 2 | gearshape.fill | "Settings" |

| Property | Тип | Описание |
|----------|-----|----------|
| `model` | `TabBarItemModel` | Модель для UI отрисовки |

---

### 12. **TabBarItemModel** (Tab Model)
```swift
struct TabBarItemModel
```

| Свойство | Тип | Описание |
|----------|-----|----------|
| `indexInTab` | `Int` | Индекс вкладки (0, 1, 2) |
| `name` | `String` | Название для accessibility |
| `image` | `UIImage` | SF Symbol image |

---

## 🔄 Диаграмма взаимодействия (Sequence)

### Сценарий 1: Переключение вкладок

```
User Tap on Chat Tab
    ↓
TabBarIcon (chat) button pressed
    ↓
coordinator.selectTab(item: .chat)
    ↓
Coordinator:
  - path = []              (очистить путь)
  - currentSelectedTab = .chat
    ↓
RouterView observes change
    ↓
tabRootView switches case
    ↓
Render: coordinator.build(step: .chat(.chat))
    ↓
ChatView rendered
```

### Сценарий 2: Навигация внутри Home вкладки

```
User tap "Scanner" button on HomeView
    ↓
coordinator.nextStep(step: .home(.scanner))
    ↓
Coordinator: path.append(.home(.scanner))
    ↓
NavigationStack updates
    ↓
navigationDestination triggered
    ↓
Render: coordinator.build(step: .home(.scanner))
    ↓
ScannerView pushed
```

### Сценарий 3: Возврат к предыдущему экрану

```
User tap Back button
    ↓
coordinator.dismiss()
    ↓
Coordinator: path.removeLast()
    ↓
NavigationStack pops
    ↓
Previous screen rendered
```

---

## 🎯 Data Flow (поток данных)

```
┌──────────────┐
│  User Input  │ (нажатие на tab, кнопку и т.д.)
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│  UI Component        │ (TabBarIcon, Button)
│  (обрабатывает action) │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────────────────┐
│  Coordinator Method              │
│  selectTab() / nextStep()         │
│  dismiss() / toRoot()             │
└──────┬───────────────────────────┘
       │
       ▼
┌────────────────────────────────────┐
│  Coordinator State Updated         │
│  @Observable marks state as dirty  │
└──────┬──────────────────────────────┘
       │
       ▼
┌────────────────────────────────────┐
│  RouterView Re-renders             │
│  (observes coordinator changes)    │
└──────┬──────────────────────────────┘
       │
       ├─ path changed?
       │   └─ NavigationStack updates
       │       └─ navigationDestination triggered
       │           └─ Render new screen
       │
       └─ currentSelectedTab changed?
           └─ tabRootView switches case
               └─ Render new tab root screen
```

---

## 🏗️ Архитектурные паттерны

### 1. **Coordinator Pattern**
- **Целевой**: Централизованное управление навигацией
- **Реализация**: Single `Coordinator` + multiple coordinator enums per tab
- **Преимущества**:
  - Все логика переходов в одном месте
  - Легко отследить, куда может перейти пользователь
  - Переиспользуемость координаторов

### 2. **Observable Pattern (@Observable)**
- **Целевой**: Reactive state management
- **Реализация**: `@Observable` macro на Coordinator
- **Преимущества**:
  - Views автоматически перерисовываются при изменении состояния
  - Никаких manual subscriptions
  - Type-safe и compile-time проверки

### 3. **Environment Pattern**
- **Целевой**: Передача coordinator глубоко вложенным views
- **Реализация**: `.environment(coordinator)` в RouterView
- **Преимущества**:
  - Coordinator доступен везде через `@Environment`
  - Не нужно передавать через параметры

### 4. **NavigationStack with Enums**
- **Целевой**: Type-safe navigation
- **Реализация**: `NavigationStack(path:)` с enum `Step`
- **Преимущества**:
  - Compile-time проверки
  - Не может быть невалидного state
  - Easy back navigation (просто `removeLast()`)

---

## 🚀 Flow Management

### Tab Selection Flow
```swift
selectTab(item: .home)
  │
  ├─ if item == currentSelectedTab:
  │   └─ path = []  (toggle: clear if same tab)
  │       └─ Back to root if already on tab
  │
  └─ else:
      ├─ path = []
      └─ currentSelectedTab = item
```

### Step Navigation Flow
```swift
nextStep(step: .home(.scanner))
  │
  └─ path.append(step)
      └─ NavigationStack auto updates
          └─ New screen pushed
```

### Back Navigation Flow
```swift
dismiss()
  │
  ├─ if !path.isEmpty:
  │   └─ path.removeLast()
  │       └─ NavigationStack auto pops
  │
  └─ else:
      └─ (no-op, уже в root)
```

---

## 📝 Примеры использования

### Переключение на Settings вкладку
```swift
@Environment(Coordinator.self) var coordinator

// ...
Button("Go to Settings") {
    coordinator.selectTab(item: .settings)
}
```

### Навигация к Scanner в Home
```swift
coordinator.nextStep(step: .home(.scanner))
```

### Читать Quran -> Конкретная sura
```swift
// В QuranListView:
coordinator.nextStep(step: .home(.sura(suraIndex: 1)))
```

### Вернуться назад
```swift
coordinator.dismiss()
```

### Back to Root of Tab
```swift
coordinator.toRoot()
```

---

## ⚙️ Вспомогательные механизмы

### Keyboard Visibility Handling
```swift
RouterView observes:
  - UIResponder.keyboardWillShowNotification
  - UIResponder.keyboardWillHideNotification

When keyboard shows:
  - shouldShowTabBar = false
  - TabBar transitions out with animation

When keyboard hides:
  - shouldShowTabBar = true
  - TabBar transitions in with animation
```

### Tab Bar Positioning
```
Positions: [-77.0, 0, 77.0]

Home (index 0):  x = -77.0
Chat (index 1):  x = 0
Settings (index 2): x = 77.0

Spacing between icons: 50pt
```

---

## 📊 Сравнение с альтернативными подходами

| Подход | Плюсы | Минусы |
|--------|-------|--------|
| **Coordinator (текущий)** | Централизованно, type-safe | Более код |
| NavigationView + @StateObject | Просто | Deprecated, сложнее с tabs |
| NavigationLink | Встроено | Не типобезопасно, hard to manage |
| Custom routing library | Feature-rich | External dependency |

---

## 🔗 Интеграция с другими модулями

```
Navigation Module
    │
    ├─ Depends on:
    │   └─ ScreenFactory (для построения Views)
    │
    ├─ Used by:
    │   ├─ RootView (auth switch)
    │   └─ Views (для навигации)
    │
    └─ Provides:
        ├─ Coordinator (@Environment)
        └─ Navigation API
```

---

**Дата создания:** 19 апреля 2026
**Версия:** 1.0
