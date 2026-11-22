# Phase 1 Technical and Data-Source Research

**Research date:** 2026-11-21  
**Repository phase:** Phase 1 - Technical Research and Decision Finalization  
**Scope:** Evidence-based research only. No provider, dataset or cloud decision is considered approved until a user explicitly confirms it.

Status: Draft for independent review. Not approved. Phase 1 remains In Review.

## 1. Research Method

Official sources were investigated before secondary sources. A claim is classified as Verified only when it is supported by an official portal, official document or official API documentation. Classification labels: Verified; Partially verified; Unverified; Inaccessible.

Source types used:

- **Confirmed official API:** an official body publishes API documentation or a working resource API contract.
- **Official downloadable dataset:** an official body publishes a machine-readable or downloadable resource.
- **Public webpage:** information is accessible publicly but no general-purpose API was established.
- **Official document/PDF:** an official scheme owner publishes a notice or guideline.
- **Manual collection:** information may be reviewed and entered only after source terms and access restrictions are checked.
- **Restricted or inaccessible:** the source requires authentication or evidence could not be verified.

This report distinguishes facts, recommendations and unresolved decisions. Existing specification requirements take precedence over this research.

## 2. Official Data-Source Inventory

### 2.1 Telangana ePASS

- **Official URL:** https://telanganaepass.cgg.gov.in/
- **Access date:** 2026-11-21
- **Source owner:** Centre for Good Governance; the portal states that content is owned and maintained by the Government of Telangana Social Welfare Department.
- **Source type:** Public application and information portal.
- **Available information:** The portal describes application prerequisites and document requirements for 2026-27. It also identifies scholarship-related services and post-matric, pre-matric and category-specific support.
- **Eligibility evidence:** Public 2026-27 instructions identify Aadhaar, caste and income certificates, bank information, bonafide certificates, course admission records and category-specific application pathways. These are application prerequisites, not a complete normalized eligibility rule set for every scheme.
- **Documents:** Some official forms and instructions are public. Some application workflows require student authentication and use of government systems.
- **API:** No confirmed public general-purpose API was established.
- **Automation:** No API or documented machine-readable scheme catalog was found. Permitted public-page or PDF collection may be considered later only after robots policy, terms, technical restrictions and source owner guidance are checked.
- **Update behavior:** Academic-year application instructions change; current-year and historical information should be stored as versions.
- **Classification:** Partially verified. Publicly accessible application portal plus official PDFs; manual verification required.

Important: ePASS application prerequisites must not be represented as universal scholarship eligibility rules.

### 2.2 National Scholarship Portal

- **Official URL:** https://scholarships.gov.in/
- **Scheme list:** https://scholarships.gov.in/m/All-Scholarships
- **Access date:** 2026-11-21
- **Legal/usage terms:** Terms could not be located in this research; any reliance on NSP terms is Unverified and requires review. Robots restrictions also require separate verification before automation.
- **Source type:** Public scholarship scheme portal and scheme guideline host.
- **Available information:** The portal identifies central-sector and state schemes, academic-year application windows, verification stages, public scheme specifications and links to guidelines/FAQs.
- **Eligibility evidence:** Individual scheme specification PDFs are the authoritative source for scheme eligibility, benefit and deadline fields.
- **Documents:** Official PDFs are publicly linked for many schemes.
- **API:** No general-purpose public NSP scheme API or official API documentation was established.
- **Automation:** Terms could not be located in this research; any reliance on NSP terms is Unverified and requires review. Automated collection should not be introduced solely from this research; robots policy, source terms and technical restrictions require separate verification.
- **Historical access:** The portal exposes current academic-year information. Historical scheme and guideline availability must be checked by scheme and academic year.
- **Classification:** Partially verified. Public webpage and official PDF source; manual verification; any collection only where terms are verified.

### 2.3 Telangana Open Data Portal

- **Official portal:** https://data.telangana.gov.in/
- **Official API page:** https://data.telangana.gov.in/datasets/api
- **Official overview:** https://it.telangana.gov.in/initiatives/open-data/
- **Open Data Policy:** https://it.telangana.gov.in/wp-content/uploads/2016/10/Telangana-Open-Data-Policy1.pdf
- **Access date:** 2026-11-21
- **Source type:** Official state open-data portal.
- **Findings:** The portal's statements about its number of datasets and APIs are Unverified and are not used as facts. The overview does not establish that a scholarship-eligibility dataset exists. No scholarship dataset identified.
- **Data suitability:** Searchable datasets may support contextual counts or grant information, but should not be treated as authoritative scheme rules without publisher and scheme verification.
- **API:** The portal states it exposes APIs for select datasets (Unverified for this research); each resource must be checked individually.
- **Classification:** Unverified. No relevant dataset, dataset identifier or access condition has been confirmed; no scholarship eligibility dataset identified.

