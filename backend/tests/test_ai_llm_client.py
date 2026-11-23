"""Unit and integration tests for Groq LLM client and AI status endpoints."""

from unittest.mock import MagicMock, patch
import httpx
import pytest
from starlette.testclient import TestClient

from app.core.config import get_settings
from app.modules.ai.llm_client import (
    GROQ_CHAT_ENDPOINT,
    GROQ_MODELS_ENDPOINT,
    LLMAuthenticationError,
    LLMClient,
    LLMConfigurationError,
    LLMRateLimitError,
    LLMTimeoutError,
)
from app.modules.ai.service import AIGuidanceService
from app.schemas.ai import AIGuidanceRequest


def test_llm_client_not_configured_by_default(monkeypatch):
    monkeypatch.delenv("CWY_LLM_API_KEY", raising=False)
    get_settings.cache_clear()

    client = LLMClient()
    assert not client.is_configured

    status = client.validate_connectivity()
    assert status["configured"] is False
    assert status["connected"] is False
    assert "CWY_LLM_API_KEY is not configured" in status["message"]

    with pytest.raises(LLMConfigurationError):
        client.generate_grounded_response("test query", "test context")


def test_groq_connectivity_success_active_model(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_valid_key")
    monkeypatch.setenv("CWY_LLM_MODEL", "openai/gpt-oss-120b")
    get_settings.cache_clear()

    client = LLMClient()
    assert client.is_configured

    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "data": [
            {"id": "openai/gpt-oss-120b", "active": True},
            {"id": "llama-3.1-8b-instant", "active": True},
        ]
    }

    with patch("httpx.Client.get", return_value=mock_resp) as mock_get:
        status = client.validate_connectivity()
        assert status["configured"] is True
        assert status["connected"] is True
        assert status["model_available"] is True
        assert "Successfully verified Groq connection" in status["message"]
        # Verify endpoint called is the official Groq models endpoint
        mock_get.assert_called_once()
        args, kwargs = mock_get.call_args
        assert args[0] == GROQ_MODELS_ENDPOINT
        assert "Bearer gsk_test_valid_key" in kwargs["headers"]["Authorization"]


def test_groq_invalid_api_key_authentication_failure(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_invalid_secret_key")
    get_settings.cache_clear()

    client = LLMClient()
    mock_resp = MagicMock()
    mock_resp.status_code = 401

    with patch("httpx.Client.get", return_value=mock_resp):
        status = client.validate_connectivity()
        assert status["configured"] is True
        assert status["connected"] is False
        assert "Invalid Groq API key" in status["message"]

    with patch("httpx.Client.post", return_value=mock_resp):
        with pytest.raises(LLMAuthenticationError) as exc_info:
            client.generate_grounded_response("Test query", "Test context")
        assert "Invalid Groq API key" in str(exc_info.value)


def test_groq_rate_limiting_429(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_key")
    get_settings.cache_clear()

    client = LLMClient()
    mock_resp = MagicMock()
    mock_resp.status_code = 429

    with patch("httpx.Client.get", return_value=mock_resp):
        status = client.validate_connectivity()
        assert status["configured"] is True
        assert status["connected"] is False
        assert "rate limit exceeded" in status["message"].lower()

    with patch("httpx.Client.post", return_value=mock_resp):
        with pytest.raises(LLMRateLimitError) as exc_info:
            client.generate_grounded_response("Test query", "Test context")
        assert "rate limit" in str(exc_info.value).lower()


def test_groq_timeout_handling(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_key")
    get_settings.cache_clear()

    client = LLMClient()

    with patch("httpx.Client.post", side_effect=httpx.TimeoutException("Connection timed out")):
        with pytest.raises(LLMTimeoutError) as exc_info:
            client.generate_grounded_response("Test query", "Test context")
        assert "timed out" in str(exc_info.value)


def test_groq_english_completion_success(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_key")
    monkeypatch.setenv("CWY_LLM_MODEL", "openai/gpt-oss-120b")
    get_settings.cache_clear()

    client = LLMClient()

    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": "According to official Telangana ePASS records, the maximum annual family income limit is INR 2,00,000 for SC/ST students.",
                }
            }
        ]
    }

    with patch("httpx.Client.post", return_value=mock_resp) as mock_post:
        reply = client.generate_grounded_response(
            query="What is the income ceiling for Telangana ePASS?",
            grounded_context="Telangana ePASS: Maximum annual family income INR 2,00,000 for SC/ST.",
            language="en",
        )
        assert "Telangana ePASS" in reply
        assert "2,00,000" in reply

        # Validate request parameters passed to official Groq API
        mock_post.assert_called_once()
        args, kwargs = mock_post.call_args
        assert args[0] == GROQ_CHAT_ENDPOINT
        payload = kwargs["json"]
        assert payload["model"] == "openai/gpt-oss-120b"
        assert payload["reasoning_format"] == "parsed"
        assert "Telangana ePASS" in payload["messages"][1]["content"]


