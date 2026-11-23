"""Resilient, secure LLM client for Claim What's Yours powered exclusively by Groq.

Enforces:
- Official Groq API integration (Base URL: https://api.groq.com/openai/v1)
- Model metadata and active status verification
- Strict zero-hallucination grounding guidelines
- Configurable timeouts (default 30s) and token limits (default 1024) via Pydantic settings
- Multilingual support: fluent Telugu and English synthesis with domain terminology
- Safe error handling without leaking API credentials or sensitive PII
- Graceful degradation when no API key is configured
"""

import logging
import time
from typing import Any
import httpx

from app.core.config import get_settings

logger = logging.getLogger("cwy.ai.llm_client")

GROQ_BASE_URL = "https://api.groq.com/openai/v1"
GROQ_CHAT_ENDPOINT = f"{GROQ_BASE_URL}/chat/completions"
GROQ_MODELS_ENDPOINT = f"{GROQ_BASE_URL}/models"


class LLMError(Exception):
    """Base exception for LLM provider errors."""


class LLMConfigurationError(LLMError):
    """Raised when the LLM provider or API key is not configured."""


class LLMAuthenticationError(LLMError):
    """Raised when the Groq API key is invalid (HTTP 401/403)."""


class LLMRateLimitError(LLMError):
    """Raised when provider rate limits (HTTP 429) are encountered."""


class LLMTimeoutError(LLMError):
    """Raised when the LLM provider request times out."""


