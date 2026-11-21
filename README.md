
# Claim What's Yours

**An AI-powered government scholarship discovery and guidance platform for students in Telangana, India.**

Claim What's Yours helps students discover government scholarships they may qualify for, understand eligibility requirements, prepare necessary documents and navigate official application procedures through a single platform.

The platform supports Telugu, Hindi and English, making scholarship information more accessible to students and families.

---

## 1. Overview

Government scholarship information is often distributed across multiple portals and government websites. Students may struggle to identify relevant schemes, understand complicated eligibility conditions, track deadlines and prepare the required documents.

Claim What's Yours addresses these challenges by bringing scholarship information together and providing personalized, explainable guidance.

Students can describe their educational and financial circumstances in natural language. The platform understands their information, evaluates it against verified scholarship rules and presents relevant opportunities with clear explanations.

The platform does not submit applications on behalf of students or guarantee scholarship approval.

---

## 2. Key Features

### Scholarship Discovery
- Discover Telangana state government scholarships.
- Discover applicable central government scholarships.
- Browse scholarships without creating an account.
- Search and filter scholarships based on relevant criteria.

### Personalized Eligibility Matching
- Create and manage student profiles.
- Describe personal circumstances in natural language.
- Evaluate profiles using a deterministic eligibility engine.
- Understand why a scholarship matches or does not match.
- Identify missing information and uncertain eligibility conditions.

### AI-Powered Assistance
- Natural-language understanding.
- Telugu, Hindi and English support.
- AI-assisted scholarship explanations.
- Retrieval-grounded document and application guidance.

### Document Guidance
- View scholarship-specific document checklists.
- Understand application requirements.
- Access official application links and sources.

### Deadline Tracking
- View relevant application deadlines.
- Track important scholarship dates.
- Receive reminders as supported features are introduced.

### Scholarship Data Verification
- Collect information from official government sources.
- Extract information from web pages and PDF notifications.
- Detect changes in scholarship information.
- Maintain verification history.
- Publish only approved and verified scheme information.

### Administrative Management
- Review scholarship records.
- Monitor source verification status.
- Manage records awaiting approval.
- Track data collection and verification activity.

---

## 3. Supported Platforms and Languages

| Category | Support |
|---|---|
| Android | Supported target |
| Web | Supported target |
| Telugu | Supported |
| Hindi | Supported |
| English | Supported |
| Initial Geographic Scope | Telangana, India |
| Scholarship Coverage | Telangana state and applicable central government schemes |

---

## 4. Technology Stack

The current technology direction is:

| Component | Technology |
|---|---|
| Frontend | Flutter |
| Backend | Python + FastAPI |
| Database | PostgreSQL |
| AI Architecture | Hybrid LLM + deterministic eligibility engine |
| Knowledge Retrieval | RAG |
| Web Data Collection | Requests, BeautifulSoup |
| Dynamic Web Extraction | Playwright |
| PDF Processing | PyMuPDF |
| Background Scheduling | APScheduler |
| Deployment | Cloud-based infrastructure |

Some technology choices remain subject to final confirmation. Refer to `spec.md` and the relevant architecture decision records for their current status.

---

## 5. System Architecture

The application is organized into the following major components:

1. **Flutter Frontend:** Provides the Android and Web user interfaces.
2. **Backend API:** Handles authentication, profiles, scholarship information and application services.
3. **Eligibility Engine:** Evaluates scholarship conditions using deterministic rules.
4. **AI Services:** Understand natural-language input and provide source-grounded guidance.
5. **RAG Layer:** Retrieves relevant information from approved official scholarship documents.
6. **Data Ingestion System:** Collects, extracts, validates and flags scholarship information for review.
7. **PostgreSQL Database:** Stores users, profiles, scholarship records, eligibility rules and related application data.

The LLM assists with understanding and guidance but never independently determines scholarship eligibility.

Only verified and approved scholarship information can be presented as confirmed.

For detailed architecture, refer to `docs/architecture.md`.

---

## 6. Repository Structure

The repository currently contains the documentation foundation:

```text
claim-whats-yours/
│
├── spec.md
├── AGENTS.md
├── IMPLEMENTATION_PLAN.md
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
│
├── .github/
│   └── copilot-instructions.md
│
├── docs/
│   ├── architecture.md
│   ├── database-schema.md
│   ├── api-specification.md
│   ├── data-sources.md
│   ├── data-pipeline.md
│   ├── ai-architecture.md
│   ├── eligibility-engine.md
│   ├── user-journeys.md
│   ├── security.md
│   ├── testing-strategy.md
│   ├── deployment.md
│   └── decisions/
```

Flutter application source, FastAPI source, database migrations, scripts, tests and deployment configuration will be added only when their implementation phases begin.
The structure may evolve as implementation progresses.

---

## 7. Getting Started

### Prerequisites

Install the following tools before setting up the project:

- Git
- Flutter SDK
- Dart SDK (included with Flutter)
- Python
- PostgreSQL
- Visual Studio Code or another suitable IDE

