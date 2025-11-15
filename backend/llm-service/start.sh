#!/bin/bash

# Скрипт для запуска Python LLM сервиса

echo "Запуск LLM сервиса..."

# Проверяем наличие виртуального окружения
if [ ! -d "venv" ]; then
    echo "Создание виртуального окружения..."
    python3 -m venv venv
fi

# Активируем виртуальное окружение
source venv/bin/activate

# Устанавливаем зависимости
echo "Установка зависимостей..."
pip install -r requirements.txt

# Запускаем сервис
echo "Запуск FastAPI сервиса на http://localhost:8000"
python main.py