### 2.4 data.gov.in

- **Official portal:** https://www.data.gov.in/
- **API documentation example:** https://www.data.gov.in/backend/dataapi/v1/swagger/fbc5a7c0-277a-47b9-97b4-545ddf9bbc18
- **Access date:** 2026-11-21
- **Source type:** Official government open-data platform with resource-level API documentation for select datasets.
- **API behavior:** Swagger documentation shows resource-specific APIs, API-key access and JSON/XML/CSV outputs. The one example Swagger reference given does not identify a scholarship resource. API keys and limits are governed by the portal.
- **License:** Published datasets and metadata are under the Government Open Data License - India, subject to individual resource terms.
- **Scholarship evidence:** The platform may contain scholarship statistics or scheme release information, but no scholarship dataset identified in this document. A reported Karnataka pre-matric resource (no API) and a reported Merit-cum-Means resource (API documentation) have no dataset identifier or resource ID recorded here and are Unverified.
- **Classification:** Partially verified. The platform and its API reference exist; no scholarship dataset, dataset identifier or resource ID has been confirmed, and it is not a scholarship catalogue.
- **MVP use:** Do not ingest a dataset unless the publisher, resource purpose, update cadence and relation to current eligibility rules are verified.

### 2.5 Ministry of Education / UGC / AICTE

- **Ministry education scholarships:** https://www.education.gov.in/en/scholarship
- **NSP official link:** https://www.education.gov.in/en/national-scholarship-portal
- **UGC student and scholarship page:** https://www.ugc.gov.in/Home/student_Corner
- **AICTE schemes:** https://www.aicte.gov.in/index.php/node/3407
- **AICTE 2026-27 notification:** https://www.aicte.gov.in/sites/default/files/Notification%20A.Y.%202026-27.pdf
- **Access date:** 2026-11-21
- **Source type:** Official scheme-owner information and annual notifications.
- **Findings:** AICTE publishes 2026-27 notifications and directs applicants through NSP. UGC publishes scheme and fellowship information. Scheme rules should be copied from the current official specification or guideline, not secondary summaries.
- **API:** No confirmed general-purpose scheme API was established for these owner sites.
- **Classification:** Partially verified for the listed official pages and PDF URLs. Any API or dataset from these owners is Unverified.

### 2.6 Official Telangana Welfare and Technical Education Notices

- The Directorate of Technical Education is reported to host PDF notices and Government Orders on post-matric scholarships and 2026-27 implementation. No URL or publication date has been established. Classification: Unverified.
- A 2026 Telangana notice with a reported family-income ceiling of 2.5 lakh is UNVERIFIED: no official notice (URL, publication date, issuing body) has been established. The figure is not used in any rule. Classification: Unverified.
- Any such notice, once verified, is academic-year-specific. It must remain versioned and must not be extrapolated to every Telangana scholarship.
- Exact source URLs and publication dates must be retained in the scholarship record. A PDF record should not be published until the complete document is verified.

### 2.7 Source verification status

