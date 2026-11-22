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

## Phase 1 Research Results

- Gemini and OpenAI JSON-schema/structured-output support: Unverified; to be confirmed from the official documentation at implementation evaluation.
- Gemini API and OpenAI are candidate options only, not decisions. Neither is evaluated for Telugu, Hindi or English quality. Profile-extraction suitability is not yet evaluated; it requires a Telugu and Hindi evaluation set (see docs/testing-strategy.md) before any provider is chosen.
- PostgreSQL full-text search is a PROPOSED baseline for keyword retrieval only. Its suitability for Telugu and Hindi retrieval is untested and must be evaluated before it is relied upon.
- Embeddings and a vector database are deferred until evidence shows that full-text retrieval is insufficient. Embedding model and retrieval approach beyond this baseline: UNRESOLVED.
- Specific LLM provider and model: UNRESOLVED.
- Every provider integration must remain behind an abstraction and must not participate in final eligibility decisions.

Detailed evidence and provider trade-offs are recorded in [Phase 1 Research](research/phase-1-research.md).

