# Deployment

Deployment is deferred until the development environment and architecture are implemented.

## Required Components

- HTTPS hosting for Flutter Web.
- Android application distribution.
- FastAPI backend hosting.
- Managed or hosted PostgreSQL.
- Background ingestion worker.
- Object storage for uploaded source documents and files.
- Environment-specific secrets.
- Logging and monitoring.
- Database backups and migrations.

## Environments

Maintain separate development, staging or testing, and production environments with separate databases and credentials.

The exact cloud provider, object-storage provider and monitoring solution are unresolved.

## Open Evaluation Items

Status: all items below are UNRESOLVED. Listed providers are proposed options only; none is approved.

- Cloud provider and hosting: UNRESOLVED.
- Database hosting and data residency: UNRESOLVED.
- Authentication provider: UNRESOLVED (Firebase Auth, Supabase Auth and JWT are options; none is approved).
- Object storage: UNRESOLVED.
- Backup and recovery targets: UNRESOLVED.
- Monitoring and deployment strategy: UNRESOLVED.
- Provider costs, limitations and vendor lock-in: UNRESOLVED; no dated official pricing has been established.

