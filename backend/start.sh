#!/bin/bash

# Скрипт для запуска Python LLM сервиса и Java Backend одновременно

set -e  # Остановка при ошибке

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Функция для очистки при выходе
cleanup() {
    echo -e "\n${YELLOW}Остановка сервисов...${NC}"
    if [ ! -z "$PYTHON_PID" ]; then
        echo "Остановка Python LLM сервиса (PID: $PYTHON_PID)"
        kill $PYTHON_PID 2>/dev/null || true
    fi
    if [ ! -z "$JAVA_PID" ]; then
        echo "Остановка Java Backend (PID: $JAVA_PID)"
        kill $JAVA_PID 2>/dev/null || true
    fi
    exit 0
}

# Устанавливаем обработчик сигналов для корректного завершения
trap cleanup SIGINT SIGTERM

# Переходим в директорию скрипта
cd "$(dirname "$0")"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Запуск Halal AI Backend Services${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Проверка занятости портов
check_port() {
    local port=$1
    local service=$2
    local pid=$(lsof -ti:$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        echo -e "${YELLOW}⚠️  Порт $port уже занят процессом (PID: $pid)${NC}"
        echo -e "${YELLOW}   Это может быть $service${NC}"
        read -p "Остановить процесс и продолжить? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Остановка процесса $pid...${NC}"
            kill $pid 2>/dev/null || kill -9 $pid 2>/dev/null || true
            sleep 2
            # Проверяем еще раз
            if lsof -ti:$port > /dev/null 2>&1; then
                echo -e "${RED}❌ Не удалось освободить порт $port${NC}"
                exit 1
            fi
            echo -e "${GREEN}✅ Порт $port освобожден${NC}"
        else
            echo -e "${RED}❌ Отменено. Освободите порт $port вручную и попробуйте снова.${NC}"
            exit 1
        fi
    fi
}

# Проверяем порты перед запуском
check_port 8000 "Python LLM Service"
check_port 8080 "Java Backend"

# 1. Запуск Python LLM сервиса
echo -e "${YELLOW}[1/2] Запуск Python LLM сервиса...${NC}"
cd llm-service

# Проверяем наличие виртуального окружения
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}Создание виртуального окружения...${NC}"
    python3 -m venv venv
fi

# Активируем виртуальное окружение
source venv/bin/activate

# Устанавливаем зависимости (если нужно)
if [ ! -f "venv/.deps_installed" ]; then
    echo -e "${YELLOW}Установка зависимостей Python...${NC}"
    pip install -q -r requirements.txt
    touch venv/.deps_installed
fi

# Запускаем Python сервис в фоне
echo -e "${YELLOW}Запуск Python сервиса на порту 8000...${NC}"
python main.py > ../python-service.log 2>&1 &
PYTHON_PID=$!

# Возвращаемся в корневую директорию backend
cd ..

# Ждем, пока Python сервис станет доступен
echo -e "${YELLOW}Ожидание готовности Python сервиса...${NC}"
MAX_WAIT=60
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Python LLM сервис готов!${NC}"
        break
    fi
    echo -n "."
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo -e "\n${RED}❌ Python сервис не запустился за $MAX_WAIT секунд${NC}"
    echo -e "${YELLOW}Проверьте логи: tail -f backend/python-service.log${NC}"
    kill $PYTHON_PID 2>/dev/null || true
    exit 1
fi

# 2. Запуск Java Backend
echo -e "\n${YELLOW}[2/2] Запуск Java Backend...${NC}"
cd halal-ai-backend

# Проверяем наличие Maven wrapper
if [ ! -f "./mvnw" ]; then
    echo -e "${RED}❌ Maven wrapper не найден!${NC}"
    exit 1
fi

# Делаем mvnw исполняемым
chmod +x ./mvnw

echo -e "${YELLOW}Запуск Java Backend на порту 8080...${NC}"
./mvnw spring-boot:run > ../java-backend.log 2>&1 &
JAVA_PID=$!

# Возвращаемся в корневую директорию backend
cd ..

# Ждем, пока Java Backend станет доступен
echo -e "${YELLOW}Ожидание готовности Java Backend...${NC}"
MAX_WAIT=90
WAIT_COUNT=0
while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    if curl -s http://localhost:8080/actuator/health > /dev/null 2>&1 || \
       curl -s http://localhost:8080/api/chat -X POST -H "Content-Type: application/json" -d '{"prompt":"test"}' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Java Backend готов!${NC}"
        break
    fi
    echo -n "."
    sleep 1
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
    echo -e "\n${YELLOW}⚠️  Java Backend может быть еще не готов, но продолжаем...${NC}"
fi

# Выводим информацию о запущенных сервисах
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Сервисы запущены!${NC}"
echo -e "${GREEN}========================================${NC}\n"
echo -e "Python LLM Service: ${GREEN}http://localhost:8000${NC} (PID: $PYTHON_PID)"
echo -e "Java Backend:       ${GREEN}http://localhost:8080${NC} (PID: $JAVA_PID)\n"
echo -e "Логи Python:  ${YELLOW}tail -f backend/python-service.log${NC}"
echo -e "Логи Java:     ${YELLOW}tail -f backend/java-backend.log${NC}\n"
echo -e "${YELLOW}Нажмите Ctrl+C для остановки всех сервисов${NC}\n"

# Ждем завершения процессов
wait

