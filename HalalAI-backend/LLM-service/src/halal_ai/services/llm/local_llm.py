"""Сервис для работы с локальной LLM моделью."""

import logging
from typing import Dict, List, Optional

import torch
from transformers import AutoModelForCausalLM, AutoTokenizer

from halal_ai.core import llm_config
from halal_ai.core.exceptions import ModelNotLoadedException
from halal_ai.services.prompts import build_prompt_text, log_prompt_if_needed

logger = logging.getLogger(__name__)


class LocalLLM:
    """Сервис для работы с локальной языковой моделью."""

    def __init__(self, model_name: Optional[str] = None):
        """
        Инициализирует сервис локальной LLM.
        
        Args:
            model_name: Название модели из HuggingFace Hub
        """
        self.model_name = model_name or llm_config.MODEL_NAME
        self.model: Optional[AutoModelForCausalLM] = None
        self.tokenizer: Optional[AutoTokenizer] = None
        self.device: torch.device = torch.device("cpu")

    async def load(self) -> None:
        """Загружает модель и токенизатор."""
        self.device = self._select_device()
        dtype = torch.float32
        device_map = None

        if self.device.type in {"cuda", "mps"}:
            dtype = torch.float16
            device_map = "auto"

        logger.info("Загружаем токенизатор: %s", self.model_name)
        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name, trust_remote_code=True)
        
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
            self.tokenizer.pad_token_id = self.tokenizer.eos_token_id
            logger.info("Установлен pad_token = eos_token (ID: %s)", self.tokenizer.pad_token_id)

        logger.info("Загружаем модель: %s", self.model_name)
        self.model = AutoModelForCausalLM.from_pretrained(
            self.model_name,
            torch_dtype=dtype,
            device_map=device_map,
            low_cpu_mem_usage=True,
        )
        
        if device_map is None:
            self.model.to(self.device)
        
        self.model.eval()
        logger.info("✅ Локальная модель загружена (device=%s, dtype=%s)", self.device, dtype)

    def generate(self, messages: List[Dict[str, str]], max_tokens: int) -> str:
        """
        Генерирует ответ на основе истории сообщений.
        
        Args:
            messages: История сообщений
            max_tokens: Максимальное количество токенов для генерации
            
        Returns:
            Сгенерированный текст
            
        Raises:
            ModelNotLoadedException: Если модель не загружена
        """
        if self.model is None or self.tokenizer is None:
            raise ModelNotLoadedException("Model or tokenizer not loaded")

        prompt_text = build_prompt_text(self.tokenizer, messages)
        log_prompt_if_needed(prompt_text)
        
        model_inputs = self.tokenizer([prompt_text], return_tensors="pt").to(self.device)
        max_new_tokens = self._sanitize_max_tokens(max_tokens)

        generation_kwargs = {
            "max_new_tokens": max_new_tokens,
            "do_sample": True,
            "temperature": llm_config.TEMPERATURE,
            "top_p": llm_config.TOP_P,
            "eos_token_id": self.tokenizer.eos_token_id,
        }
        
        if self.tokenizer.pad_token_id is not None:
            generation_kwargs["pad_token_id"] = self.tokenizer.pad_token_id

        try:
            generated_ids = self.model.generate(**model_inputs, **generation_kwargs)
        except Exception as sampling_error:
            logger.warning("Sampling decoding failed: %s. Пробуем без sampling.", sampling_error)
            fallback_kwargs = dict(generation_kwargs)
            fallback_kwargs["do_sample"] = False
            fallback_kwargs.pop("temperature", None)
            fallback_kwargs.pop("top_p", None)
            generated_ids = self.model.generate(**model_inputs, **fallback_kwargs)

        input_length = model_inputs.input_ids.shape[1]
        output_ids = generated_ids[0][input_length:].tolist()
        content = self.tokenizer.decode(output_ids, skip_special_tokens=True).strip()
        return content

    def limit_history_length(self, messages: List[Dict[str, str]]) -> List[Dict[str, str]]:
        """
        Ограничивает историю по количеству сообщений и токенов.
        
        Args:
            messages: История сообщений
            
        Returns:
            Ограниченная история
        """
        if self.tokenizer is None or not messages:
            return messages

        system_message = messages[0] if messages[0].get("role") == "system" else None
        history = messages[1:] if system_message else messages[:]

        # Ограничиваем по количеству сообщений
        if len(history) > llm_config.MAX_HISTORY_MESSAGES:
            history = history[-llm_config.MAX_HISTORY_MESSAGES :]

        if not history:
            return messages

        # Ограничиваем по количеству токенов
        trimmed_history = []
        token_budget = llm_config.MAX_HISTORY_TOKEN_LENGTH
        token_used = 0

        for message in reversed(history):
            content = message.get("content", "")
            token_count = len(self.tokenizer.encode(content, add_special_tokens=False))

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

    def _select_device(self) -> torch.device:
        """Выбирает лучший доступный device для модели."""
        if torch.cuda.is_available():
            logger.info("Обнаружен CUDA, используем GPU")
            return torch.device("cuda")
        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            logger.info("Обнаружен Apple Silicon (MPS), используем mps")
            return torch.device("mps")
        logger.info("GPU не найден, используем CPU (это значительно медленнее)")
        return torch.device("cpu")

    def _sanitize_max_tokens(self, value: int) -> int:
        """Нормализует значение max_tokens."""
        if value is None:
            return llm_config.DEFAULT_MAX_NEW_TOKENS
        return max(llm_config.MIN_NEW_TOKENS, min(value, llm_config.MAX_NEW_TOKENS))
