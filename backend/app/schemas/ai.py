"""Schemas for conversational AI guidance and application assistance."""

import uuid
from typing import Any, Literal
from pydantic import BaseModel, ConfigDict, Field


class Citation(BaseModel):
    title: str
    url: str | None = None
    source_type: str | None = None


class AIGuidanceRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")

    query: str = Field(min_length=2, max_length=1000)
    scholarship_id: uuid.UUID | None = None
    language: Literal["en", "te", "hi"] = "en"
    include_profile_context: bool = True


class AIGuidanceResponse(BaseModel):
    answer: str
    language: str
    grounded: bool
    citations: list[Citation] = []
    suggested_actions: list[str] = []
    disclaimer: str = (
        "This response is grounded in official scholarship guidelines and gazettes. "
        "Official eligibility decisions are determined solely by the deterministic eligibility engine."
    )
