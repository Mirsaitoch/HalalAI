#!/bin/bash
# Запуск набора chat-запросов для проверки валидности ответов и цитирований.
# Использование: ./scripts/test_chat_validation.sh [BASE_URL]
# Пример:     ./scripts/test_chat_validation.sh http://localhost:8000

set -e

BASE_URL=${1:-"http://localhost:8000"}
# Результаты по умолчанию: папка validation_results рядом с папкой scripts (внутри LLM-service)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${OUT_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)/validation_results}"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

mkdir -p "$OUT_DIR"
OUT_DIR_ABS=$(cd "$OUT_DIR" 2>/dev/null && pwd || echo "$OUT_DIR")
echo -e "${BLUE}🧪 Проверка валидности ответов Chat API${NC}"
echo "   BASE_URL=$BASE_URL"
echo "   Результаты (json): $OUT_DIR_ABS"
echo ""

# Проверка доступности
if ! curl -sf "$BASE_URL/health" > /dev/null; then
  echo -e "${RED}Сервер недоступен: $BASE_URL${NC}"
  echo "Запустите: ./scripts/start_server.sh"
  exit 1
fi

run_one() {
  local name="$1"
  local prompt="$2"
  local rag="${3:-true}"
  local top_k="${4:-5}"
  local max_tok="${5:-300}"
  local file="$OUT_DIR/${name}.json"

  echo -e "${BLUE}[$name]${NC} $prompt"
  local http_code
  http_code=$(curl -s -o "$file" -w "%{http_code}" -X POST "$BASE_URL/chat" \
    -H "Content-Type: application/json" \
    -d "{\"prompt\": \"$prompt\", \"use_rag\": $rag, \"rag_top_k\": $top_k, \"max_tokens\": $max_tok}")

  if [ "$http_code" != "200" ]; then
    echo -e "  ${RED}HTTP $http_code${NC}"
    return 1
  fi

  if ! command -v jq &> /dev/null; then
    echo -e "  ${GREEN}Ответ сохранён: $file${NC}"
    return 0
  fi

  local reply_len sources_count model
  reply_len=$(jq -r '.reply | length' "$file")
  sources_count=$(jq -r '.sources | length' "$file")
  model=$(jq -r '.model' "$file")

  echo -e "  ${GREEN}OK${NC} reply=${reply_len} симв. sources=$sources_count model=$model"
  if [ "$rag" = "true" ] && [ "$sources_count" -gt 0 ]; then
    echo "  Допустимые цитаты: $(jq -r '[.sources[]?.metadata | "сура \(.surah) \(.ayah_range)"] | join(", ")' "$file" 2>/dev/null || true)"
  fi
  echo ""
  return 0
}

# --- Запросы с RAG (проверка цитирований) ---
run_one "01_svinina" "Что говорится о свинине в Коране?" true 5 350
run_one "02_svinina_kratko" "Свинина халяль или харам? Приведи аят." true 3 200
run_one "03_alkogol" "Что в Коране об алкоголе и опьяняющих напитках?" true 5 300
run_one "04_myaso_halal" "Какие правила забоя и халяльного мяса в исламе?" true 5 320
run_one "05_krov_mertvechina" "Почему запрещены кровь и мертвечина? Аяты." true 5 280
run_one "06_zapretnaya_pishcha" "Какая пища запрещена в исламе по Корану? Суры и аяты." true 6 400
run_one "07_post_ramadan" "Что в Коране о посте и Рамадане?" true 5 300
run_one "08_namaz" "Что говорится о намазе в Коране? Время молитвы." true 5 280
run_one "09_miloserdie" "Где в Коране о милосердии и прощении Аллаха?" true 5 280
run_one "10_kompleks" "Что запрещено из еды и напитков? Свинина, алкоголь." true 6 350

# --- Без RAG (общая адекватность) ---
run_one "11_privet" "Привет! Кто ты и чем помогаешь?" false 3 120
run_one "12_halal_haram" "Что такое халяль и харам одним предложением?" false 3 100

echo -e "${GREEN}✅ Завершено. Файлы в $OUT_DIR${NC}"
echo ""
echo "Проверка цитат: сравните номера сур/аятов в .reply с допустимыми в .sources."
echo "При невалидных цитатах в логах сервера появятся предупреждения (🚨/❌)."
echo ""
echo "Пример просмотра ответа:"
echo "  jq '.reply' $OUT_DIR/01_svinina.json"
echo "  jq '.sources[] | {surah: .metadata.surah, ayah_range: .metadata.ayah_range}' $OUT_DIR/01_svinina.json"
