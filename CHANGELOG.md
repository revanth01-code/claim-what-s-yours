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

- Added Phase 1 evidence-based technical and official-source research.
- Updated scholarship source, ingestion, AI architecture and decision-register documentation with verified findings and proposed recommendations.
- Moved Phase 1 to In Review because research is drafted for review, but provider and infrastructure decisions still require approval.
- Reconciled the implementation roadmap with the master specification.
- Updated repository status documentation to reflect the documentation-only baseline.
- Aligned the roadmap summary in `spec.md` with the canonical phase numbers and names in `IMPLEMENTATION_PLAN.md`.
- Deferred creation of `.env.example` until Phase 3 environment setup, when the configuration contract is established; updated `AGENTS.md`, `README.md`, `spec.md` and `docs/security.md` to match.
- Returned Phase 0 to In Review pending verification: documentation consistency is not yet verified, and the earlier claim that Git-root verification established Phase 0 completion was unsupported.
- Marked the Phase 3 Git initialization and `.gitignore` tasks complete in the implementation plan.
- Reclassified Phase 1 backend-framework, public-API-verification and technical-decision tasks as incomplete pending evidence and approval.
- Recorded user approval of the Python, FastAPI and PostgreSQL backend stack and the modular monolith MVP architecture; the LLM provider, authentication provider and cloud provider remain unresolved.

### Fixed

- Removed a duplicate `build/` entry from `.gitignore` and added `*.iml` (IntelliJ module files).

