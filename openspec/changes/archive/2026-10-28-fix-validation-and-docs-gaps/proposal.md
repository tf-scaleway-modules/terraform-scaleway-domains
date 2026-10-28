# Proposal

## Why

Writing the baseline specs surfaced six inconsistencies between the code, its descriptions and its documentation. Two make the documented usage fail (no project resolved, `register_domain` without `registration`), one silently ignores accepted inputs, one accepts names the documentation forbids, and two are misleading comments or wording. All are fixable without breaking a configuration that works today.

## What Changes

Each issue was checked against the code and, for issue 3, against the provider schema (`scaleway_domain_registration`, provider 2.86).

| # | Issue | Decision | Breaking |
|---|-------|----------|----------|
| 1 | `coalesce(var.project_id, try(data...[0].id, null))` fails when nothing resolves a project, although the documentation and `examples/minimal` rely on the provider default | Code fix: replace `coalesce` by a conditional so the result is `null` | No (only configs that already errored) |
| 2 | The `registration != null` precondition can never fire: `var.registration.duration_in_years` is evaluated first and fails with a provider-agnostic attribute error | Code fix: remove the precondition, add a cross-variable `validation` on `register_domain` with the intended message | No (only configs that already errored) |
| 3 | `administrative_contact_id` and `technical_contact_id` are accepted and never used. The provider has no such arguments: `administrative_contact` and `technical_contact` are computed-only | Doc fix plus `check` warning: keep the attributes, describe them as deprecated and ignored, warn when set. Removal is left to the next major | No |
| 4 | `project_name` validation `\|\| length(...) == 1` accepts any single character | Code fix: regex `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$` | No for any name the documented rule allows; rejects only a one-character uppercase or digit name, which contradicts the documented rule |
| 5 | Comment says the record key is `{type}_{name}`, code appends `_{idx}`; reordering the list replaces records | Doc fix: correct the comment, document the key in the `records` description and README. Keying is unchanged, changing it would force replacement of every record | No |
| 6 | `weighted` and `view` called "Weighted Load Balancing" | Doc fix: "Weighted DNS routing" in README, comments, example and spec | No |

State: nothing new lands in state. Inline `owner_contact` fields (name, email, phone, address) are personal data already stored by the provider; no secret is involved, so `SECURITY.md` is not created.

Semver (terraform-versioning): **patch**. Every change is a fix, a description or a documentation change; no input or output is removed, renamed or re-defaulted, and no resource address changes.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `module-contract`: project resolution when nothing resolves a project; single-character `project_name` validation.
- `domain-registration`: `register_domain` without `registration` rejected by a validation; ignored contact IDs warn.
- `dns-records`: record key documented including its index consequence; "Weighted load balancing" renamed "Weighted DNS routing".

## Impact

- Modified: `locals.tf`, `main.tf`, `variables.tf`, `README.md` (outside the terraform-docs block), `examples/complete/main.tf` (wording only), and the three specs above.
- Added: `tests/main.tftest.hcl`.
- Module consumers: configs that errored now plan; a registration passing the two contact IDs sees a plan warning.
