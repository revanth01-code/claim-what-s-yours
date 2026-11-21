"""Declarative base for SQLAlchemy models. No models are defined here yet."""

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base class for all ORM models."""
