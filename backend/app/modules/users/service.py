"""Just-in-time provisioning of application users from verified Firebase identities.

Transaction boundaries: the service never commits or rolls back the caller's session.
A new user is inserted inside a SAVEPOINT (session.begin_nested) and flushed there, so a
unique-constraint loss to a concurrent request can be rolled back to the savepoint
without aborting the outer transaction. Verified claims are refreshed only for active
users, including the race winner. The request-scoped dependency (get_current_user) owns
the commit and rollback; if the request fails before that commit, nothing is persisted.
"""

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.modules.auth.verifier import VerifiedIdentity
from app.modules.users.models import User


def _select_by_firebase_uid(session: Session, firebase_uid: str) -> User | None:
    """Return the user row for firebase_uid, or None when no row exists."""
    return session.scalar(select(User).where(User.firebase_uid == firebase_uid))


def _sync_verified_claims(user: User, identity: VerifiedIdentity) -> User:
    """Copy email, email_verified and display_name from the verified identity when they changed.

    Role and is_active are never touched here: they are owned by the database.
    """
    if user.email != identity.email:
        user.email = identity.email
    if user.email_verified != identity.email_verified:
        user.email_verified = identity.email_verified
    if user.display_name != identity.name:
        user.display_name = identity.name
    return user


def _refresh_active_user(user: User, identity: VerifiedIdentity) -> User:
    """Refresh verified claims for an active user; leave disabled users untouched."""
    if user.is_active is True:
        _sync_verified_claims(user, identity)
    return user


def get_or_create_user_by_identity(session: Session, identity: VerifiedIdentity) -> User:
    """Return the application user for a verified identity, creating it on first sight.

    Existing active users have their verified claims refreshed. Disabled users are
    returned unchanged, even when is_active is False; enforcing account status is the
    caller's job.

    New users are created with the database defaults (role "student", is_active True).
    Role and is_active are never read from the identity.

    Race handling: if a concurrent request inserts the same firebase_uid between our
    SELECT and our INSERT, the unique constraint raises IntegrityError inside the
    SAVEPOINT. The savepoint is rolled back and the row the other request committed is
    returned, with its verified claims refreshed when it is active.

    Transactions: this function flushes but does not commit; see the module docstring.

    Raises:
        sqlalchemy.exc.IntegrityError: Only if the insert failed and no row exists for
            the uid after the rollback, which indicates a non-uniqueness constraint failure.
    """
    existing = _select_by_firebase_uid(session, identity.uid)
    if existing is not None:
        return _refresh_active_user(existing, identity)

    new_user = User(
        firebase_uid=identity.uid,
        email=identity.email,
        email_verified=identity.email_verified,
        display_name=identity.name,
    )
    try:
        with session.begin_nested():
            session.add(new_user)
            session.flush()
    except IntegrityError:
        winner = _select_by_firebase_uid(session, identity.uid)
        if winner is None:
            raise
        return _refresh_active_user(winner, identity)
    return new_user
