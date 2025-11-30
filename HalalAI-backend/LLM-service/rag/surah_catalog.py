import re
import unicodedata
from typing import Dict, List, Optional, Set


def _normalize_value(value: str, keep_digits: bool = False) -> str:
    if not value:
        return ""
    normalized = unicodedata.normalize("NFKC", value).lower()
    translation_table = str.maketrans(
        {
            "’": "",
            "'": "",
            "`": "",
            "’": "",
            "“": "",
            "”": "",
            "–": " ",
            "—": " ",
            "-": " ",
            "_": " ",
            ".": " ",
            ",": " ",
            "(": " ",
            ")": " ",
            "/": " ",
            "\\": " ",
        }
    )
    normalized = normalized.translate(translation_table)
    digits = "0-9" if keep_digits else ""
    normalized = re.sub(rf"[^a-zа-яёء-ي{digits}\s]", " ", normalized)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    return normalized


def _contains_cyrillic(value: str) -> bool:
    return any("а" <= ch <= "я" or "ё" == ch for ch in value.lower())


def _strip_articles(value: str) -> str:
    articles = (
        "al ",
        "an ",
        "ar ",
        "as ",
        "ash ",
        "at ",
        "az ",
        "ad ",
        "the ",
        "аль ",
        "ан ",
        "ар ",
        "ас ",
        "аш ",
        "ат ",
        "аз ",
        "ад ",
    )
    for article in articles:
        if value.startswith(article):
            return value[len(article) :].strip()
    return value


def _build_aliases(entry: Dict[str, str]) -> Set[str]:
    names = {entry["latin"], entry["arabic"]}
    names.update(entry.get("translations", []))
    aliases: Set[str] = set()
    for name in names:
        normalized = _normalize_value(name)
        if not normalized:
            continue
        aliases.add(normalized)
        stripped = _strip_articles(normalized)
        if stripped and stripped != normalized:
            aliases.add(stripped)
    return {alias for alias in aliases if alias}


