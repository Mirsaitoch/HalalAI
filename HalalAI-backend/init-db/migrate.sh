#!/bin/bash
# Переносим данные из локальной PostgreSQL при первом запуске контейнера
set -e

echo "Пробуем перенести данные из локальной БД (host.docker.internal)..."

if pg_dump -h host.docker.internal -U "$LOCAL_DB_USER" -d "$LOCAL_DB_NAME" \
    --no-owner --no-acl 2>/dev/null | psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
    echo "✅ Данные успешно перенесены из локальной БД"
else
    echo "⚠️  Локальная БД недоступна или пустая — начинаем с чистой базы"
fi