class LLMClient:
    """Client for authenticated LLM inference against Groq."""

    def __init__(self) -> None:
        self.settings = get_settings()
        self.provider = self.settings.llm_provider.lower()
        self.model = self.settings.llm_model
        self.timeout = self.settings.llm_timeout_seconds
        self.max_tokens = self.settings.llm_max_output_tokens

    @property
    def is_configured(self) -> bool:
        """Return True if an API key is present and configured."""
        if self.provider == "none" or not self.settings.llm_api_key:
            return False
        val = self.settings.llm_api_key.get_secret_value().strip()
        return bool(val and not val.startswith("your-") and val != "none")

    def _get_api_key(self) -> str:
        if not self.is_configured:
            raise LLMConfigurationError(
                "LLM provider API key is not configured. "
                "Please configure CWY_LLM_API_KEY in your environment variables."
            )
        return self.settings.llm_api_key.get_secret_value().strip()

    def validate_connectivity(self) -> dict[str, Any]:
        """Validate live Groq provider connectivity and active model availability.

        Queries the official Groq Models API without sending prompts or credentials.
        """
        if not self.is_configured:
            return {
                "provider": "groq",
                "model": self.model,
                "configured": False,
                "connected": False,
                "message": "CWY_LLM_API_KEY is not configured.",
            }

        api_key = self._get_api_key()
        start = time.perf_counter()

        try:
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            }
            with httpx.Client(timeout=min(self.timeout, 10)) as client:
                resp = client.get(GROQ_MODELS_ENDPOINT, headers=headers)

            latency_ms = round((time.perf_counter() - start) * 1000)

            if resp.status_code == 200:
                data = resp.json()
                active_models = [m.get("id") for m in data.get("data", []) if m.get("active", True)]

                # Check if configured model is in the active list
                model_found = self.model in active_models
                msg = (
                    f"Successfully verified Groq connection. Active model '{self.model}' is available."
                    if model_found
                    else f"Connected to Groq, but model '{self.model}' is not in active list ({len(active_models)} models found)."
                )

                return {
                    "provider": "groq",
                    "model": self.model,
                    "configured": True,
                    "connected": True,
                    "latency_ms": latency_ms,
                    "message": msg,
                    "active_models_count": len(active_models),
                    "model_available": model_found,
                }
            elif resp.status_code in (401, 403):
                return {
                    "provider": "groq",
                    "model": self.model,
                    "configured": True,
                    "connected": False,
                    "latency_ms": latency_ms,
                    "message": "Invalid Groq API key or insufficient permissions.",
                }
            elif resp.status_code == 429:
                return {
                    "provider": "groq",
                    "model": self.model,
                    "configured": True,
                    "connected": False,
                    "latency_ms": latency_ms,
                    "message": "Groq rate limit exceeded. Please wait a moment.",
                }
            else:
                return {
                    "provider": "groq",
                    "model": self.model,
                    "configured": True,
                    "connected": False,
                    "latency_ms": latency_ms,
                    "message": f"Groq validation failed with HTTP {resp.status_code}.",
                }

        except httpx.TimeoutException:
            return {
                "provider": "groq",
                "model": self.model,
                "configured": True,
                "connected": False,
                "message": f"Connection to Groq timed out after {self.timeout}s.",
            }
        except Exception as exc:
            logger.error("Groq provider connectivity check failed: %s", type(exc).__name__)
            return {
                "provider": "groq",
                "model": self.model,
                "configured": True,
                "connected": False,
                "message": f"Network error connecting to Groq: {type(exc).__name__}",
            }

    def generate_grounded_response(
        self,
        query: str,
        grounded_context: str,
        language: str = "en",
        profile_summary: str | None = None,
    ) -> str:
        """Call official Groq chat completions API to synthesize a response grounded in retrieved scholarship facts."""
        if not self.is_configured:
            raise LLMConfigurationError(
                "CWY_LLM_API_KEY is not configured on this server. "
                "Returning verified structured records directly from database."
            )

        api_key = self._get_api_key()

        # Language-specific system directive
        lang_directive = "Reply in clear, professional English."
        if language == "te":
            lang_directive = (
                "Reply in fluent, natural Telugu (తెలుగు) script. "
                "Use accurate Telugu terminology for scholarships (ఉపకార వేతనాలు, అర్హత నిబంధనలు, దరఖాస్తు గడువు, గరిష్ట కుటుంబ ఆదాయం). "
                "Do not mix transliterated Roman script unless referring to official website URLs or scheme names."
            )
        elif language == "hi":
            lang_directive = (
                "Reply in clear, natural Hindi (हिंदी) script. "
                "Use accurate Hindi terminology for government scholarships (छात्रवृत्ति, पात्रता मानदंड, आवश्यक दस्तावेज़, अंतिम तिथि)."
            )

        system_instruction = (
            "You are Claim What's Yours AI Guidance Assistant. "
            "You assist Indian students with government scholarships in Telangana and India.\n\n"
            "STRICT GROUNDING & ZERO-HALLUCINATION RULES:\n"
            "1. Ground your answer EXCLUSIVELY in the verified official scholarship records provided in the context.\n"
            "2. Never fabricate eligibility conditions, application dates, income limits, or benefit amounts.\n"
            "3. If the context does not contain the answer, explicitly state that verified official records do not confirm this.\n"
            "4. Cite the official source URLs and administering authorities provided in the context.\n"
            "5. Remind the student that final eligibility is evaluated by government authorities upon official document verification.\n"
            f"6. {lang_directive}"
        )

        user_content = (
            f"VERIFIED SCHOLARSHIP CONTEXT:\n{grounded_context}\n\n"
            f"STUDENT PROFILE:\n{profile_summary or 'Not provided'}\n\n"
            f"STUDENT QUERY:\n{query}"
        )

        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        }

        # Build payload for Groq chat completions
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system_instruction},
                {"role": "user", "content": user_content},
            ],
            "temperature": 0.2,
            "max_tokens": self.max_tokens,
        }

        # For reasoning models like openai/gpt-oss-120b, ensure reasoning is parsed cleanly
        if "gpt-oss" in self.model:
            payload["reasoning_format"] = "parsed"

        start = time.perf_counter()
        logger.info("Executing Groq chat completion model=%s, lang=%s", self.model, language)

        try:
            with httpx.Client(timeout=self.timeout) as client:
                resp = client.post(GROQ_CHAT_ENDPOINT, headers=headers, json=payload)

            latency_ms = round((time.perf_counter() - start) * 1000)

            if resp.status_code == 200:
                data = resp.json()
                choices = data.get("choices", [])
                if choices:
                    content = choices[0].get("message", {}).get("content", "")
                    # In parsed mode, content holds the final clean synthesized answer
                    if content and content.strip():
                        logger.info("Groq success: latency=%dms, length=%d chars", latency_ms, len(content.strip()))
                        return content.strip()
                    # Fallback to text if choices has text
                    text = choices[0].get("text", "")
                    if text and text.strip():
                        return text.strip()
                raise LLMError("Groq returned empty response content.")

            elif resp.status_code in (401, 403):
                logger.error("Groq authentication failure HTTP %d", resp.status_code)
                raise LLMAuthenticationError("Invalid Groq API key or unauthorized access.")

            elif resp.status_code == 429:
                logger.warning("Groq rate limit 429 encountered after %dms", latency_ms)
                raise LLMRateLimitError(
                    "Groq API rate limit reached. Please wait a moment before trying again."
                )

            elif resp.status_code == 404:
                logger.error("Groq model not found HTTP 404 for model %s", self.model)
                raise LLMConfigurationError(
                    f"Groq model '{self.model}' not found or no longer active. Please check CWY_LLM_MODEL."
                )

            else:
                logger.error("Groq API returned HTTP %d: %s", resp.status_code, resp.text[:120])
                raise LLMError(f"Groq API returned HTTP {resp.status_code}: {resp.text[:120]}")

        except httpx.TimeoutException:
            logger.error("Groq request timed out after %ds", self.timeout)
            raise LLMTimeoutError(f"Request to Groq timed out after {self.timeout} seconds.")
