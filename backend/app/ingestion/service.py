"""Transactional, idempotent scholarship import service."""

from dataclasses import dataclass, field
from decimal import Decimal
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.ingestion.schemas import (
    ImportDataset,
    ImportEligibilityCriteria,
    ImportScholarship,
    normalize_url,
)
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
    VerificationStatus,
)


_PROTECTED_STATUSES = {
    VerificationStatus.VERIFIED.value,
    VerificationStatus.APPROVED.value,
}
_STATUS_RANK = {
    VerificationStatus.COLLECTED.value: 1,
    VerificationStatus.EXTRACTED.value: 2,
    VerificationStatus.PENDING_VALIDATION.value: 3,
    VerificationStatus.PENDING_VERIFICATION.value: 4,
    VerificationStatus.VERIFIED.value: 5,
    VerificationStatus.APPROVED.value: 6,
    VerificationStatus.REJECTED.value: 0,
    VerificationStatus.ARCHIVED.value: 0,
}


@dataclass
class ImportSummary:
    """Import counters and review information."""

    created: int = 0
    updated: int = 0
    skipped: int = 0
    duplicate: int = 0
    failed: int = 0
    conflicts: list[str] = field(default_factory=list)
    errors: list[str] = field(default_factory=list)

    def as_dict(self) -> dict[str, Any]:
        return {
            "created": self.created,
            "updated": self.updated,
            "skipped": self.skipped,
            "duplicate": self.duplicate,
            "failed": self.failed,
            "conflicts": self.conflicts,
            "errors": self.errors,
        }


class ImportTransactionError(RuntimeError):
    """Raised when an import is rolled back after a database failure."""


