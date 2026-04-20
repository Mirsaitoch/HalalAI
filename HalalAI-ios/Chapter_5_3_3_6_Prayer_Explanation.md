# 5.3.3.6 Модуль времени молитвы — Подробное объяснение

## 🕌 Назначение модуля

Модуль Prayer предоставляет функциональность расчета времени молитв (намаза) на основе текущего местоположения пользователя и управления уведомлениями о приближении времени молитвы.

**Основной workflow:**
```
Пользователь открывает HomeView
        ↓
PrayerTimesCardView запрашивает текущую локацию
        ↓
LocationService получает GPS координаты
        ↓
PrayerTimeService рассчитывает время молитв для этого дня
        ↓
Отображение карточки с 5 временами молитв
        ↓
Расчет времени до следующей молитвы (обратный отсчет)
        ↓
Уведомления отправляются в установленное время
```

---

## 🔧 Архитектура модуля

### 1. **PrayerTimeService** — расчет времени молитв

**Протокол:**
```swift
protocol PrayerTimeService {
    func calculateTimes(
        for coordinate: CLLocationCoordinate2D,
        date: Date,
        method: PrayerCalculationMethod
    ) -> DailyPrayerTimes

    func nextPrayer(
        from times: DailyPrayerTimes,
        date: Date
    ) -> Prayer?
}
```

**Реализация: PrayerTimeServiceImpl**

Использует **библиотеку Adhan** (Swift пакет для расчета времени молитв):
```swift
import Adhan

let coords = Adhan.Coordinates(
    latitude: location.coordinate.latitude,
    longitude: location.coordinate.longitude
)

let times = Adhan.PrayerTimes(
    coordinates: coords,
    date: dateComponents,
    calculationParameters: params
)
```

**Adhan** — популярная открытая библиотека для расчета исламских молитв на основе астрономических вычислений:
- Положение Солнца (elevation angle)
- Географические координаты (широта, долгота)
- Часовой пояс
- Метод расчета (Россия, Татарстан, Muslim World League и т.д.)

#### Методы расчета:

| Метод | Угол Фаджра | Угол Иши | Регион |
|-------|-----------|---------|--------|
| **Russia** | 17.5° | 17.5° | РФ, Казахстан |
| **Tatarstan** | 16.5° | 16.5° | Татарстан, Башкирия |
| **Muslim World League** | 18° | 17° | Международный стандарт |
| **ISNA** | 15° | 15° | Северная Америка |
| **Egypt** | 19.5° | 17.5° | Египет |
| **Makkah** | 18.5° | 90 мин после Магриба | Саудовская Аравия |

#### 5 времен молитв:

```
Фаджр (Fajr)        — рассвет (04:30 - 05:30)
          ↓
Зухр (Dhuhr)        — полдень (12:30 - 13:30)
          ↓
Аср (Asr)           — полдник (15:00 - 16:30)
          ↓
Магриб (Maghrib)    — закат (18:30 - 19:30)
          ↓
Иша (Isha)          — ночь (20:30 - 22:00)
```

### 2. **LocationService** — получение локации

**Функция:**
```
Приложение запускается
        ↓
LocationService.requestLocation()
        ↓
CLLocationManager запрашивает разрешение у пользователя
        ↓
Пользователь разрешает: "While Using"
        ↓
GPS получает координаты (latitude, longitude)
        ↓
Координаты передаются в PrayerTimeService
```

**Важно:** Локация необходима для точного расчета, так как время молитвы зависит от географического положения.

### 3. **PrayerNotificationService** — управление уведомлениями

**Ответственность:**
- Запрос разрешения на отправку уведомлений (UNUserNotificationCenter)
- Планирование уведомлений для всех 5 молитв на 7 дней вперед
- Максимум 35 уведомлений (в пределах лимита iOS 64)
- Отмена уведомлений при изменении настроек

**Процесс:**
```
PrayerNotificationSettingsView открыта
        ↓
Пользователь включает уведомление для Фаджра
        ↓
Устанавливает смещение: -5 мин (за 5 минут до молитвы)
        ↓
PrayerNotificationService.scheduleNotifications()
        ↓
Для каждой молитвы на 7 дней:
  - Рассчитать время + смещение
  - Создать UNNotificationRequest
  - Отправить в UNUserNotificationCenter
        ↓
Уведомления будут отправлены в установленное время
        ↓
Пользователь получает системное уведомление на экран блокировки
```

