
# Claim What's Yours — Product and Technical Specification

> **Document:** Master Project Specification  
> **Project:** Claim What's Yours  
> **Version:** 1.0  
> **Status:** Baseline Specification  
> **Initial Target Region:** Telangana, India  
> **Platforms:** Android and Web  
> **Primary Languages:** Telugu, English, Hindi

---

# 1. Project Overview

## 1.1 Introduction

Claim What's Yours is an AI-powered government scholarship discovery and guidance platform designed to help students, particularly those from economically disadvantaged backgrounds, discover scholarships for which they may qualify.

Many students miss scholarship opportunities because they are unaware of available government schemes, do not understand eligibility requirements, struggle with complicated application procedures, or cannot easily find accurate information.

Claim What's Yours addresses these challenges through a centralized platform that:

- Helps students discover relevant government scholarships.
- Understands student information provided through natural language.
- Matches student profiles against verified scholarship eligibility rules.
- Explains why a student may or may not qualify.
- Provides document checklists and application guidance.
- Helps students understand deadlines and important requirements.
- Offers multilingual assistance in Telugu, Hindi, and English.
- Maintains verified scholarship information from official sources.

The platform will initially focus on Telangana students while also including applicable central government scholarship schemes.

## 1.2 Core Principle

The platform must prioritize accuracy, transparency, security, and accessibility.

**AI assists users, but AI must never independently make final scholarship eligibility decisions.**

Eligibility decisions must be produced by a deterministic rule-based engine using verified scholarship rules.

AI may help interpret natural-language information, extract structured profile details, translate content, and explain verified information.

## 1.3 Project Objectives

1. Make government scholarship information easier to discover.
2. Reduce confusion around scholarship eligibility.
3. Help students identify missing qualifications or information.
4. Explain scholarship requirements in understandable language.
5. Provide accurate document checklists and application procedures.
6. Support students who prefer Telugu or Hindi.
7. Maintain trustworthy and regularly updated scholarship data.
8. Make the platform accessible through Android and Web.
9. Protect students' personal information.
10. Build an architecture that can be maintained and extended independently of any AI coding tool.

---

# 2. Project Scope

## 2.1 Geographic Scope

Initial coverage:

- Telangana state government scholarships.
- Central government scholarships applicable to eligible students in Telangana.

The architecture should allow additional Indian states to be supported in future versions.

## 2.2 Educational Coverage

The platform should support scholarship discovery across these educational levels:

- School education.
- Pre-matric education.
- Post-matric education.
- Intermediate education.
- Diploma and polytechnic courses.
- Undergraduate courses.
- Postgraduate courses.
- Professional courses.
- Research and doctoral studies.

Actual scholarship availability will depend on verified scheme eligibility and official source information.

## 2.3 Scholarship Categories

The system should support schemes targeting different categories, including:

- SC.
- ST.
- OBC and BC.
- EBC.
- Minority communities.
- Economically weaker students.
- Students with disabilities.
- Merit-based applicants.
- Other categories explicitly recognized by individual schemes.

The platform must not assume that every category is eligible for every scheme.

## 2.4 In Scope

- Public scholarship discovery.
- Student registration and authentication.
- Student profiles.
- Guardian-assisted profiles.
- Natural-language profile extraction.
- Scholarship eligibility matching.
- Eligibility explanations.
- Scholarship detail pages.
- Document checklists.
- Official application links and instructions.
- Multilingual interface and assistance.
- AI-powered scholarship guidance.
- Notifications and reminders.
- Admin dashboard.
- Scholarship data ingestion.
- Source verification and approval.
- Scholarship data versioning and monitoring.
- Cloud deployment.

## 2.5 Out of Scope

The initial version will not:

- Submit scholarship applications on behalf of students.
- Guarantee scholarship approval or financial awards.
- Make official government eligibility decisions.
- Access private government databases without authorization.
- Bypass website authentication, CAPTCHA, or access restrictions.
- Collect unnecessary Aadhaar, bank account, or financial credentials.
- Automatically publish unverified AI-generated scholarship rules.
- Replace official government scholarship portals.
- Claim that a student has received a scholarship merely because they are eligible.

The platform provides discovery, guidance, and assistance. Final application submission and approval remain with the relevant official authorities.

---

# 3. Technology Stack

## 3.1 Frontend

| Component | Technology | Purpose |
|---|---|---|
| Mobile application | Flutter | Android application |
| Web application | Flutter Web | Browser-based application |
| State management | Riverpod | Application state |
| API communication | Dio | HTTP requests |
| Navigation | GoRouter | Application navigation |
| Local preferences | SharedPreferences / secure storage where appropriate | User preferences and session-related storage |
| Localization | Flutter localization / ARB | Telugu, Hindi, English |

The frontend must be responsive and support different screen sizes.

## 3.2 Backend

| Component | Technology | Purpose |
|---|---|---|
| Language | Python | Backend implementation |
| Framework | FastAPI | REST API |
| Validation | Pydantic | Request and response validation |
| ORM | SQLAlchemy | Database interaction |
| Migrations | Alembic | Database schema management |
| Authentication | UNRESOLVED: JWT, Firebase Auth or Supabase Auth; provider and implementation require user approval | Protected API access |
| Password hashing | Argon2id or an appropriate secure password-hashing implementation | Password protection |

## 3.3 Database and Storage

| Component | Technology | Purpose |
|---|---|---|
| Main database | PostgreSQL | Application and scholarship data |
| Document storage | S3-compatible object storage | Uploaded files and source documents |
| Cache | Redis, if required | Caching and background-task support |

PostgreSQL is the primary source of truth for application data.

Uploaded documents should not be stored directly in database records. Store files in object storage and retain their metadata and storage references in PostgreSQL.

## 3.4 AI Architecture

The project will use a hybrid AI architecture.

| Component | Approach | Responsibility |
|---|---|---|
| Natural-language understanding | LLM | Understand student descriptions |
| Profile extraction | LLM + validation | Extract structured profile information |
| Eligibility matching | Deterministic rules | Evaluate scholarship eligibility |
| Guidance assistant | RAG + LLM | Answer questions using verified information |
| Translation | Translation service / LLM | Support Telugu, Hindi, and English |
| Data extraction assistance | LLM-assisted extraction | Assist scholarship data processing |

The LLM provider must remain configurable. Business logic must not depend on one specific model provider.

## 3.5 Data Collection and Processing

| Technology | Purpose |
|---|---|
| Requests | Access permitted public HTTP resources |
| BeautifulSoup | Parse HTML |
| Playwright | Process permitted JavaScript-rendered public pages |
| PyMuPDF | Extract information from PDFs |
| Pydantic | Validate extracted structured data |
| APScheduler | Schedule ingestion and monitoring jobs |

Use official APIs wherever available and authorized. Web scraping is a fallback when permitted.

## 3.6 Development Tools

- Visual Studio Code.
- Git.
- GitHub.
- GitHub Copilot as the primary AI coding assistant.
- Python virtual environments.
- Flutter SDK.
- PostgreSQL development environment.

The project must remain compatible with Codex, Claude Code, Cursor, and other development tools.

No runtime functionality may depend on GitHub Copilot or another coding agent.

---

# 4. System Architecture

## 4.1 Architectural Approach

Use a **modular monolith** for the initial backend.

This provides clear separation of responsibilities without introducing unnecessary microservice complexity.

The scholarship ingestion and monitoring process should run separately from the main API application.

## 4.2 High-Level Architecture

```text
                    STUDENTS / GUARDIANS / ADMINS
                                  |
                   +--------------+--------------+
                   |                             |
              Flutter App                   Flutter Web
                   |                             |
                   +--------------+--------------+
                                  |
                             REST API
                               HTTPS
                                  |
                         FastAPI Backend
                                  |
       +--------------------------+--------------------------+
       |              |           |            |             |
    Auth Module   Profile     Scholarship   Eligibility    AI/RAG
                  Module       Module        Engine       Module
       |              |           |            |             |
       +--------------+-----------+------------+-------------+
                                  |
                              PostgreSQL
                                  |
                +-----------------+------------------+
                |                 |                  |
            Redis (opt.)     Object Storage      Audit Logs
                                  |
                         Background Processing
                                  |
                       Scholarship Ingestion
                                  |
            +---------------------+---------------------+
            |                     |                     |
        Official APIs        Government Websites    Official PDFs
            |                     |                     |
            +---------------------+---------------------+
                                  |
                     Extraction and Validation
                                  |
                       Admin Verification
                                  |
                       Approved Scholarship Data
                                  |
                          PostgreSQL
```

