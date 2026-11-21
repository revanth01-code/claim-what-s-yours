"""Response schemas for health endpoints."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Liveness information for the API process."""

    status: str
    application: str
    environment: str
    version: str


class DatabaseHealthResponse(BaseModel):
    """Database reachability information."""

    status: str
    database: str