### 4. **PrayerSettingsStore** — сохранение настроек

**Сохраняемые настройки:**
```swift
struct PrayerSettings {
    var calculationMethod: PrayerCalculationMethod  // Метод расчета
    var madhab: Madhab                              // Школа права (Shafi/Hanafi)
    var customFajrAngle: Double?                    // Пользовательский угол Фаджра
    var customIshaAngle: Double?                    // Пользовательский угол Иши
    var notifications: [Prayer: PrayerNotificationSetting]

    struct PrayerNotificationSetting {
        var isEnabled: Bool       // Уведомление включено?
        var offsetMinutes: Int    // За сколько минут уведомлить?
    }
}
```

**Персистентность:**
- Хранится в UserDefaults (ключ: `HalalAI.prayerSettings`)
- JSON кодирование/декодирование
- Загружается при старте приложения

---

## 📊 Данные модели

### DailyPrayerTimes — время молитв на день

```swift
struct DailyPrayerTimes {
    var date: Date
    var fajr: Date      // 04:45
    var sunrise: Date   // 06:15 (дополнительно, для информации)
    var dhuhr: Date     // 12:30
    var asr: Date       // 15:20
    var maghrib: Date   // 18:35
    var isha: Date      // 20:10

    // Вспомогательные методы:
    func time(for prayer: Prayer) -> Date?
    func allPrayers() -> [(Prayer, Date)]
}
```

### Prayer — enum молитв

```swift
enum Prayer: Hashable {
    case fajr
    case dhuhr
    case asr
    case maghrib
    case isha

    var localizedName: String {
        switch self {
        case .fajr: return "Фаджр"
        case .dhuhr: return "Зухр"
        case .asr: return "Аср"
        case .maghrib: return "Магриб"
        case .isha: return "Иша"
        }
    }

    var systemImage: String {
        // Разные иконки для каждой молитвы
    }
}
```

---

## 🕐 PrayerTimesCardViewModel — логика карточки молитв

**Свойства:**
```swift
class PrayerTimesCardViewModel {
    var todayTimes: DailyPrayerTimes?
    var nextPrayer: Prayer?
    var timeUntilNextPrayer: TimeInterval?
    var displayedTimes: DailyPrayerTimes?
    var effectiveDayOffset: Int = 0  // Для просмотра молитв на другие дни
}
```

**Процесс обновления:**
```
1. Получить текущую локацию (LocationService)
   ↓
2. Рассчитать время молитв (PrayerTimeService)
   ↓
3. Найти следующую молитву
   ↓
4. Запустить Timer для обновления обратного отсчета
   ↓
5. @Observable уведомляет View об изменениях
   ↓
6. View переренднерится с новыми временами
```

---

## ⚙️ Процесс установки уведомлений

### При первом открытии приложения:

```
1. PrayerTimesCardViewModel.refresh()
   ↓
2. Загрузить PrayerSettings из UserDefaults
   ↓
3. Если это первый раз или настройки изменились:
   ↓
4. PrayerNotificationService.requestAuthorization()
   - Запросить разрешение: "Хотите ли вы получать уведомления о молитвах?"
   ↓
5. Если пользователь разрешил:
   ↓
6. PrayerNotificationService.scheduleNotifications(for: todayTimes)
   - Для каждой молитвы с включенным уведомлением:
     * Рассчитать время + смещение
     * Создать UNNotificationRequest
     * UNUserNotificationCenter.add(request)
```

### Максимальное количество уведомлений:

```
5 молитв × 7 дней = 35 уведомлений

В пределах лимита iOS (макс 64 pending notifications)
```

### Пример уведомления:

```
Title: "Фаджр"
Body: "Время молитвы приближается"
Sound: default
Badge: +1
FireDate: 2026-04-20 04:40:00 (за 5 мин до Фаджра)
```

---

## 🎯 Взаимодействие компонентов

### Сценарий 1: Открытие HomeView

```
HomeView появляется на экране
        ↓
PrayerTimesCardView инициализируется
        ↓
PrayerTimesCardViewModel.refresh()
        ↓
LocationService.requestLocation()
  └─ если разрешено: получить GPS координаты
  └─ если запрещено: использовать последние известные координаты
        ↓
PrayerTimeService.calculateTimes(coordinates)
        ↓
DailyPrayerTimes рассчитаны для сегодня
        ↓
PrayerTimeService.nextPrayer() → определить следующую молитву
        ↓
View обновляется с новыми временами
        ↓
Timer запущен для обновления обратного отсчета каждую секунду
```

