#!/usr/bin/env python3
"""
Expand training data by finding multiple relevant verses for each question.

For each Q&A pair, search through Quran to find all verses that could answer
the question, not just the first one mentioned.
"""

import json
import re
import sys
from pathlib import Path
from collections import defaultdict


def load_quran(quran_file: str) -> list[dict]:
    """Load all Quran verses"""
    verses = []
    with open(quran_file, 'r', encoding='utf-8') as f:
        for line in f:
            verses.append(json.loads(line.strip()))
    return verses


def load_training_pairs(pairs_file: str) -> list[dict]:
    """Load existing training pairs"""
    with open(pairs_file, 'r', encoding='utf-8') as f:
        return json.load(f)


def find_relevant_verses(question: str, verses: list[dict]) -> list[dict]:
    """
    Find all verses that could be relevant to a question.
    Uses keyword matching on verse text.
    """
    # Extract keywords from question
    keywords = question.lower().replace('?', '').split()
    # Remove common words
    common = {'что', 'как', 'почему', 'какие', 'где', 'можно', 'ли', 'в', 'о', 'на', 'к', 'по'}
    keywords = [k for k in keywords if k not in common and len(k) > 2]

    relevant = []
    for verse in verses:
        text_lower = verse['text'].lower()
        # Count keyword matches
        matches = sum(1 for kw in keywords if kw in text_lower)
        if matches >= len(keywords) * 0.5:  # At least 50% of keywords
            relevant.append({
                'sura': verse['sura'],
                'verse': verse['verse'],
                'text': verse['text'],
                'match_score': matches
            })

    # Sort by match score
    return sorted(relevant, key=lambda x: -x['match_score'])


def expand_training_pairs(pairs: list[dict], verses: list[dict]) -> list[dict]:
    """Expand training pairs by adding variations with different relevant verses"""
    expanded = []
    seen = set()

    for pair in pairs:
        question = pair['query']

        # Find all relevant verses
        relevant_verses = find_relevant_verses(question, verses)

        if not relevant_verses:
            # Keep original if no new verses found
            if pair['query'] not in seen:
                expanded.append(pair)
                seen.add(pair['query'])
            continue

        # Create pairs for each relevant verse
        for i, verse_info in enumerate(relevant_verses[:3]):  # Limit to 3 variants per question
            pair_id = f"{pair['id']}_v{i+1}" if i > 0 else pair['id']

            new_pair = {
                'id': pair_id,
                'query': question,
                'relevant': verse_info['text'],
                'irrelevant': pair.get('irrelevant', 'Это не имеет отношения к Корану'),
                'source': f"{verse_info['sura']}:{verse_info['verse']}"
            }

            if new_pair['query'] + new_pair['relevant'] not in seen:
                expanded.append(new_pair)
                seen.add(new_pair['query'] + new_pair['relevant'])

    return expanded


def main():
    script_dir = Path(__file__).parent
    base_path = script_dir.parent

    pairs_file = base_path / "tests" / "fixtures" / "quranic_pairs.json"
    quran_file = base_path / "data" / "quran_ru.jsonl"
    output_file = base_path / "tests" / "fixtures" / "quranic_pairs.json"

    if not pairs_file.exists():
        print(f"Error: {pairs_file} not found")
        sys.exit(1)

    if not quran_file.exists():
        print(f"Error: {quran_file} not found")
        sys.exit(1)

    print("Loading Quran...")
    verses = load_quran(str(quran_file))
    print(f"✓ Loaded {len(verses)} verses")

    print("Loading training pairs...")
    pairs = load_training_pairs(str(pairs_file))
    print(f"✓ Loaded {len(pairs)} pairs")

    print("Expanding with multiple relevant verses...")
    expanded = expand_training_pairs(pairs, verses)
    print(f"✓ Expanded to {len(expanded)} pairs")

    # Save
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(expanded, f, ensure_ascii=False, indent=2)

    print(f"✓ Saved to {output_file}")

    # Statistics
    original_questions = {p['query'] for p in pairs}
    expanded_questions = {p['query'] for p in expanded}
    avg_pairs_per_question = len(expanded) / len(expanded_questions)

    print(f"\nStatistics:")
    print(f"  Unique questions: {len(expanded_questions)}")
    print(f"  Total pairs: {len(expanded)}")
    print(f"  Avg pairs per question: {avg_pairs_per_question:.1f}")


if __name__ == "__main__":
    main()
