#!/usr/bin/env python3
"""
Parse Q&A data and convert to training pairs format.

Reads raw Q&A from data.txt, extracts sura references, finds actual Quran text,
and generates training pairs with relevant/irrelevant examples.
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict


def load_quran(quran_file: str) -> dict:
    """Load Quran verses indexed by sura:verse"""
    verses = {}
    with open(quran_file, 'r', encoding='utf-8') as f:
        for line in f:
            v = json.loads(line.strip())
            key = f"{v['sura']}:{v['verse']}"
            verses[key] = v
    return verses


def extract_sura_references(text: str) -> list[str]:
    """Extract sura:verse references from text like 'сура 2:173' or '2:173'"""
    # Pattern: word "сура" followed by number:number, or just number:number
    pattern = r'(?:сура\s+)?(\d+):(\d+)'
    matches = re.findall(pattern, text)
    return [f"{sura}:{verse}" for sura, verse in matches]


def parse_qa_data(data_file: str) -> list[dict]:
    """Parse raw Q&A data from text file"""
    pairs = []

    with open(data_file, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by double newlines (each Q&A is separated by empty line)
    lines = content.strip().split('\n')

    current_qa = None
    for line in lines:
        line = line.strip()
        if not line:
            continue

        # Line format: "Question — Answer, сура X:Y"
        if ' — ' in line:
            parts = line.split(' — ', 1)
            question = parts[0].strip()
            rest = parts[1].strip()

            # Extract sura references
            sura_refs = extract_sura_references(rest)

            if sura_refs:
                current_qa = {
                    'question': question,
                    'answer_text': rest,
                    'sura_refs': sura_refs
                }
                pairs.append(current_qa)

    return pairs


def generate_irrelevant_for_topic(topic: str, verses: dict) -> str:
    """Generate irrelevant text for a topic"""
    # Simple heuristics: opposite/unrelated statements
    irrelevant_responses = {
        'запрет': 'Это разрешено',
        'запрещена': 'Это разрешено',
        'запрещено': 'Это разрешено',
        'запреты': 'Всё разрешено',
        'свинина': 'Мясо птицы полезно',
        'алкоголь': 'Напитки безвредны',
        'молитва': 'Молитва необязательна',
        'скромность': 'Внешность важнее всего',
        'семья': 'Семья не важна',
        'вера': 'Вера бесполезна',
        'грех': 'Грехи допустимы',
        'милость': 'Жестокость приемлема',
        'правильное': 'Неправильное поведение',
        'хорошо': 'Это плохо',
    }

    for keyword, irrelevant in irrelevant_responses.items():
        if keyword in topic.lower():
            return irrelevant

    # Default irrelevant text
    return "Это не имеет отношения к Корану"


def create_training_pairs(qa_data: list[dict], verses: dict) -> list[dict]:
    """Create training pairs with relevant and irrelevant examples"""
    training_pairs = []
    seen_questions = set()

    for qa in qa_data:
        question = qa['question']

        # Skip duplicates
        if question in seen_questions:
            continue
        seen_questions.add(question)

        # Get relevant verses
        relevant_texts = []
        sources = []
        for sura_ref in qa['sura_refs']:
            if sura_ref in verses:
                v = verses[sura_ref]
                relevant_texts.append(v['text'])
                sources.append(sura_ref)

        if not relevant_texts:
            continue

        # Create pair
        pair = {
            'id': question.lower()[:40].replace(' ', '_'),
            'query': question,
            'relevant': relevant_texts[0],  # Use first relevant verse
            'irrelevant': generate_irrelevant_for_topic(question, verses),
            'source': sources[0] if sources else 'unknown'
        }

        training_pairs.append(pair)

    return training_pairs


def main():
    script_dir = Path(__file__).parent
    base_path = script_dir.parent

    data_file = base_path / "data.txt"
    quran_file = base_path / "data" / "quran_ru.jsonl"
    output_file = base_path / "tests" / "fixtures" / "quranic_pairs_expanded.json"

    if not data_file.exists():
        print(f"Error: {data_file} not found")
        sys.exit(1)

    if not quran_file.exists():
        print(f"Error: {quran_file} not found")
        sys.exit(1)

    print("Loading Quran data...")
    verses = load_quran(str(quran_file))
    print(f"✓ Loaded {len(verses)} verses")

    print("Parsing Q&A data...")
    qa_data = parse_qa_data(str(data_file))
    print(f"✓ Parsed {len(qa_data)} Q&A pairs")

    print("Creating training pairs...")
    training_pairs = create_training_pairs(qa_data, verses)
    print(f"✓ Created {len(training_pairs)} training pairs")

    # Save to file
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(training_pairs, f, ensure_ascii=False, indent=2)

    print(f"✓ Saved to {output_file}")

    # Print statistics
    topics = defaultdict(int)
    for pair in training_pairs:
        # Extract topic from first word of question
        topic = pair['query'].split()[0]
        topics[topic] += 1

    print("\nTop topics:")
    for topic, count in sorted(topics.items(), key=lambda x: -x[1])[:10]:
        print(f"  {topic}: {count} pairs")


if __name__ == "__main__":
    main()
