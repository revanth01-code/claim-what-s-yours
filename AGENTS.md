
# AGENTS.md

# Claim What's Yours — AI Coding Agent Instructions

## 1. Project Context

**Project Name:** Claim What's Yours

**Project Type:** AI-powered government scholarship discovery and guidance platform.

**Initial Geographic Scope:** Telangana, India.

**Target Platforms:** Android and Web.

**Supported Languages:** Telugu, Hindi and English.

### Project Purpose

Claim What's Yours helps students discover government scholarships they may qualify for, understand eligibility requirements, prepare necessary documents and navigate official application procedures.

The platform centralizes scholarship information from Telangana state and applicable central government schemes.

It uses AI to understand student information expressed in natural language, a deterministic eligibility engine to evaluate scholarship conditions, and retrieval-augmented generation (RAG) to provide guidance grounded in verified official sources.

The platform does not submit scholarship applications on behalf of students and must never present unverified information as confirmed.

### Primary Development Principles

- Accuracy over convenience.
- Security and privacy by design.
- Explainable eligibility decisions.
- Official-source-backed scholarship information.
- Modular and maintainable architecture.
- Practical implementation without unnecessary complexity.
- Independence from any particular AI coding agent or AI service provider.

For complete product requirements, refer to `spec.md`.

---

## 2. Technology Stack

The following technologies define the current proposed or selected direction.

| Component | Technology | Status |
|---|---|---|
| Frontend | Flutter | Selected |
| Backend | Python + FastAPI | Approved |
| Database | PostgreSQL | Approved |
| AI Architecture | Hybrid AI | Selected |
| Language Model | Provider-independent LLM integration | To be finalized |
| Eligibility Engine | Deterministic rule-based engine | Selected |
| Knowledge Retrieval | RAG | Selected |
| Web Data Collection | Requests, BeautifulSoup | Proposed |
| Dynamic Web Extraction | Playwright | Proposed |
| PDF Extraction | PyMuPDF | Proposed |
| Background Scheduling | APScheduler | Proposed |
| Deployment | Cloud infrastructure (category only; provider UNRESOLVED) | Selected |
| Coding Agent | GitHub Copilot (primary) | Preferred |

### Technology Rules

1. Do not silently replace or change an established technology.
2. Technologies marked as proposed must not be treated as permanently finalized.
3. Before introducing an alternative technology, explain why it is needed.
4. Prefer stable, actively maintained and well-documented libraries.
5. Avoid unnecessary dependencies.
6. Keep integrations replaceable wherever practical.
7. Do not introduce technologies merely because they are popular.

When a technology decision is finalized, update the relevant documentation and, where appropriate, record it in `docs/decisions/`.

---

## 3. Documentation Hierarchy

Documentation is the primary source of project requirements and technical decisions.

Before implementing a task, consult the relevant documentation.

| File | Responsibility |
|---|---|
| `spec.md` | Master product specification and functional requirements |
| `AGENTS.md` | General instructions and rules for AI coding agents |
| `IMPLEMENTATION_PLAN.md` | Development phases, tasks and progress |
| `README.md` | Project overview, setup and execution instructions |
| `CHANGELOG.md` | Record of meaningful completed changes |
| `docs/architecture.md` | System architecture and component interactions |
| `docs/database-schema.md` | Database structure and relationships |
| `docs/api-specification.md` | API contracts and endpoint definitions |
| `docs/data-sources.md` | Official scholarship information sources |
| `docs/data-pipeline.md` | Data collection, extraction and verification |
| `docs/ai-architecture.md` | LLM, RAG and AI service implementation |
| `docs/eligibility-engine.md` | Eligibility rules and evaluation logic |
| `docs/user-journeys.md` | User flows and interactions |
| `docs/security.md` | Security and privacy requirements |
| `docs/testing-strategy.md` | Testing approach and requirements |
| `docs/deployment.md` | Deployment and infrastructure |

### Documentation Rules

