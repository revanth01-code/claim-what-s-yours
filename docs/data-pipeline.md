# Data Pipeline

## Intended Pipeline

1. Collect permitted source material.
2. Extract text or structured fields.
3. Validate extracted fields.
4. Detect duplicate or conflicting records.
5. Preserve source references.
6. Submit changes for administrator verification.
7. Publish only approved, verified scholarship versions.

## Extraction

The specification permits Requests and BeautifulSoup for public HTML, Playwright for dynamic pages, and PyMuPDF for PDFs. These technologies remain proposed until the relevant technical research is completed.

AI-assisted extraction may help produce structured drafts. It must not create final eligibility rules or publish unverified information.

## Reliability

Collection jobs must remain separate from normal API requests. Failure or change detection must not corrupt previously approved scholarship records.