## 4.3 Backend Modules

### Authentication Module

Responsible for:

- Registration.
- Login.
- Logout.
- Token refresh.
- Password management.
- Role-based authorization.

### User and Profile Module

Responsible for:

- User information.
- Student profiles.
- Multiple student profiles where authorized.
- Guardian relationships.
- Profile updates.
- Profile completeness.

### Scholarship Module

Responsible for:

- Scholarship discovery.
- Search and filtering.
- Scholarship details.
- Deadlines.
- Benefits.
- Requirements.
- Official application links.
- Publication and expiration status.

### Eligibility Module

Responsible for:

- Loading verified scholarship rules.
- Evaluating student profiles.
- Applying logical conditions.
- Returning eligibility results.
- Explaining matched and unmet conditions.
- Identifying missing information.

### AI Module

Responsible for:

- Natural-language profile understanding.
- Profile extraction.
- Multilingual assistance.
- Grounded scholarship explanations.
- RAG retrieval and response generation.

### Notification Module

Responsible for:

- Deadline reminders.
- Profile-related notifications.
- Scholarship updates.
- User notification preferences.

### Admin Module

Responsible for:

- Scholarship management.
- Data verification.
- Source management.
- Approval workflows.
- User and system monitoring.
- Audit history.

### Ingestion Module

Responsible for:

- Source monitoring.
- Document collection.
- Data extraction.
- Validation.
- Change detection.
- Preparing records for admin approval.

---

# 5. User Roles and Permissions

## 5.1 Guest

A guest can:

- Browse published scholarships.
- Search scholarships.
- Filter scholarships.
- View scholarship details.
- Read application instructions.
- View document requirements.
- Access public guidance.

A guest cannot:

- Save personalized scholarship results.
- Maintain a student profile.
- Receive personalized notifications.
- Access protected student information.

Login must not be mandatory for basic scholarship discovery.

## 5.2 Student

A student can:

- Register and log in.
- Create and update a profile.
- Provide profile information in natural language.
- Review extracted profile information.
- Search scholarships.
- Run eligibility matching.
- View eligibility explanations.
- Save scholarships.
- Track application-related progress.
- Create reminders.
- Ask the AI assistant questions.
- Manage language and notification preferences.

## 5.3 Guardian

A guardian can:

- Create or manage an authorized student profile.
- Assist with profile information.
- View scholarship opportunities for linked students.
- Help maintain document checklists.
- Receive relevant reminders when authorized.

Guardian access must be explicitly associated with a student profile.

A guardian must not automatically receive access to unrelated student accounts.

The exact consent and verification workflow should be implemented according to the applicable privacy and child-safety requirements.

## 5.4 Administrator

An administrator can:

- Add and edit scholarship records.
- Review extracted scholarship information.
- Verify official sources.
- Approve or reject scholarship changes.
- Publish verified scholarships.
- Archive expired scholarships.
- Manage data sources.
- View ingestion logs.
- Review audit logs.
- Monitor data quality.

Admin access must be restricted to authorized accounts.

---

# 6. Functional Requirements

## FR-01: Authentication

The system must provide:

- User registration.
- Login.
- Logout.
- Access token generation.
- Refresh token handling.
- Password hashing.
- Protected endpoints.
- Role-based authorization.
- Account status management.

Public scholarship browsing must work without authentication.

## FR-02: Student Profile Management

Students must be able to provide:

- Full name.
- Date of birth or age, where needed.
- State.
- District.
- Educational level.
- Current class or course.
- Institution information, where required.
- Social category, where relevant.
- Annual family income.
- Disability information, where relevant.
- Academic performance, where required.
- Other scheme-specific information.

Only collect fields necessary for scholarship discovery and eligibility.

Profile fields should support:

- Required / optional status.
- Validation rules.
- Missing-information indicators.
- User confirmation.
- Last-updated timestamps.

Sensitive information must receive appropriate protection.

## FR-03: Natural-Language Profile Input

Users can describe their situation in Telugu, Hindi, or English.

Example:

"I am studying B.Tech second year in Telangana. My family income is around 1.5 lakh per year. I belong to the SC category."

The AI should extract structured information such as:

```json
{
  "education_level": "undergraduate",
  "course": "B.Tech",
  "year_of_study": 2,
  "state": "Telangana",
  "annual_family_income": 150000,
  "category": "SC"
}
```

This is an illustrative extraction result, not an eligibility decision.

Requirements:

- Detect the input language.
- Extract supported fields.
- Identify ambiguous values.
- Never invent missing information.
- Return confidence or uncertainty indicators where appropriate.
- Ask follow-up questions for ambiguous information.
- Show extracted values to the user.
- Require user confirmation before saving them.

## FR-04: Scholarship Discovery

Users must be able to:

- Browse scholarships.
- Search by scholarship name.
- Filter by educational level.
- Filter by state.
- Filter by category.
- Filter by income requirements.
- Filter by course.
- Filter by scholarship type.
- Filter by application status or deadline.
- Sort by relevance or deadline.

Search results must contain only published scholarship records.

## FR-05: Eligibility Matching

The platform must compare student profiles with scholarship requirements.

Possible results:

- `eligible`
- `ineligible`
- `needs_more_information`
- `uncertain`

Definitions:

| Result | Meaning |
|---|---|
| eligible | All applicable mandatory conditions are satisfied |
| ineligible | At least one verified mandatory condition is not satisfied |
| needs_more_information | Required student information is missing |
| uncertain | Scholarship rules are incomplete, ambiguous, or not sufficiently verified |

Eligibility decisions must be reproducible and traceable.

The engine must not use LLM-generated conclusions as its final decision.

## FR-06: Eligibility Explanation

Each result should explain:

- Why the student matched.
- Which requirements were satisfied.
- Which requirements were not satisfied.
- Which details are missing.
- Whether any rules are uncertain.
- Which official source supports the decision.

The explanation must distinguish between confirmed rules and missing information.

## FR-07: Scholarship Details

Each scholarship detail page should include:

- Scholarship name.
- Description.
- Government department or organization.
- Scholarship type.
- Eligible states.
- Educational levels.
- Eligible categories.
- Income requirements.
- Academic requirements.
- Benefits.
- Required documents.
- Application procedure.
- Application start date, if verified.
- Application deadline, if verified.
- Renewal requirements, if applicable.
- Official application URL.
- Official source references.
- Last verification date.
- Publication status.

Unknown information must be displayed as unavailable or unverified rather than fabricated.

## FR-08: Document Checklist

The system should generate document checklists using verified scholarship requirements.

Each document item may include:

- Document name.
- Description.
- Whether mandatory or optional.
- Accepted format, if officially specified.
- Relevant official instructions.
- Completion status.

Users can track their preparation progress.

The platform must not claim that a document is officially accepted unless the relevant requirements support that statement.

## FR-09: Application Guidance

For each scholarship, provide:

1. Eligibility overview.
2. Required documents.
3. Application steps.
4. Official portal link.
5. Important deadlines.
6. Renewal information, if applicable.
7. Relevant official instructions.

Do not submit applications on behalf of students.

## FR-10: Saved Scholarships

Authenticated users can:

- Save scholarships.
- Remove saved scholarships.
- View saved scholarships.
- Review eligibility results for saved scholarships.

## FR-11: Application Tracking

Users may maintain an informational application tracker.

Suggested statuses:

- Interested.
- Preparing documents.
- Ready to apply.
- Applied.
- Awaiting result.
- Approved.
- Rejected.
- Withdrawn.

These statuses are user-managed and must not be represented as official government application statuses unless verified through an authorized integration.

## FR-12: Notifications and Reminders

Support:

- Upcoming deadline reminders.
- Saved scholarship updates.
- Important profile completion reminders.
- Scholarship status changes.
- User-created reminders.

Notifications should respect user preferences and should not expose sensitive student information unnecessarily.

## FR-13: Multilingual Support

The application must support:

- English.
- Telugu.
- Hindi.

Localization should cover:

- Navigation.
- Buttons.
- Labels.
- Forms.
- Validation messages.
- Notifications.
- Common instructions.

