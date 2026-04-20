# 5.3.3.4 Модуль Scanner — Подробное объяснение

## 🎯 Назначение модуля

Модуль Scanner предназначен для анализа состава продуктов и выявления запрещенных в Исламе (харам) ингредиентов.

**Основной workflow:**
```
Пользователь выбирает источник изображения
        ↓
Получение изображения (камера/галерея/ручной ввод)
        ↓
Распознавание текста (OCR) — Vision Framework
        ↓
IngredientService анализирует текст
        ↓
Сопоставление с базой ингредиентов
        ↓
Определение статуса халяльности
        ↓
Отображение результатов пользователю
```

---

## 📊 Архитектура модуля

### 1. **ScannerView** — экран сканера

**Ответственность:**
- Предоставление интерфейса для выбора источника изображения
- Отображение камеры или галереи
- Отображение результатов анализа
- Управление состоянием загрузки

**Типы ввода:**
- 📷 **Камера** — прямое фотографирование состава
- 🖼️ **Галерея** — выбор существующего фото
- ⌨️ **Ручной ввод** — пользователь вводит ингредиенты текстом

### 2. **ScannerViewModel** — логика экрана

**Основные методы:**
```swift
processImages(_ images: [UIImage]) async
    ↓ вызывает ↓
recognizeText(from: UIImage) async
    ↓ использует ↓
VisionFramework.recognizeText()
    ↓ получает ↓
String (распознанный текст)
    ↓ передает ↓
IngredientService.analyzeText()
```

**Состояние:**
- `manualInput: String` — текст введенный пользователем
- `analysis: ProductAnalysis?` — результат анализа
- `isLoading: Bool` — идет ли обработка

### 3. **IngredientService** — сервис анализа

**Две основные функции:**

#### a) `loadIngredients()` — загрузка базы
```
Приложение запускается
        ↓
IngredientService.loadIngredients()
        ↓
Загрузка CSV файла из Bundle
        ↓
Парсинг ингредиентов в [Ingredient]
        ↓
Сохранение в памяти для быстрого доступа
```

Ингредиенты содержат:
- `id` — уникальный идентификатор
- `eCode` — пищевая добавка (E-код)
- `nameRu` — название на русском
- `nameEn` — название на английском
- `status` — халал/харам/сомнительно/неизвестно

#### b) `analyzeText(_ text: String)` — анализ состава

```
Входящий текст:
"Растительное масло, сахар, яйцо, эмульгатор E471, ванилин"
        ↓
Извлечение отдельных ингредиентов
        ↓
Для каждого ингредиента:
  - Поиск в базе (точное совпадение)
  - Если не найдено — нечеткий поиск
  - Определение статуса
        ↓
Сбор результатов в ProductAnalysis
        ↓
Определение общего статуса продукта:
  - Если есть ХАРАМ → продукт ХАРАМ
  - Если все ХАЛАЛ → продукт ХАЛАЛ
  - Если есть СОМНИТЕЛЬНО → СОМНИТЕЛЬНО
```

### 4. **Данные и модели**

#### `Ingredient` — ингредиент из базы
```swift
struct Ingredient {
    id: "1234"
    eCode: "E471"
    status: .halal
    nameRu: "Моностеарат глицерина"
    nameEn: "Glycerol monostearate"
}
```

#### `IngredientStatus` — статус халяльности
```
case halal       ✅ Разрешено в Исламе
case haram       ❌ Запрещено в Исламе
case mushbooh    ⚠️ Сомнительно (требует уточнения)
case unknown     ❓ Неизвестный статус
```

#### `DetectedIngredient` — обнаруженный ингредиент
```swift
struct DetectedIngredient {
    name: "E471"                    // Что нашли в тексте
    status: .halal                  // Какой статус
    matchedIngredient: Ingredient?  // Найденное совпадение в БД
}
```

#### `ProductAnalysis` — результат анализа
```swift
struct ProductAnalysis {
    ingredients: [DetectedIngredient]        // Все найденные ингредиенты
    overallStatus: IngredientStatus          // Общий статус продукта
    haramIngredients: [Ingredient]           // Запрещенные ингредиенты
    mushboohIngredients: [Ingredient]        // Сомнительные ингредиенты

    var isHalal: Bool { overallStatus == .halal }
}
```

---

## 🔄 Сценарии использования

### Сценарий 1: Сканирование из камеры

```
Пользователь нажимает кнопку "Камера"
        ↓
CameraView открывает камеру устройства
        ↓
Пользователь фотографирует состав продукта
        ↓
UIImage передается в ScannerViewModel
        ↓
ScannerViewModel.recognizeText(from: UIImage)
        ↓
Vision Framework распознает текст (OCR)
        ↓
Полученный текст → IngredientService.analyzeText()
        ↓
ProductAnalysis возвращается обратно
        ↓
IngredientResultsView отображает результаты
```

### Сценарий 2: Выбор из галереи

```
Пользователь нажимает кнопку "Галерея"
        ↓
PHPickerViewController открывается
        ↓
Пользователь выбирает фото из библиотеки
        ↓
[Остальное аналогично сценарию 1]
```

