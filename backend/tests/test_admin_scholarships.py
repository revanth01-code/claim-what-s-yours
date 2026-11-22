"""Tests for scholarship verification, review, and publication admin workflows."""

import uuid
from datetime import date
from typing import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine, event
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.exceptions import register_exception_handlers
from app.db.base import Base
import app.db  # noqa: F401
from app.db.session import get_db_session
from app.main import create_app
from app.modules.auth.verifier import VerifiedIdentity, get_id_token_verifier
from app.modules.eligibility.models import EligibilityCriteria
from app.modules.scholarships.models import (
    AcademicYear,
    OfficialSource,
    Scholarship,
    ScholarshipAcademicYear,
    ScholarshipSource,
    VerificationStatus,
)
from app.modules.users.models import User

ADMIN_TOKEN = "admin-token"
STUDENT_TOKEN = "student-token"


class FakeVerifier:
    def __init__(self) -> None:
        self.identities = {
            ADMIN_TOKEN: VerifiedIdentity(
                uid="admin-fb-uid",
                email="admin@cwy.org",
                email_verified=True,
                name="Admin User",
            ),
            STUDENT_TOKEN: VerifiedIdentity(
                uid="student-fb-uid",
                email="student@cwy.org",
                email_verified=True,
                name="Student User",
            ),
        }

    def verify(self, id_token: str) -> VerifiedIdentity:
        if id_token in self.identities:
            return self.identities[id_token]
        from app.core.exceptions import AuthenticationError
        raise AuthenticationError("Invalid token")


@pytest.fixture
def db_session() -> Generator[Session, None, None]:
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
    session_factory = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    with session_factory() as session:
        # Pre-populate admin user and student user
        admin_user = User(
            id=uuid.uuid4(),
            firebase_uid="admin-fb-uid",
            email="admin@cwy.org",
            email_verified=True,
            display_name="Admin User",
            role="admin",
            is_active=True,
        )
        student_user = User(
            id=uuid.uuid4(),
            firebase_uid="student-fb-uid",
            email="student@cwy.org",
            email_verified=True,
            display_name="Student User",
            role="student",
            is_active=True,
        )
        session.add_all([admin_user, student_user])
        session.commit()
        yield session
    engine.dispose()


@pytest.fixture
def client(db_session: Session) -> Generator[TestClient, None, None]:
    app = create_app()
    verifier = FakeVerifier()

    app.dependency_overrides[get_db_session] = lambda: db_session
    app.dependency_overrides[get_id_token_verifier] = lambda: verifier

    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


@pytest.fixture
def sample_scholarship(db_session: Session) -> Scholarship:
    scholarship = Scholarship(
        name="Pre-Matric Scholarship",
        slug="pre-matric-scholarship",
        administering_authority="Ministry of Minority Affairs",
        category="minority",
        is_active=False,
    )
    db_session.add(scholarship)
    db_session.flush()

    source = OfficialSource(
        source_url="https://scholarships.gov.in/pre-matric",
        authority="Ministry of Minority Affairs",
        source_type="government_portal",
        title="Pre-Matric Scheme",
    )
    db_session.add(source)
    db_session.flush()

    assoc = ScholarshipSource(
        scholarship_id=scholarship.id,
        source_id=source.id,
        verification_status=VerificationStatus.PENDING_VERIFICATION.value,
    )
    db_session.add(assoc)

    ay = AcademicYear(year="2026-27")
    db_session.add(ay)
    db_session.flush()

    say = ScholarshipAcademicYear(
        scholarship_id=scholarship.id,
        academic_year_id=ay.id,
        is_available=True,
    )
    db_session.add(say)
    db_session.commit()
    return scholarship


def test_unauthenticated_cannot_access_admin_endpoints(client: TestClient) -> None:
    resp = client.get("/api/v1/admin/scholarships/pending")
    assert resp.status_code == 401
    assert resp.json()["error"]["code"] == "authentication_failed"


