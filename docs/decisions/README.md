# Architecture Decision Records

Architecture decision records will be added here when a relevant decision is finalized. Use `adr-template.md` in this folder as the starting point for each new record, named `NNNN-short-title.md` (for example `0001-llm-provider.md`).

No provider or implementation choice is final solely because it appears in a code example or draft.

## Status Rules

No ADR may be marked Accepted until its decision is recorded in this folder and the related entry in Known Unresolved Decisions has been removed or marked resolved.

## Known Unresolved Decisions

- LLM provider and model.
- Embedding model, if vector retrieval is used.
- Cloud provider.
- Object-storage provider.
- Authentication and verification provider.
- Guardian consent and verification workflow.
- Email, SMS or push notification provider.
- Initial verified scholarship dataset.
- Government API or downloadable-dataset availability.
- Production performance targets.
- Data-retention policy.
- Project software license.
- Specific LLM provider and model (currently: candidates Gemini API, OpenAI; not chosen).
- Authentication provider and implementation (Firebase Auth, Supabase Auth and JWT are all options; none selected).


## Phase 1 Research-Backed Recommendations

Rows marked Approved were approved by the user. All other rows are proposals or unresolved and are not accepted decisions.

| Decision | Status | Proposed recommendation | Key evidence |
|---|---|---|---|
| Backend framework | Approved (user decision) | Python + FastAPI | User approval; modular monolith for the MVP |
| Database | Approved (user decision) | PostgreSQL | User approval |
| Authentication | UNRESOLVED | Managed provider is one option; Firebase Authentication, Supabase Auth and JWT are options under evaluation; not decided | [Phase 1 research](../research/phase-1-research.md) |
| LLM provider | UNRESOLVED | Gemini API and OpenAI are candidate options only; not chosen; neither evaluated for Telugu, Hindi or English quality | [Phase 1 research](../research/phase-1-research.md) |
| Embeddings/RAG | Proposed baseline (keyword retrieval); embeddings UNRESOLVED | PostgreSQL full text first, untested for Telugu and Hindi; defer embeddings and vector infrastructure | [Phase 1 research](../research/phase-1-research.md) |
| Cloud hosting | Unresolved | Render or another provider-neutral managed container option; not approved | [Phase 1 research](../research/phase-1-research.md) |
| Object storage | Proposed | S3-compatible private storage such as Cloudflare R2 | [Phase 1 research](../research/phase-1-research.md) |
| Notifications | Unresolved | In-app first; defer SMS/push | [Phase 1 research](../research/phase-1-research.md) |
| Guardian consent | Unresolved | Require a privacy-specific design and review | [Phase 1 research](../research/phase-1-research.md) |
| Initial dataset | Proposed | Small set of manually verified official NSP/ePASS/Telangana schemes | [Phase 1 research](../research/phase-1-research.md) |
| Government API strategy | Proposed | Resource-specific APIs only; PDF/web/manual fallback | [Phase 1 research](../research/phase-1-research.md) |
| Data retention | Unresolved | Require policy and legal review | [Phase 1 research](../research/phase-1-research.md) |
| Project license | Unresolved | Defer until ownership and distribution requirements are known | Existing unresolved register |

