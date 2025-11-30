import json
import sys
from pathlib import Path

import pandas as pd

BASE_DIR = Path(__file__).resolve().parent
sys.path.append(str(BASE_DIR))

from rag.surah_catalog import get_surah_info, get_surah_name  # noqa: E402

TAFSIR_NAMES = {
    "Tafaseer1": "Ибн Касир",
    "Tafaseer2": "Ас-Саади",
}
CSV_PATH = "/Users/mirsaitsabirzanov/Documents/Dev/IOS/HalalAIMono/HalalAI-backend/LLM-service/quran.csv"
OUTPUT = "rag_tafsir_payload.json"
CHUNK_SIZE = 800
CHUNK_OVERLAP = 100

df = pd.read_csv(CSV_PATH)
# Если в исходном CSV нет явного столбца с номером аята, создаём его автоматически
df["ayah_index"] = df.groupby("Surah").cumcount() + 1

documents = []
for idx, row in df.iterrows():
    tafsir_blocks = []
    for key in ("Tafaseer1", "Tafaseer2"):
        text = row.get(key)
        if isinstance(text, str) and text.strip():
            label = TAFSIR_NAMES.get(key, key)
            tafsir_blocks.append(f"{label}:\n{text.strip()}")

    if not tafsir_blocks:
        continue  # пропускаем строки без тафсира

    arabic = (row.get("Arabic") or "").strip()
    parts = []
    if arabic:
        parts.append(f"Arabic:\n{arabic}")
    parts.append("Tafsir:\n" + "\n\n".join(tafsir_blocks))

    surah_value = row.get("Surah")
    if pd.notna(surah_value):
        try:
            surah_number = int(surah_value)
        except (ValueError, TypeError):
            surah_number = str(surah_value).strip()
    else:
        surah_number = "unknown"

    surah_info = get_surah_info(surah_number)
    surah_name_ru = get_surah_name(surah_number, prefer_locale="ru")
    surah_name_en = get_surah_name(surah_number, prefer_locale="en")
    ayah_index = int(row["ayah_index"])
    heading_parts = []
    if surah_name_ru or surah_name_en:
        heading_parts.append(f"Сура: {surah_name_ru or surah_name_en} (№{surah_number})")
    heading_parts.append(f"Аят: {ayah_index}")
    parts.insert(0, "\n".join(heading_parts))
    metadata_translations = {
        key: row.get(key)
        for key in ("Translation1", "Translation2", "Translation3")
        if isinstance(row.get(key), str) and row.get(key).strip()
    }

    documents.append(
        {
            "document_id": f"surah_{surah_number}_ayah_{ayah_index}",
            "text": "\n\n".join(parts),
            "metadata": {
                "title": row.get("Name") or surah_name_ru or surah_name_en,
                "surah": surah_number,
                "ayah_index": ayah_index,
                "has_arabic": bool(arabic),
                "translations": metadata_translations,
                "tafsir_sources": [
                    TAFSIR_NAMES.get(key, key)
                    for key in ("Tafaseer1", "Tafaseer2")
                    if isinstance(row.get(key), str) and row.get(key).strip()
                ],
                "surah_name_ru": surah_name_ru,
                "surah_name_en": surah_name_en,
                "surah_name_ar": surah_info.get("arabic") if surah_info else None,
            },
        }
    )

payload = {
    "documents": documents,
    "chunk_size": CHUNK_SIZE,
    "chunk_overlap": CHUNK_OVERLAP,
}

Path(OUTPUT).write_text(json.dumps(payload, ensure_ascii=False, indent=2))