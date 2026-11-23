"""Administrator endpoints for dynamic source registry, scheduled ingestion, and execution logs."""

from datetime import datetime, timezone
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from pydantic import BaseModel, Field
from sqlalchemy import desc, select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db_session
from app.ingestion.pipeline import DynamicIngestionPipeline
from app.modules.auth.dependencies import require_admin
from app.modules.sources.models import (
    IngestionRunLog,
    RegisteredSource,
    SourceDocument,
    SourceStatus,
    SourceType,
)
from app.modules.users.models import User

router = APIRouter(prefix="/admin/ingestion", tags=["admin-ingestion"])


# Schemas
class RegisteredSourceCreateRequest(BaseModel):
    name: str = Field(..., min_length=3, max_length=255)
    organization: str = Field(..., min_length=2, max_length=255)
    base_url: str = Field(..., min_length=8, max_length=1024)
    resource_urls: list[str] = Field(default_factory=list)
    source_type: str = Field(default=SourceType.PORTAL.value)
    access_method: str = Field(default="GET")
    parser_config: dict[str, Any] | None = None
    check_interval_hours: int = Field(default=12, ge=1, le=168)
    reliability_score: float = Field(default=1.0, ge=0.0, le=1.0)


class RegisteredSourceUpdateRequest(BaseModel):
    name: str | None = None
    organization: str | None = None
    base_url: str | None = None
    resource_urls: list[str] | None = None
    source_type: str | None = None
    access_method: str | None = None
    parser_config: dict[str, Any] | None = None
    is_enabled: bool | None = None
    check_interval_hours: int | None = None
    reliability_score: float | None = None


class RegisteredSourceResponse(BaseModel):
    id: str
    name: str
    organization: str
    base_url: str
    resource_urls: list[str]
    source_type: str
    access_method: str
    parser_config: dict[str, Any] | None
    is_enabled: bool
    check_interval_hours: int
    next_check_at: datetime | None
    last_checked_at: datetime | None
    last_success_at: datetime | None
    last_error: str | None
    health_status: str
    reliability_score: float
    created_at: datetime
    updated_at: datetime


class IngestionRunLogResponse(BaseModel):
    id: str
    trigger_type: str
    status: str
    started_at: datetime
    completed_at: datetime | None
    sources_checked: int
    records_discovered: int
    records_created: int
    records_updated: int
    records_skipped: int
    records_rejected: int
    conflicts_detected: int
    errors: list[str] | None
    source_results: list[dict[str, Any]] | None
    summary_notes: str | None


class IngestionOverviewResponse(BaseModel):
    total_sources: int
    active_sources: int
    paused_sources: int
    error_sources: int
    total_runs: int
    failed_runs: int
    last_run: IngestionRunLogResponse | None
    sources: list[RegisteredSourceResponse]


