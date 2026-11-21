# Deterministic Eligibility Engine

## Authority

The eligibility engine is the sole authority for final scholarship eligibility decisions.

An LLM must not generate eligibility rules or make final eligibility decisions.

## Rule Evaluation

The engine must evaluate verified, versioned rules using documented profile fields and supported logical operations.

Required result states are:

- `eligible`
- `ineligible`
- `needs_more_information`
- `uncertain`

## Explainability

Every result must explain matched conditions, unmet conditions, missing fields and uncertainty caused by incomplete or unverified rules.

## Safety

- Mandatory conditions with missing profile data produce `needs_more_information` rather than eligibility.
- Unverified or incomplete rules produce `uncertain`.
- Rule versions used for an evaluation must be stored for reproducibility.
- Numerical boundaries, categorical values and invalid or inconsistent profile values require tests.