- Read relevant documentation before making implementation decisions.
- Do not duplicate detailed technical documentation across multiple files.
- Keep `spec.md` as the master product requirements document.
- Keep `AGENTS.md` focused on agent behaviour and development rules.
- Keep `IMPLEMENTATION_PLAN.md` updated as work progresses.
- Update technical documentation when implementation changes affect it.
- Do not invent requirements that are not documented or authorized.

### Handling Conflicting Requirements

If documentation, existing code or user instructions conflict:

1. Identify the conflicting requirements.
2. Explain the conflict clearly.
3. Avoid making irreversible assumptions.
4. Ask for clarification when the intended behaviour is unclear.
5. Follow explicit user decisions once clarified.
6. Update affected documentation after approval.

---

## 4. General Coding Principles

All code must follow these principles.

### Code Quality

- Write clean, readable and maintainable code.
- Use meaningful names for variables, functions, classes and files.
- Keep functions and classes focused on specific responsibilities.
- Avoid unnecessarily large functions and tightly coupled modules.
- Follow language-specific conventions and established project patterns.
- Add comments and docstrings where they improve understanding.
- Handle errors explicitly.
- Avoid unnecessary abstractions and premature optimization.

### Code Reusability

- Reuse existing utilities and components wherever appropriate.
- Avoid duplicate business logic.
- Keep shared functionality in appropriate reusable modules.
- Maintain clear separation between presentation, business logic and data access.

### Configuration

- Keep environment-specific configuration outside source code.
- Use environment variables for secrets and deployment-specific settings.
- Create `.env.example` during Phase 3 environment setup, once the configuration contract is established; it must contain placeholder values only, never real credentials.
- Never commit API keys, passwords, tokens or private configuration.

### Dependencies

- Check whether an existing dependency already provides the required functionality.
- Justify new dependencies before introducing them.
- Avoid abandoned or unmaintained packages.
- Keep dependency versions controlled.
- Update dependency documentation when necessary.

---

## 5. Architecture Rules

The application must follow a modular architecture with clearly separated responsibilities.

### Frontend

Flutter is responsible for:

- User interface and navigation.
- Student onboarding and profile management.
- Scholarship discovery and filtering.
- Eligibility result presentation.
- Document checklist presentation.
- AI assistant interaction.
- Language selection.
- Authentication-related user interactions.

The frontend must not independently implement authoritative scholarship eligibility decisions.

### Backend

The backend is responsible for:

- API endpoints.
- Authentication and authorization.
- Student profile management.
- Scholarship data access.
- Eligibility evaluation.
- AI service integration.
- RAG-based guidance.
- Deadline management.
- Administrative operations.

Keep API handling, business logic, database operations and external integrations separated.

### Database

The database stores:

- User and account information.
- Student profiles.
- Scholarship records.
- Eligibility rules and rule versions.
- Eligibility evaluation results.
- Official source information.
- Verification history.
- Application guidance references.
- Notifications and administrative audit records where required.

Follow the finalized database schema.

### Eligibility Engine

The eligibility engine must:

- Evaluate verified scholarship rules deterministically.
- Produce reproducible results.
- Explain satisfied and unsatisfied conditions.
- Identify missing profile information.
- Handle unknown, conflicting and unverified rules safely.
- Never delegate the final eligibility decision to an LLM.

### AI Services

AI services must remain separate from authoritative business logic.

They may assist with:

- Natural-language understanding.
- Student profile extraction.
- Multilingual interactions.
- Translation.
- Retrieval-grounded scholarship explanations.
- Document and application guidance.

### Data Ingestion

Data ingestion must operate independently of normal user-facing API requests.

It must collect, extract, validate and flag scholarship information for review.

Only approved and verified records may become publicly available as confirmed scholarship information.

---

## 6. AI Implementation Rules

AI must assist the application without becoming the authority for scholarship eligibility or government scheme information.

### LLM Usage

- Use LLMs for natural-language understanding and structured information extraction.
- Require structured outputs wherever possible.
- Validate all extracted information before storing or processing it.
- Never assume extracted information is correct simply because the model returned it.
- Ask users to confirm important extracted profile details.
- Handle ambiguous and incomplete user inputs gracefully.
- Preserve the user's intended meaning across Telugu, Hindi and English.

