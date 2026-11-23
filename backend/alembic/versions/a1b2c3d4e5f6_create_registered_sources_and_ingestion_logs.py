"""create registered_sources, source_documents, document_chunks and ingestion_run_logs

Revision ID: a1b2c3d4e5f6
Revises: 9c0d1e2f3a4b
Create Date: 2026-11-23 20:15:00.000000
"""

from collections.abc import Sequence

import sqlalchemy as sa
from sqlalchemy.dialects import postgresql
from alembic import op

# revision identifiers, used by Alembic.
revision: str = "a1b2c3d4e5f6"
down_revision: str | None = "9c0d1e2f3a4b"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

json_type = postgresql.JSONB().with_variant(sa.JSON(), "sqlite")


def upgrade() -> None:
    # 1. registered_sources
    op.create_table(
        "registered_sources",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("organization", sa.String(length=255), nullable=False),
        sa.Column("base_url", sa.String(length=1024), nullable=False),
        sa.Column("resource_urls", json_type, nullable=False),
        sa.Column("source_type", sa.String(length=64), nullable=False, server_default="portal"),
        sa.Column("access_method", sa.String(length=64), nullable=False, server_default="GET"),
        sa.Column("parser_config", json_type, nullable=True),
        sa.Column("is_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("check_interval_hours", sa.Integer(), nullable=False, server_default="12"),
        sa.Column("next_check_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_checked_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_success_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("last_error", sa.Text(), nullable=True),
        sa.Column("health_status", sa.String(length=32), nullable=False, server_default="active"),
        sa.Column("reliability_score", sa.Float(), nullable=False, server_default="1.0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_registered_sources_name", "registered_sources", ["name"], unique=True)
    op.create_index("ix_registered_sources_is_enabled", "registered_sources", ["is_enabled"])
    op.create_index("ix_registered_sources_next_check_at", "registered_sources", ["next_check_at"])

    # 2. source_documents
    op.create_table(
        "source_documents",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("source_id", sa.String(length=36), sa.ForeignKey("registered_sources.id", ondelete="CASCADE"), nullable=False),
        sa.Column("title", sa.String(length=512), nullable=False),
        sa.Column("document_url", sa.String(length=1024), nullable=False),
        sa.Column("document_type", sa.String(length=64), nullable=False, server_default="portal_page"),
        sa.Column("raw_content", sa.Text(), nullable=True),
        sa.Column("cleaned_text", sa.Text(), nullable=False),
        sa.Column("content_hash", sa.String(length=64), nullable=False),
        sa.Column("version", sa.Integer(), nullable=False, server_default="1"),
        sa.Column("academic_year", sa.String(length=32), nullable=True),
        sa.Column("metadata_fields", json_type, nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("document_url", "version", name="uq_source_document_url_version"),
    )
    op.create_index("ix_source_documents_source_id", "source_documents", ["source_id"])
    op.create_index("ix_source_documents_document_url", "source_documents", ["document_url"])
    op.create_index("ix_source_documents_content_hash", "source_documents", ["content_hash"])

    # 3. document_chunks
    op.create_table(
        "document_chunks",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("document_id", sa.String(length=36), sa.ForeignKey("source_documents.id", ondelete="CASCADE"), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(as_uuid=True), sa.ForeignKey("scholarships.id", ondelete="SET NULL"), nullable=True),
        sa.Column("chunk_index", sa.Integer(), nullable=False),
        sa.Column("content", sa.Text(), nullable=False),
        sa.Column("chunk_metadata", json_type, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_document_chunks_document_id", "document_chunks", ["document_id"])
    op.create_index("ix_document_chunks_scholarship_id", "document_chunks", ["scholarship_id"])

    # 4. ingestion_run_logs
    op.create_table(
        "ingestion_run_logs",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("trigger_type", sa.String(length=32), nullable=False, server_default="scheduled"),
        sa.Column("status", sa.String(length=32), nullable=False, server_default="running"),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sources_checked", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("records_discovered", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("records_created", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("records_updated", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("records_skipped", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("records_rejected", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("conflicts_detected", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("errors", json_type, nullable=True),
        sa.Column("source_results", json_type, nullable=True),
        sa.Column("summary_notes", sa.Text(), nullable=True),
    )


def downgrade() -> None:
    op.drop_table("ingestion_run_logs")
    op.drop_table("document_chunks")
    op.drop_table("source_documents")
    op.drop_table("registered_sources")