SURAH_DATA = [
    {"number": 1, "latin": "Al-Fatihah", "arabic": "الفاتحة", "translations": ["Открывающая", "Аль-Фатиха", "The Opening"]},
    {"number": 2, "latin": "Al-Baqarah", "arabic": "البقرة", "translations": ["Корова", "Аль-Бакара", "The Cow"]},
    {"number": 3, "latin": "Ali Imran", "arabic": "آل عمران", "translations": ["Семейство Имрана", "Али Имран", "The Family of Imran"]},
    {"number": 4, "latin": "An-Nisa", "arabic": "النساء", "translations": ["Женщины", "Ан-Ниса", "The Women"]},
    {"number": 5, "latin": "Al-Ma'idah", "arabic": "المائدة", "translations": ["Трапеза", "Аль-Маида", "The Table Spread"]},
    {"number": 6, "latin": "Al-An'am", "arabic": "الأنعام", "translations": ["Скот", "Аль-Анам", "The Cattle"]},
    {"number": 7, "latin": "Al-A'raf", "arabic": "الأعراف", "translations": ["Преграды", "Аль-Аъраф", "The Heights"]},
    {"number": 8, "latin": "Al-Anfal", "arabic": "الأنفال", "translations": ["Трофеи", "Аль-Анфаль", "The Spoils of War"]},
    {"number": 9, "latin": "At-Tawbah", "arabic": "التوبة", "translations": ["Покаяние", "Ат-Тауба", "The Repentance"]},
    {"number": 10, "latin": "Yunus", "arabic": "يونس", "translations": ["Юнус", "Йунус", "Jonah"]},
    {"number": 11, "latin": "Hud", "arabic": "هود", "translations": ["Худ", "Гуд", "Hud"]},
    {"number": 12, "latin": "Yusuf", "arabic": "يوسف", "translations": ["Йусуф", "Юсуф", "Joseph"]},
    {"number": 13, "latin": "Ar-Ra'd", "arabic": "الرعد", "translations": ["Гром", "Ар-Ра'д", "The Thunder"]},
    {"number": 14, "latin": "Ibrahim", "arabic": "ابراهيم", "translations": ["Ибрахим", "Авраам", "Abraham"]},
    {"number": 15, "latin": "Al-Hijr", "arabic": "الحجر", "translations": ["Аль-Хиджр", "Каменные долины", "The Rocky Tract"]},
    {"number": 16, "latin": "An-Nahl", "arabic": "النحل", "translations": ["Пчёлы", "Ан-Нахль", "The Bees"]},
    {"number": 17, "latin": "Al-Isra", "arabic": "الإسراء", "translations": ["Ночной перенос", "Аль-Исра", "The Night Journey"]},
    {"number": 18, "latin": "Al-Kahf", "arabic": "الكهف", "translations": ["Пещера", "Аль-Кахф", "The Cave"]},
    {"number": 19, "latin": "Maryam", "arabic": "مريم", "translations": ["Марям", "Марьям", "Mary"]},
    {"number": 20, "latin": "Ta-Ha", "arabic": "طه", "translations": ["Та-Ха", "Та Ха", "Ta-Ha"]},
    {"number": 21, "latin": "Al-Anbiya", "arabic": "الأنبياء", "translations": ["Пророки", "Аль-Анбия", "The Prophets"]},
    {"number": 22, "latin": "Al-Hajj", "arabic": "الحج", "translations": ["Паломничество", "Аль-Хадж", "The Pilgrimage"]},
    {"number": 23, "latin": "Al-Mu'minun", "arabic": "المؤمنون", "translations": ["Верующие", "Аль-Муминун", "The Believers"]},
    {"number": 24, "latin": "An-Nur", "arabic": "النور", "translations": ["Свет", "Ан-Нур", "The Light"]},
    {"number": 25, "latin": "Al-Furqan", "arabic": "الفرقان", "translations": ["Различение", "Аль-Фуркан", "The Criterion"]},
    {"number": 26, "latin": "Ash-Shu'ara", "arabic": "الشعراء", "translations": ["Поэты", "Аш-Шуара", "The Poets"]},
    {"number": 27, "latin": "An-Naml", "arabic": "النمل", "translations": ["Муравьи", "Ан-Намль", "The Ant"]},
    {"number": 28, "latin": "Al-Qasas", "arabic": "القصص", "translations": ["Рассказанные истории", "Аль-Касас", "The Stories"]},
    {"number": 29, "latin": "Al-Ankabut", "arabic": "العنكبوت", "translations": ["Паук", "Аль-Анкабут", "The Spider"]},
    {"number": 30, "latin": "Ar-Rum", "arabic": "الروم", "translations": ["Римляне", "Ар-Рум", "The Romans"]},
    {"number": 31, "latin": "Luqman", "arabic": "لقمان", "translations": ["Лукман", "Лукман", "Luqman"]},
    {"number": 32, "latin": "As-Sajdah", "arabic": "السجدة", "translations": ["Прострация", "Ас-Саджда", "The Prostration"]},
    {"number": 33, "latin": "Al-Ahzab", "arabic": "الأحزاب", "translations": ["Союзники", "Аль-Ахзаб", "The Confederates"]},
    {"number": 34, "latin": "Saba", "arabic": "سبأ", "translations": ["Саба", "Саба", "Sheba"]},
    {"number": 35, "latin": "Fatir", "arabic": "فاطر", "translations": ["Создатель", "Фатир", "The Originator"]},
    {"number": 36, "latin": "Ya-Sin", "arabic": "يس", "translations": ["Йа-Син", "Я-Син", "Ya-Sin"]},
    {"number": 37, "latin": "As-Saffat", "arabic": "الصافات", "translations": ["Выстраивающиеся в ряд", "Ас-Саффат", "Those Who Set The Ranks"]},
    {"number": 38, "latin": "Sad", "arabic": "ص", "translations": ["Сад", "Сад", "Sad"]},
    {"number": 39, "latin": "Az-Zumar", "arabic": "الزمر", "translations": ["Толпы", "Аз-Зумар", "The Groups"]},
    {"number": 40, "latin": "Ghafir", "arabic": "غافر", "translations": ["Прощающий", "Гафир", "The Forgiver"]},
    {"number": 41, "latin": "Fussilat", "arabic": "فصلت", "translations": ["Разъяснены", "Фуссилат", "Explained In Detail"]},
    {"number": 42, "latin": "Ash-Shura", "arabic": "الشورى", "translations": ["Совет", "Аш-Шура", "The Consultation"]},
    {"number": 43, "latin": "Az-Zukhruf", "arabic": "الزخرف", "translations": ["Украшения", "Аз-Зухруф", "The Ornaments of Gold"]},
    {"number": 44, "latin": "Ad-Dukhan", "arabic": "الدخان", "translations": ["Дым", "Ад-Духан", "The Smoke"]},
    {"number": 45, "latin": "Al-Jathiyah", "arabic": "الجاثية", "translations": ["Коленопреклонённые", "Аль-Джасия", "The Crouching"]},
    {"number": 46, "latin": "Al-Ahqaf", "arabic": "الأحقاف", "translations": ["Песчаные дюны", "Аль-Ахкаф", "The Wind-Curved Sandhills"]},
    {"number": 47, "latin": "Muhammad", "arabic": "محمد", "translations": ["Мухаммад", "Мухаммад", "Muhammad"]},
    {"number": 48, "latin": "Al-Fath", "arabic": "الفتح", "translations": ["Победа", "Открытие", "The Victory"]},
    {"number": 49, "latin": "Al-Hujurat", "arabic": "الحجرات", "translations": ["Комнаты", "Аль-Худжурат", "The Rooms"]},
    {"number": 50, "latin": "Qaf", "arabic": "ق", "translations": ["Каф", "Каф", "Qaf"]},
    {"number": 51, "latin": "Adh-Dhariyat", "arabic": "الذاريات", "translations": ["Разносящие", "Ад-Зарият", "The Winnowing Winds"]},
    {"number": 52, "latin": "At-Tur", "arabic": "الطور", "translations": ["Гора", "Ат-Тур", "The Mount"]},
    {"number": 53, "latin": "An-Najm", "arabic": "النجم", "translations": ["Звезда", "Ан-Наджм", "The Star"]},
    {"number": 54, "latin": "Al-Qamar", "arabic": "القمر", "translations": ["Луна", "Аль-Камар", "The Moon"]},
    {"number": 55, "latin": "Ar-Rahman", "arabic": "الرحمن", "translations": ["Милостивый", "Ар-Рахман", "The Beneficent"]},
    {"number": 56, "latin": "Al-Waqi'ah", "arabic": "الواقعة", "translations": ["Неизбежное", "Аль-Ваки'а", "The Inevitable"]},
    {"number": 57, "latin": "Al-Hadid", "arabic": "الحديد", "translations": ["Железо", "Аль-Хадид", "The Iron"]},
    {"number": 58, "latin": "Al-Mujadilah", "arabic": "المجادلة", "translations": ["Спорящая", "Аль-Муджадила", "The Pleading Woman"]},
    {"number": 59, "latin": "Al-Hashr", "arabic": "الحشر", "translations": ["Сбор", "Аль-Хашр", "The Exile"]},
    {"number": 60, "latin": "Al-Mumtahanah", "arabic": "الممتحنة", "translations": ["Испытуемая", "Аль-Мумтахина", "The Examined One"]},
    {"number": 61, "latin": "As-Saff", "arabic": "الصف", "translations": ["Ряды", "Ас-Сафф", "The Ranks"]},
    {"number": 62, "latin": "Al-Jumu'ah", "arabic": "الجمعة", "translations": ["Пятница", "Аль-Джуму'а", "The Congregation"]},
    {"number": 63, "latin": "Al-Munafiqun", "arabic": "المنافقون", "translations": ["Лицемеры", "Аль-Мунафикун", "The Hypocrites"]},
    {"number": 64, "latin": "At-Taghabun", "arabic": "التغابن", "translations": ["Обман", "Ат-Тагабун", "The Mutual Disillusion"]},
    {"number": 65, "latin": "At-Talaq", "arabic": "الطلاق", "translations": ["Развод", "Ат-Талак", "The Divorce"]},
    {"number": 66, "latin": "At-Tahrim", "arabic": "التحريم", "translations": ["Запрещение", "Ат-Тахрим", "The Prohibition"]},
    {"number": 67, "latin": "Al-Mulk", "arabic": "الملك", "translations": ["Власть", "Аль-Мульк", "The Sovereignty"]},
    {"number": 68, "latin": "Al-Qalam", "arabic": "القلم", "translations": ["Писало", "Аль-Калам", "The Pen"]},
    {"number": 69, "latin": "Al-Haqqah", "arabic": "الحاقة", "translations": ["Истина", "Аль-Хакка", "The Reality"]},
    {"number": 70, "latin": "Al-Ma'arij", "arabic": "المعارج", "translations": ["Ступени", "Аль-Мааридж", "The Ascending Stairways"]},
    {"number": 71, "latin": "Nuh", "arabic": "نوح", "translations": ["Нух", "Ной", "Noah"]},
    {"number": 72, "latin": "Al-Jinn", "arabic": "الجن", "translations": ["Джинны", "Аль-Джинн", "The Jinn"]},
    {"number": 73, "latin": "Al-Muzzammil", "arabic": "المزمل", "translations": ["Закутавшийся", "Аль-Муззаммил", "The Enshrouded One"]},
    {"number": 74, "latin": "Al-Muddathir", "arabic": "المدثر", "translations": ["Покрывшийся", "Аль-Муддаттир", "The Cloaked One"]},
    {"number": 75, "latin": "Al-Qiyamah", "arabic": "القيامة", "translations": ["Воскрешение", "Аль-Кияма", "The Resurrection"]},
    {"number": 76, "latin": "Al-Insan", "arabic": "الإنسان", "translations": ["Человек", "Аль-Инсан", "Man"]},
    {"number": 77, "latin": "Al-Mursalat", "arabic": "المرسلات", "translations": ["Посланные", "Аль-Мурсалят", "Those Sent Forth"]},
    {"number": 78, "latin": "An-Naba", "arabic": "النبأ", "translations": ["Весть", "Ан-Наба", "The Announcement"]},
    {"number": 79, "latin": "An-Nazi'at", "arabic": "النازعات", "translations": ["Вырывающие", "Ан-Назиат", "Those Who Drag Forth"]},
    {"number": 80, "latin": "Abasa", "arabic": "عبس", "translations": ["Нахмурился", "Абаса", "He Frowned"]},
    {"number": 81, "latin": "At-Takwir", "arabic": "التكوير", "translations": ["Скручивание", "Ат-Таквир", "The Overturning"]},
    {"number": 82, "latin": "Al-Infitar", "arabic": "الانفطار", "translations": ["Разверзание", "Аль-Инфитар", "The Cleaving"]},
    {"number": 83, "latin": "Al-Mutaffifin", "arabic": "المطففين", "translations": ["Обвешивающие", "Аль-Мутаффифин", "Defrauding"]},
    {"number": 84, "latin": "Al-Inshiqaq", "arabic": "الانشقاق", "translations": ["Раскалывание", "Аль-Иншикак", "The Splitting Open"]},
    {"number": 85, "latin": "Al-Buruj", "arabic": "البروج", "translations": ["Созвездия", "Аль-Бурудж", "The Constellations"]},
    {"number": 86, "latin": "At-Tariq", "arabic": "الطارق", "translations": ["Ночной гость", "Ат-Тарик", "The Morning Star"]},
    {"number": 87, "latin": "Al-A'la", "arabic": "الأعلى", "translations": ["Всевышний", "Аль-Аъля", "The Most High"]},
    {"number": 88, "latin": "Al-Ghashiyah", "arabic": "الغاشية", "translations": ["Покрывающее", "Аль-Гашия", "The Overwhelming"]},
    {"number": 89, "latin": "Al-Fajr", "arabic": "الفجر", "translations": ["Рассвет", "Аль-Фаджр", "The Dawn"]},
    {"number": 90, "latin": "Al-Balad", "arabic": "البلد", "translations": ["Город", "Аль-Балад", "The City"]},
    {"number": 91, "latin": "Ash-Shams", "arabic": "الشمس", "translations": ["Солнце", "Аш-Шамс", "The Sun"]},
    {"number": 92, "latin": "Al-Layl", "arabic": "الليل", "translations": ["Ночь", "Аль-Лайл", "The Night"]},
    {"number": 93, "latin": "Ad-Duha", "arabic": "الضحى", "translations": ["Утро", "Ад-Духа", "The Morning Hours"]},
    {"number": 94, "latin": "Ash-Sharh", "arabic": "الشرح", "translations": ["Раскрытие груди", "Аш-Шарх", "The Relief"]},
    {"number": 95, "latin": "At-Tin", "arabic": "التين", "translations": ["Смоковница", "Ат-Тин", "The Fig"]},
    {"number": 96, "latin": "Al-Alaq", "arabic": "العلق", "translations": ["Сгусток", "Аль-Алак", "The Clinging Clot"]},
    {"number": 97, "latin": "Al-Qadr", "arabic": "القدر", "translations": ["Предопределение", "Аль-Кадр", "The Power"]},
    {"number": 98, "latin": "Al-Bayyinah", "arabic": "البينة", "translations": ["Ясное знамение", "Аль-Баййина", "The Clear Proof"]},
    {"number": 99, "latin": "Az-Zalzalah", "arabic": "الزلزلة", "translations": ["Землетрясение", "Аз-Залзалах", "The Earthquake"]},
    {"number": 100, "latin": "Al-Adiyat", "arabic": "العاديات", "translations": ["Скачущие", "Аль-Адият", "Those That Run"]},
    {"number": 101, "latin": "Al-Qari'ah", "arabic": "القارعة", "translations": ["Поражающее", "Аль-Кариа", "The Striking Calamity"]},
    {"number": 102, "latin": "At-Takathur", "arabic": "التكاثر", "translations": ["Соперничество в богатстве", "Ат-Такатхур", "The Rivalry in World Increase"]},
    {"number": 103, "latin": "Al-Asr", "arabic": "العصر", "translations": ["Время", "Аль-Аср", "The Declining Day"]},
    {"number": 104, "latin": "Al-Humazah", "arabic": "الهمزة", "translations": ["Хулитель", "Аль-Хумаза", "The Slanderer"]},
    {"number": 105, "latin": "Al-Fil", "arabic": "الفيل", "translations": ["Слон", "Аль-Филь", "The Elephant"]},
    {"number": 106, "latin": "Quraysh", "arabic": "قريش", "translations": ["Курайшиты", "Курайш", "Quraysh"]},
    {"number": 107, "latin": "Al-Ma'un", "arabic": "الماعون", "translations": ["Мелкая помощь", "Аль-Маун", "The Small Kindnesses"]},
    {"number": 108, "latin": "Al-Kawthar", "arabic": "الكوثر", "translations": ["Изобилие", "Аль-Каусар", "The Abundance"]},
    {"number": 109, "latin": "Al-Kafirun", "arabic": "الكافرون", "translations": ["Неверующие", "Аль-Кафирун", "The Disbelievers"]},
    {"number": 110, "latin": "An-Nasr", "arabic": "النصر", "translations": ["Помощь", "Ан-Наср", "The Divine Support"]},
    {"number": 111, "latin": "Al-Masad", "arabic": "المسد", "translations": ["Пальмовая верёвка", "Аль-Масад", "The Palm Fiber"]},
    {"number": 112, "latin": "Al-Ikhlas", "arabic": "الإخلاص", "translations": ["Искренность", "Аль-Ихляс", "The Sincerity"]},
    {"number": 113, "latin": "Al-Falaq", "arabic": "الفلق", "translations": ["Рассвет", "Аль-Фалак", "The Daybreak"]},
    {"number": 114, "latin": "An-Nas", "arabic": "الناس", "translations": ["Люди", "Ан-Нас", "Mankind"]},
]

