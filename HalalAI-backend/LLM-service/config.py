import logging
import os
from pathlib import Path


logger = logging.getLogger(__name__)

model_name = os.getenv("LLM_MODEL_NAME", "Qwen/Qwen3-1.7B")

DEFAULT_SYSTEM_PROMPT = (
    "Ты — HalalAI, умный исламский ассистент, специализирующийся на вопросах халяль, "
    "исламских принципах, Коране и исламском образе жизни. Твоя задача — давать точные, "
    "полезные и основанные на исламских источниках ответы. Всегда отвечай на русском языке, "
    "используй исламские термины (халяль, харам, сунна и т.д.) и будь уважительным и терпеливым. "
    "Если вопрос не связан с исламом, вежливо направь разговор в нужное русло. Отвечай кратко, "
    "но информативно."
)

MAX_HISTORY_MESSAGES = 16
MAX_HISTORY_TOKEN_LENGTH = 2048
DEFAULT_MAX_NEW_TOKENS = int(os.getenv("LLM_DEFAULT_MAX_TOKENS", "4096"))
MAX_NEW_TOKENS = int(os.getenv("LLM_MAX_TOKENS", "6144"))
MIN_NEW_TOKENS = 16

REQUEST_TIMEOUT_SECONDS = int(os.getenv("LLM_REQUEST_TIMEOUT_SECONDS", "180"))

BASE_DIR = Path(__file__).resolve().parent
DEFAULT_VECTOR_STORE_PATH = os.getenv("RAG_STORE_PATH", str(BASE_DIR / "data" / "vector_store.pt"))
DEFAULT_RAG_TOP_K = int(os.getenv("RAG_DEFAULT_TOP_K", "3"))
RAG_EMBEDDING_MODEL = os.getenv("RAG_EMBEDDING_MODEL", "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
RAG_ENABLED = os.getenv("RAG_ENABLED", "true").lower() in {"1", "true", "yes"}
RAG_EMBEDDING_DEVICE = os.getenv("RAG_EMBEDDING_DEVICE", "cpu")
RAG_SEARCH_TOP_K = int(os.getenv("RAG_SEARCH_TOP_K", "8"))

LOG_PROMPT_ENABLED = os.getenv("LLM_LOG_PROMPT", "true").lower() in {"1", "true", "yes"}
LOG_PROMPT_MAX_CHARS = int(os.getenv("LLM_LOG_PROMPT_MAX_CHARS", "4000"))
LLM_TEMPERATURE = float(os.getenv("LLM_TEMPERATURE", "0.4"))
LLM_TOP_P = float(os.getenv("LLM_TOP_P", "0.85"))

REMOTE_LLM_ENABLED = os.getenv("REMOTE_LLM_ENABLED", "true").lower() in {"1", "true", "yes"}
REMOTE_LLM_MODEL = os.getenv("REMOTE_LLM_MODEL", "xiaomi/mimo-v2-flash:free")
REMOTE_LLM_BASE_URL = os.getenv("REMOTE_LLM_BASE_URL", "https://openrouter.ai/api/v1")
REMOTE_LLM_REFERER = os.getenv("REMOTE_LLM_REFERER")
REMOTE_LLM_APP_TITLE = os.getenv("REMOTE_LLM_APP_TITLE", "HalalAI Client")
_allowed_env = os.getenv("REMOTE_LLM_ALLOWED_MODELS")
# Если переменная окружения не задана — используем дефолтный список.
_default_allowed = [
    "xiaomi/mimo-v2-flash:free",
    "tngtech/deepseek-r1t2-chimera:free",
    "gpt-4o-mini",
]
REMOTE_LLM_ALLOWED_MODELS = (
    [
        model.strip()
        for model in _allowed_env.split(",")
        if model.strip()
    ]
    if _allowed_env is not None
    else _default_allowed
)

