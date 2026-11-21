"""Isolated SQLAlchemy model tests."""

import uuid
from datetime import date, datetime, timezone
from decimal import Decimal

import pytest
from sqlalchemy import create_engine, event, inspect
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.base import Base
import app.db  # Register all models.
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)


@pytest.fixture
def sqlite_session():
    engine = create_engine("sqlite+pysqlite:///:memory:")

    @event.listens_for(engine, "connect")
    def enable_sqlite_foreign_keys(dbapi_connection, connection_record) -> None:
        del connection_record
        cursor = dbapi_connection.cursor()
        cursor.execute("PRAGMA foreign_keys=ON")
        cursor.close()

    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
    engine.dispose()


def make_scholarship(name: str = "Test Scholarship") -> Scholarship:
    return Scholarship(
        name=name,
        slug=name.lower().replace(" ", "-"),
        description="Test-only foundation record",
        administering_authority="Test Authority",
        category="general",
        benefits={"amount": "test-only"},
        application_url="https://example.gov.in/test",
        is_active=True,
    )


def test_scholarship_model_creation_and_required_fields(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    sqlite_session.add(scholarship)
    sqlite_session.commit()

    persisted = sqlite_session.get(Scholarship, scholarship.id)
    assert persisted is not None
    assert persisted.name == "Test Scholarship"
    assert persisted.slug == "test-scholarship"
    assert persisted.is_active is True
    assert persisted.created_at is not None
    assert persisted.updated_at is not None

    with pytest.raises(IntegrityError):
        sqlite_session.add(
            Scholarship(
                name="",
                slug="",
                administering_authority="",
                category="general",
            )
        )
        sqlite_session.commit()


def test_scholarship_slug_is_unique(sqlite_session: Session) -> None:
    sqlite_session.add(make_scholarship())
    sqlite_session.commit()

    duplicate = make_scholarship("Other Name")
    duplicate.slug = "test-scholarship"
    sqlite_session.add(duplicate)

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_academic_year_and_scholarship_association(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    year = AcademicYear(
        year="2026-27",
        starts_on=date(2026, 4, 1),
        ends_on=date(2027, 3, 31),
    )
    association = ScholarshipAcademicYear(
        opening_date=date(2026, 6, 1),
        closing_date=date(2026, 11, 30),
        is_available=True,
    )
    association.scholarship = scholarship
    association.academic_year = year
    sqlite_session.add(association)
    sqlite_session.commit()

    persisted = sqlite_session.get(Scholarship, scholarship.id)
    assert persisted is not None
    assert len(persisted.academic_year_associations) == 1
    assert persisted.academic_year_associations[0].academic_year.year == "2026-27"


def test_academic_year_association_dates_are_validated(
    sqlite_session: Session,
) -> None:
    association = ScholarshipAcademicYear(
        scholarship=make_scholarship(),
        academic_year=AcademicYear(year="2026-27"),
        opening_date=date(2026, 11, 30),
        closing_date=date(2026, 6, 1),
    )
    sqlite_session.add(association)

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_academic_year_and_association_are_unique(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    year = AcademicYear(year="2026-27")
    sqlite_session.add_all(
        [
            ScholarshipAcademicYear(
                scholarship=scholarship,
                academic_year=year,
            ),
            ScholarshipAcademicYear(
                scholarship=scholarship,
                academic_year=year,
            ),
        ]
    )

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_source_verification_relationship(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    source = OfficialSource(
        source_url="https://example.gov.in/official-source",
        authority="Test Government Authority",
        source_type="government_portal",
        title="Test source",
        document_reference="TEST-2026",
    )
    association = ScholarshipSource(
        verification_status="pending_verification",
        last_verified_at=datetime(2026, 11, 21, tzinfo=timezone.utc),
        verified_by="test-verifier",
        notes="Test metadata only",
    )
    association.scholarship = scholarship
    association.source = source
    sqlite_session.add(association)
    sqlite_session.commit()

    persisted = sqlite_session.get(Scholarship, scholarship.id)
    assert persisted is not None
    assert len(persisted.source_associations) == 1
    link = persisted.source_associations[0]
    assert link.source.source_url == "https://example.gov.in/official-source"
    assert link.verification_status == "pending_verification"
    assert link.last_verified_at is not None


def test_one_source_can_associate_with_multiple_scholarships(
    sqlite_session: Session,
) -> None:
    source = OfficialSource(
        source_url="https://example.gov.in/shared-source",
        authority="Test Government Authority",
        source_type="official_notification",
    )
    first = make_scholarship("First Test Scholarship")
    second = make_scholarship("Second Test Scholarship")
    sqlite_session.add_all(
        [
            ScholarshipSource(
                scholarship=first,
                source=source,
                verification_status="approved",
            ),
            ScholarshipSource(
                scholarship=second,
                source=source,
                verification_status="approved",
            ),
        ]
    )
    sqlite_session.commit()

    persisted = sqlite_session.get(OfficialSource, source.id)
    assert persisted is not None
    assert len(persisted.scholarship_associations) == 2


def test_source_url_is_unique(sqlite_session: Session) -> None:
    sqlite_session.add(
        OfficialSource(
            source_url="https://example.gov.in/unique-source",
            authority="Test Authority",
            source_type="official_pdf",
        )
    )
    sqlite_session.commit()

    sqlite_session.add(
        OfficialSource(
            source_url="https://example.gov.in/unique-source",
            authority="Another Authority",
            source_type="official_pdf",
        )
    )
    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_structured_eligibility_criteria_relationship(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    year = AcademicYear(year="2026-27")
    sqlite_session.add(
        ScholarshipAcademicYear(
            scholarship=scholarship,
            academic_year=year,
        )
    )
    sqlite_session.flush()
    criteria = EligibilityCriteria(
        minimum_academic_percentage=Decimal("60.00"),
        maximum_academic_percentage=Decimal("100.00"),
        minimum_family_income=Decimal("0"),
        maximum_family_income=Decimal("250000"),
        education_levels=["post_matric", "undergraduate"],
        courses=["B.Tech"],
        institution_requirements={"recognized": True},
        categories=["sc", "st"],
        domicile_state="Telangana",
        disability_required=False,
        renewal_only=False,
        other_conditions={"attendance_percentage": 75},
        source_reference="test-only-source-reference",
        is_verified=False,
        academic_year=year,
    )
    criteria.scholarship = scholarship
    sqlite_session.add(criteria)
    sqlite_session.commit()

    persisted = sqlite_session.get(Scholarship, scholarship.id)
    assert persisted is not None
    assert len(persisted.eligibility_criteria) == 1
    assert persisted.eligibility_criteria[0].maximum_family_income == Decimal(
        "250000.00"
    )
    assert persisted.eligibility_criteria[0].education_levels == [
        "post_matric",
        "undergraduate",
    ]


def test_eligibility_percentage_constraints(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    sqlite_session.add(
        EligibilityCriteria(
            scholarship=scholarship,
            minimum_academic_percentage=Decimal("101"),
        )
    )

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_database_tables_are_discoverable() -> None:
    engine = create_engine("sqlite+pysqlite:///:memory:")
    Base.metadata.create_all(engine)
    table_names = set(inspect(engine).get_table_names())

    assert {
        "scholarships",
        "eligibility_criteria",
        "academic_years",
        "scholarship_academic_years",
        "official_sources",
        "scholarship_sources",
    }.issubset(table_names)
    engine.dispose()


def test_duplicate_general_criteria_are_rejected(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    sqlite_session.add_all(
        [
            EligibilityCriteria(scholarship=scholarship),
            EligibilityCriteria(scholarship=scholarship),
        ]
    )

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_duplicate_year_specific_criteria_are_rejected(
    sqlite_session: Session,
) -> None:
    scholarship = make_scholarship()
    year = AcademicYear(year="2026-27")
    sqlite_session.add(
        ScholarshipAcademicYear(
            scholarship=scholarship,
            academic_year=year,
        )
    )
    sqlite_session.commit()
    sqlite_session.add_all(
        [
            EligibilityCriteria(
                scholarship=scholarship,
                academic_year=year,
            ),
            EligibilityCriteria(
                scholarship=scholarship,
                academic_year=year,
            ),
        ]
    )

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_eligibility_criteria_reject_mismatched_academic_year(
    sqlite_session: Session,
) -> None:
    first = make_scholarship("First Test Scholarship")
    second = make_scholarship("Second Test Scholarship")
    year = AcademicYear(year="2026-27")
    sqlite_session.add_all(
        [
            ScholarshipAcademicYear(
                scholarship=first,
                academic_year=year,
            ),
        ]
    )
    sqlite_session.commit()

    sqlite_session.add(
        EligibilityCriteria(
            scholarship=second,
            academic_year=year,
        )
    )

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_invalid_foreign_key_is_rejected(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    sqlite_session.add(scholarship)
    sqlite_session.commit()

    association = ScholarshipAcademicYear(
        scholarship_id=scholarship.id,
        academic_year_id=uuid.uuid4(),
    )
    sqlite_session.add(association)

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


def test_academic_year_deletion_is_restricted(sqlite_session: Session) -> None:
    scholarship = make_scholarship()
    year = AcademicYear(year="2026-27")
    sqlite_session.add(
        ScholarshipAcademicYear(
            scholarship=scholarship,
            academic_year=year,
        )
    )
    sqlite_session.commit()

    sqlite_session.delete(year)

    with pytest.raises(IntegrityError):
        sqlite_session.commit()


@pytest.mark.parametrize(
    ("model", "field", "invalid_value"),
    [
        (Scholarship, "category", "invented_category"),
        (OfficialSource, "source_type", "invented_source_type"),
        (
            ScholarshipSource,
            "verification_status",
            "invented_verification_status",
        ),
    ],
)
def test_domain_check_constraints(
    sqlite_session: Session,
    model,
    field: str,
    invalid_value: str,
) -> None:
    if model is Scholarship:
        record = Scholarship(
            name="Test Scholarship",
            slug="test-domain-scholarship",
            administering_authority="Test Authority",
            category=invalid_value,
        )
    elif model is OfficialSource:
        record = OfficialSource(
            source_url="https://example.gov.in/domain-test",
            authority="Test Authority",
            source_type=invalid_value,
        )
    else:
        scholarship = make_scholarship("Domain Test Scholarship")
        source = OfficialSource(
            source_url="https://example.gov.in/domain-test-link",
            authority="Test Authority",
            source_type="government_portal",
        )
        record = ScholarshipSource(
            scholarship=scholarship,
            source=source,
            verification_status=invalid_value,
        )

    sqlite_session.add(record)
    with pytest.raises(IntegrityError):
        sqlite_session.commit()
