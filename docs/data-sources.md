# Scholarship Data Sources

Official government sources have priority.

Candidate sources listed in the specification include:

- Telangana ePASS
- National Scholarship Portal
- Ministry of Education
- Open Government Data Platform India

These are candidates, not verified data providers or guarantees of API availability.

## Research Findings (2026-11-21, draft)

Status: Draft for independent review. Not approved. Phase 1 remains In Review.

- Telangana ePASS (Partially verified; collection method 3): a public application and scheme portal. It publishes current application prerequisites and official documents, but no general-purpose public API was established.
- National Scholarship Portal (Partially verified; collection method 3): publishes a public scheme index and linked official PDF specifications. No general-purpose public scheme API was established. Terms could not be located in this research; any reliance on NSP terms is Unverified and requires review.
- Telangana Open Data (Unverified; collection method 7): the portal's stated dataset and API counts are not used as facts. No Telangana scholarship eligibility dataset, dataset identifier or access condition was confirmed during Phase 1 research. A relevant dataset and its access conditions must be verified first.
- data.gov.in (Partially verified; collection method 7 for scholarship data): the platform and its resource-level API reference (Swagger, API-key) exist. No scholarship dataset identified. A resource is not a usable source until publisher, fields, update frequency, access conditions and relevance are verified.
- AICTE and UGC (Partially verified for listed pages and PDFs; collection method 3): publish official notices and PDFs. Any API or dataset from these owners is Unverified.

For source evidence and collection limitations, see [Phase 1 Research](research/phase-1-research.md), including section 2.7 (Source verification status).

## Source Requirements

Every source record must identify:

- Official source URL.
- Collection method.
- Retrieval date.
- Publisher or authority.
- Verification state.
- Relevant document or notification reference.
- Record version and review history.

Before a source is used for implementation or ingestion, verify access terms, relevance, update frequency and permitted collection methods.

No scholarship information is published without human verification and a recorded official source reference.

## Supported collection methods

1. Confirmed official APIs.
2. Official downloadable datasets.
3. Official government webpages and PDFs.
4. Structured administrator-assisted manual entry.

Automated scraping and API use are permitted only where the source's terms allow them. No portal is assumed to permit scraping or to provide an API.
