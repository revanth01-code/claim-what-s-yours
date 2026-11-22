"""Command-line entry point for scholarship data imports."""

import argparse
import json
import sys

import app.db  # noqa: F401 - Register all models and prevent circular import
from app.db.session import get_session_factory
from app.ingestion.service import (
    ImportTransactionError,
    ScholarshipImporter,
    load_dataset,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Import validated scholarship JSON data.")
    parser.add_argument("dataset", help="Path to a validated scholarship JSON dataset")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate and report changes, then roll back all database writes",
    )
    args = parser.parse_args()

    try:
        dataset = load_dataset(args.dataset)
        with get_session_factory()() as session:
            summary = ScholarshipImporter(session).import_dataset(
                dataset, dry_run=args.dry_run
            )
        print(json.dumps(summary.as_dict(), indent=2, default=str))
        return 0
    except (ValueError, ImportTransactionError, OSError, json.JSONDecodeError) as exc:
        print(f"Import failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