Scholarship source information should preserve its official wording and meaning.

Translated guidance must not alter eligibility conditions.

## FR-14: AI Scholarship Assistant

The assistant should help users:

- Understand scholarship requirements.
- Understand eligibility explanations.
- Identify missing profile information.
- Understand document requirements.
- Understand application procedures.
- Ask questions in Telugu, Hindi, or English.

The assistant must use verified scholarship data and source references.

It must:

- Avoid unsupported answers.
- Identify when information is unavailable.
- Distinguish general guidance from official requirements.
- Provide relevant official links.
- Avoid guaranteeing eligibility or approval.

## FR-15: Admin Dashboard

The admin dashboard should provide:

- Scholarship overview.
- Scholarship creation and editing.
- Pending verification queue.
- Source management.
- Extracted data review.
- Approval and rejection controls.
- Publication controls.
- Expiration management.
- Ingestion job status.
- Data quality indicators.
- Audit history.

## FR-16: Scholarship Data Monitoring

The system should monitor:

- New scholarship announcements.
- Deadline changes.
- Eligibility changes.
- Benefit changes.
- Application portal changes.
- Updated official documents.
- Expired scholarships.

Changes affecting important eligibility conditions must require human verification before publication.

---

# 7. User Journeys

## 7.1 Guest Scholarship Discovery

1. User opens the application.
2. User selects a preferred language.
3. User browses published scholarships.
4. User searches or applies filters.
5. User opens a scholarship.
6. User reads eligibility and requirements.
7. User visits the official application portal.

Login is not required for this journey.

## 7.2 Student Registration and Profile Creation

1. Student registers.
2. Student verifies their account using the configured verification mechanism.
3. Student logs in.
4. Student enters basic profile information.
5. Student can enter information manually or through natural language.
6. AI extracts structured information.
7. Student reviews extracted values.
8. Student corrects incorrect information.
9. Student confirms the profile.
10. Profile is saved.

## 7.3 Eligibility Matching

1. Student opens the personalized scholarship section.
2. Backend loads the confirmed student profile.
3. Backend retrieves published scholarships and verified rules.
4. Eligibility engine evaluates applicable conditions.
5. Results are classified.
6. Student sees eligible, ineligible, missing-information, or uncertain results.
7. Student can open the explanation for each scholarship.

## 7.4 Guardian-Assisted Journey

1. Guardian creates an account.
2. Guardian requests or establishes an authorized student relationship.
3. The student relationship is verified according to the implemented consent process.
4. Guardian creates or updates the linked student profile.
5. The student information is confirmed.
6. Guardian views relevant scholarship information.
7. Access remains limited to authorized linked profiles.

## 7.5 Admin Verification Journey

1. Ingestion process collects information from an approved source.
2. Extraction process identifies scholarship information.
3. Validation checks the extracted data.
4. A pending record is created.
5. Admin reviews the extracted fields and evidence.
6. Admin corrects errors if required.
7. Admin approves or rejects the record.
8. Approved data becomes publishable.
9. Published data becomes available through public APIs.
10. Every important change is recorded in the audit history.

## 7.6 AI Assistant Journey

1. User asks a question.
2. Backend identifies the language and intent.
3. Retrieval process searches approved scholarship information.
4. Relevant content and source references are provided to the LLM.
5. LLM generates a grounded answer.
6. Backend checks that the response includes appropriate source references.
7. User receives the answer and official references.

---

# 8. Scholarship Data Sources and Ingestion

## 8.1 Source Priority

Prefer sources in this order:

1. Official government APIs.
2. Official government scholarship portals.
3. Official government department websites.
4. Official government notifications and PDFs.
5. Other authoritative sources only when necessary and clearly identified.

Potential sources include:

- Telangana ePASS.
- National Scholarship Portal (NSP).
- Telangana government departments.
- Ministry of Education.
- Relevant central government ministries.
- data.gov.in.
- Telangana Open Data Portal, where relevant.

These are candidate sources. Availability of an API, permission to access data, and the ability to automate collection must be verified before implementation.

## 8.2 Ingestion Pipeline

```text
Official Source
      |
      v
Source Collector
      |
      v
Document / HTML / API Retrieval
      |
      v
Text and Data Extraction
      |
      v
AI-Assisted Structured Extraction
      |
      v
Schema and Rule Validation
      |
      v
Duplicate and Change Detection
      |
      v
Pending Verification
      |
      v
Admin Review
      |
      +------ Rejected
      |
      v
Approved Scholarship Version
      |
      v
PostgreSQL
      |
      v
Public APIs and Eligibility Engine
```

## 8.3 Data Collection Requirements

Collectors should:

- Respect source website terms and access restrictions.
- Use official APIs when available.
- Record source URLs.
- Record retrieval timestamps.
- Store relevant source documents or references.
- Handle connection failures.
- Handle changed page structures.
- Detect duplicate records.
- Record extraction failures.
- Avoid publishing data directly from raw extraction.

Do not bypass authentication, CAPTCHAs, or other access controls.

## 8.4 AI-Assisted Extraction

AI may extract:

- Scholarship name.
- Department.
- Description.
- Eligibility requirements.
- Income limits.
- Educational requirements.
- Benefits.
- Documents.
- Deadlines.
- Application instructions.
- Official links.

Every extracted field should retain its supporting evidence when possible.

AI extraction must not automatically make a record verified.

## 8.5 Data Verification Workflow

Suggested statuses:

- `collected`
- `extracted`
- `pending_validation`
- `pending_verification`
- `approved`
- `published`
- `rejected`
- `expired`
- `archived`

A record becomes available to public users only after the required verification and publication steps.

## 8.6 Source and Version History

Store:

- Source name.
- Source URL.
- Source type.
- Retrieval timestamp.
- Verification timestamp.
- Verified by.
- Source document reference.
- Extracted content.
- Previous scholarship version.
- Current scholarship version.
- Change summary.

Do not overwrite important historical scholarship information without retaining its previous version.

## 8.7 Monitoring Schedule

Initial configurable monitoring targets:

| Data | Suggested Frequency |
|---|---|
| Application deadlines and status | Every 6 hours |
| Scholarship pages | Every 24 hours |
| Official guidelines and documents | Every 7 days |

These are initial operational targets, not guaranteed source update intervals.

The scheduler must support retries, failure logs, and manual execution.

---

# 9. Eligibility Engine

## 9.1 Design

The eligibility engine must be deterministic.

It receives:

- Confirmed student profile.
- Published scholarship.
- Verified eligibility rules.

It returns:

- Result status.
- Conditions evaluated.
- Conditions satisfied.
- Conditions failed.
- Missing information.
- Uncertain conditions.
- Rule version.
- Scholarship version.

## 9.2 Rule Structure

Represent eligibility requirements in structured data.

Illustrative example:

```json
{
  "all": [
    {
      "field": "state",
      "operator": "equals",
      "value": "Telangana"
    },
    {
      "field": "annual_family_income",
      "operator": "less_than_or_equal",
      "value": 200000
    },
    {
      "field": "education_level",
      "operator": "in",
      "value": ["post_matric", "undergraduate"]
    }
  ]
}
```

This is an example rule structure only. The actual values must come from the relevant official scheme.

## 9.3 Supported Operators

The rule engine should support:

- `equals`
- `not_equals`
- `greater_than`
- `greater_than_or_equal`
- `less_than`
- `less_than_or_equal`
- `in`
- `not_in`
- `between`
- `contains`
- `is_true`
- `is_false`
- `is_present`

Logical operators:

- `all`
- `any`
- `not`

The rule schema must be validated before activation.

## 9.4 Evaluation Logic

For each scholarship:

1. Load its approved rule version.
2. Check whether the rule is complete and active.
3. Identify the profile fields required by the rule.
4. Identify missing profile information.
5. Evaluate all applicable conditions.
6. Collect failed conditions.
7. Collect uncertain or unsupported conditions.
8. Determine the result.
9. Return a structured explanation.

Suggested result precedence:

1. If a verified mandatory condition fails, return `ineligible`.
2. Otherwise, if a mandatory condition cannot be evaluated due to missing profile data, return `needs_more_information`.
3. Otherwise, if a required rule is incomplete, ambiguous, or unverified, return `uncertain`.
4. If all verified mandatory conditions are satisfied, return `eligible`.

