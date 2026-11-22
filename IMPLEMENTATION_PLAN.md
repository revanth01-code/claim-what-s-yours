
# IMPLEMENTATION_PLAN.md

# Claim What's Yours — Development Roadmap

## 1. Purpose

This document defines the implementation roadmap for Claim What's Yours.

It organizes development into phases, tasks, dependencies and deliverables so that development remains structured, measurable and consistent.

All implementation work must follow:

- `spec.md` — Product requirements and expected behaviour.
- `AGENTS.md` — Coding standards and AI agent instructions.
- `IMPLEMENTATION_PLAN.md` — Development sequence and progress.
- Relevant documents under `docs/` — Detailed technical decisions and implementation requirements.

This document must be updated as development progresses.

---

## 2. Project Development Principles

1. Follow the defined development phases in order unless a dependency or approved decision requires otherwise.
2. Complete and test foundational components before building dependent features.
3. Prioritize a reliable MVP over unnecessary complexity.
4. Do not implement future-scope features during MVP development without approval.
5. Verify official scholarship information before publishing it.
6. Keep eligibility decisions deterministic and explainable.
7. Use AI only for approved assistive responsibilities.
8. Maintain documentation alongside implementation.
9. Avoid developing frontend features against undefined or unstable APIs.
10. Do not mark tasks complete without implementation and appropriate verification.

---

## 3. Development Status Definitions

Use the following statuses for phases and tasks:

| Status | Meaning |
|---|---|
| Not Started | Work has not begun. |
| In Progress | Work is actively being implemented. |
| Blocked | Work cannot continue because of an unresolved dependency or issue. |
| In Review | Implementation is complete and awaiting verification or approval. |
| Completed | Implementation and required verification are finished. |
| Deferred | Intentionally postponed to a later phase. |

A task must not be marked Completed simply because its code has been written.

---

## 4. Phase Overview

**Canonical roadmap:** This file (`IMPLEMENTATION_PLAN.md`) is the single source of truth for phase numbering, phase names, implementation ordering and task placement. The detailed phase sections in Section 5 are canonical. The roadmap summary in `spec.md` (section 20) is an overview that must match this file; if they ever differ, `spec.md` must be corrected to match this file.

| Phase | Name | Priority |
|---|---|---|
| 0 | Project Foundation and Documentation | Critical |
| 1 | Technical Research and Decision Finalization | Critical |
| 2 | System Architecture and Database Design | Critical |
| 3 | Development Environment and Project Setup | Critical |
| 4 | Scholarship Data Collection and Verification | Critical |
| 5 | Backend Foundation and Core APIs | Critical |
| 6 | Student Profiles and Authentication | High |
| 7 | Deterministic Eligibility Engine | Critical |
| 8 | AI Profile Understanding | High |
| 9 | Scholarship Guidance and RAG | High |
| 10 | Flutter Frontend Development | High |
| 11 | Frontend and Backend Integration | High |
| 12 | Admin Dashboard and Data Management | High |
| 13 | Testing, Security and Optimization | Critical |
| 14 | Deployment and Release Preparation | High |
| 15 | Future Enhancements | Deferred |

---

# 5. Detailed Implementation Phases

## Phase 0 — Project Foundation and Documentation

**Status:** In Review

**Objective:** Establish the project's documentation, requirements and development conventions before implementation.

### Tasks

- [x] Create `spec.md`.
- [x] Create `AGENTS.md`.
- [x] Create `IMPLEMENTATION_PLAN.md`.
- [x] Create `README.md`.
- [x] Create `CHANGELOG.md`.
- [x] Finalize the remaining sections of `spec.md`.
- [x] Prepare the technical documentation structure.
- [x] Identify unresolved product and technical decisions.
- [ ] Review documentation for consistency.

### Deliverables

- Complete master specification.
- General AI coding-agent instructions.
- Development roadmap.
- Initial project README and changelog.
- Organized documentation structure.

### Completion Criteria

