# Proposal

## Why

Scaleway provider 2.89.0 (2026-10-27) is out and the module pins `~> 2.86`. A gap analysis of the four provider objects the module uses (`scaleway_domain_zone`, `scaleway_domain_record`, `scaleway_domain_registration`, data `scaleway_account_project`) between 2.86.0 and 2.89.0 shows no functional change to the domain resources (2.87-2.89 only reword the `domain_registration` import docs; 2.87 adds a computed `srn` to the project data source). The value is therefore in provider features that already exist at 2.86.0 but that the module never exposed: `scaleway_domain_registration` has had `auto_renew`, `dnssec` and the computed `ds_record` since before 2.86, while the module hard-wires the defaults and offers no way to read the DS record. Without them a registered domain expires silently unless auto-renewal is set by hand in the console, and DNSSEC cannot be enabled or its DS record read for the registrar.

## What Changes

Adopted (all exist in provider 2.86.0, verified in the v2.86.0 docs and schema):

- New optional `registration.auto_renew` (bool, default `false`, the provider default) forwarded to `scaleway_domain_registration.this`.
- New optional `registration.dnssec` (bool, default `false`, the provider default) forwarded to `scaleway_domain_registration.this`.
- New output `registration_ds_record` (`null` when `register_domain = false`), so a consumer can publish the DS record of a DNSSEC-enabled domain at the registrar.
- Tested compatibility with provider 2.89.0 (the existing `~> 2.86` constraint already resolves to it); `examples/complete` and the `registration` example show the new options; README compatibility note.

Considered and not adopted: see design.md, Non-goals.

| Item | Breaking |
|------|----------|
| `registration.auto_renew`, `registration.dnssec` | No. New `optional()` attributes whose default equals the provider default; existing callers send the same values as today |
| `registration_ds_record` | No. New output; none removed or reshaped |
| Provider floor | Unchanged: `~> 2.86`. Nothing adopted needs an argument absent from 2.86.0 |

No input or output has its type, default or meaning changed.

State: one computed value already stored by the provider (`ds_record`) becomes visible as an output; it holds the public DNSSEC key and digest, not a secret. `status` and `expired_at` are not adopted: the 2.89.0 schema does not expose them (see design.md, Implementation notes). The EPP transfer authorisation code (effectively a credential) is not exposed either, so no new secret-bearing input or output exists and `terraform-security` needs no write-only argument. Inline `owner_contact` personal data is already in state and unchanged.

Semver (terraform-versioning): **minor**. New inputs with defaults and new outputs; no removed or renamed input or output, no changed default that alters resources, no floor raise.

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `domain-registration`: adds auto-renewal and DNSSEC options and the registration DS record output.
- `module-contract`: the exhaustive list of outputs gains `registration_ds_record`; the disabled-features scenario covers it.

## Impact

- Modified: `variables.tf` (`registration` object, description), `main.tf` (two arguments), `outputs.tf` (one output after `registration_id`), `tests/main.tftest.hcl`, `examples/registration/main.tf` and `examples/registration/outputs.tf` (`examples/complete` has no registration and is only re-validated), `README.md` (outside the terraform-docs block), and the two specs above.
- Unchanged: `versions.tf` (`~> 2.86`), `locals.tf`, `data.tf`, zone and record resources.
- Consumers: no action. A domain whose auto-renewal or DNSSEC was switched on outside Terraform already shows a plan diff today (the provider schema default is `false`); the new inputs let them record the real value instead.
