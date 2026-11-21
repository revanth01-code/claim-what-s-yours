# Changelog

All meaningful changes to Claim What's Yours are recorded here.

The format is maintained in reverse chronological order.

## [Unreleased]

### Added

- Added repository foundation documentation structure.
- Added `.gitignore` coverage for Flutter, Python, FastAPI, PostgreSQL, VS Code and environment files.
- Added `.github/copilot-instructions.md`.
- Added initial technical documentation derived from the approved specification.
- Added the architecture decision record directory and ADR template.
- Added `docs/decisions/adr-template.md` as the starting point for architecture decision records.

### Changed

- Reconciled the implementation roadmap with the master specification.
- Updated repository status documentation to reflect the documentation-only baseline.
- Aligned the roadmap summary in `spec.md` with the canonical phase numbers and names in `IMPLEMENTATION_PLAN.md`.
- Deferred creation of `.env.example` until Phase 3 environment setup, when the configuration contract is established; updated `AGENTS.md`, `README.md`, `spec.md` and `docs/security.md` to match.
- Set Phase 0 to Completed after the independent documentation and Git-root verification.
- Marked the Phase 3 Git initialization and `.gitignore` tasks complete in the implementation plan.

### Fixed

- Removed a duplicate `build/` entry from `.gitignore` and added `*.iml` (IntelliJ module files).

