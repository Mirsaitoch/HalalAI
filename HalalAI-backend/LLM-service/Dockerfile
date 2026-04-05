FROM python:3.11-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY pyproject.toml .
RUN pip install --no-cache-dir \
    "fastapi>=0.104.1" \
    "uvicorn[standard]>=0.24.0" \
    "pydantic>=2.5.0" \
    "openai>=1.13.3" \
    "sentence-transformers>=2.6.0" \
    "pandas>=2.0.0"

COPY src/ src/
COPY data/ data/

RUN pip install --no-cache-dir -e . --no-deps

# Скачиваем модель эмбеддингов при сборке — контейнер стартует мгновенно
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2')"

EXPOSE 8000

ENV PYTHONUNBUFFERED=1

CMD ["uvicorn", "halal_rag.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
