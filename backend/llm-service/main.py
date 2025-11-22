from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional, List, Dict
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer
import logging
import os

# Настройка логирования
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="LLM Service", version="1.0.0")

# Глобальные переменные для модели и токенизатора
model = None
tokenizer = None
model_device = torch.device("cpu")
model_name = os.getenv("LLM_MODEL_NAME", "Qwen/Qwen3-1.7B")

DEFAULT_SYSTEM_PROMPT = (
    "Ты — HalalAI, умный исламский ассистент, специализирующийся на вопросах халяль, "
    "исламских принципах, Коране и исламском образе жизни. Твоя задача — давать точные, "
    "полезные и основанные на исламских источниках ответы. Всегда отвечай на русском языке, "
    "используй исламские термины (халяль, харам, сунна и т.д.) и будь уважительным и терпеливым. "
    "Если вопрос не связан с исламом, вежливо направь разговор в нужное русло. Отвечай кратко, "
    "но информативно."
)

MAX_HISTORY_MESSAGES = 16  # ограничение истории по количеству сообщений
MAX_HISTORY_TOKEN_LENGTH = 2048  # ограничения истории по количеству токенов
DEFAULT_MAX_NEW_TOKENS = int(os.getenv("LLM_DEFAULT_MAX_TOKENS", "256"))
MAX_NEW_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "1024"))
MIN_NEW_TOKENS = 16
ALLOWED_ROLES = {"system", "user", "assistant"}

class ChatMessage(BaseModel):
    role: str  # "user" или "assistant"
    content: str

class ChatRequest(BaseModel):
    prompt: Optional[str] = None  # Для обратной совместимости
    messages: Optional[List[ChatMessage]] = None  # История сообщений
    max_tokens: Optional[int] = 1024

class ChatResponse(BaseModel):
    reply: str

def _select_device() -> torch.device:
    """Определяет оптимальное устройство для инференса."""
    if torch.cuda.is_available():
        logger.info("Обнаружен CUDA, используем GPU")
        return torch.device("cuda")
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        logger.info("Обнаружен Apple Silicon (MPS), используем mps")
        return torch.device("mps")
    logger.info("GPU не найден, используем CPU (это значительно медленнее)")
    return torch.device("cpu")

def _sanitize_max_tokens(value: Optional[int]) -> int:
    """Гарантирует допустимый диапазон количества генерируемых токенов."""
    if value is None:
        return DEFAULT_MAX_NEW_TOKENS
    return max(MIN_NEW_TOKENS, min(value, MAX_NEW_TOKENS))