- [x] Core product requirements are documented.
- [x] User roles and journeys are defined.
- [x] MVP and future scope are clearly separated.
- [x] Critical technical decisions are identified.
- [ ] Documentation is consistent and ready to guide implementation.

---

## Phase 1 — Technical Research and Decision Finalization

**Status:** In Review

**Objective:** Validate the proposed technologies, external services and implementation approaches.

### Tasks

- [ ] Evaluate and finalize the backend framework.
  - Status note: FastAPI and PostgreSQL are proposed baselines; no backend framework or database has been finally approved.
- [x] Evaluate and finalize the database.
- [ ] Select an authentication approach.
- [x] Evaluate LLM providers and available models.
- [x] Define the provider-independent AI integration approach.
- [x] Evaluate multilingual input and extraction capabilities.
- [x] Select the RAG implementation approach.
- [x] Investigate official scholarship information sources.
- [ ] Verify whether relevant public APIs or downloadable datasets exist.
  - Status note: partially investigated; no relevant scholarship API or dataset has been verified.
- [x] Evaluate HTML and PDF extraction requirements.
- [x] Evaluate cloud deployment options.
- [x] Identify notification service requirements.
- [ ] Document technical decisions and alternatives.
  - Status note: research drafted at docs/research/phase-1-research.md; not approved; decisions not final.

### Deliverables

- Finalized technology stack.
- Verified list of candidate data sources.
- AI provider evaluation.
- Data extraction strategy.
- Architecture Decision Records.

### Completion Criteria

- [x] Critical baseline technologies are finalized.
- [x] Important external dependencies are identified.
- [x] Data collection feasibility is established.
- [x] Major technical uncertainties are documented.

---

## Phase 2 — System Architecture and Database Design

**Status:** Not Started

**Objective:** Define the internal structure of the application before implementing individual modules.

### Tasks

- [ ] Design the overall system architecture.
- [ ] Define frontend, backend and database responsibilities.
- [ ] Define backend modules and their interactions.
- [ ] Define AI service boundaries.
- [ ] Define eligibility engine boundaries.
- [ ] Design the scholarship data ingestion architecture.
- [ ] Define the data verification workflow.
- [ ] Design the database schema.
- [ ] Define entity relationships and constraints.
- [ ] Design API contracts.
- [ ] Define authentication and authorization boundaries.
- [ ] Define error handling and logging.
- [ ] Document major architectural decisions.

### Deliverables

- `docs/architecture.md`
- `docs/database-schema.md`
- `docs/api-specification.md`
- `docs/user-journeys.md`
- Relevant architecture decision records.

### Completion Criteria

- [ ] Major application components are defined.
- [ ] Database entities and relationships are reviewed.
- [ ] API contracts are documented.
- [ ] Module responsibilities are clear.
- [ ] Architecture supports all approved MVP requirements.

---

## Phase 3 — Development Environment and Project Setup

**Status:** In Progress

**Objective:** Create the initial development environment and repository structure.

### Tasks

- [x] Initialize Git repository.
- [ ] Create the Flutter project.
- [ ] Configure Android and Web targets.
- [ ] Initialize the Python backend.
- [ ] Configure the FastAPI application.
- [ ] Configure PostgreSQL connectivity.
- [ ] Set up database migrations.
- [ ] Establish environment configuration.
- [x] Configure `.gitignore`.
- [ ] Create frontend and backend development commands.
- [ ] Configure linting and formatting.
- [ ] Establish automated testing infrastructure.
- [ ] Verify local frontend and backend execution.

### Deliverables

- Working Flutter application.
- Working backend service.
- Database connection.
- Initial project structure.
- Development and testing instructions.

### Completion Criteria

- [ ] Flutter application runs on Android.
- [ ] Flutter Web runs successfully.
- [ ] Backend starts successfully.
- [ ] Database connectivity works.
- [ ] Initial tests execute successfully.

---

## Phase 4 — Scholarship Data Collection and Verification

**Status:** Not Started

