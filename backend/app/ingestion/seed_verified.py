"""Seed script to idempotently import and activate verified official scholarships.

Sources:
- Telangana ePASS (Government of Telangana)
- National Scholarship Portal (NSP, Government of India)
- Ministry of Education (PM-USP CSSS)
- Ministry of Social Justice and Empowerment (PM YASASVI)
- Department of Empowerment of Persons with Disabilities (DEPwD)
"""

import json
from pathlib import Path
import sys
import uuid

import app.db  # noqa: F401
from app.db.session import get_session_factory
from app.ingestion.service import ScholarshipImporter, load_dataset
from app.modules.admin.models import AuditAction, VerificationAuditLog
from app.modules.scholarships.models import (
    Scholarship,
    ScholarshipSource,
    VerificationStatus,
)
from app.modules.users.models import User


def seed_verified_scholarships(dataset_path: Path | None = None) -> int:
    """Idempotently import and activate verified government scholarships."""
    if dataset_path is None:
        dataset_path = Path(__file__).resolve().parents[2] / "data" / "scholarships.verified.json"

    if not dataset_path.exists():
        print(f"Error: Verified dataset not found at {dataset_path}", file=sys.stderr)
        return 1

    print(f"Loading verified scholarship dataset from {dataset_path}...")
    dataset = load_dataset(str(dataset_path))

    SessionLocal = get_session_factory()
    with SessionLocal() as session:
        # 1. Run standard transactional importer
        importer = ScholarshipImporter(session)
        summary = importer.import_dataset(dataset)
        print("Initial import summary:", json.dumps(summary.as_dict(), indent=2))

        # 2. Ensure an administrative user exists for verified audit trail
        admin = session.query(User).filter(User.role == "admin").first()
        if not admin:
            admin = User(
                id=uuid.uuid4(),
                firebase_uid="cwy-system-provisioned-admin",
                email="system.admin@claimwhatsyours.gov.in",
                display_name="CWY System Administrator",
                role="admin",
            )
            session.add(admin)
            session.flush()

        # 3. Publish and activate all verified schemes with active criteria
        activated_count = 0
        for item in dataset.scholarships:
            sch = session.query(Scholarship).filter(Scholarship.slug == item.slug).first()
            if not sch:
                continue

            # Mark sources as verified
            for assoc in sch.source_associations:
                assoc.verification_status = VerificationStatus.VERIFIED.value

            # Mark criteria as verified
            for crit in sch.eligibility_criteria:
                crit.is_verified = True

            # Mark scholarship as active
            if not sch.is_active:
                sch.is_active = True
                activated_count += 1

                # Audit log for system verified publication
                log = VerificationAuditLog(
                    scholarship_id=sch.id,
                    admin_user_id=admin.id,
                    action=AuditAction.SCHOLARSHIP_PUBLISH.value,
                    target_type="scholarship",
                    target_id=sch.id,
                    notes=f"Activated verified scheme from official authority {sch.administering_authority}",
                    details={"source": "seed_verified", "slug": sch.slug},
                )
                session.add(log)

        session.commit()
        print(f"Successfully verified and activated {activated_count} newly published schemes (all {len(dataset.scholarships)} schemes active).")

    return 0


if __name__ == "__main__":
    raise SystemExit(seed_verified_scholarships())