If a condition cannot safely be evaluated, do not treat it as satisfied.

## 9.5 Explainability

Each condition result should contain:

- Field.
- Operator.
- Required value.
- Student value, when safe to display.
- Result.
- Explanation.
- Source reference.

## 9.6 Rule Versioning

Every eligibility evaluation must be associated with:

- Scholarship ID.
- Scholarship version.
- Eligibility rule version.
- Evaluation timestamp.

If rules change, previously generated results must not silently be treated as evaluations against the new rules.

## 9.7 Testing

Include tests for:

- Valid eligible profiles.
- Invalid profiles.
- Missing income information.
- Missing category information.
- Boundary income values.
- Unsupported operators.
- Incomplete rules.
- Expired scholarships.
- Conflicting conditions.
- Rule version changes.

---

# 10. AI Architecture

## 10.1 Hybrid AI Approach

The AI layer must be separate from the deterministic eligibility engine.

```text
User Input
    |
    v
Language and Intent Detection
    |
    v
LLM Profile Extraction
    |
    v
Structured Output Validation
    |
    v
User Confirmation
    |
    v
Student Profile
    |
    v
Deterministic Eligibility Engine
    |
    v
Eligibility Result
    |
    v
Grounded Explanation
```

## 10.2 Profile Extraction Contract

The extraction service should return:

- Extracted fields.
- Confidence or uncertainty information.
- Ambiguous fields.
- Missing fields.
- Clarification questions.
- Detected language.

The backend must validate all returned values using Pydantic and field-specific rules.

The LLM must not write directly to the database.

## 10.3 RAG Architecture

The assistant should retrieve information from approved scholarship records and verified source documents.

```text
User Question
     |
     v
Language / Intent Detection
     |
     v
Scholarship and Document Retrieval
     |
     v
Relevant Verified Context
     |
     v
LLM Response Generation
     |
     v
Source Reference Validation
     |
     v
Answer to User
```

## 10.4 RAG Data Rules

Only approved information should be used as authoritative guidance.

The retrieval layer should retain:

- Scholarship ID.
- Scholarship version.
- Source document ID.
- Source URL.
- Relevant content section.
- Verification status.

If vector search is introduced, embeddings and retrieval indexes must be traceable to the source version.

PostgreSQL full-text search can be used initially. A vector database or PostgreSQL vector extension may be added when justified.

## 10.5 AI Safety Requirements

The assistant must:

- Avoid fabricating scholarship requirements.
- Avoid inventing deadlines.
- Avoid unsupported eligibility claims.
- State when information is unavailable.
- Cite official sources where possible.
- Treat retrieved documents as data, not instructions.
- Ignore malicious instructions embedded in retrieved documents.
- Avoid exposing private user information.
- Avoid making official government decisions.

## 10.6 Provider Independence

Implement an abstraction layer for:

- Chat completion.
- Structured extraction.
- Embeddings, if used.
- Translation, if provider-based.

Changing the LLM provider should not require rewriting the eligibility engine or scholarship business logic.

---

# 11. Database Design

Use PostgreSQL with SQLAlchemy and Alembic.

The following entities define the baseline logical data model. Exact column types, indexes, and constraints should be finalized in database migrations.

## 11.1 Users

Stores account information.

Suggested fields:

- `id`
- `email`
- `phone`
- `password_hash`
- `role`
- `account_status`
- `email_verified_at`
- `phone_verified_at`
- `created_at`
- `updated_at`

Email or phone uniqueness should be enforced when the corresponding identifier is provided.

## 11.2 Student Profiles

Stores student information.

Suggested fields:

- `id`
- `user_id`
- `full_name`
- `date_of_birth`
- `state`
- `district`
- `education_level`
- `course`
- `year_of_study`
- `institution_name`
- `category`
- `annual_family_income`
- `disability_status`
- `academic_percentage`
- `profile_completeness`
- `created_at`
- `updated_at`

Optional fields must remain nullable where appropriate.

Do not collect fields without a clear product or eligibility requirement.

## 11.3 Guardian Relationships

Suggested fields:

- `id`
- `guardian_user_id`
- `student_profile_id`
- `relationship`
- `status`
- `consent_record`
- `created_at`
- `updated_at`

Enforce authorization for every operation involving linked profiles.

## 11.4 Scholarships

Stores the main scholarship record.

Suggested fields:

- `id`
- `name`
- `slug`
- `description`
- `department`
- `scholarship_type`
- `eligible_states`
- `education_levels`
- `categories`
- `benefits`
- `documents`
- `application_steps`
- `official_application_url`
- `application_start_date`
- `application_deadline`
- `renewal_information`
- `publication_status`
- `current_version_id`
- `created_at`
- `updated_at`

Structured fields should use appropriate JSONB or relational structures depending on querying and validation requirements.

## 11.5 Scholarship Sources

Suggested fields:

- `id`
- `name`
- `source_url`
- `source_type`
- `department`
- `access_method`
- `is_active`
- `last_checked_at`
- `created_at`
- `updated_at`

## 11.6 Scholarship Versions

Suggested fields:

- `id`
- `scholarship_id`
- `version_number`
- `content_snapshot`
- `change_summary`
- `source_id`
- `verification_status`
- `verified_by`
- `verified_at`
- `published_at`
- `created_at`

## 11.7 Eligibility Rules

Suggested fields:

- `id`
- `scholarship_id`
- `version_id`
- `rule_definition`
- `rule_status`
- `created_at`
- `updated_at`

Rules must be validated before activation.

## 11.8 Eligibility Evaluations

Suggested fields:

- `id`
- `student_profile_id`
- `scholarship_id`
- `scholarship_version_id`
- `eligibility_rule_version_id`
- `result`
- `matched_conditions`
- `failed_conditions`
- `missing_conditions`
- `uncertain_conditions`
- `evaluated_at`

## 11.9 Saved Scholarships

Suggested fields:

- `id`
- `user_id`
- `scholarship_id`
- `created_at`

Enforce uniqueness for each user and scholarship combination.

## 11.10 Application Tracking

Suggested fields:

- `id`
- `user_id`
- `student_profile_id`
- `scholarship_id`
- `status`
- `notes`
- `applied_at`
- `updated_at`

## 11.11 Notifications

Suggested fields:

- `id`
- `user_id`
- `type`
- `title`
- `message`
- `related_scholarship_id`
- `scheduled_at`
- `sent_at`
- `read_at`
- `status`
- `created_at`

## 11.12 Notification Preferences

Suggested fields:

- `id`
- `user_id`
- `email_enabled`
- `push_enabled`
- `deadline_reminders_enabled`
- `scholarship_updates_enabled`
- `preferred_language`
- `updated_at`

## 11.13 Documents

Stores document metadata and references.

Suggested fields:

- `id`
- `owner_user_id`
- `student_profile_id`
- `document_type`
- `storage_key`
- `file_name`
- `mime_type`
- `file_size`
- `upload_status`
- `created_at`

Only implement document uploads when needed. Use private storage, access controls, file validation, and retention policies.

## 11.14 Ingestion Jobs

Suggested fields:

- `id`
- `source_id`
- `job_type`
- `status`
- `started_at`
- `completed_at`
- `records_processed`
- `records_failed`
- `error_summary`

## 11.15 Audit Logs

Suggested fields:

- `id`
- `actor_user_id`
- `action`
- `entity_type`
- `entity_id`
- `old_values`
- `new_values`
- `created_at`

Audit logs should avoid storing unnecessary sensitive information.

## 11.16 Database Requirements

- Use UUID primary keys where appropriate.
- Use foreign-key constraints.
- Add indexes for frequently queried fields.
- Enforce uniqueness constraints.
- Use database transactions for related operations.
- Use UTC timestamps.
- Store money values using suitable decimal or integer representations.
- Use migrations for all schema changes.
- Apply access controls at the service and API layers.
- Retain scholarship history and eligibility rule versions.

---

# 12. REST API Specification

## 12.1 API Conventions

Base path:

`/api/v1`

All APIs should use JSON unless a file upload or download requires another content type.

Authentication:

`Authorization: Bearer <access_token>`

Public endpoints do not require authentication.

Protected endpoints require valid authentication and appropriate permissions.

Use consistent HTTP status codes and error responses.

## 12.2 Standard Success Response

Illustrative response:

```json
{
  "data": {},
  "meta": {}
}
```