**Objective:** Build the verified scholarship information foundation.

### Tasks

#### Source Research

- [ ] Identify relevant Telangana government scholarship sources.
- [ ] Identify applicable central government scholarship sources.
- [ ] Investigate National Scholarship Portal information.
- [ ] Investigate Telangana ePASS information.
- [ ] Investigate relevant government notifications and PDFs.
- [ ] Verify source accessibility and usage restrictions.
- [ ] Document source reliability and update frequency.

#### Data Collection

- [ ] Implement individual source collectors.
- [ ] Implement HTTP request handling.
- [ ] Implement permitted HTML extraction.
- [ ] Implement PDF extraction.
- [ ] Preserve original documents and source references.
- [ ] Implement retry and failure handling.
- [ ] Record collection timestamps.

#### Data Processing

- [ ] Define the standardized scholarship data format.
- [ ] Extract structured scheme information.
- [ ] Validate extracted records.
- [ ] Implement duplicate detection.
- [ ] Implement change detection.
- [ ] Preserve historical scheme versions.

#### Verification

- [ ] Implement review and approval workflows.
- [ ] Track verification status.
- [ ] Verify eligibility conditions against official documents.
- [ ] Verify benefits and deadlines.
- [ ] Publish only approved scholarship records.

### Deliverables

- Data source registry.
- Scholarship collectors.
- Extraction and validation modules.
- Scholarship verification workflow.
- Initial verified scholarship database.

### Completion Criteria

- [ ] Relevant collectors work reliably.
- [ ] Extracted records follow the approved schema.
- [ ] Original sources remain traceable.
- [ ] Unverified records cannot be published as confirmed.
- [ ] Initial scholarship records are reviewed and approved.

---

## Phase 5 — Backend Foundation and Core APIs

**Status:** Not Started

**Objective:** Implement the backend infrastructure and core application services.

### Tasks

- [ ] Implement backend configuration.
- [ ] Implement database models.
- [ ] Implement database repositories.
- [ ] Implement service layer.
- [ ] Implement API routing.
- [ ] Implement consistent error handling.
- [ ] Implement request and response validation.
- [ ] Implement authentication foundations.
- [ ] Implement authorization foundations.
- [ ] Implement scholarship listing API.
- [ ] Implement scholarship detail API.
- [ ] Implement scholarship filtering and search.
- [ ] Implement deadline retrieval API.
- [ ] Implement health-check endpoint.
- [ ] Implement structured logging.

### Deliverables

- Functional backend foundation.
- Core scholarship APIs.
- Database integration.
- API documentation and tests.

### Completion Criteria

- [ ] Core endpoints work as documented.
- [ ] Database operations are reliable.
- [ ] API validation and errors are consistent.
- [ ] Authentication and permissions are tested.

---

## Phase 6 — Student Profiles and Authentication

**Status:** Not Started

**Objective:** Build account management and student profile functionality.

### Tasks

- [ ] Implement registration.
- [ ] Implement login and logout.
- [ ] Implement session or token management.
- [ ] Implement user roles.
- [ ] Implement student profile creation.
- [ ] Implement profile editing.
- [ ] Implement profile validation.
- [ ] Implement guardian-assisted profile management.
- [ ] Define guardian/student permissions.
- [ ] Implement profile retrieval and deletion.
- [ ] Implement user language preferences.
- [ ] Implement profile ownership and access checks.

### Deliverables

- Authentication module.
- Student profile management.
- Guardian-assisted account functionality.
- Related APIs and tests.

### Completion Criteria

- [ ] Students can manage their profiles.
- [ ] Guardian permissions follow approved rules.
- [ ] Unauthorized profile access is prevented.
- [ ] Profile information is validated and stored correctly.

---

## Phase 7 — Deterministic Eligibility Engine

**Status:** Not Started

**Objective:** Implement the core scholarship eligibility evaluation system.

### Tasks