def test_student_cannot_access_admin_endpoints(client: TestClient) -> None:
    resp = client.get(
        "/api/v1/admin/scholarships/pending",
        headers={"Authorization": f"Bearer {STUDENT_TOKEN}"},
    )
    assert resp.status_code == 403
    assert resp.json()["error"]["code"] == "forbidden"
    assert "Administrator access required" in resp.json()["error"]["message"]


def test_admin_can_view_pending_scholarships(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    resp = client.get(
        "/api/v1/admin/scholarships/pending",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) == 1
    assert data[0]["id"] == str(sample_scholarship.id)
    assert data[0]["is_active"] is False


def test_invalid_verification_status_is_rejected(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "invalid_status", "notes": "bad"},
    )
    assert resp.status_code == 400
    assert "Invalid verification status" in resp.json()["error"]["message"]


def test_overlong_source_review_metadata_is_rejected_with_422(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified", "title": "x" * 256},
    )
    assert resp.status_code == 422


def test_admin_can_verify_source_and_update_metadata(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={
            "status": "verified",
            "notes": "Verified from official gazette notification.",
            "title": "Official 2026 Guidelines",
            "document_reference": "DOC-10294",
        },
    )
    assert resp.status_code == 200
    body = resp.json()
    assert body["verification_status"] == "verified"
    assert body["title"] == "Official 2026 Guidelines"
    assert body["document_reference"] == "DOC-10294"
    assert body["verified_by"] == "admin@cwy.org"


def test_publication_blocked_when_evidence_missing(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    # 1. Unverified source + no criteria -> fails
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"notes": "publishing attempt"},
    )
    assert resp.status_code == 400
    assert "at least one official source must be verified" in resp.json()["error"]["message"]


def test_publication_blocked_when_criteria_unverified(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # Verify source first
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified"},
    )

    # Attempt to publish without criteria
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert resp.status_code == 400
    assert "without reviewed eligibility criteria" in resp.json()["error"]["message"]

    # Add criteria (cannot specify is_verified on creation)
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={
            "minimum_academic_percentage": 50.0,
            "maximum_family_income": 250000.0,
        },
    )
    assert crit_resp.status_code == 200
    assert crit_resp.json()["is_verified"] is False

    # Attempt publish again - fails because criteria is not verified
    resp2 = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert resp2.status_code == 400
    assert "all eligibility criteria must be reviewed and verified" in resp2.json()["error"]["message"]


def test_rejected_records_cannot_be_published(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # Mark source as rejected
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "rejected", "notes": "Fake source"},
    )
    # Add criteria and approve it
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={
            "minimum_academic_percentage": 60.0,
        },
    )
    assert crit_resp.status_code == 200
    crit_id = crit_resp.json()["id"]
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True},
    )

    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert resp.status_code == 400
    assert "at least one official source must be verified" in resp.json()["error"]["message"]


def test_approved_records_can_be_published_explicitly(
    client: TestClient, sample_scholarship: Scholarship, db_session: Session
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # 1. Verify source
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified"},
    )
    # 2. Add criteria and review/verify it
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={
            "minimum_academic_percentage": 50.0,
            "maximum_family_income": 250000.0,
            "notes": "Criteria matches official 2026 gazette",
        },
    )
    assert crit_resp.status_code == 200
    crit_id = crit_resp.json()["id"]

    rev_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True},
    )
    assert rev_resp.status_code == 200
    assert rev_resp.json()["is_verified"] is True

    # 3. Publish
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"notes": "All requirements met and verified."},
    )
    assert resp.status_code == 200
    assert resp.json()["is_active"] is True

    # Confirm it now appears in public catalog
    pub_resp = client.get("/api/v1/scholarships?page=1&page_size=10")
    assert pub_resp.status_code == 200
    assert pub_resp.json()["meta"]["total"] == 1


