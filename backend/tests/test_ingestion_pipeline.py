"""Unit and integration tests for dynamic official source registry, discovery pipeline, and ingestion scheduler."""

from datetime import datetime, timezone
from unittest.mock import MagicMock, patch
import pytest
from starlette.testclient import TestClient

from app.core.config import get_settings
from app.db.base import Base
from app.ingestion.pipeline import (
    DynamicIngestionPipeline,
    ExtractedScholarshipOpportunity,
)
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
    VerificationStatus,
)
from app.modules.sources.models import (
    DocumentChunk,
    IngestionRunLog,
    RegisteredSource,
    SourceDocument,
    SourceStatus,
    SourceType,
)
from app.modules.users.models import User


@pytest.fixture
def test_db_session():
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker
    from sqlalchemy.pool import StaticPool
    import app.modules.users.models  # noqa
    import app.modules.scholarships.models  # noqa
    import app.modules.eligibility.models  # noqa
    import app.modules.profiles.models  # noqa
    import app.modules.applications.models  # noqa
    import app.modules.admin.models  # noqa
    import app.modules.sources.models  # noqa

    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    session = session_factory()
    yield session
    session.close()
    engine.dispose()


@pytest.fixture
def admin_user(test_db_session):
    user = User(
        email="test_admin@example.com",
        display_name="Test Admin",
        firebase_uid="fb_test_admin_123",
        role="admin",
        is_active=True,
    )
    test_db_session.add(user)
    test_db_session.commit()
    return user


def test_bootstrap_registered_sources(test_db_session):
    pipeline = DynamicIngestionPipeline(test_db_session)
    count = pipeline.bootstrap_registered_sources()
    assert count >= 3

    sources = test_db_session.query(RegisteredSource).all()
    assert len(sources) >= 3
    source_names = [s.name for s in sources]
    assert any("Telangana ePASS" in name for name in source_names)
    assert any("National Scholarship Portal" in name for name in source_names)


def test_add_dynamic_source_without_code_changes(test_db_session, admin_user):
    from app.api.v1.admin_ingestion import register_new_source, RegisteredSourceCreateRequest

    req = RegisteredSourceCreateRequest(
        name="Telangana Department of Technical Education",
        organization="Government of Telangana",
        base_url="https://dte.telangana.gov.in/",
        resource_urls=["https://dte.telangana.gov.in/notifications"],
        source_type="portal",
        check_interval_hours=24,
    )

    resp = register_new_source(req, admin=admin_user, session=test_db_session)
    assert resp.name == "Telangana Department of Technical Education"
    assert resp.is_enabled is True

    # Verify persistent in database
    db_src = test_db_session.query(RegisteredSource).filter(RegisteredSource.name == req.name).first()
    assert db_src is not None
    assert db_src.organization == "Government of Telangana"


def test_discovery_and_extraction_new_scholarship(test_db_session, admin_user):
    pipeline = DynamicIngestionPipeline(test_db_session)
    pipeline.bootstrap_registered_sources()

    src = test_db_session.query(RegisteredSource).first()
    opp = ExtractedScholarshipOpportunity(
        name="New Telangana Engineering Excellence Scheme",
        slug="new-telangana-engineering-excellence-scheme",
        description="Merit scholarship for top engineering rankers in Telangana.",
        administering_authority="Higher Education Department, Telangana",
        category="merit",
        benefits={"annual_grant": "₹50,000 per year"},
        application_url="https://dte.telangana.gov.in/excellence",
        academic_year="2026-27",
        closing_date="2027-01-31",
        education_levels=["undergraduate"],
        maximum_family_income=300000.0,
        domicile_state="Telangana",
        categories=["general", "bc", "sc", "st"],
        source_url="https://dte.telangana.gov.in/excellence",
        source_title="DTE Excellence Notification",
    )

    result = pipeline._process_and_store_opportunity(opp, src, admin_user)
    assert result == "created"

    # Verify scholarship created in unverified state for admin gate
    sch = test_db_session.query(Scholarship).filter(Scholarship.slug == opp.slug).first()
    assert sch is not None
    assert sch.is_active is False
    assert len(sch.eligibility_criteria) == 1
    assert sch.eligibility_criteria[0].maximum_family_income == 300000.0
    assert sch.eligibility_criteria[0].is_verified is False