- [ ] Define the eligibility rule representation.
- [ ] Define supported condition types.
- [ ] Implement numerical comparisons.
- [ ] Implement categorical comparisons.
- [ ] Implement AND/OR condition evaluation.
- [ ] Implement nested rule evaluation where required.
- [ ] Implement missing-information handling.
- [ ] Implement uncertain-result handling.
- [ ] Implement eligibility explanations.
- [ ] Implement rule versioning.
- [ ] Implement eligibility result storage.
- [ ] Implement profile-to-scholarship matching.
- [ ] Implement eligibility recalculation.
- [ ] Create comprehensive eligibility test cases.

### Required Result States

- Eligible.
- Ineligible.
- Needs more information.
- Uncertain.

### Deliverables

- Deterministic eligibility engine.
- Rule evaluation module.
- Eligibility explanation system.
- Matching API.
- Eligibility test suite.

### Completion Criteria

- [ ] Matching uses approved scheme rules.
- [ ] Results are deterministic and reproducible.
- [ ] Every result contains an explanation.
- [ ] Missing information is identified.
- [ ] Unverified rules cannot produce confirmed eligibility.
- [ ] Edge cases are covered by tests.

---

## Phase 8 — AI Profile Understanding

**Status:** Not Started

**Objective:** Allow students to describe their circumstances naturally in Telugu, Hindi or English.

### Tasks

- [ ] Implement provider-independent LLM interface.
- [ ] Integrate the selected LLM provider.
- [ ] Define structured student profile schema.
- [ ] Design extraction prompts.
- [ ] Implement natural-language profile extraction.
- [ ] Implement input language handling.
- [ ] Implement output schema validation.
- [ ] Implement missing-information detection.
- [ ] Implement confidence and ambiguity handling.
- [ ] Allow users to review extracted information.
- [ ] Implement extraction API.
- [ ] Add model failure handling.
- [ ] Test multilingual inputs.

### Deliverables

- AI integration layer.
- Profile extraction service.
- Structured profile validation.
- Multilingual test cases.

### Completion Criteria

- [ ] Telugu, Hindi and English inputs are supported.
- [ ] Extracted information follows the approved schema.
- [ ] Invalid or ambiguous outputs are handled safely.
- [ ] Users can review and correct extracted information.
- [ ] LLM output never directly determines eligibility.

---

## Phase 9 — Scholarship Guidance and RAG

**Status:** Not Started

**Objective:** Provide reliable scholarship-specific document and application guidance.

### Tasks

- [ ] Define the knowledge ingestion process.
- [ ] Select document storage and retrieval technologies.
- [ ] Prepare verified source documents.
- [ ] Implement document processing.
- [ ] Implement chunking and metadata extraction.
- [ ] Implement embedding generation if required.
- [ ] Implement retrieval.
- [ ] Implement source-grounded generation.
- [ ] Implement document checklist generation.
- [ ] Implement application step guidance.
- [ ] Implement citation and source references.
- [ ] Handle unavailable or conflicting information.
- [ ] Test retrieval quality and answer grounding.

### Deliverables

- RAG service.
- Verified knowledge base.
- Document checklist service.
- Application guidance service.
- Guidance API.

### Completion Criteria

- [ ] Guidance uses approved official sources.
- [ ] Source references are available.
- [ ] Unsupported requirements are not invented.
- [ ] Missing source information is communicated clearly.
- [ ] Retrieval and answer quality are evaluated.

---

## Phase 10 — Flutter Frontend Development

**Status:** Not Started

**Objective:** Build the user-facing Android and Web application.

### Tasks

#### Foundation

- [ ] Establish Flutter architecture.
- [ ] Configure navigation.
- [ ] Configure state management.
- [ ] Configure API communication.
- [ ] Implement error and loading states.
- [ ] Configure localization.

#### Screens

- [ ] Home / Discover.
- [ ] Student onboarding.
- [ ] Login and registration.
- [ ] Student profile.
- [ ] Eligibility results.
- [ ] Scholarship details.
- [ ] Document checklist.
- [ ] Deadline tracker.
- [ ] AI assistant.
- [ ] Settings.
- [ ] Admin interface, if included in the selected frontend architecture.

