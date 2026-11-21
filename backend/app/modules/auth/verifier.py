"""Firebase ID-token verification mapped onto application exceptions."""

import logging
from dataclasses import dataclass
from typing import Any, Protocol

from firebase_admin import auth as firebase_auth

from app.core.exceptions import (
    AccountDisabledError,
    AuthenticationError,
    AuthServiceUnavailableError,
)
from app.modules.auth.firebase import FirebaseConfigurationError, get_firebase_app

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class VerifiedIdentity:
    """Identity claims taken from a verified Firebase ID token."""

    uid: str
    email: str | None
    email_verified: bool
    name: str | None


class IdTokenVerifier(Protocol):
    """Verifies an ID token and returns the identity it carries."""

    def verify(self, id_token: str) -> VerifiedIdentity:
        """Return the verified identity or raise an application exception."""
        ...


def _extract_uid(decoded: dict[str, Any]) -> str:
    """Return the non-empty uid from decoded claims, falling back to sub."""
    uid = decoded.get("uid") if "uid" in decoded else decoded.get("sub")
    if not isinstance(uid, str) or not uid:
        raise AuthenticationError("Invalid authentication token")
    return uid


class FirebaseIdTokenVerifier:
    """Verifies Firebase ID tokens with the Firebase Admin SDK.

    Token revocation is checked on every request (check_revoked=True). Logout, account
    disabling and password changes must take effect immediately for protected endpoints;
    the cost is one extra Firebase lookup per request, accepted for this MVP. Email
    verification status is read only from the verified token's email_verified claim,
    never inferred from the address.
    """

    def verify(self, id_token: str) -> VerifiedIdentity:
        """Verify the token and map the SDK outcome onto application exceptions."""
        try:
            app = get_firebase_app()
            decoded = firebase_auth.verify_id_token(id_token, app=app, check_revoked=True)
            uid = _extract_uid(decoded)
            return VerifiedIdentity(
                uid=uid,
                email=decoded.get("email"),
                email_verified=decoded.get("email_verified") is True,
                name=decoded.get("name"),
            )
        except AuthenticationError:
            raise
        except firebase_auth.RevokedIdTokenError:
            raise AuthenticationError("Authentication token has been revoked") from None
        except firebase_auth.ExpiredIdTokenError:
            raise AuthenticationError("Authentication token has expired") from None
        except firebase_auth.InvalidIdTokenError:
            raise AuthenticationError("Invalid authentication token") from None
        except firebase_auth.UserDisabledError:
            raise AccountDisabledError() from None
        except FirebaseConfigurationError:
            raise AuthServiceUnavailableError() from None
        except Exception as exc:
            logger.error("ID token verification unavailable: %s", type(exc).__name__)
            raise AuthServiceUnavailableError() from None


def get_id_token_verifier() -> IdTokenVerifier:
    """Return the verifier used by FastAPI dependencies; overridable in tests."""
    return FirebaseIdTokenVerifier()