### Сценарий 2: Изменение метода расчета в настройках

```
PrayerNotificationSettingsView открыта
        ↓
Пользователь выбирает "Татарстан" вместо "Россия"
        ↓
PrayerSettings.calculationMethod = .tatarstan
        ↓
Сохранено в UserDefaults
        ↓
PrayerTimeService использует новый метод
        ↓
Времена молитв пересчитываются
        ↓
PrayerNotificationService.cancelAllPrayerNotifications()
        ↓
Запланированы новые уведомления с новыми временами
        ↓
Пользователь видит обновленные времена
```

### Сценарий 3: Получение уведомления

```
В установленное время (например, 04:40 для Фаджра):
        ↓
iOS отправляет локальное уведомление
        ↓
Пользователь видит на экране блокировки:
   ┌─────────────────────┐
   │ HalalAI             │
   │ 🕌 Фаджр            │
   │ Время молитвы       │
   │ приближается        │
   └─────────────────────┘
        ↓
Пользователь может коснуться и открыть приложение
```

---

## 📐 Алгоритм расчета времени молитв

**Входные данные:**
- Географические координаты (широта, долгота)
- Дата и время
- Метод расчета (углы возвышения Солнца)
- Часовой пояс

**Процесс:**
```
1. Рассчитать юлианский день (Julian Day Number)
2. Рассчитать положение Солнца (прямое восхождение, склонение)
3. Для каждой молитвы:
   a. Рассчитать угол возвышения Солнца в момент молитвы
   b. Решить уравнение: sin(elevation) = sin(latitude) * sin(declination)
                          + cos(latitude) * cos(declination) * cos(hour_angle)
   c. Найти время (hour angle) когда это уравнение выполняется
   d. Конвертировать в местное время
4. Применить корректировки (смещения по методу расчета)
5. Вернуть DailyPrayerTimes
```

**Точность:** ±1-2 минуты в зависимости от метода расчета

---

## 🔐 Разрешения и безопасность

**Требуемые разрешения:**
- `NSLocationWhenInUseUsageDescription` — для определения молитвы
- `NSUserNotificationsUsageDescription` — для уведомлений
- `NSCalendarsUsageDescription` — для работы с датами/временем

**Обработка отказа:**
```
Если пользователь не разрешил локацию:
    └─ Использовать город из настроек (если сохранен)
    └─ Или использовать последние известные координаты
    └─ Или предложить ввести город вручную
```

---

## 🏗️ Связь с другими модулями

```
Home Module
    └─ использует PrayerTimesCardView
        └─ зависит от PrayerTimeService

Settings Module
    └─ PrayerNotificationSettingsView
        └─ управляет PrayerSettings
            └─ triggers PrayerNotificationService
```

---

## 📊 Пример расчета для Казани (55.7964° N, 49.1086° E)

**Дата: 2026-04-20, Метод: Tatarstan**

```
Фаджр (Fajr)      04:45:00  ← -16.5° elevation of sun
Восход (Sunrise)  06:18:00
Зухр (Dhuhr)      12:29:00  ← солнце в зените
Аср (Asr)         15:43:00  ← тень равна высоте объекта
Магриб (Maghrib)  18:41:00  ← заход солнца
Иша (Isha)        20:14:00  ← -16.5° below horizon
```

**Обратный отсчет (текущее время: 12:15):**
```
⏳ До Аср:      1ч 28м
🕌 Текущая молитва: Зухр
⏱️ Времени прошло: 0ч 14м от Зухра
```

---

## 🎨 UI/UX особенности

**PrayerTimesCardView:**
- Отображает все 5 молитв в виде таблицы
- Выделяет текущую молитву
- Показывает обратный отсчет до следующей
- Свайп влево/вправо для просмотра молитв на другие дни

**PrayerNotificationSettingsView:**
- Переключатели для каждой молитвы
- Слайдер для настройки смещения времени (-30 мин до +10 мин)
- Кнопка "Тест уведомления" для проверки

---

**Диаграмма:** `Chapter_5_3_3_6_Prayer_Module.puml`

**Ключевая информация:**
- 📚 **Библиотека Adhan** для расчета времени молитв (астрономические вычисления)
- 🔔 **Apple UserNotifications Framework** для управления уведомлениями
- 📍 **CoreLocation Framework** для получения GPS координат
- 💾 **UserDefaults** для сохранения настроек пользователя
