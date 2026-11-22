# Deterministic Eligibility Engine

**Status:** Proposed; not approved. This design has not been approved for implementation. Rule schema, renewal handling and open questions below remain unresolved.

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

## Logical Structure

Rules are structured JSON, not free text. A rule is composed of the following logical operators:

- `all`: every condition in the group must hold.
- `any`: at least one alternative in the group must hold.
- `not`: an explicit exclusion. If the wrapped condition matches, the exclusion applies.

Groups may be nested, as described in `docs/research/phase-1-research.md` (section 5, "Recommended rule shape"). Each leaf condition uses a typed field and an operator.

## Mandatory and Alternative Conditions

Each condition is classified as either:

- **Mandatory:** must be satisfied for the rule to produce `eligible`.
- **Optional within a group:** an alternative inside an `any` group, or otherwise not required on its own.

Handling of a missing optional condition:

- A missing profile value for an optional condition must not be treated as `false`.
- If the optional condition cannot be evaluated, its branch is recorded as unknown, and the result follows the uncertainty rules below.
- An unknown alternative branch must never be counted as a failed branch.

## Exclusion Conditions

- A matched exclusion (`not`) makes the result `ineligible`.
- Exclusions are evaluated before any positive (eligibility) conclusion is reached.
- Result precedence is defined in `spec.md`, section 9.4 (Evaluation Logic): `ineligible` is checked first, then `needs_more_information`, then `uncertain`, then `eligible`. The research document states that exclusions are evaluated before an eligible conclusion, but `spec.md` does not explicitly list exclusions in its precedence. Verify against spec.md.

## Comparison Types

### Numerical comparisons

Supported numerical operators (from `spec.md`, section 9.3): `equals`, `not_equals`, `greater_than`, `greater_than_or_equal`, `less_than`, `less_than_or_equal`, `between`.

- Boundary values must use inclusive or exclusive comparisons explicitly. The rule must state the bound type for every `between` condition. No default is assumed.
- Generic examples only (placeholder values, not real thresholds):
  - `greater_than_or_equal` with `<threshold>`: the profile value must be greater than or equal to `<threshold>`.
  - `less_than` with `<threshold>`: the profile value must be strictly less than `<threshold>`.
  - `between` with `<lower>` and `<upper>`, lower bound inclusive, upper bound exclusive (bound types must be stated in the rule).

### Categorical comparisons

Supported categorical operators (from `spec.md`, section 9.3): `equals`, `not_equals`, `in`, `not_in`, `contains`.

- Generic examples only:
  - `equals` with `<category>`: the profile value must equal `<category>`.
  - `in` with `[<category_a>, <category_b>]`: the profile value must be one of the listed categories.

Presence and boolean checks (`is_present`, `is_true`, `is_false`) are also supported by `spec.md`.

## Missing Information

- If a mandatory condition references a profile field that is missing, the result is `needs_more_information`.
- The result must name the missing field(s) explicitly.
- A missing field must never be silently treated as satisfied or as failed.

## Uncertain and Incomplete Rules

- A rule with status `unverified` yields `uncertain`.
- A rule with a missing source reference yields `uncertain`.
- A rule that is incomplete, ambiguous or conflicting yields `uncertain`.
- Unknown branches are never treated as false.

## Per-Condition Source References

Every condition must reference:

- its source document,
- its source section,
- its verification status.

A condition without a source reference cannot produce a confirmed result. Any evaluation that depends on such a condition must return `uncertain`.

## Academic-Year and Rule-Version Tracking

- Each rule has a version and an academic year (or applicable period).
- Each evaluation result must record the rule version used.
- Conditions about academic years are compared against the rule version's academic year, not the current calendar year (per `docs/research/phase-1-research.md`, section 5).
- Evaluating a rule against a profile for a different academic year than the rule's academic year must be flagged in the result.

## Renewal Conditions

- Renewal conditions are a separate rule type, with their own source reference and verification status.
- The document shape for renewal conditions is UNRESOLVED and must be decided in Phase 2.
- No renewal rules are defined in this document.

## Open Questions

- **UNRESOLVED (a):** Exact schema for rule representation.
- **UNRESOLVED (b):** Evaluation of renewal conditions.
- **UNRESOLVED (c):** How to represent ambiguous or conflicting official wording.
- **UNRESOLVED (d):** Age threshold, if any. Any age-based condition requires legal review before it is encoded.

