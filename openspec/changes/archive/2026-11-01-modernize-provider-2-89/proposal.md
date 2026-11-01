# Proposal

## Why

The module pins `scaleway/scaleway ~> 2.86`; 2.89.0 (2026-10-27) is the latest release on the Terraform and OpenTofu registries (2.90.0 is tagged on GitHub only, with no binaries; `~> 2.89` accepts it once published). The 2.89.0 schema adds nothing to the domain resources, so the value of this release is cleanup: a major bump is allowed and the module carries shims that only a breaking change can remove: a project lookup that duplicates `project_id`, a `register_domain` boolean next to the `registration` object it guards, two contact IDs ignored since v1.2.0 with a promised removal, records keyed by list position (reordering replaces live DNS records), a redundant `geo_ip.matches` nesting and two outputs derivable from `records`. The `extension_fr` sub-blocks needed to register `.fr` domains for companies, associations and trademarks are in the schema but not exposed.

## What Changes

Gap analysis against the 2.89.0 schema (`scaleway_domain_registration`, `_zone`, `_record`; data `scaleway_account_project`; adjacent: data sources `scaleway_domain_{zone,record,registration}`): no new or deprecated argument on the three resources. Docs and schema disagree again: `scaleway_domain_registration` docs list `status`, `expired_at`, `epp_code`; the schema has none of them (computed attributes are `ds_record`, `task_id`, `administrative_contact`, `technical_contact`), so no such output is possible. There is no DNSSEC, zone-import or auto-renew resource: those are arguments of the registration (already adopted in v1.3.0).

### Adopted features

| Item | Resource / argument | Provider version |
|------|---------------------|------------------|
| Provider floor `~> 2.89` | `versions.tf` | 2.89.0 |
| FR extension details `registration.owner_contact.extension_fr.{individual_info,association_info,duns_info,trademark_info}` | `scaleway_domain_registration.owner_contact.extension_fr` nested blocks | in the 2.89.0 schema; introducing release not found in docs or changelog, the floor covers it |
| CIDR validation of `view[*].subnet` | module validation (no provider change) | n/a |

### Breaking changes

| Change | Consumer edit |
|--------|---------------|
| `organization_id` and `project_name` removed; the `scaleway_account_project` data source is dropped | Pass `project_id = "<uuid>"` (or nothing for the provider default project) |
| `register_domain` removed; registration exists when `registration != null` | Delete `register_domain = true`; keep `registration = {...}`. Remove `registration` (and set nothing) to disable |
| `registration.administrative_contact_id` / `technical_contact_id` and check `registration_contact_ids_ignored` removed | Delete both attributes (they were ignored) |
| `records` is `map(object)` keyed by a consumer-chosen key, not a list keyed `<type>_<name>_<index>` | Convert the list to a map; add one root `moved` block per record (README upgrade section) or the records are destroyed and recreated |
| Record `data` is a required attribute of the object type (was `optional` + validation) | No edit: records already had to set it; the error is now a type error |
| Record `name` becomes `optional(string, "")` | None, widening only |
| `geo_ip` is the list of matches (was `{ matches = [...] }`) | `geo_ip = { matches = X }` becomes `geo_ip = X` |
| Outputs `record_ids`, `record_fqdns` and `project_id` removed | `record_ids` -> `[for r in module.x.records : r.id]`; `record_fqdns` -> `{ for k, r in module.x.records : k => r.fqdn }`; `project_id` -> the value passed in |
| `view[*].subnet` must be a CIDR | Fix a malformed subnet (it was rejected by the API anyway) |

### Simplifications

| Item | Result |
|------|--------|
| `data.tf` | deleted (no data source) |
| `locals.tf` | `project_id` and `records_map` removed; only `dns_zone` stays |
| `variables.tf` | three inputs removed, one validation turned into a type constraint, one into a CIDR check; `register_domain` cross-validation removed |
| `main.tf` | `for_each = var.records` directly; check block removed; `depends_on` on the zone kept |
| `outputs.tf` | three outputs removed |
| Tests | project-lookup runs replaced; override_data removed |