For paginated responses:

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "page_size": 20,
    "total": 100,
    "total_pages": 5
  }
}
```

## 12.3 Standard Error Response

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The provided information is invalid.",
    "details": []
  }
}
```

Do not expose stack traces, database errors, secrets, or internal implementation details to clients.

## 12.4 Authentication Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/auth/register` | Public | Register account |
| POST | `/api/v1/auth/login` | Public | Authenticate user |
| POST | `/api/v1/auth/refresh` | Authenticated refresh flow | Refresh access token |
| POST | `/api/v1/auth/logout` | Authenticated | Revoke session or refresh token |
| POST | `/api/v1/auth/forgot-password` | Public | Request password reset |
| POST | `/api/v1/auth/reset-password` | Public with valid reset token | Reset password |
| GET | `/api/v1/auth/me` | Authenticated | Get current user |

### Registration Request

```json
{
  "email": "student@example.com",
  "password": "example-password",
  "role": "student"
}
```

The exact registration fields and verification mechanism may be adapted to the authentication approach, which is unresolved and requires user approval.

### Login Request

```json
{
  "email": "student@example.com",
  "password": "example-password"
}
```

### Login Response

```json
{
  "data": {
    "access_token": "token",
    "token_type": "bearer",
    "expires_in": 3600,
    "user": {
      "id": "uuid",
      "role": "student"
    }
  }
}
```

Production token handling must follow secure storage and refresh-token policies.

## 12.5 Profile Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/profiles` | Authenticated | Create student profile |
| GET | `/api/v1/profiles` | Authenticated | List accessible profiles |
| GET | `/api/v1/profiles/{profile_id}` | Authorized | Get profile |
| PUT | `/api/v1/profiles/{profile_id}` | Authorized | Update profile |
| PATCH | `/api/v1/profiles/{profile_id}` | Authorized | Partially update profile |
| DELETE | `/api/v1/profiles/{profile_id}` | Authorized | Request profile deletion |
| GET | `/api/v1/profiles/{profile_id}/completeness` | Authorized | Get profile completeness |

## 12.6 AI Profile Extraction Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/profile/extract` | Public with rate limits or authenticated | Extract profile information from natural language |
| POST | `/api/v1/profile/extract/confirm` | Authenticated | Confirm and save reviewed extracted information |

The existing draft endpoint `/api/profile/extract` is retained as `/api/v1/profile/extract` under the versioned API prefix.

### Extraction Request

```json
{
  "text": "I am studying B.Tech second year in Telangana. My family income is 150000 per year.",
  "language": "en"
}
```

### Extraction Response

```json
{
  "data": {
    "extracted_profile": {
      "education_level": "undergraduate",
      "course": "B.Tech",
      "year_of_study": 2,
      "state": "Telangana",
      "annual_family_income": 150000
    },
    "missing_fields": [
      "category"
    ],
    "ambiguous_fields": [],
    "clarification_questions": [],
    "requires_confirmation": true
  }
}
```

The response must never silently save extracted information.

## 12.7 Scholarship Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/api/v1/scholarships` | Public | Browse scholarships |
| GET | `/api/v1/scholarships/{scholarship_id}` | Public | Get scholarship details |
| GET | `/api/v1/scholarships/search` | Public | Search scholarships |
| GET | `/api/v1/scholarships/filters` | Public | Get available filter options |
| GET | `/api/v1/scholarships/{scholarship_id}/sources` | Public | Get published source references |

Suggested query parameters:

- `page`
- `page_size`
- `search`
- `state`
- `education_level`
- `category`
- `scholarship_type`
- `course`
- `deadline_status`
- `sort_by`
- `sort_order`

Only published scholarship records should be returned by public endpoints.

## 12.8 Eligibility Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/eligibility/match` | Authenticated | Match a profile against scholarships |
| GET | `/api/v1/eligibility/results` | Authenticated | List previous results |
| GET | `/api/v1/eligibility/results/{result_id}` | Authorized | Get evaluation details |
| POST | `/api/v1/eligibility/evaluate/{scholarship_id}` | Authenticated | Evaluate one scholarship |

The existing draft endpoint `/api/eligibility/match` is retained as `/api/v1/eligibility/match`.

### Match Request

```json
{
  "profile_id": "uuid",
  "scholarship_ids": []
}
```

An empty scholarship list means evaluate against the currently published and applicable scholarship collection.

### Match Response

```json
{
  "data": [
    {
      "scholarship_id": "uuid",
      "scholarship_name": "Example Scholarship",
      "result": "needs_more_information",
      "matched_conditions": [],
      "failed_conditions": [],
      "missing_conditions": [
        {
          "field": "category",
          "reason": "Required information is missing"
        }
      ],
      "uncertain_conditions": [],
      "scholarship_version": 1,
      "rule_version": 1
    }
  ]
}
```

## 12.9 Saved Scholarship Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/saved-scholarships` | Authenticated | Save scholarship |
| GET | `/api/v1/saved-scholarships` | Authenticated | List saved scholarships |
| DELETE | `/api/v1/saved-scholarships/{scholarship_id}` | Authenticated | Remove saved scholarship |

## 12.10 Application Tracking Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/applications` | Authenticated | Create tracker entry |
| GET | `/api/v1/applications` | Authenticated | List tracker entries |
| GET | `/api/v1/applications/{application_id}` | Authorized | Get tracker entry |
| PATCH | `/api/v1/applications/{application_id}` | Authorized | Update tracker entry |
| DELETE | `/api/v1/applications/{application_id}` | Authorized | Delete tracker entry |

These endpoints maintain user-managed tracking information only.

## 12.11 Document Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/api/v1/scholarships/{scholarship_id}/documents` | Public | Get required document checklist |
| GET | `/api/v1/profiles/{profile_id}/documents` | Authorized | List uploaded documents |
| POST | `/api/v1/profiles/{profile_id}/documents` | Authorized | Upload document |
| DELETE | `/api/v1/documents/{document_id}` | Authorized | Delete uploaded document |

Document upload should be implemented only after file-storage and privacy requirements are finalized.

## 12.12 Guardian Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/guardians/requests` | Authenticated | Request a student relationship |
| GET | `/api/v1/guardians/relationships` | Authenticated | List relationships |
| POST | `/api/v1/guardians/relationships/{id}/approve` | Authorized | Approve relationship |
| POST | `/api/v1/guardians/relationships/{id}/reject` | Authorized | Reject relationship |
| DELETE | `/api/v1/guardians/relationships/{id}` | Authorized | Revoke relationship |

The actual consent workflow must be finalized before enabling guardian access in production.

## 12.13 AI Assistant Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| POST | `/api/v1/assistant/chat` | Public with rate limits or authenticated | Ask scholarship questions |
| GET | `/api/v1/assistant/conversations` | Authenticated | List conversations |
| GET | `/api/v1/assistant/conversations/{id}` | Authorized | Get conversation |
| DELETE | `/api/v1/assistant/conversations/{id}` | Authorized | Delete conversation |

### Chat Request

```json
{
  "message": "What documents are required for this scholarship?",
  "language": "en",
  "scholarship_id": "uuid",
  "conversation_id": null
}
```

### Chat Response

```json
{
  "data": {
    "answer": "The verified scholarship information lists the following documents...",
    "language": "en",
    "sources": [
      {
        "scholarship_id": "uuid",
        "source_name": "Official Government Source",
        "source_url": "https://example.gov.in"
      }
    ],
    "insufficient_information": false
  }
}
```

The source name and URL above are illustrative. Real responses must use actual verified sources.

## 12.14 Notification Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/api/v1/notifications` | Authenticated | List notifications |
| PATCH | `/api/v1/notifications/{id}/read` | Authorized | Mark as read |
| PATCH | `/api/v1/notifications/read-all` | Authenticated | Mark all as read |
| GET | `/api/v1/notifications/preferences` | Authenticated | Get preferences |
| PUT | `/api/v1/notifications/preferences` | Authenticated | Update preferences |
| POST | `/api/v1/reminders` | Authenticated | Create reminder |
| DELETE | `/api/v1/reminders/{id}` | Authorized | Delete reminder |

