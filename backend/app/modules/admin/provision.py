"""CLI tool to explicitly inspect, dry-run, or provision/promote a user to administrator."""

import argparse
import sys

import app.db  # noqa: F401
from app.db.session import get_session_factory
from app.modules.admin.models import AuditAction, VerificationAuditLog
from app.modules.users.models import User
from sqlalchemy import func, select


def grant_admin(
    email: str | None = None,
    firebase_uid: str | None = None,
    inspect: bool = False,
    dry_run: bool = False,
    confirm: bool = False,
) -> int:
    if not inspect and not dry_run and not confirm:
        print("Error: Must specify one of --inspect, --dry-run, or --confirm.", file=sys.stderr)
        return 1

    if not email and not firebase_uid:
        print("Error: Either --email or --firebase-uid must be provided.", file=sys.stderr)
        return 1

    normalized_email = email.strip().lower() if email else None
    normalized_uid = firebase_uid.strip() if firebase_uid else None

    SessionLocal = get_session_factory()
    with SessionLocal() as session:
        query = select(User)
        if normalized_email:
            query = query.where(func.lower(User.email) == normalized_email)
        else:
            query = query.where(User.firebase_uid == normalized_uid)

        users = session.scalars(query).all()
        if len(users) == 0:
            target = f"email '{normalized_email}'" if normalized_email else f"UID '{normalized_uid}'"
            print(f"Error: User with {target} not found in database. User must sign in once first.", file=sys.stderr)
            return 1
        if len(users) > 1:
            ids = ", ".join(str(u.id) for u in users)
            print(
                f"Error: {len(users)} users match; refusing to change any role. Matching user ids: {ids}.",
                file=sys.stderr,
            )
            return 1

        user = users[0]

        # Account status validations
        if not user.is_active:
            print(f"Error: Cannot promote disabled user {user.id}.", file=sys.stderr)
            return 1

        if not user.email_verified:
            print(
                f"Error: Cannot promote user {user.id} with unverified email '{user.email}'.",
                file=sys.stderr,
            )
            return 1

        if inspect:
            print(
                f"User Details:\n"
                f"  ID: {user.id}\n"
                f"  Firebase UID: {user.firebase_uid}\n"
                f"  Email: {user.email}\n"
                f"  Email Verified: {user.email_verified}\n"
                f"  Role: {user.role}\n"
                f"  Is Active: {user.is_active}\n"
                f"  Display Name: {user.display_name or 'N/A'}"
            )
            return 0

        if user.role == "admin":
            print(f"User {user.id} ({user.email or user.firebase_uid}) is already an administrator.")
            return 0

        if dry_run:
            print(
                f"[DRY RUN] Planned administrator promotion:\n"
                f"  User ID: {user.id}\n"
                f"  Firebase UID: {user.firebase_uid}\n"
                f"  Email: {user.email}\n"
                f"  Current Role: {user.role} -> Target Role: admin\n"
                f"  Audit Action: {AuditAction.ADMIN_PROMOTE.value}\n"
                f"No database changes committed."
            )
            return 0

        if confirm:
            previous_role = user.role
            user.role = "admin"
            log = VerificationAuditLog(
                scholarship_id=None,
                admin_user_id=user.id,
                action=AuditAction.ADMIN_PROMOTE.value,
                target_type="user",
                target_id=user.id,
                notes="Provisioned as admin via CLI",
                details={"promoted_by": "cli", "previous_role": previous_role},
            )
            session.add(log)
            session.commit()
            print(f"Success: User {user.id} ({user.email or user.firebase_uid}) role updated to 'admin'. Audit log recorded.")
            return 0

    return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="Grant admin role to an existing user.")
    target_group = parser.add_mutually_exclusive_group(required=True)
    target_group.add_argument("--email", help="User email address")
    target_group.add_argument("--firebase-uid", help="User Firebase UID")

    action_group = parser.add_mutually_exclusive_group(required=True)
    action_group.add_argument("--inspect", action="store_true", help="Inspect user status without modifying")
    action_group.add_argument("--dry-run", action="store_true", help="Simulate promotion without applying changes")
    action_group.add_argument("--confirm", action="store_true", help="Execute promotion and record audit log")

    args = parser.parse_args()
    return grant_admin(
        email=args.email,
        firebase_uid=args.firebase_uid,
        inspect=args.inspect,
        dry_run=args.dry_run,
        confirm=args.confirm,
    )


if __name__ == "__main__":
    raise SystemExit(main())
