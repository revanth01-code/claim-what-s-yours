"""Reusable FastAPI dependencies for authenticated routes.

These are dependencies, not middleware: only routes that declare them require a token.
"""

from fastapi import Depends, Request, Security
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.exc import DBAPIError, InterfaceError, OperationalError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.exceptions import (
    AccountDisabledError,
    AuthenticationError,
    AuthorizationError,
    DatabaseUnavailableError,
)
from app.db.session import get_db_session
from app.modules.auth.verifier import (
    IdTokenVerifier,
    VerifiedIdentity,
    get_id_token_verifier,
)
from app.modules.users.models import User
from app.modules.users.service import get_or_create_user_by_identity

# auto_error=False so a missing or non-Bearer header reaches get_bearer_token, which
# maps it to this module's 401 payload instead of FastAPI's default 403.
_bearer_scheme = HTTPBearer(auto_error=False)


def get_bearer_token(
    request: Request,
    credentials: HTTPAuthorizationCredentials | None = Security(_bearer_scheme),
) -> str:
    """Extract the bearer token from the Authorization header.

    Raises AuthenticationError when the header is missing, is not a "Bearer <token>"
    credential, or the token is empty or contains whitespace. RFC 6750 allows one or
    more spaces after the scheme, so surplus spacing before the token is tolerated.
    """
    if credentials is None:
        if "authorization" not in request.headers:
            raise AuthenticationError("Authentication token is required")
        raise AuthenticationError("Invalid authentication token")
    token = credentials.credentials.strip()
    if not token or any(char.isspace() for char in token):
        raise AuthenticationError("Invalid authentication token")
    return token


def get_verified_identity(
    token: str = Depends(get_bearer_token),
    verifier: IdTokenVerifier = Depends(get_id_token_verifier),
) -> VerifiedIdentity:
    """Verify the bearer token and return the identity it carries.

    This is a plain sync dependency on purpose: FastAPI runs it in a threadpool,
    so the blocking Firebase verification call does not stall the event loop.
    The application user is resolved from this identity by get_current_user; the
    verified uid remains the source of truth for identity.
    """
    return verifier.verify(token)


def _is_database_outage(exc: SQLAlchemyError) -> bool:
    """Return True only when the error means the database connection itself failed.

    Constraint, data and programming errors are not outages and must not be reported
    as 503.
    """
    if isinstance(exc, (OperationalError, InterfaceError)):
        return True
    return isinstance(exc, DBAPIError) and bool(exc.connection_invalidated)


def _safe_rollback(session: Session) -> None:
    """Roll back the session, ignoring failures so the original error is what propagates."""
    try:
        session.rollback()
    except SQLAlchemyError:
        pass


def get_current_user(
    identity: VerifiedIdentity = Depends(get_verified_identity),
    session: Session = Depends(get_db_session),
) -> User:
    """Return the application user for the verified identity, provisioning it on first use.

    Plain sync dependency: FastAPI runs it in a threadpool because it does blocking DB I/O.
    The session is committed only after the account is confirmed active. Inactive accounts
    are rolled back and rejected with AccountDisabledError (403), so nothing is persisted
    for a rejected request. Genuine database outages become DatabaseUnavailableError (503);
    other database errors propagate (500).
    """
    try:
        user = get_or_create_user_by_identity(session, identity)
        if not user.is_active:
            _safe_rollback(session)  # a rejected request persists nothing
            raise AccountDisabledError()
        session.commit()
    except AccountDisabledError:
        raise
    except SQLAlchemyError as exc:
        _safe_rollback(session)
        if _is_database_outage(exc):
            raise DatabaseUnavailableError() from exc
        raise
    return user


def require_admin(
    current_user: User = Depends(get_current_user),
) -> User:
    """Enforce that the authenticated user possesses the admin role.

    Students and other non-admin users are rejected with AuthorizationError (403).
    """
    if current_user.role != "admin":
        raise AuthorizationError("Administrator access required.")
    return current_user