### Сценарий 3: Ручной ввод

```
Пользователь нажимает "Ввести вручную"
        ↓
TextField для ввода текста состава
        ↓
Пользователь вводит: "Масло, сахар, яйцо"
        ↓
Нажимает "Проверить"
        ↓
ScannerViewModel.processManualInput()
        ↓
IngredientService.analyzeText(manualInput)
        ↓
Результаты отображаются
```

---

## 🔐 Контроль доступа

**Только авторизованные пользователи могут использовать Scanner:**

```swift
if authManager.isAuthenticated {
    // Показать ScannerView
} else if authManager.isGuest {
    // Показать баннер: "Требуется вход для сканирования"
}
```

Гостевые пользователи не могут сканировать из-за:
- Ограничения лицензирования
- Необходимости отслеживания использования сервиса
- Требований backend API

---

## 📋 Технические детали

### Vision Framework (OCR)

```swift
import Vision

// Распознавание текста из изображения
func recognizeText(from image: UIImage) async -> String {
    guard let cgImage = image.cgImage else { return "" }

    let request = VNRecognizeTextRequest()
    let handler = VNImageRequestHandler(cgImage: cgImage)

    try? handler.perform([request])

    // Извлечение текста из результатов
    let recognizedStrings = (request.results as? [VNRecognizedTextObservation])?
        .compactMap { $0.topCandidate(1)?.string } ?? []

    return recognizedStrings.joined(separator: " ")
}
```

### Алгоритм сопоставления ингредиентов

```
Входящий текст: "Масло растительное, сахар, яйцо, E471"
        ↓
Split по запятым, точкам, скобкам
        ↓
["Масло растительное", "сахар", "яйцо", "E471"]
        ↓
Для каждого слова/фразы:
  1. Точный поиск в базе (case-insensitive)
  2. Нечеткий поиск (Levenshtein distance)
  3. Поиск по E-коду (если есть)
  4. Если ничего не найдено → unknown status
```

### Базовая структура CSV файла ингредиентов

```csv
id,eCode,status,nameRu,nameEn
1,E471,halal,Моностеарат глицерина,Glycerol monostearate
2,E445,haram,Желатин,Gelatin
3,,halal,Подсолнечное масло,Sunflower oil
```

---

## ⚙️ Интеграция с системой

### Где используется ScannerView?

**Навигация из HomeView:**
```
HomeView
    └─ Кнопка "Проверить продукт"
        └─ coordinator.nextStep(step: .home(.scanner))
            └─ ScannerView отображается
```

### Как ScannerViewModel создается?

```swift
// В ScreenFactory:
func makeScannerView() -> ScannerView {
    return ScannerView(
        ingredientService: dc.ingredientService,
        authManager: dc.authManager
    )
}
```

### Инициализация IngredientService

```swift
// При старте приложения:
IngredientServiceImpl().loadIngredients()
    // Загружает CSV из Bundle
    // Парсит в [Ingredient]
    // Сохраняет в памяти для быстрого доступа
```

---

## 🎯 Ключевые особенности

### 1. **Разделение ответственности**
- ✅ ScannerView — только UI
- ✅ ScannerViewModel — логика взаимодействия
- ✅ IngredientService — сетевые и аналитические операции

### 2. **Асинхронная обработка**
- ✅ OCR выполняется в фоне
- ✅ Анализ ингредиентов без блокировки UI
- ✅ Плавное отображение результатов

### 3. **Кэширование базы**
- ✅ Ингредиенты загружаются один раз
- ✅ Быстрый поиск в памяти
- ✅ Минимизация сетевых запросов

### 4. **Безопасность**
- ✅ Только авторизованные пользователи
- ✅ Проверка authManager перед использованием
- ✅ Никаких личных данных в запросах

---

## 📊 Пример результата анализа

**Входящий текст:**
```
Ингредиенты: Растительное масло, сахар, яйцо,
эмульгатор E471, консервант E210, желатин
```

**Результат анализа:**
```
ProductAnalysis(
    ingredients: [
        DetectedIngredient(name: "Масло", status: .halal, ...),
        DetectedIngredient(name: "Сахар", status: .halal, ...),
        DetectedIngredient(name: "Яйцо", status: .halal, ...),
        DetectedIngredient(name: "E471", status: .halal, ...),
        DetectedIngredient(name: "E210", status: .mushbooh, ...),
        DetectedIngredient(name: "Желатин", status: .haram, ...)
    ],
    overallStatus: .haram,  // ← Есть запрещенный ингредиент
    haramIngredients: [Ingredient(желатин)],
    mushboohIngredients: [Ingredient(E210)]
)
```

**Отображение:**
```
❌ ПРОДУКТ ХАРАМ

Запрещенные ингредиенты:
• Желатин (животного происхождения)

Сомнительные ингредиенты:
⚠️ E210 (Бензойная кислота)
```

---

**Диаграмма:** `Chapter_5_3_3_4_Scanner_Module.puml`