SURAH_BY_NUMBER: Dict[int, Dict[str, str]] = {entry["number"]: entry for entry in SURAH_DATA}

_LONG_ALIAS_INDEX: Dict[str, int] = {}
_SHORT_ALIAS_INDEX: Dict[str, int] = {}
for item in SURAH_DATA:
    for alias in _build_aliases(item):
        key = alias.replace("  ", " ").strip()
        if not key:
            continue
        if len(key.replace(" ", "")) < 4:
            _SHORT_ALIAS_INDEX.setdefault(key, item["number"])
        else:
            _LONG_ALIAS_INDEX.setdefault(key, item["number"])

_SURAH_KEYWORDS = [
    kw
    for kw in {
        _normalize_value("surah"),
        _normalize_value("sura"),
        _normalize_value("surat"),
        _normalize_value("сура"),
        _normalize_value("суры"),
        _normalize_value("сурой"),
        _normalize_value("суре"),
        _normalize_value("сурах"),
        _normalize_value("сурами"),
    }
    if kw
]

_SURAH_NUMBER_FORWARD = re.compile(r"(?:surah|sura|surat|сура|суры|сурой|суре|сурах|сурами)\s*(?P<number>\d{1,3})")
_SURAH_NUMBER_REVERSE = re.compile(r"(?P<number>\d{1,3})\s*(?:surah|sura|surat|сура|суры|сурой|суре|сурах|сурами)")


