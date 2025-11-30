import logging
from typing import Dict, List

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM

from config import (
    DEFAULT_MAX_NEW_TOKENS,
    MAX_NEW_TOKENS,
    MIN_NEW_TOKENS,
    model_name,
)
from prompt_utils import build_prompt_text, log_prompt_if_needed

logger = logging.getLogger(__name__)


class LocalLLM:
    def __init__(self):
        self.model = None
        self.tokenizer = None
        self.model_device = torch.device("cpu")
        self.model_name = model_name

    async def load(self):
        self.model_device = self._select_device()
        dtype = torch.float32
        device_map = None
        if self.model_device.type in {"cuda", "mps"}:
            dtype = torch.float16
            device_map = "auto"

        self.tokenizer = AutoTokenizer.from_pretrained(self.model_name, trust_remote_code=True)
        if self.tokenizer.pad_token is None:
            self.tokenizer.pad_token = self.tokenizer.eos_token
            self.tokenizer.pad_token_id = self.tokenizer.eos_token_id
            logger.info("Установлен pad_token = eos_token (ID: %s)", self.tokenizer.pad_token_id)

        self.model = AutoModelForCausalLM.from_pretrained(
            self.model_name,
            dtype=dtype,
            device_map=device_map,
            low_cpu_mem_usage=True,
        )
        if device_map is None:
            self.model.to(self.model_device)
        self.model.eval()
        logger.info("✅ Локальная модель загружена (device=%s, dtype=%s)", self.model_device, dtype)

    def generate(self, messages: List[Dict[str, str]], max_tokens: int) -> str:
        prompt_text = build_prompt_text(self.tokenizer, messages)
        log_prompt_if_needed(logger, prompt_text)
        model_inputs = self.tokenizer([prompt_text], return_tensors="pt").to(self.model_device)
        max_new_tokens = self._sanitize_max_tokens(max_tokens)

        generation_kwargs = {
            "max_new_tokens": max_new_tokens,
            "do_sample": True,
            "temperature": 0.4,
            "top_p": 0.85,
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

    def _select_device(self) -> torch.device:
        if torch.cuda.is_available():
            logger.info("Обнаружен CUDA, используем GPU")
            return torch.device("cuda")
        if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            logger.info("Обнаружен Apple Silicon (MPS), используем mps")
            return torch.device("mps")
        logger.info("GPU не найден, используем CPU (это значительно медленнее)")
        return torch.device("cpu")

    def _sanitize_max_tokens(self, value: int) -> int:
        if value is None:
            return DEFAULT_MAX_NEW_TOKENS
        return max(MIN_NEW_TOKENS, min(value, MAX_NEW_TOKENS))

