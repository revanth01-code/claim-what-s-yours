"""Registry and models for dynamic official scholarship sources, documents and ingestion runs.

Adheres strictly to docs/architecture.md, docs/ai-architecture.md, and docs/data-sources.md:
- Database-driven source registry for official organizations (APIs, websites, PDFs, notifications).
- Dynamic document ingestion, versioning, and change tracking.
- Independent execution logging without relying on long-lived in-process memory.
"""

from datetime import datetime, timezone
import enum
from typing import Any
import uuid

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    JSON,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from app.db.base import Base

JSONValue = JSONB().with_variant(JSON, "sqlite")


class SourceType(str, enum.Enum):
    PORTAL = "portal"
    API = "api"
    HTML_PAGE = "html_page"
    PDF_DOCUMENT = "pdf_document"
    PUBLIC_FEED = "public_feed"
    GAZETTE_NOTIFICATION = "gazette_notification"


class SourceStatus(str, enum.Enum):
    ACTIVE = "active"
    PAUSED = "paused"
    DISABLED = "disabled"
    ERROR = "error"


class DocumentType(str, enum.Enum):
    GAZETTE = "gazette"
    GUIDELINE = "guideline"
    ANNOUNCEMENT = "announcement"
    APPLICATION_FORM = "application_form"
    PORTAL_PAGE = "portal_page"


class RegisteredSource(Base):
    """Database-driven source registry for official government organizations and portals."""

    __tablename__ = "registered_sources"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False, unique=True, index=True)
    organization = Column(String(255), nullable=False)
    base_url = Column(String(1024), nullable=False)
    resource_urls = Column(JSONValue, nullable=False, default=list)  # list of specific endpoints/pages
    source_type = Column(String(64), nullable=False, default=SourceType.PORTAL.value)
    access_method = Column(String(64), nullable=False, default="GET")
    parser_config = Column(JSONValue, nullable=True)  # custom selectors, headers, or query parameters
    is_enabled = Column(Boolean, nullable=False, default=True, index=True)
    check_interval_hours = Column(Integer, nullable=False, default=12)
    next_check_at = Column(DateTime(timezone=True), nullable=True, index=True)
    last_checked_at = Column(DateTime(timezone=True), nullable=True)
    last_success_at = Column(DateTime(timezone=True), nullable=True)
    last_error = Column(Text, nullable=True)
    health_status = Column(String(32), nullable=False, default=SourceStatus.ACTIVE.value)
    reliability_score = Column(Float, nullable=False, default=1.0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    documents = relationship("SourceDocument", back_populates="source", cascade="all, delete-orphan")


class SourceDocument(Base):
    """Official government documents, PDFs, or raw snapshots ingested for RAG and verification."""

    __tablename__ = "source_documents"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    source_id = Column(String(36), ForeignKey("registered_sources.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(512), nullable=False)
    document_url = Column(String(1024), nullable=False, index=True)
    document_type = Column(String(64), nullable=False, default=DocumentType.PORTAL_PAGE.value)
    raw_content = Column(Text, nullable=True)
    cleaned_text = Column(Text, nullable=False)
    content_hash = Column(String(64), nullable=False, index=True)
    version = Column(Integer, nullable=False, default=1)
    academic_year = Column(String(32), nullable=True)
    metadata_fields = Column(JSONValue, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    source = relationship("RegisteredSource", back_populates="documents")
    chunks = relationship("DocumentChunk", back_populates="document", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("document_url", "version", name="uq_source_document_url_version"),
    )


class DocumentChunk(Base):
    """Indexed chunks for semantic retrieval, criteria grounding, and source citation."""

    __tablename__ = "document_chunks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    document_id = Column(String(36), ForeignKey("source_documents.id", ondelete="CASCADE"), nullable=False, index=True)
    scholarship_id = Column(String(36), ForeignKey("scholarships.id", ondelete="SET NULL"), nullable=True, index=True)
    chunk_index = Column(Integer, nullable=False)
    content = Column(Text, nullable=False)
    chunk_metadata = Column(JSONValue, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    document = relationship("SourceDocument", back_populates="chunks")


class IngestionRunLog(Base):
    """Execution history for scheduled and manual ingestion pipeline runs."""

    __tablename__ = "ingestion_run_logs"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    trigger_type = Column(String(32), nullable=False, default="scheduled")  # scheduled, manual, github_actions
    status = Column(String(32), nullable=False, default="running")  # running, success, failed, partial
    started_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime(timezone=True), nullable=True)
    sources_checked = Column(Integer, nullable=False, default=0)
    records_discovered = Column(Integer, nullable=False, default=0)
    records_created = Column(Integer, nullable=False, default=0)
    records_updated = Column(Integer, nullable=False, default=0)
    records_skipped = Column(Integer, nullable=False, default=0)
    records_rejected = Column(Integer, nullable=False, default=0)
    conflicts_detected = Column(Integer, nullable=False, default=0)
    errors = Column(JSONValue, nullable=True)
    source_results = Column(JSONValue, nullable=True)
    summary_notes = Column(Text, nullable=True)