#### User Experience

- [ ] Implement Telugu, Hindi and English translations.
- [ ] Implement responsive layouts.
- [ ] Optimize mobile navigation.
- [ ] Implement empty states.
- [ ] Implement validation messages.
- [ ] Ensure official source links are accessible.
- [ ] Test smaller screen sizes.

### Deliverables

- Flutter Android application.
- Flutter Web application.
- Reusable UI components.
- Multilingual interface.

### Completion Criteria

- [ ] All approved MVP screens are implemented.
- [ ] Navigation works correctly.
- [ ] Android and Web layouts are functional.
- [ ] Localization works across the application.
- [ ] Loading, error and empty states are handled.

---

## Phase 11 — Frontend and Backend Integration

**Status:** Not Started

**Objective:** Connect the Flutter application with backend and AI services.

### Tasks

- [ ] Integrate authentication APIs.
- [ ] Integrate profile APIs.
- [ ] Integrate scholarship discovery APIs.
- [ ] Integrate eligibility matching.
- [ ] Integrate scholarship detail APIs.
- [ ] Integrate document guidance.
- [ ] Integrate deadline APIs.
- [ ] Integrate AI assistant.
- [ ] Implement frontend error handling.
- [ ] Implement token and session handling.
- [ ] Verify end-to-end user journeys.

### Deliverables

- Integrated Android application.
- Integrated Web application.
- Complete MVP user journeys.

### Completion Criteria

- [ ] Frontend and backend communicate reliably.
- [ ] Data is displayed correctly.
- [ ] Authentication and authorization work.
- [ ] Complete student journeys pass integration tests.

---

## Phase 12 — Admin Dashboard and Data Management

**Status:** Not Started

**Objective:** Provide administrative control over scholarship records and source verification.

### Tasks

- [ ] Implement admin authentication and authorization.
- [ ] Implement scholarship record management.
- [ ] Implement source registry management.
- [ ] Display verification status.
- [ ] Display source collection history.
- [ ] Display records pending review.
- [ ] Implement approval and rejection workflows.
- [ ] Implement change review.
- [ ] Implement audit history.
- [ ] Implement ingestion monitoring.

### Deliverables

- Administrative dashboard.
- Scholarship review workflow.
- Source monitoring interface.

### Completion Criteria

- [ ] Only authorized administrators can access administrative functions.
- [ ] Verification actions are recorded.
- [ ] Unapproved information cannot be published.
- [ ] Source and ingestion status are visible.

---

## Phase 13 — Testing, Security and Optimization

**Status:** Not Started

**Objective:** Verify that the complete application is reliable, secure and ready for deployment.

### Tasks

- [ ] Run backend unit tests.
- [ ] Run frontend tests.
- [ ] Run integration tests.
- [ ] Run end-to-end tests.
- [ ] Test eligibility edge cases.
- [ ] Test multilingual extraction.
- [ ] Test source extraction failures.
- [ ] Test outdated scholarship records.
- [ ] Test authentication and authorization.
- [ ] Review privacy and data handling.
- [ ] Review API security.
- [ ] Test failure and recovery behaviour.
- [ ] Test low-bandwidth behaviour.
- [ ] Optimize database queries.
- [ ] Optimize frontend performance.
- [ ] Review logging and monitoring.
- [ ] Fix critical and high-priority issues.

### Deliverables

- Test reports.
- Security review.
- Performance review.
- Stabilized application.

### Completion Criteria

- [ ] Critical user journeys pass.
- [ ] No unresolved critical security issue remains.
- [ ] Eligibility results are validated.
- [ ] Data verification protections work.
- [ ] Major defects are resolved or documented.

---

## Phase 14 — Deployment and Release Preparation

**Status:** Not Started

**Objective:** Deploy the application and prepare it for real-world use.

