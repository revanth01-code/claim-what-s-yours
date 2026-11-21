
# Contributing to Claim What's Yours

Thank you for your interest in contributing to Claim What's Yours.

This document explains the guidelines and workflow for contributing to the project. All contributors, including human developers and AI coding agents, are expected to follow these guidelines.

## 1. Before You Start

Before making changes, review the following project documents:

- `README.md` — Project overview and setup instructions.
- `spec.md` — Product requirements and functional scope.
- `AGENTS.md` — Coding standards and instructions for AI coding agents.
- `IMPLEMENTATION_PLAN.md` — Development phases and priorities.
- `CHANGELOG.md` — Record of significant project changes.

If your proposed contribution conflicts with these documents, clarify the requirement before implementing it.

## 2. Contribution Workflow

Follow this workflow when contributing:

1. Understand the relevant requirement.
2. Review the existing implementation before changing anything.
3. Identify the files and components that need modification.
4. Implement the change using the project's architecture and coding standards.
5. Add or update tests where necessary.
6. Run relevant tests and checks.
7. Update documentation if the change affects existing behavior, setup, APIs, or architecture.
8. Update `CHANGELOG.md` when the change is significant.
9. Review the final changes for unintended modifications.

Do not implement unrelated features as part of a contribution.

## 3. Code Quality Guidelines

All contributions should follow these principles:

- Write clean, readable, and maintainable code.
- Use meaningful names for variables, functions, classes, and files.
- Avoid unnecessary complexity and duplicated logic.
- Keep components and modules focused on specific responsibilities.
- Handle errors explicitly.
- Avoid hardcoded credentials, secrets, and environment-specific values.
- Follow the existing formatting and linting conventions.
- Add comments only when they clarify non-obvious logic.

## 4. Architecture Guidelines

Contributions must respect the established project architecture.

- Keep the Flutter frontend separate from backend business logic.
- Keep API endpoints, services, data-access logic, and business rules appropriately separated.
- Keep scholarship eligibility decisions in the deterministic eligibility engine.
- Do not allow an LLM to independently determine final scholarship eligibility.
- Keep AI-related components modular and replaceable.
- Avoid unnecessary dependencies between unrelated modules.
- Do not introduce a new architectural pattern without evaluating its impact.

## 5. Scholarship Data Accuracy

Scholarship information directly affects students, so data accuracy is essential.

- Prefer official government sources.
- Record the source URL and relevant verification information.
- Do not publish unverified scholarship information.
- Do not invent eligibility requirements, benefits, deadlines, or application procedures.
- Preserve source references for extracted information.
- Clearly distinguish verified information from information that is incomplete or awaiting verification.
- Update outdated scholarship information when reliable new information becomes available.

Any contribution that changes scholarship rules must include supporting source information and appropriate tests.

## 6. AI and Eligibility Guidelines

When modifying AI-related functionality:

- Use AI for natural-language understanding, information extraction, translation, and grounded assistance.
- Validate AI-extracted profile information before using it.
- Use deterministic rules for eligibility calculations.
- Return `needs-more-information` when required profile details are missing.
- Return an uncertain result when scholarship rules are incomplete or unverified.
- Ground generated guidance in approved scholarship information.
- Never present fabricated AI-generated information as official guidance.
- Keep AI provider integrations replaceable.

## 7. Security and Privacy

Every contribution must follow the project's security and privacy requirements.

- Never commit API keys, passwords, tokens, or secrets.
- Never collect unnecessary personal information.
- Avoid logging sensitive student information.
- Validate and sanitize user input.
- Enforce authentication and authorization on protected operations.
- Apply appropriate access controls to student and guardian data.
- Do not expose private student information through APIs or logs.
- Do not bypass website authentication, CAPTCHAs, or access restrictions when collecting data.

Security-sensitive changes should receive additional review before merging.

## 8. Testing Requirements

Contributions should include appropriate tests.

Depending on the change, this may include:

- Unit tests
- API tests
- Integration tests
- Flutter widget tests
- Eligibility engine tests
- Data validation tests
- Security and authorization tests

For eligibility-related changes, include test cases covering:

- Eligible students
- Ineligible students
- Missing profile information
- Incomplete scholarship rules
- Boundary conditions
- Invalid or inconsistent input

Do not claim that tests have passed unless they have actually been executed successfully.

## 9. Documentation Updates

Update documentation whenever a contribution changes:

- Project architecture
- API contracts
- Database structure
- Environment variables
- Installation or setup procedures
- Scholarship data workflows
- AI behavior
- Security requirements
- User-facing functionality

If a technical decision changes, update the relevant project documentation rather than allowing conflicting descriptions to remain.

## 10. Git and Commit Guidelines

Use meaningful commit messages that describe the purpose of a change.

Recommended format:

`<type>: <short description>`

Examples:

- `feat: add scholarship discovery endpoint`
- `fix: correct eligibility boundary calculation`
- `docs: update backend setup instructions`
- `test: add eligibility engine test cases`
- `refactor: separate scholarship validation service`
- `chore: update project dependencies`

Recommended commit types:

| Type | Purpose |
|---|---|
| `feat` | New functionality |
| `fix` | Bug fixes |
| `docs` | Documentation changes |
| `test` | Test additions or updates |
| `refactor` | Code restructuring without behavior changes |
| `chore` | Maintenance and configuration |
| `security` | Security-related changes |

Do not commit generated files, temporary files, local databases, or environment secrets unless explicitly required.

## 11. Pull Request Guidelines

Before submitting a pull request:

- Ensure the contribution addresses a clear requirement.
- Keep changes focused and reasonably small.
- Run relevant tests and quality checks.
- Update affected documentation.
- Review the changed files.
- Explain important implementation decisions.
- Mention known limitations or incomplete work.

A pull request should include:

1. Summary of the change.
2. Reason for the change.
3. Important implementation details.
4. Tests performed.
5. Screenshots, where relevant for UI changes.
6. Known limitations, if any.

Do not merge changes that introduce unverified scholarship rules, security vulnerabilities, or broken core functionality.

## 12. AI Coding Agent Contributions

AI coding agents must follow `AGENTS.md` and the same contribution requirements as human developers.

AI agents should:

- Inspect existing code before modifying it.
- Follow the current implementation plan.
- Avoid replacing working implementations without a clear reason.
- Avoid making assumptions about undocumented requirements.
- Explain significant architectural decisions.
- Add tests for newly implemented functionality.
- Report errors and incomplete work honestly.
- Never claim that an implementation is complete without verification.

AI-generated code must be reviewed and tested before being accepted.

## 13. Scope and Priorities

Contributions should prioritize:

1. Data accuracy and reliability.
2. Security and privacy.
3. Core scholarship discovery functionality.
4. Correct eligibility calculations.
5. Clear application guidance.
6. Multilingual accessibility.
7. Performance and usability.
8. Additional enhancements.

Avoid introducing unnecessary features or dependencies that increase complexity without providing meaningful value.

## 14. Questions and Clarifications

If a requirement is unclear:

- Check the existing project documentation.
- Review related implementations.
- Identify the exact ambiguity.
- Ask for clarification instead of making assumptions.

When proposing a new feature or architectural change, explain its purpose, benefits, limitations, and impact on the existing system.

---

**Project:** Claim What's Yours

**Contribution Principle:** Every contribution should improve the platform without compromising scholarship data accuracy, student privacy, security, or reliability.
