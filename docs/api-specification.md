# API Specification

The REST API conventions and endpoint contracts are defined in `spec.md`, primarily in section 12.

## Conventions

- Use versioned API routes under `/api/v1`.
- Use JSON request and response bodies.
- Use Pydantic for request and response validation.
- Use consistent success and error shapes.
- Protect personalized and administrative operations with authentication and authorization.
- Do not expose unverified scholarship information as confirmed.

## Core Endpoint Groups

- Authentication.
- Student profiles.
- AI profile extraction.
- Scholarship discovery and details.
- Eligibility evaluation.
- Saved scholarships.
- Application tracking.
- Documents.
- Guardian relationships.
- AI assistant.
- Notifications.
- Administration.
- Health and system status.

No endpoint implementation or OpenAPI source file exists yet.