## 12.15 Admin Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/api/v1/admin/dashboard` | Admin | Dashboard overview |
| POST | `/api/v1/admin/scholarships` | Admin | Create scholarship |
| PUT | `/api/v1/admin/scholarships/{id}` | Admin | Update scholarship |
| GET | `/api/v1/admin/scholarships/pending` | Admin | List pending verification records |
| POST | `/api/v1/admin/scholarships/{id}/approve` | Admin | Approve record |
| POST | `/api/v1/admin/scholarships/{id}/reject` | Admin | Reject record |
| POST | `/api/v1/admin/scholarships/{id}/publish` | Admin | Publish approved record |
| POST | `/api/v1/admin/scholarships/{id}/archive` | Admin | Archive scholarship |
| GET | `/api/v1/admin/sources` | Admin | List sources |
| POST | `/api/v1/admin/sources` | Admin | Add source |
| PATCH | `/api/v1/admin/sources/{id}` | Admin | Update source |
| GET | `/api/v1/admin/ingestion/jobs` | Admin | List ingestion jobs |
| POST | `/api/v1/admin/ingestion/jobs/run` | Admin | Trigger authorized ingestion job |
| GET | `/api/v1/admin/audit-logs` | Admin | View audit history |

All admin operations must be protected by server-side authorization.

## 12.16 System Endpoints

| Method | Endpoint | Access | Purpose |
|---|---|---|---|
| GET | `/health` | Public or infrastructure-restricted | Health check |
| GET | `/api/v1/health` | Public or infrastructure-restricted | API health |
| GET | `/api/v1/version` | Public | Application version |

Do not expose detailed infrastructure information through public health endpoints.

## 12.17 API Requirements

All endpoints must:

- Validate inputs.
- Enforce authorization.
- Return consistent errors.
- Use pagination for large collections.
- Apply rate limits to expensive or public AI operations.
- Avoid leaking personal information.
- Log important administrative actions.
- Use appropriate HTTP status codes.
- Be documented through FastAPI OpenAPI documentation.

The endpoint list is the baseline API contract. Implementation may add internal endpoints when necessary, but should not create overlapping or redundant APIs.

---

# 13. Frontend Application Structure

## 13.1 Main Screens

### Public Screens

1. Splash screen.
2. Language selection.
3. Home page.
4. Scholarship discovery.
5. Scholarship search results.
6. Scholarship details.
7. Public guidance.

### Authentication Screens

1. Registration.
2. Login.
3. Password recovery.
4. Account verification.

### Student Screens

1. Student dashboard.
2. Profile creation.
3. Profile editing.
4. Natural-language profile input.
5. Profile confirmation.
6. Scholarship recommendations.
7. Eligibility results.
8. Eligibility explanation.
9. Saved scholarships.
10. Document checklist.
11. Application tracker.
12. Notifications.
13. AI assistant.
14. Settings.

### Guardian Screens

1. Guardian dashboard.
2. Linked student profiles.
3. Relationship requests.
4. Student scholarship results.
5. Student document checklist.
6. Notifications.

### Admin Screens

1. Admin dashboard.
2. Scholarship management.
3. Pending verification.
4. Source management.
5. Ingestion monitoring.
6. Audit logs.
7. Data quality overview.

## 13.2 UI/UX Principles

- Mobile-first design.
- Simple navigation.
- Clear language.
- Accessible color contrast.
- Responsive layouts.
- Large touch targets.
- Clear loading states.
- Clear error messages.
- Empty-state guidance.
- Accessible forms.
- Multilingual support.

The platform should not overwhelm students with technical terminology.

## 13.3 Scholarship Card

Each scholarship card should show, where available:

- Scholarship name.
- Department.
- Educational level.
- Short description.
- Deadline.
- Scholarship type.
- Eligibility status for authenticated users.

Do not show a personalized eligibility status to a guest without a confirmed profile.

## 13.4 Eligibility Result UI

Use distinct labels:

- Eligible.
- Not eligible.
- More information required.
- Eligibility uncertain.

Show an explanation and relevant source information rather than only a colored indicator.

---

# 14. Notifications and Background Jobs

## 14.1 Notification Events

Potential events:

- Deadline approaching.
- Deadline changed.
- New relevant scholarship published.
- Saved scholarship updated.
- Profile incomplete.
- Reminder scheduled by user.

## 14.2 Reminder Logic

Deadline reminders should:

- Use verified deadline dates.
- Respect the user's time zone.
- Avoid duplicate notifications.
- Respect notification preferences.
- Stop when the scholarship is archived or no longer applicable.

Do not generate reminders from unverified deadline information.

## 14.3 Background Processing

Use scheduled jobs for:

- Source monitoring.
- Scholarship ingestion.
- Deadline checks.
- Notification scheduling.
- Expiration checks.
- Data consistency checks.

Keep long-running ingestion tasks out of request-response API handlers.

---

# 15. Security and Privacy

## 15.1 Authentication and Authorization

- Use secure password hashing.
- Use short-lived access tokens.
- Implement secure refresh-token handling.
- Revoke sessions when necessary.
- Apply role-based access control.
- Verify ownership or authorized guardian access for every protected profile operation.
- Never rely on frontend-only access restrictions.

## 15.2 Personal Data Protection

- Collect only necessary data.
- Avoid collecting Aadhaar or bank credentials unless a clearly justified future requirement is approved.
- Do not expose student profiles publicly.
- Protect uploaded documents.
- Avoid logging sensitive profile details.
- Provide an appropriate account and data deletion process.
- Define data retention policies.

## 15.3 API Security

- HTTPS in production.
- Input validation.
- Rate limiting.
- Secure CORS configuration.
- SQL injection protection through safe database access.
- File upload validation.
- Secure error handling.
- Authentication on protected routes.
- Authorization checks on object access.
- Protection against common web vulnerabilities.

## 15.4 Secrets Management

Never hardcode:

- Database credentials.
- API keys.
- JWT secrets.
- LLM provider keys.
- Storage credentials.
- Email or notification credentials.

Use environment variables or an appropriate cloud secret-management service.

The `.env.example` file is deferred: it will be created during development environment setup (Phase 3) once the environment configuration contract is established, and must then contain placeholder values only. Do not commit real secrets to it.

## 15.5 Uploaded Document Security

If document uploads are enabled:

- Validate MIME types and file extensions.
- Enforce file-size limits.
- Use private storage.
- Generate short-lived access links where needed.
- Restrict access to the owner and authorized parties.
- Consider malware scanning.
- Define retention and deletion procedures.

## 15.6 Regulatory Considerations

Before production deployment, review applicable Indian privacy, cybersecurity, child-safety, and data-protection requirements, including the Digital Personal Data Protection framework and applicable rules.

Do not assume that this specification alone establishes legal compliance.

---

# 16. Non-Functional Requirements

## 16.1 Performance

- Public scholarship browsing should use pagination.
- Frequently accessed published scholarship data may be cached.
- Expensive AI calls should be rate-limited.
- Ingestion must not block normal API operations.
- Database queries should use appropriate indexes.

Initial performance targets should be measured and refined during testing.

## 16.2 Reliability

- Handle external source failures.
- Retry temporary ingestion errors.
- Preserve successfully collected data when a later source request fails.
- Avoid duplicate records.
- Use transactions for critical operations.
- Record failed background jobs.
- Do not publish partial or invalid scholarship records.

## 16.3 Scalability

The modular architecture should allow future scaling of:

- API instances.
- Background workers.
- Database resources.
- File storage.
- AI provider integrations.

Do not introduce microservices unless actual operational requirements justify them.

## 16.4 Maintainability

- Modular code.
- Clear interfaces.
- Type hints.
- Consistent naming.
- Automated tests.
- Database migrations.
- API documentation.
- Centralized configuration.
- Structured logging.

## 16.5 Accessibility

- Readable text.
- Keyboard navigation on Web.
- Screen-reader-friendly labels.
- Adequate contrast.
- Responsive layouts.
- Clear validation instructions.

## 16.6 Observability

Track:

- API errors.
- API response times.
- Authentication failures.
- AI request failures.
- Ingestion job failures.
- Data verification delays.
- Notification failures.
- Database health.

Do not log unnecessary sensitive user data.

---

# 17. Testing Strategy

## 17.1 Backend Unit Tests

Test:

- Authentication services.
- Profile validation.
- Scholarship validation.
- Eligibility operators.
- Eligibility result classification.
- Rule versioning.
- Notification scheduling.
- Data extraction validation.

## 17.2 API Tests

Test:

