## Context

The baseline specs deliberately left these inconsistencies unspecified. Resources involved: `scaleway_domain_registration.this`, `scaleway_domain_record.this`, the `scaleway_account_project` data source. No provider version change: all arguments used exist in `~> 2.86`.

## Decisions

- **Project ID (issue 1).** `local.project_id = var.project_id != null ? var.project_id : try(data.scaleway_account_project.this[0].id, null)`. `coalesce` rejects an all-null list; the conditional yields `null`, which the provider reads as "use the provider default project". Same result as before whenever `coalesce` succeeded, so no diff for existing state.
- **Registration without details (issue 2).** A `validation` on `register_domain` (`!var.register_domain || var.registration != null`) replaces the unreachable precondition. Cross-variable references in `validation` are supported by the required toolchain (`>= 1.10.7`). The error now names the real cause instead of an attribute-access error.
- **Ignored contact IDs (issue 3).** The provider schema for `scaleway_domain_registration` has `owner_contact_id` and `owner_contact` only; `administrative_contact` and `technical_contact` are computed. The two inputs cannot be forwarded. Removing them is a major change, so they stay, are described as deprecated and ignored, and a `check "registration_contact_ids_ignored"` warns when either is set (terraform-security: guardrails via `check` for legal but misleading configurations). Removal is a candidate for the next major.
- **Project name (issue 4).** The regex becomes `^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$`: one lowercase letter, or 2 to 63 characters ending in a letter or digit. The error message already states this rule.
- **Record keys (issue 5).** Keys stay `<type>_<name>_<index>`. Dropping the index would collide for repeated type/name pairs (the complete example has two `MX` records at the root), and any other key needs `moved` blocks for every record. Only the comment, the `records` description and the README change, stating that inserting or reordering records replaces the shifted ones and that new records should be appended.
- **Wording (issue 6).** "Weighted DNS routing" matches the sibling "Geo IP routing" and "View-based routing"; the records are DNS answers, not a load balancer. The spec requirement is renamed accordingly.

## Perpetual diff and state migration

No resource argument changes value, so no plan diff and no migration. The `project_id` expression returns the same value as before for every input that previously worked.

## Risks / Trade-offs

- Rejecting a one-character uppercase or digit `project_name` could affect a consumer whose Scaleway project is literally named that way; the documented rule always forbade it.
- The cross-variable validation on `register_domain` needs the toolchain floor already declared; no floor change.