### Eligibility Decisions

- Never use an LLM as the final eligibility decision-maker.
- All eligibility decisions must pass through the deterministic eligibility engine.
- Never generate eligibility rules directly from unverified AI output.
- Return an uncertain result when required scheme rules are unavailable or unverified.

### RAG and Grounding

- Ground scheme-specific answers in approved official information.
- Preserve source references for retrieved information.
- Do not invent application steps, benefits, deadlines or document requirements.
- Clearly indicate when reliable source information is unavailable.
- Do not present unsupported AI-generated answers as official guidance.

### AI Reliability

- Handle model timeouts and provider failures.
- Validate model responses against expected schemas.
- Implement appropriate retry and fallback behaviour.
- Keep AI provider integrations replaceable.
- Monitor model usage, failures and costs.
- Protect the application against prompt injection and malicious retrieved content.

### AI Provider Independence

Do not tightly couple application logic to a specific LLM provider.

Use an abstraction layer so the underlying provider or model can be changed without rewriting unrelated application functionality.

---

## 7. Data Accuracy and Verification Rules

Scholarship information is a critical part of the application.

Accuracy must take priority over collecting a large number of schemes.

### Source Requirements

- Prefer official government websites and notifications.
- Preserve the original source URL.
- Record the source organization and document reference.
- Record collection and verification timestamps.
- Maintain source history wherever practical.
- Respect website terms, robots policies and access restrictions.
- Never bypass authentication, CAPTCHAs or access controls.

### Data Processing

Maintain distinct stages for:

1. Collected information.
2. Extracted information.
3. Validated information.
4. Pending verification.
5. Verified and approved information.
6. Published information.
7. Expired or archived information.

### Verification Rules

- Scraped information is not automatically verified.
- AI-extracted information is not automatically verified.
- Important eligibility conditions must be checked against official sources.
- Conflicting information must be flagged for review.
- Changes to deadlines, benefits and eligibility conditions require verification.
- Preserve historical versions of scholarship rules.
- Never silently overwrite previously verified information.

### Public Information

Every published scholarship must have:

- A scholarship name.
- Verified eligibility conditions.
- Available benefits and requirements.
- Applicable education level.
- Official source reference.
- Verification status.
- Relevant application dates, where available.

If information is incomplete or outdated, communicate that limitation clearly.

---

## 8. Security and Privacy Rules

Security and privacy must be considered throughout development.

### Personal Information

- Collect only information necessary for the application's functionality.
- Do not request Aadhaar numbers or bank account credentials for basic scholarship discovery.
- Avoid collecting sensitive documents unless explicitly required by an approved feature.
- Do not expose personal information in logs or error messages.
- Apply appropriate data retention and deletion practices.

### Authentication and Authorization

- Enforce authentication for protected functionality.
- Apply role-based access control.
- Validate permissions on the backend.
- Never rely solely on frontend permission checks.
- Enforce student and guardian access boundaries.
- Protect administrator functionality.

### Application Security

- Hash passwords using appropriate password-hashing algorithms.
- Validate all incoming data.
- Protect against common web and API vulnerabilities.
- Apply appropriate rate limits.
- Use secure communication.
- Protect secrets and tokens.
- Handle uploaded files securely if file uploads are implemented.
- Maintain audit records for important administrative actions.

### Compliance

Follow applicable Indian privacy and data protection requirements, including relevant Digital Personal Data Protection legislation and rules.

For features involving minors, guardian permissions and applicable consent requirements must be handled carefully.

---

## 9. Frontend Development Rules

### Flutter

- Maintain a single Flutter codebase for Android and Web.
- Keep widgets modular and reusable.
- Separate UI components from business and data-access logic.
- Follow the established state-management approach once finalized.
- Use responsive layouts.
- Support Telugu, Hindi and English throughout the application.
- Avoid hardcoded user-facing strings.
- Handle loading, empty, success and error states.
- Ensure navigation is consistent.
- Design for mobile-first usage and limited digital literacy.

### User Experience

