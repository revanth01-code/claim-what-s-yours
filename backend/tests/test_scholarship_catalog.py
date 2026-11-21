"""Tests for the read-only scholarship catalog API."""

from collections.abc import Iterator
from datetime import date, datetime, timezone
from decimal import Decimal
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event, select
from sqlalchemy.pool import StaticPool
from sqlalchemy.exc import OperationalError
from sqlalchemy.orm import Session

from app.db.base import Base
import app.db
from app.db.session import get_db_session
from app.main import create_app
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
)


@pytest.fixture
def catalog_client() -> Iterator[tuple[TestClient, object]]:
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
    application = create_app()

    def override_db_session():
        with Session(engine) as session:
            yield session

    application.dependency_overrides[get_db_session] = override_db_session
    client = TestClient(application)
    yield client, engine
    client.close()
    engine.dispose()


def add_scholarship(
    engine,
    *,
    name: str = "Telangana Test Scholarship",
    slug: str = "telangana-test-scholarship",
    category: str = "sc",
    is_active: bool = True,
    description: str = "Official test description",
    education_level: str | None = "undergraduate",
    year: str | None = "2026-27",
    source_status: str = "approved",
) -> UUID:
    with Session(engine) as session:
        scholarship = Scholarship(
            name=name,
            slug=slug,
            description=description,
            administering_authority="Test Government Authority",
            category=category,
            benefits={"amount": "test-value"},
            application_url="https://example.gov.in/apply",
            is_active=is_active,
        )
        session.add(scholarship)

        if year:
            academic_year = session.scalar(
                select(AcademicYear).where(AcademicYear.year == year)
            )
            if academic_year is None:
                academic_year = AcademicYear(
                    year=year,
                    starts_on=date(2026, 4, 1),
                    ends_on=date(2027, 3, 31),
                )
                session.add(academic_year)
            session.flush()
            association = ScholarshipAcademicYear(
                scholarship=scholarship,
                academic_year=academic_year,
                is_available=True,
                opening_date=date(2026, 6, 1),
                closing_date=date(2026, 11, 30),
            )
            session.add(association)

        if education_level:
            session.flush()
            criteria = EligibilityCriteria(
                scholarship=scholarship,
                academic_year=None,
                maximum_family_income=Decimal("250000"),
                education_levels=[education_level],
                categories=[category],
                is_verified=True,
            )
            session.add(criteria)

        source = OfficialSource(
            source_url=f"https://example.gov.in/{slug}",
            authority="Test Government Authority",
            source_type="government_portal",
            title=f"{name} official source",
        )
        session.add(source)
        session.flush()
        session.add(
            ScholarshipSource(
                scholarship=scholarship,
                source=source,
                verification_status=source_status,
                last_verified_at=datetime(2026, 11, 21, tzinfo=timezone.utc),
                verified_by="Test Verification Unit",
            )
        )
        session.commit()
        return scholarship.id


