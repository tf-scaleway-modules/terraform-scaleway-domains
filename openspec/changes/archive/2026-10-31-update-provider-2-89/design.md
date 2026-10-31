## Context

See proposal.md - Why. Current state: `main.tf` creates `scaleway_domain_registration.this` with `domain_names`, `duration_in_years`, `project_id`, `owner_contact_id` and an `owner_contact` block; no `auto_renew`, `dnssec` or computed attribute is used. `versions.tf` pins `~> 2.86`.

Gap analysis, provider objects the module manages, 2.86.0 vs 2.89.0 docs (`/tmp/scw-docs`) and 2.86.0 schema:

| Object | 2.86.0 -> 2.89.0 | Not exposed by the module |
|--------|------------------|---------------------------|
| `scaleway_domain_zone` | no change | `ns_master`, `message`, `updated_at` (computed) |
| `scaleway_domain_record` | no change | nothing: `geo_ip`, `weighted`, `view`, `http_service`, TTL, priority all forwarded |
| `scaleway_domain_registration` | docs only (import wording) | `auto_renew`, `dnssec` (args); `ds_record`, `task_id` (computed; `status`, `expired_at`, `epp_code`, `registrar`, `dns_zones` per the docs, absent from the schema, see Implementation notes) |
| data `scaleway_account_project` | 2.87.0: computed `srn` added | `srn` |

## Goals / Non-Goals

**Goals**
- Expose `auto_renew` and `dnssec` and the registration DS record with zero change for existing callers.
- Keep the floor at `~> 2.86`.

**Non-Goals / Deferred** (quality-simplicity: smallest change that solves the task, no speculative surface)
- Raising the floor to `~> 2.89`: nothing adopted needs it; `~> 2.86` already resolves to 2.89.0. Raising it would be a MAJOR bump (terraform-versioning, terraform-providers) for no gain.
- `registration_status` and `registration_expired_at` outputs: the provider docs list `status` and `expired_at`, but the 2.89.0 schema does not expose them (Implementation notes); revisit if a later provider adds them (minor change).
- `epp_code` output: transfer authorisation code, a credential; exposing it would land a secret in outputs and need `sensitive` plus a SECURITY.md entry for a rare need (terraform-security, quality-security).
- `registrar`, `dns_zones`, `task_id`, `updated_at`, `ns_master`, `message`, project `srn` outputs: no consumer need identified; adding them is possible later as a minor change (terraform-outputs: output only what consumers need).
- Multiple `domain_names` per registration: the module is single-domain by design (`domain`); would change the contract.
- Data sources (`scaleway_domain_zone`, `scaleway_domain_record`, `scaleway_domain_registration`): the module manages, not reads; the existing `create_zone = false` path already covers pre-existing zones.
- Record `priority` default (provider `0`, module `null`), record key scheme and removal of the ignored `administrative_contact_id`/`technical_contact_id`: unrelated or breaking; left for a future major.
- Extra validation tying `dnssec` to `create_zone`: the API's precondition is not documented by the provider; a guess could reject valid input (quality-security: validate at the boundary only what is known).

## Decisions

- **Arguments.** `scaleway_domain_registration.this` gets `auto_renew = var.registration.auto_renew` and `dnssec = var.registration.dnssec`. Both exist in provider 2.86.0 (`Optional`, `Default: false`), so the floor is unchanged.
- **Input shape.** Two `optional(bool, false)` attributes in the existing `registration` object. The `false` default equals the provider's schema default, so the value sent when omitted is identical to today's (terraform-variables: optional attribute defaults must not differ from the server's). Booleans in an object attribute keep the established input; renaming to an `enable_` prefix is not applied because every sibling attribute of `registration` mirrors a provider argument name, which the module follows. Type errors are rejected by the object type, so no `validation` block is added.
- **Outputs.** `registration_ds_record = var.register_domain ? scaleway_domain_registration.this[0].ds_record : null`, mirroring `registration_id`. Placed after `registration_id` (terraform-outputs ordering). Not sensitive: `ds_record` is the public DNSSEC key and digest the registrar needs.
- **Docs.** `registration` description documents the two options, that `dnssec` publishes a DS record readable through `registration_ds_record`, and that auto-renewal bills the owner. README gets a short compatibility note: tested with provider 2.89.0.

## Perpetual diff and state migration

- Defaults match the provider schema, and the provider Read sets `auto_renew` and `dnssec` from the API, so a second plan is empty after apply.
- Existing state: no resource address changes, no `moved` block, no replacement. Upgrading the module is a no-op plan for any registration whose API values are `false`. If auto-renewal or DNSSEC was enabled outside Terraform, the plan already shows `true -> false` today (schema default); the caller sets the input to `true` to remove it. In-place update only; the provider toggles them through update calls, not replacement.
- New outputs are computed from existing attributes, so state needs no migration; they appear after the first refresh.
- `ds_record` is empty/unknown until DNSSEC is enabled; the output passes it through unchanged and does not index into it, so it cannot fail when empty.

## Risks / Trade-offs

- Enabling DNSSEC on a domain whose DNS is not served by Scaleway can break resolution -> the input description states that the zone must be served by Scaleway DNS and the DS record published; default stays `false`.
- Enabling `auto_renew` causes billing -> default `false`, description warns (quality-security: safe defaults).
- Mock provider returns generated values for computed attributes, so output tests assert null/non-null shape only, not provider-real content.
- Integration against a real account is skipped: there is no `tests/integration` fixture yet and registration costs money; the 2.89.0 compatibility claim rests on `tofu init/validate/test` with the 2.89.0 provider resolved, and the unchanged resource schemas.

## Implementation notes

- The provider docs for `scaleway_domain_registration` list `status`, `expired_at` and `epp_code`, but the 2.89.0 schema (`tofu providers schema -json`) does not expose them: referencing `.status` or `.expired_at` fails `tofu validate` with "Unsupported attribute". The resource exposes only `ds_record`, `task_id`, `administrative_contact`, `technical_contact` and `id` as computed attributes. `registration_status` and `registration_expired_at` were therefore dropped (deferred, see Non-Goals); `auto_renew`, `dnssec` and `registration_ds_record` are unchanged. Still a minor release, floor `~> 2.86`.
- `tofu test` cannot assert the "Not a boolean" scenario: a type conversion error on an input variable is not a check failure, so `expect_failures = [var.registration]` reports "Missing expected failure" and the run fails. The `registration_options_not_boolean_rejected` run was dropped; the behaviour is guaranteed by the object type itself (no `validation` block exists to test).
