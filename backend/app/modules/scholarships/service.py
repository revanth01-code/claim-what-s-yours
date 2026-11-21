"""Read-only scholarship catalog operations."""

import math
from typing import Literal
from uuid import UUID

from sqlalchemy import String, cast, func, or_, select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, selectinload

from app.core.exceptions import DatabaseUnavailableError
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)


SortField = Literal["name", "created_at", "updated_at", "category"]
SortOrder = Literal["asc", "desc"]


def _escape_search(value: str) -> str:
    return value.strip().replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")


def _catalog_query():
    return (
        select(Scholarship)
        .where(Scholarship.is_active.is_(True))
        .options(
            selectinload(Scholarship.eligibility_criteria),
            selectinload(Scholarship.academic_year_associations).selectinload(
                ScholarshipAcademicYear.academic_year
            ),
            selectinload(Scholarship.source_associations).selectinload(
                ScholarshipSource.source
            ),
        )
    )


def list_scholarships(
    session: Session,
    *,
    page: int,
    page_size: int,
    search: str | None,
    academic_year: str | None,
    category: str | None,
    education_level: str | None,
    sort_by: SortField,
    sort_order: SortOrder,
) -> tuple[list[Scholarship], int, int]:
    """Return active scholarships and catalog pagination metadata."""
    query = _catalog_query()
    count_query = select(func.count(func.distinct(Scholarship.id))).select_from(
        Scholarship
    )
    count_query = count_query.where(Scholarship.is_active.is_(True))

    if search:
        escaped = _escape_search(search)
        if escaped:
            pattern = f"%{escaped}%"
            search_filter = or_(
                Scholarship.name.ilike(pattern, escape="\\"),
                Scholarship.description.ilike(pattern, escape="\\"),
            )
            query = query.where(search_filter)
            count_query = count_query.where(search_filter)

    if category:
        query = query.where(Scholarship.category == category)
        count_query = count_query.where(Scholarship.category == category)

    if academic_year:
        year_join = select(ScholarshipAcademicYear.scholarship_id).join(
            AcademicYear,
            AcademicYear.id == ScholarshipAcademicYear.academic_year_id,
        )
        year_join = year_join.where(
            AcademicYear.year == academic_year,
            ScholarshipAcademicYear.is_available.is_(True),
        )
        availability_filter = Scholarship.id.in_(year_join)
        query = query.where(availability_filter)
        count_query = count_query.where(availability_filter)

    if education_level:
        if session.bind is not None and session.bind.dialect.name == "sqlite":
            education_join = select(EligibilityCriteria.scholarship_id).where(
                cast(EligibilityCriteria.education_levels, String).contains(
                    education_level
                )
            )
        else:
            education_join = select(EligibilityCriteria.scholarship_id).where(
                EligibilityCriteria.education_levels.contains([education_level])
            )
        education_filter = Scholarship.id.in_(education_join)
        query = query.where(education_filter)
        count_query = count_query.where(education_filter)

    sort_columns = {
        "name": Scholarship.name,
        "created_at": Scholarship.created_at,
        "updated_at": Scholarship.updated_at,
        "category": Scholarship.category,
    }
    sort_column = sort_columns[sort_by]
    query = query.order_by(
        sort_column.asc() if sort_order == "asc" else sort_column.desc(),
        Scholarship.id.asc(),
    )
    query = query.offset((page - 1) * page_size).limit(page_size)

    try:
        total = session.scalar(count_query) or 0
        items = list(session.scalars(query).unique())
    except SQLAlchemyError as exc:
        raise DatabaseUnavailableError() from exc

    total_pages = math.ceil(total / page_size) if total else 0
    return items, total, total_pages


def get_scholarship(session: Session, scholarship_id: UUID) -> Scholarship | None:
    """Return one active scholarship by ID."""
    query = _catalog_query().where(Scholarship.id == scholarship_id)
    try:
        return session.scalars(query).unique().one_or_none()
    except SQLAlchemyError as exc:
        raise DatabaseUnavailableError() from exc