def test_list_scholarships(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(engine)

    response = client.get("/api/v1/scholarships")

    assert response.status_code == 200
    body = response.json()
    assert body["meta"]["total"] == 1
    assert body["meta"]["page"] == 1
    assert body["meta"]["page_size"] == 20
    assert body["data"][0]["name"] == "Telangana Test Scholarship"


def test_scholarship_detail(catalog_client) -> None:
    client, engine = catalog_client
    scholarship_id = add_scholarship(engine)

    response = client.get(f"/api/v1/scholarships/{scholarship_id}")

    assert response.status_code == 200
    body = response.json()
    assert body["id"] == str(scholarship_id)
    assert body["eligibility_criteria"][0]["education_levels"] == ["undergraduate"]
    assert body["academic_years"][0]["academic_year"] == "2026-27"
    assert body["sources"][0]["verification_status"] == "approved"
    assert body["sources"][0]["last_verified_at"] is not None


def test_unknown_scholarship_returns_404(catalog_client) -> None:
    client, _engine = catalog_client

    response = client.get(
        "/api/v1/scholarships/00000000-0000-0000-0000-000000000000"
    )

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "http_error"


def test_pagination_and_page_size_validation(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(engine)

    assert client.get("/api/v1/scholarships?page=0").status_code == 422
    assert client.get("/api/v1/scholarships?page_size=101").status_code == 422

    response = client.get("/api/v1/scholarships?page=2&page_size=1")
    assert response.status_code == 200
    assert response.json()["meta"]["page"] == 2
    assert response.json()["meta"]["total_pages"] == 1
    assert response.json()["data"] == []


def test_search_by_name_and_description(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(
        engine,
        name="Alpha Merit Scholarship",
        slug="alpha-merit-scholarship",
        description="Special official support",
    )

    assert client.get("/api/v1/scholarships?search=Alpha").json()["meta"]["total"] == 1
    assert client.get("/api/v1/scholarships?search=official").json()["meta"]["total"] == 1
    assert client.get("/api/v1/scholarships?search=missing").json()["meta"]["total"] == 0


def test_academic_year_filter(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(engine, year="2026-27")

    assert client.get(
        "/api/v1/scholarships?academic_year=2026-27"
    ).json()["meta"]["total"] == 1
    assert client.get(
        "/api/v1/scholarships?academic_year=2025-26"
    ).json()["meta"]["total"] == 0


def test_category_filter(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(engine, category="sc")

    assert client.get(
        "/api/v1/scholarships?category=sc"
    ).json()["meta"]["total"] == 1
    assert client.get(
        "/api/v1/scholarships?category=merit"
    ).json()["meta"]["total"] == 0
    assert client.get(
        "/api/v1/scholarships?category=invalid"
    ).status_code == 422


def test_education_level_filter(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(engine, education_level="undergraduate")

    assert client.get(
        "/api/v1/scholarships?education_level=undergraduate"
    ).json()["meta"]["total"] == 1
    assert client.get(
        "/api/v1/scholarships?education_level=post_matric"
    ).json()["meta"]["total"] == 0


def test_inactive_scholarship_is_excluded(catalog_client) -> None:
    client, engine = catalog_client
    inactive_id = add_scholarship(engine, is_active=False)

    listing = client.get("/api/v1/scholarships")
    detail = client.get(f"/api/v1/scholarships/{inactive_id}")

    assert listing.json()["meta"]["total"] == 0
    assert detail.status_code == 404


def test_academic_year_availability_requires_available(catalog_client) -> None:
    client, engine = catalog_client
    with Session(engine) as session:
        scholarship = Scholarship(
            name="Unavailable Scholarship",
            slug="unavailable-scholarship",
            administering_authority="Test Authority",
            category="other",
            is_active=True,
        )
        year = AcademicYear(year="2026-27")
        association = ScholarshipAcademicYear(
            scholarship=scholarship,
            academic_year=year,
            is_available=False,
        )
        session.add(association)
        session.commit()

    response = client.get(
        "/api/v1/scholarships?academic_year=2026-27"
    )

    assert response.status_code == 200
    assert response.json()["meta"]["total"] == 0


def test_empty_results(catalog_client) -> None:
    client, _engine = catalog_client

    response = client.get("/api/v1/scholarships")

    assert response.status_code == 200
    assert response.json()["data"] == []
    assert response.json()["meta"]["total"] == 0
    assert response.json()["meta"]["total_pages"] == 0


def test_sorting(catalog_client) -> None:
    client, engine = catalog_client
    add_scholarship(
        engine,
        name="Zulu Scholarship",
        slug="zulu-scholarship",
    )
    add_scholarship(
        engine,
        name="Alpha Scholarship",
        slug="alpha-scholarship",
    )

    ascending = client.get(
        "/api/v1/scholarships?sort_by=name&sort_order=asc"
    ).json()["data"]
    descending = client.get(
        "/api/v1/scholarships?sort_by=name&sort_order=desc"
    ).json()["data"]

    assert ascending[0]["name"] == "Alpha Scholarship"
    assert descending[0]["name"] == "Zulu Scholarship"


def test_database_not_configured_dependency_returns_503(
    monkeypatch,
) -> None:
    from app.core.exceptions import register_exception_handlers
    from app.db.session import get_db_session

    monkeypatch.delenv("CWY_DATABASE_URL", raising=False)
    application = create_app()

    response = TestClient(application).get("/api/v1/scholarships")

    assert response.status_code == 503


def test_database_execution_failure_returns_503(
    monkeypatch,
) -> None:
    monkeypatch.setenv(
        "CWY_DATABASE_URL",
        "postgresql+psycopg://user:secret@database.example/test",
    )

    class UnavailableSession:
        def scalar(self, statement):
            del statement
            raise OperationalError(
                "SELECT 1",
                {},
                Exception("test database unavailable"),
            )

    application = create_app()

    def unavailable_session():
        yield UnavailableSession()

    application.dependency_overrides[get_db_session] = unavailable_session
    response = TestClient(application).get("/api/v1/scholarships")

    assert response.status_code == 503
    assert response.json()["error"]["code"] == "database_unavailable"
