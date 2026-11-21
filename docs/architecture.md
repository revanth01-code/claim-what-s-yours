# System Architecture

## Architectural Approach

The initial backend is a modular monolith. This keeps application modules independently understandable without introducing microservices before they are required.

## High-Level Components

- Flutter Android application.
- Flutter Web application.
- FastAPI REST API.
- PostgreSQL database.
- Deterministic eligibility engine.
- Provider-independent AI integration.
- RAG retrieval for verified scholarship guidance.
- Background ingestion worker.
- Admin verification workflow.
- Optional cache or object storage only where the implementation requires it.

## Backend Module Boundaries

The backend should expose modules for:

- Authentication and authorization.
- Users and student profiles.
- Scholarships and publication state.
- Eligibility evaluation.
- AI profile extraction and grounded assistance.
- Notifications.
- Administration.
- Ingestion and verification.

Keep HTTP handling, domain logic, persistence and external integrations in separate layers within modules.

## Dependency Boundary

The Flutter application communicates with FastAPI over HTTPS. It must not calculate authoritative eligibility results.

The eligibility engine consumes only profile data and approved, verified scholarship rules. It must not call an LLM for a final decision.

AI components may extract profile information and retrieve grounded guidance, but extracted values require validation and user confirmation.

## External Services

Cloud hosting, LLM providers, object storage, notification providers and authentication providers remain unresolved. Application boundaries should permit provider replacement without changing eligibility or publication rules.

