"""Firebase Admin SDK adapter: lazily initialises a named app used for ID-token verification."""

import logging
import threading

import firebase_admin
from firebase_admin import credentials

from app.core.config import get_settings

APP_NAME = "claim-whats-yours-auth"

logger = logging.getLogger(__name__)

_app_lock = threading.Lock()
_cached_app: firebase_admin.App | None = None


class FirebaseConfigurationError(RuntimeError):
    """Raised when the Firebase Admin SDK cannot be initialised."""

    def __init__(self) -> None:
        super().__init__("Firebase authentication is not configured.")


def _build_app() -> firebase_admin.App:
    """Initialise the named Firebase app from the configured credentials."""
    settings = get_settings()
    try:
        return firebase_admin.get_app(APP_NAME)
    except ValueError:
        pass
    try:
        if settings.firebase_credentials_path:
            credential = credentials.Certificate(settings.firebase_credentials_path)
        else:
            credential = credentials.ApplicationDefault()
        options = {"projectId": settings.firebase_project_id} if settings.firebase_project_id else {}
        return firebase_admin.initialize_app(credential, options, name=APP_NAME)
    except Exception as exc:
        # Do not chain or log the original message: it may contain the credentials path.
        logger.warning("Firebase initialisation failed: %s", type(exc).__name__)
        raise FirebaseConfigurationError() from None


def get_firebase_app() -> firebase_admin.App:
    """Return the cached named Firebase app, initialising it once on first use."""
    global _cached_app
    if _cached_app is None:
        with _app_lock:
            if _cached_app is None:
                _cached_app = _build_app()
    return _cached_app


def reset_firebase_app_cache() -> None:
    """Clear the module-level app cache. Intended for tests only."""
    global _cached_app
    with _app_lock:
        _cached_app = None