- Registration and login.
- Public scholarship access.
- Protected profile access.
- Authorization failures.
- Eligibility matching.
- Scholarship filtering.
- Admin approval.
- Notification preferences.
- Invalid requests.
- Pagination.

## 17.3 Frontend Tests

Test:

- Navigation.
- Authentication screens.
- Profile forms.
- Language selection.
- Scholarship browsing.
- Eligibility result rendering.
- Error and loading states.
- Responsive layouts.

## 17.4 Integration Tests

Test complete workflows:

- User registration to profile creation.
- Natural-language extraction to profile confirmation.
- Profile to eligibility matching.
- Scholarship ingestion to admin approval.
- Admin publication to public discovery.
- Verified data retrieval to AI assistant response.
- Deadline detection to notification creation.

## 17.5 Data Quality Tests

Test:

- Missing scholarship fields.
- Invalid dates.
- Duplicate scholarships.
- Invalid source URLs.
- Unsupported eligibility operators.
- Unverified records.
- Expired schemes.
- Conflicting source information.

## 17.6 Security Tests

Test:

- Unauthorized profile access.
- Guardian access restrictions.
- Admin-only endpoint protection.
- Token expiration.
- Invalid token handling.
- File access restrictions.
- Input validation.
- Rate limits.

## 17.7 Testing Rule

No feature should be marked complete solely because its code has been written.

It must pass its relevant tests and acceptance criteria.

---

# 18. Deployment Architecture

## 18.1 Deployment Approach

Deploy the system to cloud infrastructure.

The exact cloud provider is not finalized.

The architecture should support:

- Flutter Web hosting.
- Android application distribution.
- FastAPI backend hosting.
- PostgreSQL hosting.
- Background ingestion worker.
- Object storage.
- Secure environment configuration.
- Logging and monitoring.

## 18.2 Production Components

```text
Flutter Web
    |
    v
HTTPS Hosting / CDN
    |
    v
FastAPI Backend
    |
    +------ PostgreSQL
    |
    +------ Object Storage
    |
    +------ AI Provider
    |
    +------ Notification Provider

Background Worker
    |
    +------ Official Sources
    |
    +------ PostgreSQL
    |
    +------ Object Storage
```

## 18.3 Environments

Maintain separate environments:

- Development.
- Testing / Staging.
- Production.

Use different credentials and databases for each environment.

## 18.4 Deployment Requirements

- Production HTTPS.
- Environment-based configuration.
- Database migrations.
- Secure secrets.
- Database backups.
- Error monitoring.
- Health checks.
- Logging.
- Deployment documentation.
- Rollback strategy.

## 18.5 Android and Web

Flutter should share reusable application logic while allowing platform-specific handling where required.

The Web version must not expose backend secrets or depend on local development configuration.

---

# 19. Project Folder Structure

The following is the target logical structure. It may be adjusted during implementation while preserving module separation.

```text
claim-whats-yours/
│
├── frontend/
│   └── flutter_app/
│       ├── lib/
│       │   ├── core/
│       │   │   ├── config/
│       │   │   ├── constants/
│       │   │   ├── networking/
│       │   │   ├── routing/
│       │   │   ├── theme/
│       │   │   ├── localization/
│       │   │   └── utils/
│       │   │
│       │   ├── features/
│       │   │   ├── auth/
│       │   │   ├── home/
│       │   │   ├── profile/
│       │   │   ├── scholarships/
│       │   │   ├── eligibility/
│       │   │   ├── saved_scholarships/
│       │   │   ├── applications/
│       │   │   ├── documents/
│       │   │   ├── assistant/
│       │   │   ├── notifications/
│       │   │   ├── guardian/
│       │   │   └── admin/
│       │   │
│       │   └── main.dart
│       │
│       ├── test/
│       ├── assets/
│       └── pubspec.yaml
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   └── v1/
│   │   │
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── security.py
│   │   │   └── logging.py
│   │   │
│   │   ├── db/
│   │   │   ├── session.py
│   │   │   └── base.py
│   │   │
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── repositories/
│   │   ├── services/
│   │   │
│   │   ├── modules/
│   │   │   ├── auth/
│   │   │   ├── profiles/
│   │   │   ├── scholarships/
│   │   │   ├── eligibility/
│   │   │   ├── ai/
│   │   │   ├── assistant/
│   │   │   ├── notifications/
│   │   │   ├── guardians/
│   │   │   └── admin/
│   │   │
│   │   ├── ingestion/
│   │   │   ├── collectors/
│   │   │   ├── extractors/
│   │   │   ├── validators/
│   │   │   ├── monitors/
│   │   │   └── scheduler.py
│   │   │
│   │   └── main.py
│   │
│   ├── alembic/
│   ├── tests/
│   ├── requirements.txt
│   └── .env.example (created in Phase 3 once the environment contract is established)
│
├── docs/
│   ├── architecture/
│   ├── api/
│   ├── database/
│   └── data-sources/
│
├── scripts/
│
├── .gitignore
├── AGENTS.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── IMPLEMENTATION_PLAN.md
├── README.md
└── spec.md
```

This structure is a starting point. Do not create empty modules simply to match the diagram. Add them when the corresponding implementation phase begins.

---

# 20. Implementation Roadmap

**Canonical roadmap:** `IMPLEMENTATION_PLAN.md` is the single source of truth for phase numbering, names, ordering and task placement. This section is an overview that must match it; if the two ever differ, `IMPLEMENTATION_PLAN.md` governs.

Development must follow a phase-by-phase approach.

Each phase must have clear deliverables, tests, and completion criteria.

## Phase 0 — Project Foundation and Documentation

- Finalize `spec.md`.
- Finalize `AGENTS.md`.
- Finalize `IMPLEMENTATION_PLAN.md`.
- Finalize `README.md`.
- Create `CHANGELOG.md`.
- Create `CONTRIBUTING.md`.
- Initialize the project Git repository.
- Establish the project folder structure.

**Completion:** Documentation is consistent and the project foundation is ready.

## Phase 1 — Technical Research and Decision Finalization

- Identify initial scholarship sources.
- Check API availability.
- Review website access conditions.
- Test HTML extraction.
- Test PDF extraction.
- Evaluate AI provider options.
- Evaluate deployment options.
- Finalize authentication approach.
- Finalize guardian consent workflow.
- Finalize initial data model.

**Completion:** Important technical dependencies and risks are understood.

## Phase 2 — System Architecture and Database Design

- Finalize architecture.
- Define database relationships.
- Define Pydantic schemas.
- Define API contracts.
- Define eligibility rule schema.
- Define data verification workflow.
- Define security boundaries.

**Completion:** Architecture and database design are documented and reviewed.

## Phase 3 — Development Environment and Project Setup

- Initialize Git repository.
- Establish project folder structure.
- Initialize Flutter application.
- Initialize FastAPI backend.
- Configure PostgreSQL.
- Configure SQLAlchemy and Alembic.
- Configure environment variables.
- Add linting and testing.
- Add basic CI checks.

**Completion:** Frontend and backend run locally and can communicate.

## Phase 4 — Scholarship Data Collection and Verification

- Identify official sources.
- Implement collectors.
- Implement HTML and PDF extraction.
- Implement schema validation.
- Implement duplicate detection.
- Implement source tracking.
- Implement admin verification queue.
- Store approved scholarship versions.

**Completion:** Verified scholarship records can be safely created and published.

## Phase 5 — Backend Foundation and Core APIs

- Implement configuration.
- Implement database connection.
- Implement API versioning.
- Implement error handling.
- Implement authentication foundations.
- Implement logging.
- Implement health checks.
- Scholarship listing.
- Scholarship details.
- Search.
- Filtering.
- Pagination.
- Official source references.
- Published-data restrictions.

**Completion:** Backend foundation is stable and tested, and guests and authenticated users can discover published scholarships.

## Phase 6 — Student Profiles and Authentication

- Registration.
- Login.
- Token handling.
- Profile creation.
- Profile updates.
- Profile validation.
- Guardian relationship foundations.
- Authorization tests.

**Completion:** Users can securely manage authorized student profiles.

## Phase 7 — Deterministic Eligibility Engine

- Implement rule schema.
- Implement supported operators.
- Implement logical evaluation.
- Implement result classification.
- Implement explanations.
- Implement rule versioning.
- Implement comprehensive tests.

