#!/bin/bash

# Скрипт для остановки всех сервисов

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Остановка сервисов...${NC}\n"

# Останавливаем Python сервис (порт 8000)
PYTHON_PID=$(lsof -ti:8000 2>/dev/null)
if [ ! -z "$PYTHON_PID" ]; then
    echo -e "${YELLOW}Остановка Python LLM сервиса (PID: $PYTHON_PID)${NC}"
    kill $PYTHON_PID 2>/dev/null || true
    sleep 1
    # Если процесс еще жив, принудительно завершаем
    if kill -0 $PYTHON_PID 2>/dev/null; then
        kill -9 $PYTHON_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Python сервис остановлен${NC}"
else
    echo -e "${YELLOW}Python сервис не запущен${NC}"
fi

# Останавливаем Java Backend (порт 8080)
JAVA_PID=$(lsof -ti:8080 2>/dev/null)
if [ ! -z "$JAVA_PID" ]; then
    echo -e "${YELLOW}Остановка Java Backend (PID: $JAVA_PID)${NC}"
    kill $JAVA_PID 2>/dev/null || true
    sleep 2
    # Если процесс еще жив, принудительно завершаем
    if kill -0 $JAVA_PID 2>/dev/null; then
        kill -9 $JAVA_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Java Backend остановлен${NC}"
else
    echo -e "${YELLOW}Java Backend не запущен${NC}"
fi

# Также ищем процессы по имени
pkill -f "python main.py" 2>/dev/null && echo -e "${GREEN}✅ Остановлены процессы Python${NC}" || true
pkill -f "spring-boot:run" 2>/dev/null && echo -e "${GREEN}✅ Остановлены процессы Spring Boot${NC}" || true

echo -e "\n${GREEN}Все сервисы остановлены!${NC}"

