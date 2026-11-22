# Data Pipeline

## Intended Pipeline

1. Collect source material using the method selected for that source (see [Supported collection methods](data-sources.md#supported-collection-methods)).
2. Extract text or structured fields.
3. Validate extracted fields.
4. Detect duplicate or conflicting records.
5. Preserve source references.
6. Submit changes for administrator verification.
7. Publish only approved, verified scholarship versions.

Record stages follow AGENTS.md section 7: collected, extracted, validated, pending verification, verified and approved, published, expired or archived.

## Collection Method Selection

Each source is assigned one collection method from the four supported methods, based on its verified access conditions:

- **Method 1, confirmed official API:** only where a specific resource's API contract is confirmed and the terms allow use.
- **Method 2, official downloadable dataset:** only where the publisher, terms and fields are verified.
- **Method 3, official government webpage or PDF:** only where the source's terms and robots/technical restrictions allow it; otherwise manual review.
- **Method 4, structured administrator-assisted manual entry:** every field keeps its source URL and document reference, and administrator approval is required before publication.

A source classified Unverified or Inaccessible is blocked from collection until it is classified. In the meantime, method 4 (administrator-assisted entry) may be used if approved.

## Extraction

The specification names Requests and BeautifulSoup for public HTML, Playwright for dynamic pages, and PyMuPDF for PDFs. These are candidate tools only. Their use for a given source is permitted only where that source's verified terms allow the selected collection method.

AI-assisted extraction may help produce structured drafts. It must not create final eligibility rules or publish unverified information.

## Reliability

Collection jobs must remain separate from normal API requests. Failure or change detection must not corrupt previously approved scholarship records.

## Evidence-Based MVP Strategy

For the initial implementation:

1. Start with structured manual entry and administrator review for a small set of verified official schemes.
2. Preserve each raw source PDF or official page, source URL, retrieval date and verification metadata.
3. Use resource-specific official APIs only after each API contract is individually confirmed.
4. Permit public-page collection only after source terms and robots/technical restrictions are verified.
5. Use Pydantic validation, duplicate detection and change detection before pending-verification state.
6. Publish only approved academic-year versions.

No general-purpose NSP or ePASS API should be assumed. No portal is assumed to permit scraping or to provide an API. AI-assisted extraction remains a draft stage only.

No scholarship information is published without human verification and a recorded official source reference.