Additional requirements may be introduced as the technology stack is finalized.

### Clone the Repository

```bash
git clone <repository-url>
cd claim-whats-yours
```

### Frontend Setup

Once the Flutter project is initialized:

```bash
cd frontend
flutter pub get
```

Run on Android:

```bash
flutter run
```

Run on Web:

```bash
flutter run -d chrome
```

### Backend Setup

Once the FastAPI backend is initialized:

```bash
cd backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate it on Windows:

```powershell
venv\Scripts\activate
```

Activate it on Linux or macOS:

```bash
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Start the development server:

```bash
uvicorn app.main:app --reload
```

The default local API documentation will be available at:

```text
http://127.0.0.1:8000/docs
```

### Environment Configuration

Create a `.env` file in the backend directory when the configuration structure is established.

Example:

```env
APP_ENV=development
DATABASE_URL=
SECRET_KEY=
LLM_PROVIDER=
LLM_API_KEY=
```

`.env.example` will be created during Phase 3 (Development Environment and Project Setup), once the configuration contract is established. It will document required configuration variables using placeholder values only, never real credentials.

Never commit `.env` files containing secrets.

### Database Setup

After PostgreSQL and the database configuration are finalized:

1. Create the development database.
2. Configure the database connection.
3. Apply database migrations.
4. Verify database connectivity.

Refer to `docs/database-schema.md` and `docs/deployment.md` for detailed instructions.

**Note:** These commands describe the intended setup. They become executable project instructions once the corresponding frontend and backend files have been implemented.

---

## 8. Development Workflow

Development follows the phases defined in `IMPLEMENTATION_PLAN.md`.

The general workflow is:

1. Understand the requirements.
2. Review the existing codebase.
3. Identify dependencies and affected modules.
4. Plan the implementation.
5. Implement the approved functionality.
6. Run relevant tests.
7. Update documentation.
8. Record meaningful changes.
9. Report completion and remaining issues.

Refer to `AGENTS.md` for detailed coding-agent instructions.

---

## 9. Data Sources

The platform prioritizes official government information.

Initial candidate sources include:

- [Telangana ePASS](https://telanganaepass.cgg.gov.in/)
- [National Scholarship Portal](https://scholarships.gov.in/)
- [Ministry of Education](https://www.education.gov.in/)
- [Open Government Data Platform India](https://www.data.gov.in/)

These are candidate sources, not a guarantee that every relevant scholarship or dataset is available through a public API.

Source accessibility, relevance, permitted collection methods and update frequency must be verified before implementation.

All published scholarship information must be traceable to official sources.

---

## 10. Testing

Testing is an essential part of development.

The project will include:

- Unit tests.
- Backend API tests.
- Database integration tests.
- Eligibility engine tests.
- AI extraction and validation tests.
- Data ingestion tests.
- Flutter widget tests.
- End-to-end tests.
- Security and authorization tests.

Run tests using the commands documented for the relevant module once the project testing infrastructure is established.

Refer to `docs/testing-strategy.md` for the detailed testing approach.

---

## 11. Security and Privacy

The platform follows privacy-conscious development principles.

- Browsing scholarship information does not require login.
- Login is required for personalized features.
- Only necessary personal information should be collected.
- Aadhaar and bank credentials are not required for basic scholarship discovery.
- Student and guardian access must follow defined permissions.
- API keys and secrets must never be committed.
- Unverified information must not be presented as confirmed.
- Appropriate data protection requirements must be followed.

Refer to `docs/security.md` for detailed security requirements.

---

## 12. Project Documentation

| Document | Description |
|---|---|
| `spec.md` | Complete product specification |
| `AGENTS.md` | Instructions for AI coding agents |
| `IMPLEMENTATION_PLAN.md` | Development roadmap and progress |
| `CHANGELOG.md` | Project change history |
| `docs/` | Detailed technical documentation |

Read the relevant documentation before contributing to the project.

---

## 13. Development Status

**Project Status:** Phase 0 (Project Foundation and Documentation) is complete; application implementation not started. See IMPLEMENTATION_PLAN.md for the canonical phase status.

Implementation progress is tracked in `IMPLEMENTATION_PLAN.md`.

Features described in this README represent the intended product scope and should not be assumed to be implemented or deployed yet.

---

## 14. Contribution Guidelines

Contributions should follow the project's documentation and development standards.

Before making changes:

1. Understand the relevant requirements.
2. Inspect the existing implementation.
3. Follow `AGENTS.md`.
4. Avoid unrelated modifications.
5. Test changes.
6. Update relevant documentation.

Do not introduce architectural changes or new product features without appropriate approval.

---

## 15. License

License: To be decided.

A license should be selected and added before the project is publicly distributed.

---

## 16. Contact and Project Information

**Project:** Claim What's Yours

**Purpose:** Making government scholarship opportunities easier to discover, understand and access.

Additional project links and contact information will be added when available.