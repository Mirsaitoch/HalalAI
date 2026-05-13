"""Общие фикстуры для тестов halal_rag."""

import pytest


@pytest.fixture(autouse=True)
def reset_dependency_container():
    """Сбрасывает синглтон контейнера между тестами (ленивый импорт для coverage)."""
    from halal_rag.api import dependencies

    dependencies.DependencyContainer._rag = None
    dependencies.DependencyContainer._llm_client = None
    dependencies.DependencyContainer._chat_service = None
    yield
    dependencies.DependencyContainer._rag = None
    dependencies.DependencyContainer._llm_client = None
    dependencies.DependencyContainer._chat_service = None
