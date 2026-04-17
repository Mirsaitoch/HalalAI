#!/usr/bin/env python3
"""
Create chunked representation of Quran data.

Groups verses into chunks of size N with optional overlap.
Chunk format: {chunk_id, sura, verse_start, verse_end, text}
"""

import json
import sys
from pathlib import Path


def create_chunks(
    input_file: str,
    output_file: str,
    chunk_size: int = 3,
    overlap: int = 1
):
    """
    Create chunks from verse-level Quran data.

    Args:
        input_file: Path to quran_ru.jsonl (verse-level data)
        output_file: Path to save quran_chunks.jsonl
        chunk_size: Number of verses per chunk (default 3)
        overlap: Number of verses to overlap between chunks (default 1)
    """
    # Load all verses
    verses = []
    with open(input_file, 'r', encoding='utf-8') as f:
        for line in f:
            verses.append(json.loads(line.strip()))

    print(f"Loaded {len(verses)} verses")

    # Group by sura
    suras = {}
    for v in verses:
        sura_num = v['sura']
        if sura_num not in suras:
            suras[sura_num] = []
        suras[sura_num].append(v)

    print(f"Grouped into {len(suras)} suras")

    # Create chunks per sura
    chunks = []
    chunk_id = 0

    for sura_num in sorted(suras.keys()):
        verses_in_sura = suras[sura_num]

        # Create chunks with overlap
        for i in range(0, len(verses_in_sura), chunk_size - overlap):
            chunk_verses = verses_in_sura[i:i + chunk_size]
            if len(chunk_verses) == 0:
                continue

            # Build chunk
            chunk_text = "\n\n".join([
                f"Сура {v['sura']}:{v['verse']}\n{v['text']}"
                for v in chunk_verses
            ])

            chunk = {
                "chunk_id": f"chunk_{chunk_id:05d}",
                "sura": sura_num,
                "verse_start": chunk_verses[0]['verse'],
                "verse_end": chunk_verses[-1]['verse'],
                "text": chunk_text
            }
            chunks.append(chunk)
            chunk_id += 1

    print(f"Created {len(chunks)} chunks")

    # Save chunks
    with open(output_file, 'w', encoding='utf-8') as f:
        for chunk in chunks:
            f.write(json.dumps(chunk, ensure_ascii=False) + '\n')

    print(f"Saved chunks to {output_file}")


if __name__ == "__main__":
    script_dir = Path(__file__).parent
    data_dir = script_dir.parent / "data"

    input_file = data_dir / "quran_ru.jsonl"
    output_file = data_dir / "quran_chunks.jsonl"

    if not input_file.exists():
        print(f"Error: {input_file} not found")
        sys.exit(1)

    create_chunks(
        str(input_file),
        str(output_file),
        chunk_size=3,
        overlap=1
    )
    print("Done!")
