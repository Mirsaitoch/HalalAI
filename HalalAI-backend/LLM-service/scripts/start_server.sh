#!/bin/bash
# Скрипт для запуска LLM сервиса с автоматической очисткой порта

set -e

PORT=${1:-8000}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "🚀 Запуск HalalAI LLM Service на порту $PORT..."

# Проверяем и освобождаем порт если занят
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Порт $PORT занят, освобождаем..."
    PID=$(lsof -ti:$PORT)
    kill -9 $PID 2>/dev/null || true
    sleep 1
    echo "✅ Порт $PORT освобожден"
fi

# Активируем виртуальное окружение
if [ ! -d "venv" ]; then
    echo "❌ Виртуальное окружение не найдено. Создайте его: python -m venv venv"
    exit 1
fi

source venv/bin/activate

echo "📦 Проверка зависимостей..."
python -c "import fastapi, torch" 2>/dev/null || {
    echo "❌ Зависимости не установлены. Выполните: pip install -r requirements.txt"
    exit 1
}

echo "✅ Все готово к запуску!"
echo "🌐 Сервер будет доступен по адресу: http://localhost:$PORT"
echo "📚 Документация: http://localhost:$PORT/docs"
echo "📊 Метрики: http://localhost:$PORT/metrics"
echo ""
echo "Нажмите Ctrl+C для остановки сервера"
echo ""

# Запускаем сервер
python -m halal_ai.main
