#!/usr/bin/env python3
"""Interactive RAG testing tool."""

import sys
import json
from pathlib import Path
from colorama import Fore, Back, Style, init

# Add src to path
sys.path.insert(0, str(Path(__file__).parent / "src"))

from halal_rag.rag.retriever import SimpleRAG
from halal_rag.quality.checker import QualityChecker

init(autoreset=True)  # Auto-reset colors


class InteractiveTester:
    def __init__(self):
        self.rag = None
        self.checker = QualityChecker()
        self._load()

    def _load(self):
        """Load Quranic documents and RAG."""
        print(f"\n{Fore.CYAN}Loading Quranic documents...{Style.RESET_ALL}")
        docs = []
        data_file = Path(__file__).parent / "data" / "quran_ru.jsonl"

        with open(data_file, 'r', encoding='utf-8') as f:
            for line in f:
                docs.append(json.loads(line))

        print(f"{Fore.GREEN}✓ Loaded {len(docs)} verses{Style.RESET_ALL}")

        print(f"{Fore.CYAN}Initializing RAG with fine-tuned model...{Style.RESET_ALL}")
        self.rag = SimpleRAG(documents=docs, use_finetuned=True)
        print(f"{Fore.GREEN}✓ RAG ready!{Style.RESET_ALL}\n")

    def search(self, query: str, top_k: int = 3):
        """Search and display results."""
        if not query.strip():
            print(f"{Fore.YELLOW}Empty query!{Style.RESET_ALL}")
            return

        print(f"\n{Fore.CYAN}🔍 Searching: '{query}'{Style.RESET_ALL}")
        results = self.rag.search(query, top_k=top_k)

        if not results:
            print(f"{Fore.RED}No results found!{Style.RESET_ALL}")
            return

        print(f"{Fore.GREEN}Found {len(results)} results:{Style.RESET_ALL}\n")

        for i, result in enumerate(results, 1):
            score = result['score']
            sura = result['sura']
            verse = result['verse']
            title = result['title'].strip()
            subtitle = result['subtitle'].strip()
            text = result['text'][:120] + "..." if len(result['text']) > 120 else result['text']

            # Color code relevance
            if score > 0.7:
                score_color = Fore.GREEN
            elif score > 0.6:
                score_color = Fore.YELLOW
            else:
                score_color = Fore.CYAN

            print(f"{Fore.WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"{Fore.CYAN}#{i} | {score_color}Relevance: {score:.1%}{Fore.WHITE} | Сура {sura}, Аят {verse}")
            print(f"{Fore.MAGENTA}{title} {subtitle}")
            print(f"{Fore.WHITE}{text}\n")

    def check_response(self, query: str, response: str):
        """Check quality of LLM response."""
        print(f"\n{Fore.CYAN}Checking response quality...{Style.RESET_ALL}")

        # Get sources
        sources = self.rag.search(query, top_k=3)

        # Check quality
        report = self.checker.check_response(response, sources)

        # Display report
        print(f"{Fore.CYAN}Query: {query}{Style.RESET_ALL}")
        print(f"{Fore.CYAN}Response: {response}\n{Style.RESET_ALL}")

        quality_colors = {
            'excellent': Fore.GREEN,
            'good': Fore.GREEN,
            'acceptable': Fore.YELLOW,
            'poor': Fore.RED,
            'critical': Fore.RED,
        }
        color = quality_colors.get(report['quality'], Fore.WHITE)

        print(f"Quality: {color}{report['quality'].upper()}{Style.RESET_ALL}")
        print(f"Hallucinations: {Fore.RED if report['hallucinations_detected'] else Fore.GREEN}" +
              f"{'YES ⚠️' if report['hallucinations_detected'] else 'NO ✓'}{Style.RESET_ALL}")
        print(f"Total citations: {report['total_citations']}")
        print(f"Invalid citations: {len(report['invalid_citations'])}")

        if report['invalid_citations']:
            print(f"\n{Fore.RED}Invalid citations:{Style.RESET_ALL}")
            for invalid in report['invalid_citations']:
                print(f"  - Сура {invalid['surah']}, Аят {invalid['ayah']}")

    def interactive(self):
        """Interactive REPL."""
        print(f"\n{Fore.CYAN}{'='*60}")
        print(f"{Back.CYAN}{Fore.WHITE} HalalAI RAG Interactive Tester {Style.RESET_ALL}")
        print(f"{Fore.CYAN}{'='*60}{Style.RESET_ALL}\n")

        print("Commands:")
        print("  search <query>              - Search for documents")
        print("  check <query> | <response>  - Check response quality")
        print("  help                        - Show this help")
        print("  quit                        - Exit")
        print()

        while True:
            try:
                cmd = input(f"{Fore.CYAN}→ {Style.RESET_ALL}").strip()

                if not cmd:
                    continue

                if cmd.lower() == 'quit':
                    print(f"{Fore.YELLOW}Bye! 👋{Style.RESET_ALL}")
                    break

                if cmd.lower() == 'help':
                    print("Commands:")
                    print("  search <query>              - Search for documents")
                    print("  check <query> | <response>  - Check response quality")
                    print("  quit                        - Exit")
                    continue

                if cmd.lower().startswith('search '):
                    query = cmd[7:].strip()
                    self.search(query, top_k=5)

                elif cmd.lower().startswith('check '):
                    parts = cmd[6:].split('|')
                    if len(parts) == 2:
                        query = parts[0].strip()
                        response = parts[1].strip()
                        self.check_response(query, response)
                    else:
                        print(f"{Fore.RED}Format: check <query> | <response>{Style.RESET_ALL}")

                else:
                    print(f"{Fore.YELLOW}Unknown command: {cmd}{Style.RESET_ALL}")
                    print("Type 'help' for available commands")

            except KeyboardInterrupt:
                print(f"\n{Fore.YELLOW}Interrupted{Style.RESET_ALL}")
                break
            except Exception as e:
                print(f"{Fore.RED}Error: {e}{Style.RESET_ALL}")


if __name__ == "__main__":
    tester = InteractiveTester()
    tester.interactive()