def match_surah_numbers(text: str) -> List[int]:
    if not text:
        return []
    normalized = _normalize_value(text, keep_digits=True)
    if not normalized:
        return []
    padded = f" {normalized} "
    numbers: Set[int] = set()

    for regex in (_SURAH_NUMBER_FORWARD, _SURAH_NUMBER_REVERSE):
        for match in regex.finditer(padded):
            number = int(match.group("number"))
            if 1 <= number <= 114:
                numbers.add(number)

    for alias, number in _LONG_ALIAS_INDEX.items():
        if f" {alias} " in padded:
            numbers.add(number)

    for alias, number in _SHORT_ALIAS_INDEX.items():
        for keyword in _SURAH_KEYWORDS:
            if f" {keyword} {alias} " in padded or f" {alias} {keyword} " in padded:
                numbers.add(number)
                break

    return sorted(numbers)


def get_surah_info(number: int) -> Optional[Dict[str, str]]:
    try:
        key = int(number)
    except (TypeError, ValueError):
        return None
    return SURAH_BY_NUMBER.get(key)


def get_surah_name(number: int, prefer_locale: str = "ru") -> Optional[str]:
    info = get_surah_info(number)
    if not info:
        return None
    translations = info.get("translations", [])
    if prefer_locale == "ru":
        for value in translations:
            if value and _contains_cyrillic(value):
                return value
    elif prefer_locale == "en":
        for value in translations:
            if value and all(ord(ch) < 128 for ch in value):
                return value
    return info["latin"]


def describe_surah(number: int) -> Optional[str]:
    info = get_surah_info(number)
    if not info:
        return None
    display = get_surah_name(number, prefer_locale="ru") or info["latin"]
    return f"{display} (сура {info['number']})"


__all__ = ["SURAH_DATA", "match_surah_numbers", "get_surah_info", "get_surah_name", "describe_surah"]

