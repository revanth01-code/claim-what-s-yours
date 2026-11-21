"""Engine and session factories. Importing this module does not connect to the database."""

from collections.abc import Generator
from functools import lru_cache

from sqlalchemy import create_engine
from sqlalchemy.engine import Engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings
from app.core.exceptions import DatabaseNotConfiguredError


@lru_cache(maxsize=1)
def get_engine() -> Engine:
    """Create (once) and return the SQLAlchemy engine.

    Raises:
        DatabaseNotConfiguredError: If CWY_DATABASE_URL is not configured.
    """
    settings = get_settings()
    if settings.database_url is None:
        raise DatabaseNotConfiguredError()
    database_url = settings.database_url.get_secret_value()
    return create_engine(
        database_url,
        pool_pre_ping=True,
        connect_args={"connect_timeout": settings.database_connect_timeout_seconds},
    )


@lru_cache(maxsize=1)
def get_session_factory() -> sessionmaker[Session]:
    """Return the cached session factory bound to the engine."""
    return sessionmaker(bind=get_engine(), autoflush=False, expire_on_commit=False)


def get_db_session() -> Generator[Session, None, None]:
    """FastAPI dependency that yields a session and always closes it."""
    session = get_session_factory()()
    try:
        yield session
    finally:
        session.close()