| Source | Official URL given | Dataset or resource ID | Documentation | Access conditions | Classification | Collection method class |
|---|---|---|---|---|---|---|
| Telangana ePASS | Yes (https://telanganaepass.cgg.gov.in/) | Not established | Application prerequisites and official forms/PDFs; no API | Some workflows require student authentication; terms not established | Partially verified | (3) Official government webpage or PDF |
| National Scholarship Portal | Yes (https://scholarships.gov.in/) | Not established | Scheme specification PDFs; no API documentation | Terms could not be located; any reliance is Unverified and requires review | Partially verified | (3) Official government webpage or PDF |
| Telangana Open Data Portal | Yes (https://data.telangana.gov.in/) | Not established | API page listed (https://data.telangana.gov.in/datasets/api); not reviewed per resource | Not established; each resource must be verified | Unverified | (7) Unverified |
| data.gov.in | Yes (https://www.data.gov.in/) | Not established; no scholarship resource identified | Swagger reference (one example URL given); platform API reference | Government Open Data License - India, subject to resource terms; API keys governed by the portal | Partially verified | (7) Unverified for scholarship data; (1) only if a specific resource contract is confirmed |
| Ministry of Education (NSP link, scholarship page) | Yes (https://www.education.gov.in/en/scholarship) | Not established | Official scheme information pages | Not established | Partially verified | (3) Official government webpage or PDF |
| AICTE | Yes (https://www.aicte.gov.in/index.php/node/3407; 2026-27 notification PDF URL) | Not established | Annual notification PDF; scheme pages | Not established | Partially verified | (3) Official government webpage or PDF |
| UGC | Yes (https://www.ugc.gov.in/Home/student_Corner) | Not established | Scheme and fellowship pages | Not established | Partially verified | (3) Official government webpage or PDF |
| Telangana Directorate of Technical Education notices | Not established | Not established | Reported PDF notices and Government Orders | Not established | Unverified | (7) Unverified |
| 2026 Telangana post-matric income-ceiling notice | Not established | Not established | Not established | Not established | Unverified | (7) Unverified. Reported figure; not used in any rule |

## 3. Source Availability Matrix

| Source | Confirmed public webpage | Confirmed official document/PDF | Confirmed API/dataset | Current eligibility catalogue | Recommended MVP treatment |
|---|---:|---:|---:|---:|---|
| Telangana ePASS | Yes | Application instructions | No general API found | Partial application prerequisites | Manual, verified review; no assumptions |
| National Scholarship Portal | Yes | Yes, scheme specifications | No general API found | Scheme index and PDFs | Public listing plus verified PDF ingestion |
| Telangana Open Data | Yes | Policy and data formats | Select datasets/APIs stated (Unverified) | Not confirmed for scholarships | Search individual datasets; do not assume eligibility |
| data.gov.in | Yes | CSV/XLSX/JSON/XML resources | Resource-specific API documentation exists; no scholarship resource identified | Historical/statistical, not comprehensive | Use only verified publisher datasets |
| AICTE | Yes | Annual notices and scheme PDFs | No general API found | Scheme-specific | Verify and manually or semi-automatically ingest |
| UGC | Yes | Guidelines and pages | No general API found | Scheme-specific | Verify and ingest by academic year |
| Central ministries | Yes | Guidelines vary | Unconfirmed | Scheme-specific | Manual source review first |

## 4. Recommended MVP Data-Collection Strategy

### 4.1 Priority order

1. **Official verified documents and PDFs**
   - Use after the source and document authority are confirmed.
   - Store the original URL, retrieval date, publisher, academic year, hash and effective dates.
   - Keep the raw file in object storage and extracted text in PostgreSQL.

2. **Official resource APIs**
   - Integrate data.gov.in only when a specific resource is relevant and the resource has a confirmed API contract.
   - Use Telangana Open Data only for resources whose publisher and field meanings have been verified.
   - Do not use a resource just because it contains a word such as "scholarship".

3. **Public webpage collection, only where terms allow**
   - Consider for public NSP and official ministry pages only after NSP terms (Unverified) and robots policy are reviewed.
   - Revalidate robots policy, terms and page structure before implementation.
   - A public URL does not imply permission for unrestricted scraping or reuse.

4. **Structured administrator entry**
   - Use for small high-value MVP scheme sets.
   - Every field must retain the source URL and supporting document reference.
   - Admin approval is required before publication.

Manual review and verification should remain the primary fallback. Automated extraction should never be the authority for rules.

### 4.2 Practical ingestion workflow

1. Source registration.
2. Document or page retrieval.
3. Raw artifact preservation.
4. Text and structured-field extraction.
5. Pydantic schema validation.
6. Duplicate detection using normalized name, owner, academic year and source URL.
7. Conflict detection across sources.
8. Pending validation and human verification.
9. Approval and publication.
10. Versioned update or withdrawal.

### 4.3 Version and publication rules

Every record should retain:

- Academic year.
- Effective start and end dates.
- Application start and deadline dates.
- Source URL and document ID.
- Source publisher.
- Retrieval and verification timestamps.
- Verifier identity.
- Previous version reference.
- Change summary.
- Publication status.

Withdrawals should create a new archived version rather than deleting old source evidence.

## 5. Eligibility-Rule Research

Scholarship rules commonly include (uncited):

- State or domicile.
- Social category.
- Family income.
- Education level.
- Course, degree or institution.
- Academic performance.
- Gender.
- Disability status.
- Previous award or renewal status.
- Course type, quota or admission basis.
- Attendance.
- Institution recognition.
- Age.
- Income certificate year or evidence date.
- Academic-year-specific exceptions.

Illustrative only; no scheme rule is established by this document.

The representation should support structured JSON rules rather than free text alone.

### Recommended rule shape

Use:

- `all`: all conditions must pass.
- `any`: at least one alternative must pass.
- `not`: explicit exclusion.
- Typed fields and operators.
- Rule versions.
- Source references per condition or rule.
- Effective academic-year range.
- Optional/mandatory classification.
- `needs_more_information` behavior.
- `uncertain` behavior for incomplete, conflicting or unverified rules.

Supported initial operators are already specified in `spec.md`: equals, not-equals, numerical comparisons, membership, between, contains and presence/boolean checks.

### Missing and uncertain outcomes

- Missing a mandatory field produces `needs_more_information`.
- A verified mandatory condition that fails produces `ineligible`.
- An incomplete, ambiguous or unverified mandatory rule produces `uncertain`.
- Explicit exclusions should be evaluated before an eligible conclusion.
- Unknown alternative branches must not be treated as false.
- Boundary values must use inclusive/exclusive comparisons explicitly.
- Academic-year conditions must be compared against the rule version, not the current calendar year.

No eligibility example should be encoded from this document. The reported 2026 Telangana post-matric framework is Unverified and must not be encoded until its official notice is established, source review and testing are complete.

## 6. AI and Multilingual Technology Research

### Provider comparison

| Provider/approach | Strengths | Risks/limits | MVP suitability |
|---|---|---|---|
| Google Gemini API | Structured JSON output support reported in the research, not verified against dated official documentation; Pydantic/Python integration reported; multilingual quality claimed, not evaluated. | Model, rate limit and data-retention terms vary by API tier and account; none established with a dated official source | Candidate option; not evaluated for Telugu, Hindi or English quality. |
| OpenAI API | Structured-output support reported in the research; not verified against dated official documentation; Pydantic helpers; replaceable SDK | Cost, vendor data handling and model lifecycle | Candidate option; not evaluated for Telugu, Hindi or English quality. |
| Azure OpenAI / hosted enterprise models | Enterprise controls and regional deployment options | More setup cost and regional/model availability may require approval | Consider for privacy or enterprise deployment |
| AWS Bedrock | Multiple models and AWS-native controls | Integration and model choice are more complex for an MVP | Consider later if AWS is selected |
| Self-hosted/open model | Maximum provider control; can run in controlled infrastructure | GPU/operations cost, quality and multilingual maintenance | Not recommended for the initial MVP |

Gemini and OpenAI both publicly document structured output constrained by JSON Schema. Provider quality, Telugu/Hindi accuracy and exact model availability must be measured on the project's actual extraction test set.

### Embedding and RAG

- PostgreSQL full-text search should be the initial retrieval mechanism.
- Embedding/vector search should be deferred until enough verified source documents show that full-text search is insufficient.
- If embeddings are introduced, use a provider-independent embedding interface.
- Store source document ID, scholarship version, source URL and retrieval verification state with every embedding or chunk.
- Any vector or full-text index must be rebuilt or invalidated when a verified source version changes.

### Recommendation

Proposed recommendation, not final approval:

- **LLM:** configurable Gemini API integration for the MVP, with OpenAI-compatible abstraction and no provider-specific eligibility logic.
- **Structured extraction:** Pydantic schemas and strict JSON output; user confirmation required before profile storage.
- **RAG:** PostgreSQL full-text retrieval initially.
- **Embeddings:** unresolved; Gemini or OpenAI embeddings may be compared in a provider-neutral spike after the MVP retrieval baseline exists.

Official evidence:

- Google Gemini structured outputs: https://aistudio.google.com/docs/structured-output
- OpenAI structured outputs: https://developers.openai.com/api/docs/guides/structured-outputs
- Google Vertex AI text embeddings: https://docs.cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text-embeddings-api

## 7. Cloud, Database, Authentication and Storage Research

### 7.1 Hosting and PostgreSQL

Options investigated:

- **Render:** FastAPI web service, background workers and managed PostgreSQL in one provider. Pricing varies by instance and free-tier limits.
- **Neon:** managed PostgreSQL with scale-to-zero and a free tier. It has no application hosting; a separate backend host is required.
- **Supabase:** managed PostgreSQL plus optional auth and storage. It can reduce MVP integration work but couples more platform services to the project.
- **AWS/Azure/Google Cloud:** strong production controls and regional options, but more deployment and operational complexity for a hackathon-sized MVP.

Proposed recommendation:

- Development and staging: Neon or Supabase database, subject to provider approval and data-residence review.
- Backend: Render or a small managed container platform for MVP deployment.
- Do not make application logic assume a managed database vendor.

At the time of research, Render documented web services, background workers and PostgreSQL at https://render.com/pricing and https://docs.render.com/postgresql. Neon pricing is documented at https://neon.com/pricing.

### 7.2 Authentication

Options investigated:

- **Firebase Authentication:** Flutter SDK support, email/password and federated providers, Identity Platform for MFA and advanced audit features.
- **Supabase Auth:** PostgreSQL-centric auth and Flutter integration.
- **Auth0:** managed identity, broad enterprise features and higher cost/operational complexity.
- **Self-hosted JWT:** fully controlled, but the project must build and maintain password reset, verification, token storage, MFA, session revocation and abuse controls.

Firebase official documentation: https://firebase.google.com/docs/auth

Proposed MVP recommendation:

- Use a standard managed authentication provider that supports Flutter and Flutter Web.
- Recommend Firebase Authentication with email/password for a small MVP, subject to explicit approval and privacy review.
- OTP/phone authentication should not be enabled until consent, cost and abuse-control requirements are approved.
- The FastAPI backend must continue to verify identity tokens server-side and enforce authorization itself.

### 7.3 Object storage

Options investigated:

- **Cloudflare R2:** S3-compatible API and zero egress fees; suitable for source PDFs and private document metadata.
- **Supabase Storage:** integrated with Supabase Auth and PostgreSQL, but adds platform coupling.
- **AWS S3/Azure Blob/Google Cloud Storage:** mature, region-selectable and suitable for production; more configuration.
- **MinIO:** S3-compatible and controllable, but adds operations.

Proposed recommendation:

- Cloudflare R2 or an equivalent S3-compatible provider for the MVP, subject to approval and private-bucket security review.
- Keep file metadata and verification state in PostgreSQL.
- Use short-lived signed URLs for authorized document access.

Official R2 documentation: https://www.cloudflare.com/products/r2/

### 7.4 Notifications

No notification provider is selected. For MVP:

- Start with in-app notifications and user reminders.
- Add email through a dedicated provider later if required.
- Defer SMS/OTP and push notifications until volume, cost and consent requirements are known.

## 8. Security, Privacy and Compliance Findings

### 8.1 Data minimization

Collect and retain only fields necessary for scholarship discovery and eligibility. Aadhaar and bank account credentials must not be added to basic profiles.

### 8.2 Minor users and guardians

The project should treat minors as a sensitive user population. Guardian access should require a documented relationship, verifiable consent and server-side authorization.

Official DPDP Act and rules sources:

- Official Gazette: https://egazette.gov.in/WriteReadData/2023/247847.pdf
- Ministry of Electronics and Information Technology DPDP Rules: https://www.meity.gov.in/documents/act-and-policies/digital-personal-data-protection-rules-2025-gDOxUjMtQWa

The rules require verifiable parental consent for personal-data processing involving children and emphasize consent notice, purpose limitation, and data-principal rights. The exact commencement and enforcement details require checking the final official rules and legal guidance.

### 8.3 LLM privacy

Before provider approval:

- Define whether profile text is retained by the provider.
- Request zero or minimized retention where available.
- Prohibit real profile data in provider training if the provider/plan permits training.
- Configure API keys outside source code.
- Send only required fields and approved scholarship excerpts.
- Record provider, model and processing purpose.

### 8.4 Uploaded documents

- Use private storage.
- Validate MIME type, size and malware risk.
- Expose only through server authorization and short-lived signed URLs.
- Define deletion and retention procedures.
- Do not store Aadhaar or bank documents unless a later approved feature justifies them.

### 8.5 Logging and backups

- Redact names, profile values, documents and tokens from logs.
- Maintain audit logs for scholarship publication and admin authorization.
- Back up PostgreSQL separately from object storage.
- Define recovery point and recovery time targets only after expected usage is known.

### 8.6 Legal status

The engineering conclusions above are not legal advice. Data-retention periods, guardian consent, child verification and compliance scope require review by a qualified India data-protection professional where the platform becomes a production service.

## 9. Decision Matrix

| Decision area | Options investigated | Proposed recommendation | Status | Cost/operational implications | Risk |
|---|---|---|---|---|---|
| Backend framework | FastAPI, Django, Flask | FastAPI | Proposed baseline; implementation may proceed after user review | Lightweight async API and FastAPI ecosystem | Confirmed by existing specification |
| Database | PostgreSQL managed by Neon, Supabase or cloud; local PostgreSQL | PostgreSQL as required; Neon or Supabase only for MVP staging, pending approval | Proposed | Usage-based or fixed plans; scale-to-zero may affect latency | Provider lock-in and regional/privacy terms |
| Authentication | Firebase Auth, Supabase Auth, Auth0, self-hosted JWT | Firebase Auth for MVP, subject to approval | Unresolved | Managed MAU/SMS/MFA charges | OTP abuse, minors, account recovery |
| LLM provider | Gemini, OpenAI, Azure OpenAI, AWS Bedrock, self-hosted | Gemini API as configurable MVP candidate; preserve provider interface | Proposed | Usage-based; free tiers change frequently | Retention, model drift, multilingual quality |
| Embedding model | PostgreSQL full text; Gemini embeddings; OpenAI embeddings | PostgreSQL full text now; embeddings unresolved | Proposed | Adds storage/embedding and reindex operations | Low-quality retrieval and version drift |
| RAG retrieval | PostgreSQL full text, managed search, vector DB | PostgreSQL full text for MVP | Proposed | Low operational complexity | Adequacy must be tested |
| Cloud hosting | Render, Fly.io, Railway, AWS, Azure, Google Cloud | Render or a comparable managed container host for MVP | Proposed, unresolved | Monthly instance cost plus database/object storage | Vendor lock-in and regional availability |
| Object storage | Cloudflare R2, S3, Azure Blob, Supabase, MinIO | Cloudflare R2 or S3-compatible provider | Proposed, unresolved | Storage/operations low; private access and signed URLs | Provider egress, bucket security |
| Notifications | In-app, email, SMS, push | In-app and email later; no SMS/push initially | Proposed | SMS/push require ongoing provider cost | Consent, cost and abuse |
| Guardian consent | Built-in relationship verification, self-managed consent, provider-assisted identity | Deferral to a privacy-specific ADR until requirements are established | Unresolved | Verification, audit and legal review | Minor-user and authorization risk |
| Initial scholarship dataset | ePASS, NSP, state PDFs, data.gov.in, Telangana Open Data | Start with a small manually verified set of official NSP/official Telangana schemes | Proposed, unresolved | High human verification cost | Incorrect publication |
| Government APIs | data.gov.in resource APIs, Telangana data APIs, NSP/no confirmed API | API only for confirmed resource contracts; otherwise PDF/manual workflows | Proposed | API keys, limits and maintenance | False API assumptions |
| Data retention | Short-term profiles, policy-derived periods, legal review | Deferral pending production requirements and legal review | Unresolved | Storage and deletion processes | Compliance and privacy risk |

## 10. Risks and Limitations

- Official website content may change without notice.
- No source established a comprehensive, stable, free NSP API.
- The Telangana Open Data and data.gov.in portals expose resource-specific content; each resource must be verified.
- AI language quality for Telugu and Hindi must be tested.
- Structured output does not validate semantic correctness.
- Cloud prices and free tiers change; exact spend should be reconfirmed before purchase.
- DPDP implementation details require legal and regulatory review.
- The technical research is evidence sufficient for planning but not approval.

## 11. Phase 1 Conclusion

Phase 1 research is sufficient to document:

- The official-source inventory.
- The lack of a confirmed NSP/ePASS general-purpose API.
- Resource-specific API documentation on data.gov.in, with no scholarship resource identified.
- A practical PDF/web/manual ingestion strategy.
- Deterministic eligibility-rule requirements.
- Provider-independent AI integration needs.
- MVP-oriented provider options.
- The unresolved decisions that require explicit approval.

No application code or provider account is created. No recommendation is considered approved until the user confirms it.

