"""Basic logging configuration. Never log secrets or connection strings."""

import logging


def configure_logging() -> None:
    """Configure root logging at INFO level with a plain format."""
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