- Use clear and simple language.
- Avoid unnecessary steps.
- Display eligibility explanations prominently.
- Distinguish confirmed, uncertain and incomplete information.
- Make official source links easy to access.
- Ensure essential functionality works on smaller screens.

Do not introduce major design-system or navigation changes without authorization.

---

## 10. Backend Development Rules

### Python

- Follow Python conventions and PEP 8.
- Use type hints wherever practical.
- Use Pydantic schemas for request and response validation.
- Keep business logic outside route handlers.
- Handle exceptions consistently.
- Use appropriate asynchronous patterns where needed.
- Avoid blocking operations inside asynchronous request handlers.

### API Development

- Follow the documented API contracts.
- Use appropriate HTTP methods and status codes.
- Validate requests and responses.
- Return consistent error structures.
- Implement authentication and authorization where required.
- Add pagination and filtering where specified.
- Avoid exposing internal exceptions or sensitive implementation details.

### Database Development

- Follow the approved database schema.
- Use migrations for schema changes.
- Define appropriate constraints and relationships.
- Use transactions where required.
- Avoid inefficient database queries.
- Never modify production data structures manually without an approved migration process.

---

## 11. Testing Requirements

Testing is mandatory for meaningful implementation changes.

### Required Testing Areas

**Unit Testing**
- Business logic.
- Eligibility conditions.
- Data validation.
- Utility functions.
- AI output parsing.

**Integration Testing**
- Database operations.
- Backend services.
- External source integrations.
- AI service integrations.

**API Testing**
- Request and response validation.
- Authentication.
- Authorization.
- Error handling.
- Filtering and pagination.

**Data Pipeline Testing**
- HTML extraction.
- PDF extraction.
- Duplicate detection.
- Change detection.
- Verification workflows.
- Invalid and incomplete source data.

**Frontend Testing**
- Widget tests.
- Navigation.
- Form validation.
- Responsive layouts.
- Multilingual presentation.

**End-to-End Testing**
- Student discovery journey.
- Profile extraction and confirmation.
- Eligibility matching.
- Scholarship detail viewing.
- Document guidance.

### Testing Rules

- Write tests for new business logic.
- Test edge cases and failure conditions.
- Run relevant tests after modifications.
- Run regression tests when shared functionality changes.
- Fix failures introduced by the implementation.
- Never claim tests passed without executing them.
- Clearly report tests that could not be executed.

---

## 12. Development Workflow

Follow this workflow whenever beginning a new task or coding session.

### Step 1: Understand the Project

Read:

1. `AGENTS.md`
2. Relevant sections of `spec.md`
3. `IMPLEMENTATION_PLAN.md`
4. Relevant technical documentation.

### Step 2: Inspect the Existing Codebase

- Understand the current folder structure.
- Identify existing modules and implementations.
- Inspect relevant files before modifying them.
- Identify existing conventions and dependencies.
- Determine the current development phase.

### Step 3: Understand the Task

- Identify the requested functionality.
- Identify dependencies.
- Check whether the task is within the current development phase.
- Identify missing requirements.
- Ask for clarification when necessary.

### Step 4: Plan the Implementation

Before significant changes:

- Identify files to create or modify.
- Explain the proposed implementation approach when appropriate.
- Identify potential risks.
- Avoid unnecessary modifications.

### Step 5: Implement

- Implement only the authorized task.
- Follow established architecture and coding standards.
- Reuse existing functionality.
- Keep changes focused.
- Avoid unrelated refactoring.

### Step 6: Test

- Run relevant tests.
- Check for regressions.
- Verify expected behaviour.
- Fix implementation-related failures.

### Step 7: Update Documentation

Where applicable:

- Update technical documentation.
- Update `IMPLEMENTATION_PLAN.md`.
- Record meaningful completed changes in `CHANGELOG.md`.
- Update `README.md` if setup or usage instructions change.

### Step 8: Report Completion

Provide a concise report covering:

- Implemented functionality.
- Files created or modified.
- Tests executed and results.
- Important decisions.
- Known issues.
- Remaining work.

---