**Completion:** Eligibility results are deterministic, explainable, and traceable.

## Phase 8 — AI Profile Understanding

- Configure LLM abstraction.
- Implement language detection.
- Implement profile extraction.
- Implement structured validation.
- Implement clarification flow.
- Implement confirmation workflow.
- Test extraction quality.

**Completion:** Natural-language information can be safely converted into confirmed profile data.

## Phase 9 — Scholarship Guidance and RAG

- Prepare verified content for retrieval.
- Implement retrieval service.
- Implement grounded prompt construction.
- Implement source references.
- Implement assistant APIs.
- Implement multilingual responses.
- Test unsupported-question handling.

**Completion:** The assistant answers using verified scholarship information and identifies uncertainty.

## Phase 10 — Flutter Frontend Development

- Application structure.
- Navigation.
- Localization.
- Authentication screens.
- Profile screens.
- Scholarship discovery.
- Scholarship details.
- Eligibility results.
- Saved scholarships.
- Application tracker.
- AI assistant.
- Notifications.

**Completion:** Core user journeys work through the frontend.

## Phase 11 — Frontend and Backend Integration

- Integrate authentication.
- Integrate profile APIs.
- Integrate scholarship APIs.
- Integrate eligibility APIs.
- Integrate AI APIs.
- Integrate notifications.
- Handle loading and error states.
- Test complete workflows.

**Completion:** Frontend and backend operate together reliably.

## Phase 12 — Admin Dashboard and Data Management

- Admin dashboard.
- Scholarship verification.
- Publication controls.
- Source monitoring.
- Ingestion logs.
- Audit history.
- Expiration management.

**Completion:** Administrators can manage scholarship data safely.

## Phase 13 — Testing, Security and Optimization

- Unit testing.
- Integration testing.
- API testing.
- Frontend testing.
- Eligibility testing.
- Data quality testing.
- Authorization testing.
- Performance testing.
- Security review.

**Completion:** Core acceptance criteria pass.

## Phase 14 — Deployment and Release Preparation

- Configure cloud infrastructure.
- Deploy backend.
- Deploy database.
- Deploy frontend.
- Configure object storage.
- Configure secrets.
- Configure backups.
- Configure monitoring.
- Prepare Android release.
- Perform production smoke tests.

**Completion:** The application is deployed and operational.

## Phase 15 — Future Enhancements

**Status:** Deferred

Potential future features:

- Additional Indian states.
- More regional languages.
- Advanced scholarship recommendation ranking.
- Improved accessibility features.
- Additional official integrations.
- More notification channels.
- Advanced analytics.
- Additional document assistance features.

Future features must not compromise the reliability of existing functionality.


---

# 21. Acceptance Criteria

The initial release is acceptable when the following conditions are met.

## 21.1 Discovery

- Guests can browse scholarships without login.
- Users can search and filter scholarships.
- Only published scholarship records appear publicly.
- Scholarship pages display available source references.
- Missing information is not fabricated.

## 21.2 Profiles

- Users can register and log in.
- Students can create and update profiles.
- Profile information is validated.
- Natural-language extraction requires user confirmation.
- Unauthorized users cannot access another student's profile.

## 21.3 Eligibility

- The engine evaluates verified rules deterministically.
- All four eligibility result states are supported.
- Missing information is clearly identified.
- Unverified rules cannot produce a confirmed eligible result.
- Results retain scholarship and rule versions.
- Explanations identify relevant conditions.

## 21.4 AI Assistant

- Supports Telugu, Hindi, and English interactions.
- Retrieves approved scholarship information.
- Provides relevant official source references.
- Does not invent eligibility requirements or deadlines.
- Identifies insufficient information.

## 21.5 Data Management

- Scholarship records retain source references.
- Extracted information is validated.
- Admin approval is required before publication.
- Important changes are versioned.
- Failed ingestion jobs are recorded.

## 21.6 Security

- Protected endpoints enforce authentication.
- Role permissions are enforced server-side.
- Student data is protected.
- Secrets are not committed.
- Uploaded documents, if supported, are private and access-controlled.

## 21.7 Application

- Android application builds successfully.
- Flutter Web application builds successfully.
- Main user journeys work.
- Error and loading states are handled.
- Core automated tests pass.

---

# 22. Development and AI Coding Agent Instructions

All developers and AI coding agents must follow these rules.

## 22.1 Documentation Hierarchy

Use documents in this order:

1. `spec.md` — Product and technical requirements.
2. `AGENTS.md` — Coding and development rules.
3. `IMPLEMENTATION_PLAN.md` — Development sequence and progress.
4. `README.md` — Setup and project overview.
5. `CONTRIBUTING.md` — Contribution workflow.
6. `CHANGELOG.md` — Significant project changes.

If a conflict exists, identify it and request clarification rather than silently choosing an interpretation.

## 22.2 Phase-by-Phase Development

- Work on one defined phase or task at a time.
- Inspect existing code before changing it.
- Identify dependencies before implementing.
- Avoid implementing unrelated features.
- Test completed work.
- Update documentation when necessary.
- Report incomplete work honestly.

## 22.3 No Assumptions

Do not invent:

- Scholarship rules.
- Government API availability.
- Official deadlines.
- Required documents.
- Database credentials.
- Cloud configuration.
- Authentication provider capabilities.

If required information is unavailable, mark it as unresolved and explain what is needed.

## 22.4 Implementation Independence

The project must remain:

- Developable in VS Code.
- Compatible with GitHub Copilot.
- Compatible with other coding agents.
- Independent of external coding-agent runtime services.
- Maintainable by developers without AI assistance.

## 22.5 Definition of Done

A feature is complete only when:

1. Requirements are implemented.
2. Appropriate validation exists.
3. Authorization is enforced where needed.
4. Tests are added.
5. Relevant tests are executed successfully.
6. Documentation is updated.
7. Known limitations are documented.
8. No unrelated or unintended changes are introduced.

---

# 23. Open Technical Decisions

The following items require research or explicit finalization before their relevant implementation phases.

| Decision | Current Status |
|---|---|
| Flutter for Android and Web | Confirmed |
| Python and FastAPI backend | Approved (user decision) |
| PostgreSQL | Approved (user decision) |
| Modular monolith architecture | Approved for MVP (user decision) |
| Hybrid AI approach | Confirmed |
| Deterministic eligibility engine | Required |
| LLM provider | To be finalized |
| Embedding model | To be finalized if vector search is used |
| Cloud provider | To be finalized |
| Object storage provider | To be finalized |
| Authentication and verification provider | To be finalized |
| Guardian consent and verification workflow | To be finalized |
| Email/SMS/push notification providers | To be finalized |
| Exact initial scholarship dataset | To be researched and verified |
| Government API availability | To be verified source by source |
| Production performance targets | To be measured and finalized |
| Data retention policy | To be finalized before production |

Do not block unrelated development work because an optional provider has not been selected. Use interfaces and configuration so that provider-specific implementation can be added later.

---

# 24. Final Product Principles

Every implementation decision must follow these principles:

1. **Accuracy first:** Scholarship information must be supported by reliable sources.
2. **Deterministic eligibility:** Final eligibility calculations must use verified rules, not LLM guesses.
3. **Transparency:** Users must understand why a result was produced.
4. **Privacy:** Collect and expose only necessary student information.
5. **Accessibility:** Make the platform understandable to students with different language and technical backgrounds.
6. **Human verification:** Critical scholarship data changes require appropriate review.
7. **Reliability:** Failure of an external source or AI provider must not corrupt existing verified information.
8. **Maintainability:** Keep modules clear and replaceable.
9. **Independence:** The application must not depend on any AI coding agent at runtime.
10. **Practical implementation:** Build incrementally, test continuously, and avoid unnecessary architectural complexity.

---

# 25. Final Project Definition

Claim What's Yours is a multilingual government scholarship discovery and guidance platform that combines verified government scholarship information, natural-language student profile understanding, deterministic eligibility matching, and AI-powered assistance.

Its purpose is not merely to list scholarships, but to help students understand which opportunities may apply to them, what information they need, which documents they should prepare, and how to proceed through official application channels.

The platform must remain trustworthy by ensuring that every eligibility result and important scholarship requirement is grounded in verified information.

**The success of Claim What's Yours will be measured by the accuracy, clarity, accessibility, and reliability of the guidance it provides to students.**
