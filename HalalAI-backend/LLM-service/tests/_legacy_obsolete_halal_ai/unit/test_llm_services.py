"""Тесты для LLM сервисов."""

import pytest
import torch
from unittest.mock import MagicMock, patch

from halal_ai.core.exceptions import ModelNotLoadedException, RemoteLLMException
from halal_ai.services.llm import (
    LocalLLM,
    get_remote_skip_reason,
    select_remote_model,
    should_use_remote_llm,
)


@pytest.fixture
def mock_local_llm():
    """Создает мок LocalLLM с загруженной моделью."""
    llm = LocalLLM()
    llm.model_loaded = True
    llm.device = "cpu"
    
    # Мокируем модель и токенизатор
    llm.model = MagicMock()
    llm.tokenizer = MagicMock()
    
    # Создаем мок для результата токенизации с методом .to()
    mock_encoding = MagicMock()
    mock_encoding.input_ids = torch.tensor([[1, 2, 3]])
    mock_encoding.attention_mask = torch.tensor([[1, 1, 1]])
    mock_encoding.to.return_value = mock_encoding
    
    # Настраиваем токенизатор чтобы возвращал наш мок
    llm.tokenizer.return_value = mock_encoding
    llm.tokenizer.eos_token_id = 2
    llm.tokenizer.pad_token_id = 0
    
    # Настраиваем модель для генерации
    # Возвращаем тензор вместо списка
    llm.model.generate.return_value = torch.tensor([[1, 2, 3, 4, 5]])
    
    # Настраиваем декодирование
    llm.tokenizer.decode.return_value = "Test response"
    
    return llm


class TestLocalLLM:
    """Тесты для LocalLLM."""

    def test_generate_raises_if_not_loaded(self):
        """Generate выбрасывает ошибку если модель не загружена."""
        llm = LocalLLM()
        with pytest.raises(ModelNotLoadedException):
            llm.generate([{"role": "user", "content": "test"}], 100)

    def test_generate_with_loaded_model(self, mock_local_llm):
        """Generate работает с загруженной моделью."""
        messages = [{"role": "user", "content": "What is halal?"}]
        result = mock_local_llm.generate(messages, 100)
        assert isinstance(result, str)
        assert result == "Test response"

    def test_limit_history_length(self, mock_local_llm):
        """Ограничивает длину истории."""
        # Создаем длинную историю
        messages = [{"role": "system", "content": "System"}]
        for i in range(30):
            messages.append({"role": "user", "content": f"Question {i}"})
            messages.append({"role": "assistant", "content": f"Answer {i}"})

        result = mock_local_llm.limit_history_length(messages)
        
        # Проверяем что история ограничена
        assert len(result) < len(messages)
        # System message должен сохраниться
        assert result[0]["role"] == "system"

    def test_sanitize_max_tokens(self, mock_local_llm):
        """Нормализует max_tokens."""
        from halal_ai.core import llm_config
        
        # Слишком большое значение
        assert mock_local_llm._sanitize_max_tokens(99999) == llm_config.MAX_NEW_TOKENS
        
        # Слишком маленькое значение
        assert mock_local_llm._sanitize_max_tokens(1) == llm_config.MIN_NEW_TOKENS
        
        # Валидное значение
        assert mock_local_llm._sanitize_max_tokens(500) == 500


class TestRemoteLLMHelpers:
    """Тесты для вспомогательных функций remote LLM."""

    def test_should_use_remote_llm(self):
        """Проверка логики использования удаленной LLM."""
        with patch("halal_ai.core.remote_llm_config.ENABLED", True):
            assert should_use_remote_llm("test_key") is True
            assert should_use_remote_llm(None) is False
            assert should_use_remote_llm("") is False

    def test_get_remote_skip_reason(self):
        """Возвращает причину пропуска remote LLM."""
        assert get_remote_skip_reason(None) == "api_key не передан"
        
        with patch("halal_ai.core.remote_llm_config.ENABLED", False):
            assert "REMOTE_LLM_ENABLED" in get_remote_skip_reason("test_key")

    def test_select_remote_model_validates_allowed_list(self):
        """Проверяет модель по списку разрешенных."""
        with patch("halal_ai.core.remote_llm_config.ALLOWED_MODELS", ["model1", "model2"]):
            # Разрешенная модель
            assert select_remote_model("model1") == "model1"
            
            # Неразрешенная модель
            with pytest.raises(RemoteLLMException):
                select_remote_model("forbidden_model")

    def test_select_remote_model_removes_prefix(self):
        """Удаляет префикс remote: или local: из названия модели."""
        with patch("halal_ai.core.remote_llm_config.ALLOWED_MODELS", ["model1"]):
            assert select_remote_model("remote:model1") == "model1"
            assert select_remote_model("local:model1") == "model1"

    def test_select_remote_model_rejects_none(self):
        """Отклоняет none как название модели."""
        with pytest.raises(RemoteLLMException):
            select_remote_model("none")