## 13. Code Modification and Change Management Rules

AI coding agents must protect existing project work.

- Inspect files before modifying them.
- Do not rewrite entire files unnecessarily.
- Do not delete existing functionality without authorization.
- Do not overwrite user-created work.
- Do not modify unrelated modules.
- Do not silently change established API contracts.
- Do not change finalized architecture without approval.
- Do not remove tests merely to make a test suite pass.
- Do not suppress errors without understanding their cause.
- Preserve compatibility where practical.
- Explain significant structural changes.

If a requested implementation requires changing an existing architectural decision, explain the reason and obtain approval first.

---

## 14. Git and Version Control Rules

- Use meaningful commit messages.
- Keep changes logically organized.
- Do not commit secrets or credentials.
- Maintain an appropriate `.gitignore`.
- Do not force-push without explicit permission.
- Do not rewrite Git history without explicit permission.
- Avoid committing generated files unless required.
- Do not knowingly commit broken or untested changes.
- Review modified files before preparing a commit.

Never create, push or merge commits unless explicitly authorized by the user or an approved workflow.

---

## 15. Development Scope and Prioritization

Follow the priorities established in `spec.md` and `IMPLEMENTATION_PLAN.md`.

### MVP First

- Prioritize essential user journeys.
- Implement reliable core functionality before advanced features.
- Avoid building future-scope features prematurely.
- Prefer a working, testable implementation over unnecessary complexity.

### Scope Control

- Do not introduce new product features without approval.
- Do not expand the project scope based on assumptions.
- Identify optional improvements separately from required implementation.
- Clearly distinguish completed, in-progress and pending work.

### Practical Engineering

- Choose the simplest architecture that satisfies documented requirements.
- Avoid premature microservices, unnecessary infrastructure and excessive abstraction.
- Keep the system extensible without overengineering the MVP.

---

## 16. Error Handling and Reliability

The application must handle failures gracefully.

- Government websites may be unavailable.
- External APIs may fail.
- AI providers may become unavailable.
- PDF and web extraction may fail.
- Database connections may be interrupted.
- Users may submit incomplete or invalid information.

Agents must:

- Handle expected failures explicitly.
- Avoid silently discarding important errors.
- Provide useful user-facing error messages.
- Log technical details safely.
- Implement retries only where appropriate.
- Avoid duplicate processing during retries.
- Preserve access to previously approved scholarship information when external services are unavailable.

A failure in an external AI service must not prevent users from browsing already verified scholarship information.

---

## 17. Independence and Portability

The project must remain independent of any specific development agent or AI platform.

- Do not make application runtime dependent on GitHub Copilot, Codex, Claude Code, Cursor or similar coding agents.
- Do not require a particular IDE to run or deploy the application.
- Keep the application runnable through documented standard development commands.
- Avoid provider-specific dependencies where a portable alternative is practical.
- Keep AI integrations replaceable.
- Store project knowledge in documentation and source code, not only in agent conversation history.
- Ensure another developer or coding agent can continue development using the repository.

---

## 18. Definition of Done

A task is considered complete only when all applicable conditions are satisfied.

- The requested functionality is implemented.
- The implementation follows the project architecture.
- Relevant tests have been executed.
- No known implementation-related regression remains unresolved.
- Security and data accuracy requirements are respected.
- Relevant documentation has been updated.
- `IMPLEMENTATION_PLAN.md` reflects the actual progress.
- `CHANGELOG.md` records meaningful completed changes.
- Known limitations are documented.
- The completion report is provided.

Do not mark incomplete or untested functionality as complete.

---

## 19. Final Instructions

Always prioritize:

1. User requirements and approved decisions.
2. Product requirements in `spec.md`.
3. Technical decisions in the relevant documentation.
4. Existing architectural and coding conventions.
5. Maintainability, security and data accuracy.

When something is unclear, ask rather than guess.

Do not implement unapproved features, invent requirements, or silently change project decisions.

The goal is to build Claim What's Yours as a reliable, secure, maintainable and extensible platform that provides students with accurate government scholarship information and explainable guidance.
