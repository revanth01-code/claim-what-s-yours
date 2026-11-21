"""Database connectivity check used by the health endpoint."""

import logging

from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.core.exceptions import DatabaseNotConfiguredError
from app.db.session import get_session_factory

logger = logging.getLogger(__name__)


def check_database_connection() -> bool:
    """Return True if the database answers SELECT 1, otherwise False.

    Only the exception class name is logged, never the URL or exception text.
    """
    session: Session | None = None
    try:
        session = get_session_factory()()
        session.execute(text("SELECT 1"))
        return True
    except (DatabaseNotConfiguredError, SQLAlchemyError) as exc:
        logger.warning("Database health check failed: %s", type(exc).__name__)
        return False
    finally:
        if session is not None:
            session.close()
