"""Tests for validated, transactional scholarship ingestion."""

from collections.abc import Iterator
from copy import deepcopy
from datetime import date
from decimal import Decimal

import pytest
from sqlalchemy import create_engine, event, func, select
from sqlalchemy.orm import Session
from sqlalchemy.pool import StaticPool
from pydantic import ValidationError

from app.db.base import Base
import app.db
from app.ingestion.schemas import ImportDataset
from app.ingestion.service import (
    ImportTransactionError,
    ScholarshipImporter,
    load_dataset,
)
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)


@pytest.fixture
def ingestion_session() -> Iterator[Session]:
    engine = create_engine(
        "sqlite+pysqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    @event.listens_for(engine, "connect")
    def enable_foreign_keys(dbapi_connection, connection_record) -> None:
        del connection_record
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def sample_payload() -> dict:
    return {
        "scholarships": [
            {
                "name": "  Example   Scholarship ",
                "slug": "Example Scholarship",
                "description": None,
                "administering_authority": "Example Authority",
                "category": "general",
                "benefits": None,
                "application_url": "https://example.gov.in/apply/",
                "academic_years": [
                    {
                        "year": "2026-27",
                        "is_available": True,
                        "closing_date": "2027-03-31",
                    }
                ],
                "eligibility_criteria": [
                    {
                        "academic_year": "2026-27",
                        "education_levels": ["undergraduate"],
                        "maximum_family_income": 250000,
                    },
                    {
                        "education_levels": ["post_matric"],
                    },
                ],
                "sources": [
                    {
                        "source_url": "https://example.gov.in/source#section",
                        "authority": "Example Authority",
                        "source_type": "government_portal",
                        "verification_status": "pending_verification",
                    }
                ],
            }
        ]
    }


def test_valid_dataset_is_normalized_and_loaded() -> None:
    dataset = ImportDataset.model_validate(sample_payload())
    record = dataset.scholarships[0]

    assert record.slug == "example-scholarship"
    assert record.name == "Example Scholarship"
    assert str(record.application_url) == "https://example.gov.in/apply"
    assert str(record.sources[0].source_url) == "https://example.gov.in/source"
    assert record.description is None


def test_invalid_and_incomplete_records_are_rejected() -> None:
    payload = sample_payload()
    payload["scholarships"][0]["sources"] = []

    with pytest.raises(ValidationError):
        ImportDataset.model_validate(payload)

    payload = sample_payload()
    payload["scholarships"][0]["eligibility_criteria"][0]["academic_year"] = "2025-26"
    with pytest.raises(ValidationError):
        ImportDataset.model_validate(payload)


def test_duplicate_slugs_and_source_urls_are_rejected() -> None:
    payload = sample_payload()
    payload["scholarships"].append(deepcopy(payload["scholarships"][0]))
    with pytest.raises(ValidationError, match="duplicate scholarship slugs"):
        ImportDataset.model_validate(payload)

    payload = sample_payload()
    payload["scholarships"][0]["sources"].append(
        deepcopy(payload["scholarships"][0]["sources"][0])
    )
    with pytest.raises(ValidationError, match="duplicate source URLs"):
        ImportDataset.model_validate(payload)

    payload = sample_payload()
    payload["scholarships"][0]["eligibility_criteria"].append(
        deepcopy(payload["scholarships"][0]["eligibility_criteria"][0])
    )
    with pytest.raises(ValidationError, match="duplicate eligibility criteria"):
        ImportDataset.model_validate(payload)


def test_import_creates_relationships_and_preserves_unknown_values(
    ingestion_session: Session,
) -> None:
    dataset = ImportDataset.model_validate(sample_payload())
    summary = ScholarshipImporter(ingestion_session).import_dataset(dataset)

    assert summary.created >= 6
    scholarship = ingestion_session.scalar(select(Scholarship))
    assert scholarship is not None
    assert scholarship.description is None
    assert scholarship.benefits is None
    assert scholarship.is_active is False
    assert len(scholarship.academic_year_associations) == 1
    assert scholarship.academic_year_associations[0].academic_year.year == "2026-27"
    criteria = sorted(
        scholarship.eligibility_criteria,
        key=lambda item: item.academic_year_id is not None,
    )
    assert criteria[0].academic_year_id is None
    assert criteria[1].academic_year_id is not None
    assert criteria[1].maximum_family_income == Decimal("250000.00")


def test_repeated_import_is_idempotent(ingestion_session: Session) -> None:
    dataset = ImportDataset.model_validate(sample_payload())
    importer = ScholarshipImporter(ingestion_session)

    importer.import_dataset(dataset)
    first_counts = {
        "scholarships": ingestion_session.scalar(select(func.count(Scholarship.id))),
        "years": ingestion_session.scalar(select(func.count(AcademicYear.id))),
        "sources": ingestion_session.scalar(select(func.count(OfficialSource.id))),
        "criteria": ingestion_session.scalar(select(func.count(EligibilityCriteria.id))),
    }
    second = importer.import_dataset(dataset)
    second_counts = {
        "scholarships": ingestion_session.scalar(select(func.count(Scholarship.id))),
        "years": ingestion_session.scalar(select(func.count(AcademicYear.id))),
        "sources": ingestion_session.scalar(select(func.count(OfficialSource.id))),
        "criteria": ingestion_session.scalar(select(func.count(EligibilityCriteria.id))),
    }

    assert second.duplicate >= 3
    assert second_counts == first_counts


def test_existing_source_with_legacy_trailing_slash_is_reused(
    ingestion_session: Session,
) -> None:
    ingestion_session.add(
        OfficialSource(
            source_url="https://example.gov.in/source/",
            authority="Legacy Authority",
            source_type="government_portal",
        )
    )
    ingestion_session.commit()

    dataset = ImportDataset.model_validate(sample_payload())
    ScholarshipImporter(ingestion_session).import_dataset(dataset)

    assert ingestion_session.scalar(select(func.count(OfficialSource.id))) == 1


def test_dry_run_writes_nothing(ingestion_session: Session) -> None:
    dataset = ImportDataset.model_validate(sample_payload())

    summary = ScholarshipImporter(ingestion_session).import_dataset(
        dataset, dry_run=True
    )

    assert summary.created > 0
    assert ingestion_session.scalar(select(func.count(Scholarship.id))) == 0
    assert ingestion_session.scalar(select(func.count(OfficialSource.id))) == 0


def test_transaction_rolls_back_when_import_fails(ingestion_session: Session) -> None:
    payload = sample_payload()
    payload["scholarships"][0]["sources"][0]["verification_status"] = "approved"
    dataset = ImportDataset.model_validate(payload)

    with pytest.raises(ImportTransactionError):
        ScholarshipImporter(ingestion_session).import_dataset(dataset)

    assert ingestion_session.scalar(select(func.count(Scholarship.id))) == 0
    assert ingestion_session.scalar(select(func.count(AcademicYear.id))) == 0


def test_verified_sources_are_not_overwritten(ingestion_session: Session) -> None:
    dataset = ImportDataset.model_validate(sample_payload())
    importer = ScholarshipImporter(ingestion_session)
    importer.import_dataset(dataset)

    association = ingestion_session.scalar(select(ScholarshipSource))
    assert association is not None
    association.verification_status = "approved"
    ingestion_session.commit()

    changed = sample_payload()
    changed["scholarships"][0]["name"] = "Changed Scholarship"
    changed_dataset = ImportDataset.model_validate(changed)
    summary = importer.import_dataset(changed_dataset)

    scholarship = ingestion_session.scalar(select(Scholarship))
    assert scholarship is not None
    assert scholarship.name == "Example Scholarship"
    assert summary.conflicts


def test_sample_dataset_loads() -> None:
    dataset = load_dataset("data/scholarships.sample.json")
    assert len(dataset.scholarships) == 3
    assert all(record.sources for record in dataset.scholarships)
