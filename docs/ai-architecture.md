# AI Architecture

## Hybrid Model

AI services assist with:

- Natural-language profile understanding.
- Structured profile extraction.
- Telugu, Hindi and English assistance.
- Retrieval-grounded scholarship explanations.
- Document and application guidance.

The deterministic eligibility engine owns all final eligibility decisions.

## Provider Boundary

No LLM provider is selected. Implementations must depend on a provider-independent interface and configuration rather than provider-specific types or SDK behavior.

## Profile Extraction

Extracted values must be validated, confirmed by the student or authorized guardian, and kept separate from verified profile values until accepted.

Missing fields must remain unknown; they must not be inferred or fabricated.

## RAG Grounding

Generated answers must use approved scholarship content and preserve source references. Unsupported answers must state that reliable source information is unavailable.

## Safety

Protect against prompt injection and malicious retrieved content. Handle provider timeout and failure without preventing access to previously verified scholarship records.