### Deferred / Rejected

| Item | Decision | Reason |
|------|----------|--------|
| `registration_status`, `registration_expired_at`, `epp_code` outputs | Rejected | Absent from the 2.89.0 schema (docs list them); `epp_code` would also be a credential in state |
| `code_auth_afnic_info` (FR trademark auth code) | Rejected | One-time authorisation code with no write-only form and not marked sensitive by the provider: cannot meet `terraform-security` |
| `extension_nl`, `fax_number` of `owner_contact` | Rejected | Undocumented semantics; no stated consumer need (`quality-simplicity`) |
| `dnssec` tied to `create_zone` by validation | Rejected (kept from v1.3.0) | API precondition undocumented; a guess could reject valid input |
| At most one dynamic block (`geo_ip`/`weighted`/`view`/`http_service`) per record | Rejected | Neither schema nor docs state a conflict; the API decides |
| Multiple `domain_names` per registration | Rejected (kept) | Module is single-domain by design |
| Data sources `scaleway_domain_{zone,record,registration}` | Rejected | Module manages, `create_zone = false` covers existing zones |
| Zone outputs `ns_master`, `message`, `updated_at`; registration `task_id`; project `srn` | Rejected | No consumer need identified |
| `tags`, `region`/`zone`, `name` prefix | Not applicable | Domain resources are global and have neither `tags` nor a region (verified in the schema); the module derives no names |
| Write-only / ephemeral secrets | Not applicable | No secret-bearing input exists |
| Zone import | Not applicable | No import resource in the provider |

## Capabilities

### New Capabilities
<!-- none -->

### Modified Capabilities
- `module-contract`: provider floor, input list, project handling, outputs, upgrade guide.
- `domain-registration`: registration driven by `registration != null`, ignored contact IDs removed, FR extension details.
- `dns-zone`: project applied unchanged.
- `dns-records`: map keyed records, `geo_ip` shape, `data` typed required, CIDR `view` subnets, `records` output only.

## Semver

**Major** (terraform-versioning): v1.3.0 -> **v2.0.0**. Inputs removed: `organization_id`, `project_name`, `register_domain`, `registration.administrative_contact_id`, `registration.technical_contact_id`. Inputs whose type changes: `records` (list -> map), `records[*].geo_ip` (object -> list), `records[*].data` (optional -> required), `records[*].name` (required -> optional default `""`). Inputs with changed meaning: `registration` (non-null now enables registration). Outputs removed: `record_ids`, `record_fqdns`, `project_id`. Outputs whose meaning changes: none (`records` keys change with the input keys). Provider floor `~> 2.86` -> `~> 2.89`. `required_version` stays `>= 1.10.7` (no write-only or ephemeral use).

## State

Nothing new lands in state. Registration, zone and `ds_record` are unchanged; the inline `owner_contact` personal data is already stored. No secret is added (`terraform-security`: none needed). Addresses: registration and zone keep `this[0]`; each record address changes key (`scaleway_domain_record.this["A_@_0"]` -> `["<key>"]`), handled by consumer-side `moved` blocks (design.md). The dropped data source disappears from state without effect.

## Impact

- Files: `versions.tf`, `variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`, `data.tf` (deleted), `tests/main.tftest.hcl`, `examples/{minimal,complete,registration}`, `README.md` (outside the terraform-docs block; new "Upgrading from v1 to v2"), `openspec/config.yaml` context (provider floor, layout, project convention).
- Specs: the four capabilities above.
- Standards: `quality-simplicity`, `quality-security`, `quality-production-readiness`, `terraform-versioning`, `terraform-providers`, `terraform-variables`, `terraform-outputs`, `terraform-security`.
- Consumers: every caller changes its input (project, `register_domain`, records) and reads fewer outputs.
