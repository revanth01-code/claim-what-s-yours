# Copilot Instructions

## Project

Claim What's Yours is a modular-monolith scholarship discovery and guidance platform built with Flutter, Python/FastAPI, and PostgreSQL.

## Source of Truth

Consult these files before changing code or documentation:

1. `spec.md`
2. `AGENTS.md`
3. `IMPLEMENTATION_PLAN.md`
4. `README.md`
5. `CONTRIBUTING.md`

Use the detailed phase tasks in `IMPLEMENTATION_PLAN.md` as the canonical implementation roadmap. Keep `spec.md` authoritative for product requirements.

## Implementation Rules

- Do not implement work outside the active approved phase.
- Do not make provider selections for cloud, LLM, embedding, authentication, storage, notifications or data sources.
- Do not invent scholarship records, eligibility rules, government APIs or datasets.
- Keep Flutter frontend code separate from FastAPI business logic.
- Keep final eligibility decisions in the deterministic rules engine. An LLM must never determine eligibility.
- Publish only verified, official-source-backed scholarship information.
- Preserve source references and verification state.
- Keep provider integrations behind replaceable abstractions.
- Never commit secrets or environment-specific credentials.
- Add focused tests and update relevant documentation.

## Documentation

- Keep technical details in `docs/` rather than duplicating them in `spec.md`.
- Update `IMPLEMENTATION_PLAN.md` for verified progress.
- Update `CHANGELOG.md` for meaningful completed changes.
- Do not mark unimplemented or untested work as complete.