def test_groq_telugu_completion_success(monkeypatch):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_key")
    monkeypatch.setenv("CWY_LLM_MODEL", "openai/gpt-oss-120b")
    get_settings.cache_clear()

    client = LLMClient()

    telugu_text = "అధికారిక తెలంగాణ ePASS మార్గదర్శకాల ప్రకారం, ఎస్సీ/ఎస్టీ విద్యార్థుల కుటుంబ వార్షిక ఆదాయ పరిమితి రూ. 2,00,000."
    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": telugu_text,
                }
            }
        ]
    }

    with patch("httpx.Client.post", return_value=mock_resp) as mock_post:
        reply = client.generate_grounded_response(
            query="తెలంగాణ ePASS ఉపకార వేతనం కోసం ఆదాయ పరిమితి ఎంత?",
            grounded_context="తెలంగాణ ePASS: కుటుంబ వార్షిక గరిష్ట ఆదాయం రూ. 2,00,000.",
            language="te",
        )
        assert "తెలంగాణ ePASS" in reply
        assert "2,00,000" in reply

        # Validate Telugu prompt instructions in system prompt
        args, kwargs = mock_post.call_args
        sys_prompt = kwargs["json"]["messages"][0]["content"]
        assert "తెలుగు" in sys_prompt
        assert "ఉపకార వేతనాలు" in sys_prompt


@pytest.fixture
def sqlite_session():
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy.pool import StaticPool
    from app.db.base import Base
    import app.modules.users.models  # noqa: F401
    import app.modules.scholarships.models  # noqa: F401
    import app.modules.eligibility.models  # noqa: F401
    import app.modules.profiles.models  # noqa: F401
    import app.modules.applications.models  # noqa: F401
    import app.modules.admin.models  # noqa: F401

    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    session = session_factory()
    yield session
    session.close()
    engine.dispose()


def test_groq_rag_grounded_answer(monkeypatch, sqlite_session):
    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.setenv("CWY_LLM_API_KEY", "gsk_test_key")
    get_settings.cache_clear()

    mock_resp = MagicMock()
    mock_resp.status_code = 200
    mock_resp.json.return_value = {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": "Eligible candidates can apply directly on https://telanganaepass.cgg.gov.in as confirmed by official state guidelines.",
                }
            }
        ]
    }

    service = AIGuidanceService(sqlite_session)
    with patch("httpx.Client.post", return_value=mock_resp):
        response = service.get_guidance(
            AIGuidanceRequest(
                query="How do I apply for Telangana scholarships?",
                include_profile_context=False,
                language="en",
            ),
            profile=None,
        )
        assert response.answer is not None
        assert "https://telanganaepass.cgg.gov.in" in response.answer
        assert len(response.disclaimer) > 0


def test_ai_status_endpoint_groq(monkeypatch):
    from fastapi import FastAPI
    from app.api.v1.ai import router as ai_router

    monkeypatch.setenv("CWY_LLM_PROVIDER", "groq")
    monkeypatch.delenv("CWY_LLM_API_KEY", raising=False)
    get_settings.cache_clear()

    test_app = FastAPI()
    test_app.include_router(ai_router, prefix="/api/v1")

    with TestClient(test_app) as client:
        resp = client.get("/api/v1/ai/status")
        assert resp.status_code == 200
        data = resp.json()
        assert data["provider"] == "groq"
        assert data["configured"] is False
        assert data["connected"] is False
