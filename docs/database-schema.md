# Database Schema

PostgreSQL is the primary source of truth.

The final schema is not implemented yet. This document summarizes the entities documented in `spec.md` and identifies design constraints.

## Core Entities

- Users
- Student profiles
- Guardian relationships
- Scholarships
- Scholarship sources
- Scholarship versions
- Eligibility rules
- Eligibility evaluations
- Saved scholarships
- Application tracking records
- Notifications
- Notification preferences
- Documents
- Ingestion jobs
- Audit logs

## Required Data Qualities

- Preserve source references for published scholarship fields.
- Preserve verification and approval state.
- Preserve scholarship rule versions.
- Store eligibility explanations and missing conditions.
- Link evaluation results to the rule version and profile version used.
- Prevent public APIs from exposing unverified scholarship records as confirmed.
- Keep uploaded document metadata and object-storage references in PostgreSQL rather than file bytes.

## Privacy

Only necessary student information should be persisted. Authorization must be enforced for profile access and guardian relationships. Aadhaar numbers and bank credentials are not required for basic discovery.

The exact retention policy and document storage provider remain unresolved.