def test_repeated_execution_does_not_create_duplicates(test_db_session, admin_user):
    pipeline = DynamicIngestionPipeline(test_db_session)
    pipeline.bootstrap_registered_sources()

    src = test_db_session.query(RegisteredSource).first()
    opp = ExtractedScholarshipOpportunity(
        name="Unique Seed Test Scheme",
        slug="unique-seed-test-scheme",
        administering_authority="Test Authority",
        application_url="https://test.gov.in/apply",
        source_url="https://test.gov.in/apply",
    )

    res1 = pipeline._process_and_store_opportunity(opp, src, admin_user)
    assert res1 == "created"

    # Second run with same opportunity
    res2 = pipeline._process_and_store_opportunity(opp, src, admin_user)
    assert res2 == "skipped"

    # Total count in database must remain 1
    count = test_db_session.query(Scholarship).filter(Scholarship.slug == opp.slug).count()
    assert count == 1


def test_deadline_change_detection_and_audit_logging(test_db_session, admin_user):
    pipeline = DynamicIngestionPipeline(test_db_session)
    pipeline.bootstrap_registered_sources()

    src = test_db_session.query(RegisteredSource).first()
    opp_v1 = ExtractedScholarshipOpportunity(
        name="Dynamic Deadline Scheme",
        slug="dynamic-deadline-scheme",
        administering_authority="Test Authority",
        application_url="https://test.gov.in/apply",
        source_url="https://test.gov.in/apply",
        academic_year="2026-27",
        closing_date="2026-11-30",
    )
    pipeline._process_and_store_opportunity(opp_v1, src, admin_user)

    # Opportunity announced extension
    opp_v2 = ExtractedScholarshipOpportunity(
        name="Dynamic Deadline Scheme",
        slug="dynamic-deadline-scheme",
        administering_authority="Test Authority",
        application_url="https://test.gov.in/apply",
        source_url="https://test.gov.in/apply",
        academic_year="2026-27",
        closing_date="2026-12-31",
    )
    res_update = pipeline._process_and_store_opportunity(opp_v2, src, admin_user)
    assert res_update == "updated"

    # Verify updated deadline in database
    sch = test_db_session.query(Scholarship).filter(Scholarship.slug == "dynamic-deadline-scheme").first()
    assoc = sch.academic_year_associations[0]
    assert str(assoc.closing_date) == "2026-12-31"


def test_inaccessible_source_error_resilience(test_db_session):
    pipeline = DynamicIngestionPipeline(test_db_session)
    pipeline.bootstrap_registered_sources()

    # Add unreachable dummy source
    bad_source = RegisteredSource(
        name="Broken Government Portal",
        organization="Test Org",
        base_url="https://this-domain-does-not-exist-at-all-123456.gov.in/",
        source_type="portal",
        is_enabled=True,
    )
    test_db_session.add(bad_source)
    test_db_session.commit()

    # Pipeline should complete without unhandled exception and report error on bad source
    run_log = pipeline.run_discovery_and_ingestion(trigger_type="test")
    assert run_log is not None
    assert bad_source.health_status == SourceStatus.ERROR.value or bad_source.last_error is not None


def test_admin_ingestion_webhook_endpoint(monkeypatch, test_db_session):
    from fastapi import FastAPI
    from app.api.v1.admin_ingestion import router as ingestion_router
    from app.db.session import get_db_session

    monkeypatch.setenv("CWY_INGESTION_SECRET", "test-secret-token-123")
    get_settings.cache_clear()

    test_app = FastAPI()
    test_app.dependency_overrides[get_db_session] = lambda: test_db_session
    test_app.include_router(ingestion_router, prefix="/api/v1")

    client = TestClient(test_app)

    # Missing header -> 401
    resp_unauth = client.post("/api/v1/admin/ingestion/webhook-trigger")
    assert resp_unauth.status_code == 401

    # Valid secret -> 200
    with patch("app.ingestion.pipeline.fetch_url_safely", return_value=(200, "<html>Telangana ePASS</html>", {})):
        resp_auth = client.post(
            "/api/v1/admin/ingestion/webhook-trigger",
            headers={"X-Ingestion-Secret": "test-secret-token-123"},
        )
        assert resp_auth.status_code == 200
        data = resp_auth.json()
        assert data["trigger_type"] == "github_actions_cron"
        assert data["status"] in ("success", "running")