### Tasks

- [ ] Finalize cloud provider.
- [ ] Configure production backend.
- [ ] Provision production database.
- [ ] Configure secure environment variables.
- [ ] Configure file storage if required.
- [ ] Configure database migrations.
- [ ] Configure backups.
- [ ] Configure logging and monitoring.
- [ ] Deploy backend.
- [ ] Deploy Flutter Web.
- [ ] Prepare Android release build.
- [ ] Configure production API endpoints.
- [ ] Run production smoke tests.
- [ ] Document deployment and rollback procedures.

### Deliverables

- Deployed backend.
- Deployed Web application.
- Android release build.
- Production configuration.
- Deployment documentation.

### Completion Criteria

- [ ] Production services are accessible.
- [ ] Database connectivity is verified.
- [ ] Core application workflows work in production.
- [ ] Backups and monitoring are configured.
- [ ] Deployment and rollback instructions are documented.

---

## Phase 15 — Future Enhancements

**Status:** Deferred

**Objective:** Extend the application after the MVP is stable.

### Potential Enhancements

- [ ] Telugu voice interaction.
- [ ] Push notifications.
- [ ] SMS reminders.
- [ ] Advanced application tracking.
- [ ] Enhanced NGO and volunteer tools.
- [ ] Expanded source monitoring.
- [ ] Additional Indian state coverage.
- [ ] Additional Indian language support.
- [ ] Scholarship comparison.
- [ ] Advanced analytics.
- [ ] Additional accessibility features.

Future enhancements require prioritization and approval before implementation.

---

# 6. Cross-Phase Requirements

The following requirements apply throughout development.

## 6.1 Documentation

- Keep documentation synchronized with implementation.
- Record significant architecture changes.
- Update setup instructions when development commands change.
- Maintain accurate implementation status.

## 6.2 Testing

- Test new functionality as it is developed.
- Do not postpone all testing until the end.
- Add regression tests for important bug fixes.
- Maintain test coverage for eligibility and data verification logic.

## 6.3 Security

- Never commit secrets.
- Validate inputs.
- Enforce backend authorization.
- Protect personal information.
- Review security implications before introducing new integrations.

## 6.4 Data Reliability

- Preserve official source references.
- Maintain verification history.
- Keep unverified information separate.
- Never invent scholarship conditions.
- Handle source failures without losing approved data.

## 6.5 AI Reliability

- Validate LLM outputs.
- Ground scheme-specific answers in verified sources.
- Keep eligibility evaluation deterministic.
- Handle provider failures gracefully.
- Monitor usage and costs.

---

# 7. Current Development Status

| Item | Status |
|---|---|
| Product specification | Baseline complete |
| AI coding-agent instructions | Baseline complete |
| Implementation roadmap | Baseline complete |
| README | Baseline complete |
| Changelog | Created |
| Technical documentation | Initial documentation created |
| Architecture decisions | In Progress (ADR template created; no decisions recorded yet) |
| Application implementation | Not Started |

Update this table as actual progress is made.

Do not assume that creating documentation automatically completes the corresponding implementation phase.

---

# 8. Task Management Rules

When adding or updating tasks:

1. Use clear, actionable descriptions.
2. Break large tasks into smaller verifiable tasks.
3. Identify dependencies.
4. Assign priorities where useful.
5. Update statuses based on actual work.
6. Record blockers and their reasons.
7. Avoid deleting completed task history.
8. Add new tasks only when they are justified by approved requirements.

For significant tasks, record:

- Task description.
- Expected outcome.
- Dependencies.
- Relevant files or modules.
- Verification requirements.
- Completion status.

---

# 9. Final Development Principle

The goal is not simply to build an application with many features.

The goal is to deliver a reliable scholarship discovery platform that helps students understand their opportunities through accurate information, explainable eligibility decisions and trustworthy official-source-backed guidance.

Development must prioritize correctness, security, usability and maintainability over unnecessary complexity or premature feature expansion.