class ScholarshipImporter:
    """Apply validated records while preserving verified information."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def import_dataset(self, dataset: ImportDataset, *, dry_run: bool = False) -> ImportSummary:
        summary = ImportSummary()
        transaction = (
            self.session.begin_nested()
            if self.session.in_transaction()
            else self.session.begin()
        )
        try:
            for record in dataset.scholarships:
                self._import_record(record, summary)
            self.session.flush()
            if dry_run:
                transaction.rollback()
            else:
                transaction.commit()
        except Exception as exc:
            transaction.rollback()
            summary.failed += 1
            summary.errors.append(str(exc))
            raise ImportTransactionError("Scholarship import was rolled back.") from exc
        return summary

    def _import_record(self, record: ImportScholarship, summary: ImportSummary) -> None:
        scholarship = self.session.scalar(
            select(Scholarship).where(Scholarship.slug == record.slug)
        )
        is_new = scholarship is None
        if is_new:
            if record.is_active:
                summary.conflicts.append(
                    f"new scholarship {record.slug} remains inactive until source verification"
                )
            scholarship = Scholarship(
                name=record.name,
                slug=record.slug,
                description=record.description,
                administering_authority=record.administering_authority,
                category=record.category.value,
                benefits=record.benefits,
                application_url=str(record.application_url) if record.application_url else None,
                is_active=False,
            )
            self.session.add(scholarship)
            self.session.flush()
            summary.created += 1
        else:
            assert scholarship is not None
            protected = self._scholarship_is_protected(scholarship)
            changed = self._update_scholarship(scholarship, record, protected, summary)
            summary.updated += int(changed)
            summary.skipped += int(not changed)

        years = self._upsert_years(scholarship, record, summary)
        self.session.flush()
        self._upsert_criteria(scholarship, record, years, summary)
        self.session.flush()
        self._upsert_sources(scholarship, record, summary)
        self.session.flush()

    def _scholarship_is_protected(self, scholarship: Scholarship) -> bool:
        return any(
            association.verification_status in _PROTECTED_STATUSES
            for association in scholarship.source_associations
        )

    def _update_scholarship(
        self,
        scholarship: Scholarship,
        record: ImportScholarship,
        protected: bool,
        summary: ImportSummary,
    ) -> bool:
        values = {
            "name": record.name,
            "description": record.description,
            "administering_authority": record.administering_authority,
            "category": record.category.value,
            "benefits": record.benefits,
            "application_url": str(record.application_url) if record.application_url else None,
        }
        if record.is_active is not None:
            values["is_active"] = record.is_active
        changed = False
        for field_name, incoming in values.items():
            if incoming is None:
                continue
            current = getattr(scholarship, field_name)
            if current == incoming:
                continue
            if field_name == "is_active" and incoming is True:
                summary.conflicts.append(
                    f"scholarship {scholarship.slug} cannot be activated by an import"
                )
                continue
            if protected:
                summary.conflicts.append(
                    f"protected scholarship {scholarship.slug}: field {field_name} differs"
                )
                continue
            setattr(scholarship, field_name, incoming)
            changed = True
        return changed

    def _upsert_years(
        self,
        scholarship: Scholarship,
        record: ImportScholarship,
        summary: ImportSummary,
    ) -> dict[str, AcademicYear]:
        years: dict[str, AcademicYear] = {}
        for incoming in record.academic_years:
            year = self.session.scalar(
                select(AcademicYear).where(AcademicYear.year == incoming.year)
            )
            if year is None:
                year = AcademicYear(
                    year=incoming.year,
                    starts_on=incoming.starts_on,
                    ends_on=incoming.ends_on,
                )
                self.session.add(year)
                self.session.flush()
                summary.created += 1
            else:
                for field_name in ("starts_on", "ends_on"):
                    incoming_value = getattr(incoming, field_name)
                    current_value = getattr(year, field_name)
                    if incoming_value is None or incoming_value == current_value:
                        continue
                    if current_value is None:
                        setattr(year, field_name, incoming_value)
                        summary.updated += 1
                    else:
                        summary.conflicts.append(
                            f"academic year {incoming.year}: "
                            f"field {field_name} differs"
                        )
            years[incoming.year] = year
            association = self.session.scalar(
                select(ScholarshipAcademicYear).where(
                    ScholarshipAcademicYear.scholarship_id == scholarship.id,
                    ScholarshipAcademicYear.academic_year_id == year.id,
                )
            )
            if association is None:
                association = ScholarshipAcademicYear(
                    scholarship=scholarship,
                    academic_year=year,
                    is_available=incoming.is_available,
                    opening_date=incoming.opening_date,
                    closing_date=incoming.closing_date,
                    name_override=incoming.name_override,
                    description_override=incoming.description_override,
                    benefits_override=incoming.benefits_override,
                    application_url_override=(
                        str(incoming.application_url_override)
                        if incoming.application_url_override
                        else None
                    ),
                )
                self.session.add(association)
                summary.created += 1
            else:
                summary.duplicate += 1
                self._update_year_association(association, incoming, summary)
        return years

    def _update_year_association(self, association, incoming, summary: ImportSummary) -> None:
        values = {
            "is_available": incoming.is_available,
            "opening_date": incoming.opening_date,
            "closing_date": incoming.closing_date,
            "name_override": incoming.name_override,
            "description_override": incoming.description_override,
            "benefits_override": incoming.benefits_override,
            "application_url_override": (
                str(incoming.application_url_override)
                if incoming.application_url_override
                else None
            ),
        }
        for field_name, value in values.items():
            if value is None or getattr(association, field_name) == value:
                continue
            summary.conflicts.append(
                f"academic-year association {association.academic_year_id}: "
                f"field {field_name} differs"
            )

    def _upsert_criteria(
        self,
        scholarship: Scholarship,
        record: ImportScholarship,
        years: dict[str, AcademicYear],
        summary: ImportSummary,
    ) -> None:
        for incoming in record.eligibility_criteria:
            if incoming.is_verified:
                raise ValueError(
                    f"import cannot assert verified eligibility criteria for "
                    f"{scholarship.slug}"
                )
            year = years.get(incoming.academic_year) if incoming.academic_year else None
            criteria = self.session.scalar(
                select(EligibilityCriteria).where(
                    EligibilityCriteria.scholarship_id == scholarship.id,
                    EligibilityCriteria.academic_year_id
                    == (year.id if year else None),
                )
            )
            if criteria is None:
                criteria = EligibilityCriteria(
                    scholarship=scholarship,
                    academic_year=year,
                    **self._criteria_values(incoming),
                )
                self.session.add(criteria)
                summary.created += 1
            elif criteria.is_verified:
                summary.duplicate += 1
                if self._criteria_values(incoming) != self._criteria_values_from_model(criteria):
                    summary.conflicts.append(
                        f"verified eligibility criteria conflict for {scholarship.slug}"
                    )
            else:
                values = self._criteria_values(incoming)
                changed = False
                for field_name, value in values.items():
                    if value is not None and getattr(criteria, field_name) != value:
                        setattr(criteria, field_name, value)
                        changed = True
                summary.updated += int(changed)
                summary.duplicate += int(not changed)

    @staticmethod
    def _criteria_values(incoming: ImportEligibilityCriteria) -> dict[str, Any]:
        return {
            "minimum_academic_percentage": incoming.minimum_academic_percentage,
            "maximum_academic_percentage": incoming.maximum_academic_percentage,
            "minimum_family_income": incoming.minimum_family_income,
            "maximum_family_income": incoming.maximum_family_income,
            "education_levels": incoming.education_levels,
            "courses": incoming.courses,
            "institution_requirements": incoming.institution_requirements,
            "categories": incoming.categories,
            "domicile_state": incoming.domicile_state,
            "gender_restriction": incoming.gender_restriction,
            "disability_required": incoming.disability_required,
            "renewal_only": incoming.renewal_only,
            "other_conditions": incoming.other_conditions,
            "source_reference": incoming.source_reference,
            "is_verified": incoming.is_verified,
        }

    @staticmethod
    def _criteria_values_from_model(criteria: EligibilityCriteria) -> dict[str, Any]:
        return {
            field_name: getattr(criteria, field_name)
            for field_name in ScholarshipImporter._criteria_values(
                ImportEligibilityCriteria()
            )
        }

    def _upsert_sources(
        self,
        scholarship: Scholarship,
        record: ImportScholarship,
        summary: ImportSummary,
    ) -> None:
        for incoming in record.sources:
            incoming_status = incoming.verification_status.value
            if incoming_status in _PROTECTED_STATUSES:
                raise ValueError(
                    f"import cannot assert {incoming_status} for {incoming.source_url}; "
                    "verified records require an explicit verification workflow"
                )
            normalized_url = normalize_url(incoming.source_url)
            source = self._find_source_by_normalized_url(normalized_url)
            if source is None:
                source = OfficialSource(
                    source_url=normalized_url,
                    authority=incoming.authority,
                    source_type=incoming.source_type.value,
                    title=incoming.title,
                    document_reference=incoming.document_reference,
                )
                self.session.add(source)
                self.session.flush()
                summary.created += 1
            association = self.session.scalar(
                select(ScholarshipSource).where(
                    ScholarshipSource.scholarship_id == scholarship.id,
                    ScholarshipSource.source_id == source.id,
                )
            )
            if association is None:
                self.session.add(
                    ScholarshipSource(
                        scholarship=scholarship,
                        source=source,
                        verification_status=incoming_status,
                        last_verified_at=None,
                        verified_by=None,
                        notes=incoming.notes,
                    )
                )
                summary.created += 1
                continue
            summary.duplicate += 1
            if association.verification_status in _PROTECTED_STATUSES:
                if association.verification_status != incoming_status:
                    summary.conflicts.append(
                        f"protected source conflict for {normalized_url}"
                    )
                continue
            if _STATUS_RANK[incoming_status] > _STATUS_RANK[association.verification_status]:
                association.verification_status = incoming_status
                summary.updated += 1
            elif _STATUS_RANK[incoming_status] < _STATUS_RANK[association.verification_status]:
                summary.conflicts.append(
                    f"source verification downgrade rejected for {normalized_url}"
                )

    def _find_source_by_normalized_url(
        self, normalized_url: str
    ) -> OfficialSource | None:
        """Reuse legacy source rows whose stored URL normalizes to the same URL."""
        for source in self.session.scalars(select(OfficialSource)):
            if normalize_url(source.source_url) == normalized_url:
                return source
        return None


def load_dataset(path: str) -> ImportDataset:
    """Load and validate a JSON dataset before opening a database transaction."""
    import json
    from pathlib import Path

    payload = json.loads(Path(path).read_text(encoding="utf-8"))
    return ImportDataset.model_validate(payload)
