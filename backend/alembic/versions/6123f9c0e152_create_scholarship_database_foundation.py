"""create scholarship database foundation

Revision ID: 6123f9c0e152
Revises:
Create Date: 2026-11-21 21:55:47

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql


revision: str = "6123f9c0e152"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "academic_years",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("year", sa.String(length=20), nullable=False),
        sa.Column("starts_on", sa.Date(), nullable=True),
        sa.Column("ends_on", sa.Date(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "length(year) > 0",
            name="ck_academic_years_year_not_empty",
        ),
        sa.CheckConstraint(
            "ends_on IS NULL OR starts_on IS NULL OR ends_on >= starts_on",
            name="ck_academic_years_date_range",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("year"),
    )

    op.create_table(
        "official_sources",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("source_url", sa.String(length=2048), nullable=False),
        sa.Column("authority", sa.String(length=255), nullable=False),
        sa.Column("source_type", sa.String(length=64), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=True),
        sa.Column("document_reference", sa.String(length=255), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "length(source_url) > 0",
            name="ck_official_sources_url_not_empty",
        ),
        sa.CheckConstraint(
            "source_type IN ('government_api', 'government_portal', "
            "'government_department', 'official_notification', "
            "'official_pdf', 'other_authority')",
            name="ck_official_sources_source_type",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("source_url", name="uq_official_sources_url"),
    )
    op.create_index(
        "ix_official_sources_authority",
        "official_sources",
        ["authority"],
        unique=False,
    )

    op.create_table(
        "scholarships",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("slug", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("administering_authority", sa.String(length=255), nullable=False),
        sa.Column("category", sa.String(length=64), nullable=False),
        sa.Column(
            "benefits",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column("application_url", sa.String(length=2048), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "length(administering_authority) > 0",
            name="ck_scholarships_authority_not_empty",
        ),
        sa.CheckConstraint(
            "length(name) > 0",
            name="ck_scholarships_name_not_empty",
        ),
        sa.CheckConstraint(
            "category IN ('general', 'sc', 'st', 'obc', 'ebc', 'minority', "
            "'economically_weaker', 'disability', 'merit', 'other')",
            name="ck_scholarships_category",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("slug"),
    )
    op.create_index(
        "ix_scholarships_category_active",
        "scholarships",
        ["category", "is_active"],
        unique=False,
    )
    op.create_index("ix_scholarships_name", "scholarships", ["name"], unique=False)

    op.create_table(
        "scholarship_academic_years",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column("academic_year_id", sa.Uuid(), nullable=False),
        sa.Column("is_available", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("opening_date", sa.Date(), nullable=True),
        sa.Column("closing_date", sa.Date(), nullable=True),
        sa.Column("name_override", sa.String(length=255), nullable=True),
        sa.Column("description_override", sa.Text(), nullable=True),
        sa.Column(
            "benefits_override",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column("application_url_override", sa.String(length=2048), nullable=True),
        sa.CheckConstraint(
            "closing_date IS NULL OR opening_date IS NULL "
            "OR closing_date >= opening_date",
            name="ck_scholarship_academic_year_dates",
        ),
        sa.ForeignKeyConstraint(
            ["academic_year_id"],
            ["academic_years.id"],
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id"],
            ["scholarships.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "scholarship_id",
            "academic_year_id",
            name="uq_scholarship_academic_year",
        ),
    )
    op.create_index(
        "ix_scholarship_academic_year_dates",
        "scholarship_academic_years",
        ["opening_date", "closing_date"],
        unique=False,
    )

    op.create_table(
        "eligibility_criteria",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column("academic_year_id", sa.Uuid(), nullable=True),
        sa.Column("minimum_academic_percentage", sa.Numeric(5, 2), nullable=True),
        sa.Column("maximum_academic_percentage", sa.Numeric(5, 2), nullable=True),
        sa.Column("minimum_family_income", sa.Numeric(12, 2), nullable=True),
        sa.Column("maximum_family_income", sa.Numeric(12, 2), nullable=True),
        sa.Column(
            "education_levels",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column(
            "courses",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column(
            "institution_requirements",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column(
            "categories",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column("domicile_state", sa.String(length=100), nullable=True),
        sa.Column("gender_restriction", sa.String(length=32), nullable=True),
        sa.Column("disability_required", sa.Boolean(), nullable=True),
        sa.Column("renewal_only", sa.Boolean(), server_default="false", nullable=False),
        sa.Column(
            "other_conditions",
            postgresql.JSONB(astext_type=sa.Text()).with_variant(
                sa.JSON(), "sqlite"
            ),
            nullable=True,
        ),
        sa.Column("source_reference", sa.Text(), nullable=True),
        sa.Column("is_verified", sa.Boolean(), server_default="false", nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.CheckConstraint(
            "maximum_academic_percentage IS NULL "
            "OR (maximum_academic_percentage >= 0 "
            "AND maximum_academic_percentage <= 100)",
            name="ck_eligibility_max_academic_percentage",
        ),
        sa.CheckConstraint(
            "maximum_family_income IS NULL OR maximum_family_income >= 0",
            name="ck_eligibility_max_family_income",
        ),
        sa.CheckConstraint(
            "minimum_academic_percentage IS NULL "
            "OR (minimum_academic_percentage >= 0 "
            "AND minimum_academic_percentage <= 100)",
            name="ck_eligibility_min_academic_percentage",
        ),
        sa.CheckConstraint(
            "minimum_academic_percentage IS NULL "
            "OR maximum_academic_percentage IS NULL "
            "OR maximum_academic_percentage >= minimum_academic_percentage",
            name="ck_eligibility_academic_percentage_range",
        ),
        sa.CheckConstraint(
            "minimum_family_income IS NULL "
            "OR maximum_family_income IS NULL "
            "OR maximum_family_income >= minimum_family_income",
            name="ck_eligibility_family_income_range",
        ),
        sa.CheckConstraint(
            "minimum_family_income IS NULL OR minimum_family_income >= 0",
            name="ck_eligibility_min_family_income",
        ),
        sa.ForeignKeyConstraint(
            ["academic_year_id"],
            ["academic_years.id"],
            ondelete="RESTRICT",
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id"],
            ["scholarships.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id", "academic_year_id"],
            [
                "scholarship_academic_years.scholarship_id",
                "scholarship_academic_years.academic_year_id",
            ],
            ondelete="RESTRICT",
            name="fk_eligibility_criteria_scholarship_year",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "scholarship_id",
            "academic_year_id",
            name="uq_eligibility_criteria_scholarship_year",
        ),
    )
    op.create_index(
        "uq_eligibility_criteria_general",
        "eligibility_criteria",
        ["scholarship_id"],
        unique=True,
        postgresql_where=sa.text("academic_year_id IS NULL"),
        sqlite_where=sa.text("academic_year_id IS NULL"),
    )

    op.create_table(
        "scholarship_sources",
        sa.Column("id", sa.Uuid(), nullable=False),
        sa.Column("scholarship_id", sa.Uuid(), nullable=False),
        sa.Column("source_id", sa.Uuid(), nullable=False),
        sa.Column(
            "verification_status",
            sa.String(length=32),
            server_default="pending_verification",
            nullable=False,
        ),
        sa.Column("last_verified_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("verified_by", sa.String(length=255), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.CheckConstraint(
            "verification_status IN ('collected', 'extracted', "
            "'pending_validation', 'pending_verification', 'verified', "
            "'approved', 'rejected', 'archived')",
            name="ck_scholarship_sources_verification_status",
        ),
        sa.ForeignKeyConstraint(
            ["scholarship_id"],
            ["scholarships.id"],
            ondelete="CASCADE",
        ),
        sa.ForeignKeyConstraint(
            ["source_id"],
            ["official_sources.id"],
            ondelete="CASCADE",
        ),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "scholarship_id",
            "source_id",
            name="uq_scholarship_source",
        ),
    )
    op.create_index(
        "ix_scholarship_sources_status_verified",
        "scholarship_sources",
        ["verification_status", "last_verified_at"],
        unique=False,
    )


def downgrade() -> None:
    op.drop_index(
        "ix_scholarship_sources_status_verified",
        table_name="scholarship_sources",
    )
    op.drop_table("scholarship_sources")
    op.drop_index(
        "uq_eligibility_criteria_general",
        table_name="eligibility_criteria",
    )
    op.drop_table("eligibility_criteria")
    op.drop_index(
        "ix_scholarship_academic_year_dates",
        table_name="scholarship_academic_years",
    )
    op.drop_table("scholarship_academic_years")
    op.drop_index("ix_scholarships_name", table_name="scholarships")
    op.drop_index(
        "ix_scholarships_category_active",
        table_name="scholarships",
    )
    op.drop_table("scholarships")
    op.drop_index(
        "ix_official_sources_authority",
        table_name="official_sources",
    )
    op.drop_table("official_sources")
    op.drop_table("academic_years")
