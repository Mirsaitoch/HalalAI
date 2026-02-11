#!/bin/bash
# Скрипт для проверки API HalalAI LLM Service

set -e

BASE_URL=${1:-"http://localhost:8000"}
echo "🧪 Тестирование API: $BASE_URL"
echo "========================================"
echo ""

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 1. Health Check
echo -e "${BLUE}1. Health Check${NC}"
echo "curl $BASE_URL/health"
curl -s "$BASE_URL/health" | jq '.'
echo ""
echo "---"
echo ""

# 2. RAG Status
echo -e "${BLUE}2. RAG Status${NC}"
echo "curl $BASE_URL/rag/status"
curl -s "$BASE_URL/rag/status" | jq '.'
echo ""
echo "---"
echo ""

# 3. Метрики (общая сводка)
echo -e "${BLUE}3. Метрики - Общая сводка${NC}"
echo "curl $BASE_URL/metrics"
curl -s "$BASE_URL/metrics" | jq '.'
echo ""
echo "---"
echo ""

# 4. Health метрик
echo -e "${BLUE}4. Health системы мониторинга${NC}"
echo "curl $BASE_URL/metrics/health"
curl -s "$BASE_URL/metrics/health" | jq '.'
echo ""
echo "---"
echo ""

# 5. Rate Limiter статистика
echo -e "${BLUE}5. Rate Limiter статистика${NC}"
echo "curl $BASE_URL/metrics/ratelimit"
curl -s "$BASE_URL/metrics/ratelimit" | jq '.'
echo ""
echo "---"
echo ""

# 6. Тест чата без RAG
echo -e "${BLUE}6. Тест чата без RAG${NC}"
echo "curl -X POST $BASE_URL/chat -H 'Content-Type: application/json' -d '{...}'"
curl -s -X POST "$BASE_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Привет! Кто ты?",
    "use_rag": false,
    "max_tokens": 100
  }' | jq '.'
echo ""
echo "---"
echo ""

# 7. Тест чата с RAG
echo -e "${BLUE}7. Тест чата с RAG (свинина)${NC}"
echo "curl -X POST $BASE_URL/chat -H 'Content-Type: application/json' -d '{...}'"
curl -s -X POST "$BASE_URL/chat" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Что говорится о свинине в Коране?",
    "use_rag": true,
    "rag_top_k": 3,
    "max_tokens": 200
  }' | jq '.'
echo ""
echo "---"
echo ""

# 8. Последние запросы
echo -e "${BLUE}8. Последние 3 запроса${NC}"
echo "curl $BASE_URL/metrics/queries/recent?limit=3"
curl -s "$BASE_URL/metrics/queries/recent?limit=3" | jq '.'
echo ""
echo "---"
echo ""

# 9. Тест Rate Limiting (отправка 5 быстрых запросов)
echo -e "${BLUE}9. Тест Rate Limiting (5 быстрых запросов)${NC}"
echo "Отправляем 5 запросов подряд..."
for i in {1..5}; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE_URL/chat" \
    -H "Content-Type: application/json" \
    -d '{"prompt": "test", "use_rag": false, "max_tokens": 10}')
  
  if [ "$HTTP_CODE" == "200" ]; then
    echo -e "  Запрос $i: ${GREEN}✅ 200 OK${NC}"
  elif [ "$HTTP_CODE" == "429" ]; then
    echo -e "  Запрос $i: ${YELLOW}⚠️  429 Rate Limited${NC}"
  else
    echo "  Запрос $i: ❌ $HTTP_CODE"
  fi
done
echo ""
echo "---"
echo ""

# 10. Доступные модели
echo -e "${BLUE}10. Доступные модели${NC}"
echo "curl $BASE_URL/models"
curl -s "$BASE_URL/models" | jq '.'
echo ""
echo "---"
echo ""

# 11. Итоговые метрики
echo -e "${BLUE}11. Финальная сводка метрик${NC}"
curl -s "$BASE_URL/metrics" | jq '{
  total_requests: .requests.total,
  success_rate: .requests.success_rate,
  avg_latency_ms: .latency.request_avg_ms,
  p95_latency_ms: .latency.request_p95_ms,
  rag_queries: .rag.queries,
  rag_empty_rate: .rag.empty_rate
}'
echo ""

echo ""
echo -e "${GREEN}✅ Все проверки завершены!${NC}"
echo ""
echo "📚 Документация: $BASE_URL/docs"
echo "📊 Метрики: $BASE_URL/metrics"
echo "🏥 Health: $BASE_URL/health"
