from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
import logging

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM Service", version="1.0.0")

# Глобальные переменные для модели и токенизатора
model = None
tokenizer = None
model_name = "Qwen/Qwen3-4B-Instruct-2507"

class ChatMessage(BaseModel):
    role: str  # "user" или "assistant"
    content: str

class ChatRequest(BaseModel):
    prompt: Optional[str] = None  # Для обратной совместимости
    messages: Optional[List[ChatMessage]] = None  # История сообщений
    max_tokens: Optional[int] = 1024

class ChatResponse(BaseModel):
    reply: str

@app.on_event("startup")
async def load_model():
    """Загружает модель при старте приложения"""
    global model, tokenizer
    
    logger.info(f"Загрузка модели {model_name}...")
    try:
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype="auto",
            device_map="auto"
        )
        logger.info("✅ Модель успешно загружена")
    except Exception as e:
        logger.error(f"❌ Ошибка при загрузке модели: {e}")
        raise

@app.get("/health")
async def health_check():
    """Проверка здоровья сервиса"""
    if model is None or tokenizer is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    return {"status": "healthy", "model": model_name}

@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    """Генерация ответа на основе промпта или истории сообщений"""
    logger.info(f"Получен запрос: prompt={request.prompt}, messages={len(request.messages) if request.messages else 0}")
    
    if model is None or tokenizer is None:
        logger.error("Модель не загружена!")
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    try:
        # Подготавливаем сообщения
        if request.messages:
            # Используем историю сообщений
            messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
            logger.info(f"Используется история из {len(messages)} сообщений")
        elif request.prompt:
            # Обратная совместимость: используем простой промпт
            messages = [{"role": "user", "content": request.prompt}]
            logger.info(f"Используется простой промпт: {request.prompt[:100]}...")
        else:
            logger.error("Не указан ни prompt, ни messages")
            raise HTTPException(status_code=400, detail="Either 'prompt' or 'messages' must be provided")
        
        logger.info("Применяем шаблон чата...")
        
        # Применяем шаблон чата
        text = tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
        
        logger.info("Токенизируем входные данные...")
        # Токенизируем входные данные
        model_inputs = tokenizer([text], return_tensors="pt").to(model.device)
        
        # Генерируем ответ
        max_new_tokens = min(request.max_tokens or 1024, 16384)  # Ограничиваем максимум
        logger.info(f"Начинаем генерацию ответа (max_new_tokens={max_new_tokens})...")
        
        with torch.no_grad():
            generated_ids = model.generate(
                **model_inputs,
                max_new_tokens=max_new_tokens,
                do_sample=True,
                temperature=0.7,
                top_p=0.9
            )
        
        logger.info("Генерация завершена, декодируем ответ...")
        # Декодируем только сгенерированную часть
        output_ids = generated_ids[0][len(model_inputs.input_ids[0]):].tolist()
        content = tokenizer.decode(output_ids, skip_special_tokens=True)
        
        logger.info(f"✅ Сгенерирован ответ длиной {len(content)} символов")
        if content:
            logger.info(f"Первые 200 символов ответа: {content[:200]}...")
        else:
            logger.warning("⚠️  Ответ пустой!")
        
        return ChatResponse(reply=content)
        
    except Exception as e:
        logger.error(f"Ошибка при генерации: {e}")
        raise HTTPException(status_code=500, detail=f"Generation error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