def test_audit_history_is_preserved(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # Step 1: Verify source
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified", "notes": "Source confirmed"},
    )
    # Step 2: Add criteria
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 50.0, "notes": "Draft criteria"},
    )
    criteria_id = crit_resp.json()["id"]

    # Step 3: Approve criteria
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{criteria_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True, "notes": "Criteria confirmed"},
    )

    # Step 4: Publish
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"notes": "Ready for students"},
    )

    # Step 5: Unpublish
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/unpublish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"notes": "Temporary withdrawal for review"},
    )

    # Check audit logs
    audit_resp = client.get(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/audit-logs",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert audit_resp.status_code == 200
    logs = audit_resp.json()
    assert len(logs) == 5
    actions = [log["action"] for log in logs]
    assert actions == [
        "source_verify",
        "criteria_create",
        "criteria_approve",
        "scholarship_publish",
        "scholarship_unpublish",
    ]
    assert logs[0]["notes"] == "Source confirmed"
    assert logs[-1]["notes"] == "Temporary withdrawal for review"


def test_criteria_create_with_is_verified_rejected_by_extra_forbid(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 50.0, "is_verified": True},
    )
    assert resp.status_code == 422


def test_criteria_update_resets_is_verified_to_false(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    # 1. Create criteria
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 50.0},
    )
    crit_id = crit_resp.json()["id"]

    # 2. Approve criteria
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True},
    )

    # 3. Update criteria
    upd_resp = client.put(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 55.0},
    )
    assert upd_resp.status_code == 200
    # Verification must be revoked
    assert upd_resp.json()["is_verified"] is False


def test_rejected_source_cannot_be_reverified(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # Reject source
    resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "rejected", "notes": "Invalid portal"},
    )
    assert resp.status_code == 200

    # Attempt to re-verify
    re_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified"},
    )
    assert re_resp.status_code == 400
    assert "A rejected source cannot be re-verified" in re_resp.json()["error"]["message"]


def test_rejecting_only_verified_source_auto_unpublishes_scholarship(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    # 1. Verify source
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified"},
    )
    # 2. Create and approve criteria
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 50.0},
    )
    crit_id = crit_resp.json()["id"]
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True},
    )
    # 3. Publish
    pub_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert pub_resp.status_code == 200
    assert pub_resp.json()["is_active"] is True

    # 4. Reject the verified source
    rej_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "rejected", "notes": "Revoked official status"},
    )
    assert rej_resp.status_code == 200

    # 5. Verify the scholarship is now inactive
    pending_resp = client.get(
        "/api/v1/admin/scholarships/pending",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert pending_resp.status_code == 200
    matching = [s for s in pending_resp.json()["data"] if s["id"] == str(sample_scholarship.id)]
    assert len(matching) == 1
    assert matching[0]["is_active"] is False


def test_publish_and_unpublish_idempotency(
    client: TestClient, sample_scholarship: Scholarship
) -> None:
    source_assoc = sample_scholarship.source_associations[0]
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/sources/{source_assoc.source_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"status": "verified"},
    )
    crit_resp = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"minimum_academic_percentage": 50.0},
    )
    crit_id = crit_resp.json()["id"]
    client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/criteria/{crit_id}/review",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
        json={"is_verified": True},
    )

    # First publish
    res1 = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert res1.status_code == 200
    assert res1.json()["is_active"] is True

    # Second publish (idempotent)
    res2 = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/publish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert res2.status_code == 200
    assert res2.json()["is_active"] is True

    # First unpublish
    unres1 = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/unpublish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert unres1.status_code == 200
    assert unres1.json()["is_active"] is False

    # Second unpublish (idempotent)
    unres2 = client.post(
        f"/api/v1/admin/scholarships/{sample_scholarship.id}/unpublish",
        headers={"Authorization": f"Bearer {ADMIN_TOKEN}"},
    )
    assert unres2.status_code == 200
    assert unres2.json()["is_active"] is False