def _ensure_system_prompt(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Добавляет дефолтный системный промпт, если он отсутствует."""
    if not messages:
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}]
    first_role = messages[0].get("role")
    if first_role != "system":
        logger.info("Системный промпт отсутствует, добавляем дефолтный (client-side history без system role).")
        return [{"role": "system", "content": DEFAULT_SYSTEM_PROMPT}] + messages
    return messages

def _limit_history_length(messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
    """Ограничивает историю по количеству сообщений и длине в токенах."""
    if tokenizer is None or not messages:
        return messages

    system_message = messages[0] if messages[0].get("role") == "system" else None
    history = messages[1:] if system_message else messages[:]

    # Ограничиваем сначала по количеству сообщений
    if len(history) > MAX_HISTORY_MESSAGES:
        history = history[-MAX_HISTORY_MESSAGES:]

    if not history:
        return messages

    # Затем по количеству токенов (всегда оставляем последнее сообщение)
    trimmed_history = []
    token_budget = MAX_HISTORY_TOKEN_LENGTH
    token_used = 0

    for message in reversed(history):
        content = message.get("content", "")
        token_count = len(tokenizer.encode(content, add_special_tokens=False))

        if trimmed_history and token_used + token_count > token_budget:
            break

        trimmed_history.append(message)
        token_used += token_count

    if not trimmed_history:
        trimmed_history = history[-1:]
    else:
        trimmed_history.reverse()

    if system_message:
        return [system_message] + trimmed_history
    return trimmed_history

def _prepare_messages(request: ChatRequest) -> List[Dict[str, str]]:
    """Нормализует и проверяет структуру сообщений из запроса."""
    normalized: List[Dict[str, str]] = []

    if request.messages:
        for msg in request.messages:
            role = (msg.role or "").strip().lower()
            if role not in ALLOWED_ROLES:
                raise HTTPException(status_code=400, detail=f"Unsupported role '{msg.role}'")
            content = (msg.content or "").strip()
            if not content:
                continue
            normalized.append({"role": role, "content": content})
    elif request.prompt:
        normalized.append({"role": "user", "content": request.prompt.strip()})
        print("request.prompt.strip(): " + request.prompt.strip())
    else:
        raise HTTPException(status_code=400, detail="Either 'prompt' or 'messages' must be provided")

    if not normalized:
        raise HTTPException(status_code=400, detail="Message list is empty after normalization")

    with_system = _ensure_system_prompt(normalized)
    return _limit_history_length(with_system)

def _build_model_inputs(messages: List[Dict[str, str]]):
    """Создает строку с историей и токенизирует ее."""
    text = tokenizer.apply_chat_template(
        messages,
        tokenize=False,
        add_generation_prompt=True,
        enable_thinking=False
    )
    return tokenizer([text], return_tensors="pt").to(model_device)

@torch.inference_mode()
def _run_generation(model_inputs, generation_kwargs):
    """Запускает генерацию с отключенным градиентом."""
    return model.generate(
        **model_inputs,
        **generation_kwargs,
    )

@app.on_event("startup")
async def load_model():
    """Загружает модель при старте приложения"""
    global model, tokenizer, model_device

    logger.info(f"Загрузка модели {model_name}...")
    try:
        model_device = _select_device()
        dtype = torch.float32
        device_map = None
        if model_device.type in {"cuda", "mps"}:
            dtype = torch.float16
            device_map = "auto"

        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            trust_remote_code=True,
        )
        # Устанавливаем pad_token если его нет
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token
            tokenizer.pad_token_id = tokenizer.eos_token_id
            logger.info(f"Установлен pad_token = eos_token (ID: {tokenizer.pad_token_id})")

        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            dtype=dtype,
            device_map=device_map,
            low_cpu_mem_usage=True,
        )
        if device_map is None:
            model.to(model_device)
        model.eval()
        logger.info("✅ Модель успешно загружена (device=%s, dtype=%s)", model_device, dtype)
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
    logger.info(
        "Получен запрос: prompt_provided=%s, messages=%s",
        bool(request.prompt),
        len(request.messages) if request.messages else 0,
    )
    if model is None or tokenizer is None:
        logger.error("Модель не загружена!")
        raise HTTPException(status_code=503, detail="Model not loaded")

    try:
        messages = _prepare_messages(request)
        logger.info("Используется история из %s сообщений (после нормализации)", len(messages))

        model_inputs = _build_model_inputs(messages)
        max_new_tokens = _sanitize_max_tokens(request.max_tokens)

        input_token_size = model_inputs.input_ids.shape[1]
        logger.info(
            "Начинаем генерацию ответа (max_new_tokens=%s, input_tokens=%s)",
            max_new_tokens,
            input_token_size,
        )

        generation_kwargs = {
            "max_new_tokens": max_new_tokens,
            "do_sample": False,
            "eos_token_id": tokenizer.eos_token_id,
        }
        if tokenizer.pad_token_id is not None:
            generation_kwargs["pad_token_id"] = tokenizer.pad_token_id

        try:
            generated_ids = _run_generation(model_inputs, generation_kwargs)
        except Exception as greedy_error:
            error_str = str(greedy_error).lower()
            logger.warning("Greedy decoding failed: %s", greedy_error)
            if any(keyword in error_str for keyword in ("probability", "inf", "nan")):
                sampling_kwargs = dict(generation_kwargs)
                sampling_kwargs["do_sample"] = True
                logger.info("Пробуем генерацию с sampling (минимальные параметры)...")
                generated_ids = _run_generation(model_inputs, sampling_kwargs)
            else:
                raise

        input_length = model_inputs.input_ids.shape[1]
        output_ids = generated_ids[0][input_length:].tolist()
        content = tokenizer.decode(output_ids, skip_special_tokens=True).strip()

        if content:
            logger.info("✅ Сгенерирован ответ длиной %s символов", len(content))
        else:
            logger.warning("⚠️ Ответ пустой после декодирования")

        return ChatResponse(reply=content)

    except HTTPException:
        raise
    except RuntimeError as runtime_error:
        error_message = str(runtime_error).lower()
        if "out of memory" in error_message:
            if torch.cuda.is_available():
                torch.cuda.empty_cache()
            logger.error("CUDA out of memory во время генерации: %s", runtime_error)
            raise HTTPException(status_code=500, detail="LLM ran out of memory during generation")
        logger.error("RuntimeError во время генерации: %s", runtime_error)
        raise HTTPException(status_code=500, detail=str(runtime_error))
    except Exception as e:
        logger.error(f"Ошибка при генерации: {e}")
        raise HTTPException(status_code=500, detail=f"Generation error: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