@router.get("/overview", response_model=IngestionOverviewResponse)
def get_ingestion_overview(
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> IngestionOverviewResponse:
    """Return overall health, sources, and execution summary for the Admin Ingestion Dashboard."""
    pipeline = DynamicIngestionPipeline(session)
    pipeline.bootstrap_registered_sources()

    sources = session.scalars(select(RegisteredSource).order_by(RegisteredSource.name)).all()
    total_sources = len(sources)
    active_sources = sum(1 for s in sources if s.is_enabled and s.health_status == SourceStatus.ACTIVE.value)
    paused_sources = sum(1 for s in sources if not s.is_enabled)
    error_sources = sum(1 for s in sources if s.health_status == SourceStatus.ERROR.value)

    total_runs = session.query(IngestionRunLog).count()
    failed_runs = session.query(IngestionRunLog).filter(IngestionRunLog.status == "failed").count()

    last_run = session.scalar(select(IngestionRunLog).order_by(desc(IngestionRunLog.started_at)).limit(1))

    return IngestionOverviewResponse(
        total_sources=total_sources,
        active_sources=active_sources,
        paused_sources=paused_sources,
        error_sources=error_sources,
        total_runs=total_runs,
        failed_runs=failed_runs,
        last_run=IngestionRunLogResponse(
            id=str(last_run.id),
            trigger_type=last_run.trigger_type,
            status=last_run.status,
            started_at=last_run.started_at,
            completed_at=last_run.completed_at,
            sources_checked=last_run.sources_checked,
            records_discovered=last_run.records_discovered,
            records_created=last_run.records_created,
            records_updated=last_run.records_updated,
            records_skipped=last_run.records_skipped,
            records_rejected=last_run.records_rejected,
            conflicts_detected=last_run.conflicts_detected,
            errors=last_run.errors,
            source_results=last_run.source_results,
            summary_notes=last_run.summary_notes,
        ) if last_run else None,
        sources=[
            RegisteredSourceResponse(
                id=str(s.id),
                name=s.name,
                organization=s.organization,
                base_url=s.base_url,
                resource_urls=s.resource_urls or [],
                source_type=s.source_type,
                access_method=s.access_method,
                parser_config=s.parser_config,
                is_enabled=s.is_enabled,
                check_interval_hours=s.check_interval_hours,
                next_check_at=s.next_check_at,
                last_checked_at=s.last_checked_at,
                last_success_at=s.last_success_at,
                last_error=s.last_error,
                health_status=s.health_status,
                reliability_score=s.reliability_score,
                created_at=s.created_at,
                updated_at=s.updated_at,
            )
            for s in sources
        ],
    )


@router.get("/sources", response_model=list[RegisteredSourceResponse])
def list_registered_sources(
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> list[RegisteredSourceResponse]:
    """List all registered official scholarship sources."""
    pipeline = DynamicIngestionPipeline(session)
    pipeline.bootstrap_registered_sources()
    sources = session.scalars(select(RegisteredSource).order_by(RegisteredSource.name)).all()
    return [
        RegisteredSourceResponse(
            id=str(s.id),
            name=s.name,
            organization=s.organization,
            base_url=s.base_url,
            resource_urls=s.resource_urls or [],
            source_type=s.source_type,
            access_method=s.access_method,
            parser_config=s.parser_config,
            is_enabled=s.is_enabled,
            check_interval_hours=s.check_interval_hours,
            next_check_at=s.next_check_at,
            last_checked_at=s.last_checked_at,
            last_success_at=s.last_success_at,
            last_error=s.last_error,
            health_status=s.health_status,
            reliability_score=s.reliability_score,
            created_at=s.created_at,
            updated_at=s.updated_at,
        )
        for s in sources
    ]


@router.post("/sources", response_model=RegisteredSourceResponse, status_code=status.HTTP_201_CREATED)
def register_new_source(
    payload: RegisteredSourceCreateRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> RegisteredSourceResponse:
    """Register a new official scholarship source dynamically without changing Python code."""
    existing = session.scalar(select(RegisteredSource).where(RegisteredSource.name == payload.name))
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Source with name '{payload.name}' already exists.",
        )

    src = RegisteredSource(
        name=payload.name,
        organization=payload.organization,
        base_url=payload.base_url,
        resource_urls=payload.resource_urls,
        source_type=payload.source_type,
        access_method=payload.access_method,
        parser_config=payload.parser_config,
        check_interval_hours=payload.check_interval_hours,
        reliability_score=payload.reliability_score,
        health_status=SourceStatus.ACTIVE.value,
        is_enabled=True,
    )
    session.add(src)
    session.commit()
    session.refresh(src)

    return RegisteredSourceResponse(
        id=str(src.id),
        name=src.name,
        organization=src.organization,
        base_url=src.base_url,
        resource_urls=src.resource_urls or [],
        source_type=src.source_type,
        access_method=src.access_method,
        parser_config=src.parser_config,
        is_enabled=src.is_enabled,
        check_interval_hours=src.check_interval_hours,
        next_check_at=src.next_check_at,
        last_checked_at=src.last_checked_at,
        last_success_at=src.last_success_at,
        last_error=src.last_error,
        health_status=src.health_status,
        reliability_score=src.reliability_score,
        created_at=src.created_at,
        updated_at=src.updated_at,
    )


@router.patch("/sources/{source_id}", response_model=RegisteredSourceResponse)
def update_registered_source(
    source_id: str,
    payload: RegisteredSourceUpdateRequest,
    admin: User = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> RegisteredSourceResponse:
    """Update or pause an existing official scholarship source."""
    src = session.get(RegisteredSource, source_id)
    if not src:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Source not found.")

    for field_name, value in payload.model_dump(exclude_unset=True).items():
        setattr(src, field_name, value)

    session.commit()
    session.refresh(src)

    return RegisteredSourceResponse(
        id=str(src.id),
        name=src.name,
        organization=src.organization,
        base_url=src.base_url,
        resource_urls=src.resource_urls or [],
        source_type=src.source_type,
        access_method=src.access_method,
        parser_config=src.parser_config,
        is_enabled=src.is_enabled,
        check_interval_hours=src.check_interval_hours,
        next_check_at=src.next_check_at,
        last_checked_at=src.last_checked_at,
        last_success_at=src.last_success_at,
        last_error=src.last_error,
        health_status=src.health_status,
        reliability_score=src.reliability_score,
        created_at=src.created_at,
        updated_at=src.updated_at,
    )


@router.post("/trigger", response_model=IngestionRunLogResponse)
def trigger_ingestion_pipeline(
    source_id: str | None = Query(None, description="Optional specific source to check"),
    force_recheck: bool = Query(False, description="Force re-parsing even if document content hash matches"),
    admin: User | None = Depends(require_admin),
    session: Session = Depends(get_db_session),
) -> IngestionRunLogResponse:
    """Manually trigger discovery and ingestion pipeline by an authenticated admin."""
    pipeline = DynamicIngestionPipeline(session)
    run_log = pipeline.run_discovery_and_ingestion(
        trigger_type="manual_admin",
        target_source_id=source_id,
        force_recheck=force_recheck,
    )
    return IngestionRunLogResponse(
        id=str(run_log.id),
        trigger_type=run_log.trigger_type,
        status=run_log.status,
        started_at=run_log.started_at,
        completed_at=run_log.completed_at,
        sources_checked=run_log.sources_checked,
        records_discovered=run_log.records_discovered,
        records_created=run_log.records_created,
        records_updated=run_log.records_updated,
        records_skipped=run_log.records_skipped,
        records_rejected=run_log.records_rejected,
        conflicts_detected=run_log.conflicts_detected,
        errors=run_log.errors,
        source_results=run_log.source_results,
        summary_notes=run_log.summary_notes,
    )


@router.post("/webhook-trigger", response_model=IngestionRunLogResponse)
def webhook_trigger_ingestion(
    x_ingestion_secret: str | None = Header(None, alias="X-Ingestion-Secret"),
    session: Session = Depends(get_db_session),
) -> IngestionRunLogResponse:
    """External scheduled cron trigger (e.g., GitHub Actions scheduled workflow).

    Secured via CWY_INGESTION_SECRET; does not require interactive Firebase Auth.
    """
    settings = get_settings()
    configured_secret = settings.ingestion_secret.get_secret_value() if settings.ingestion_secret else None

    # If secret is configured, require match
    if configured_secret and x_ingestion_secret != configured_secret:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing X-Ingestion-Secret header.",
        )

    pipeline = DynamicIngestionPipeline(session)
    run_log = pipeline.run_discovery_and_ingestion(trigger_type="github_actions_cron")

    return IngestionRunLogResponse(
        id=str(run_log.id),
        trigger_type=run_log.trigger_type,
        status=run_log.status,
        started_at=run_log.started_at,
        completed_at=run_log.completed_at,
        sources_checked=run_log.sources_checked,
        records_discovered=run_log.records_discovered,
        records_created=run_log.records_created,
        records_updated=run_log.records_updated,
        records_skipped=run_log.records_skipped,
        records_rejected=run_log.records_rejected,
        conflicts_detected=run_log.conflicts_detected,
        errors=run_log.errors,
        source_results=run_log.source_results,
        summary_notes=run_log.summary_notes,
    )
