# Design

## Context

See proposal.md. Current v1.3.0 surface: `scaleway_domain_registration.this` (count), `scaleway_domain_zone.this` (count), `scaleway_domain_record.this` (for_each over a list-derived map keyed `<type>_<name>_<index>`), data `scaleway_account_project.this`, one `check` block. Provider `~> 2.86`, `required_version >= 1.10.7`.

Gap analysis on the 2.89.0 schema (`/tmp/scw-schema/schema-2.89.0.json`):

| Object | Findings | Module use |
|--------|----------|------------|
| `scaleway_domain_registration` | Args: `domain_names`, `duration_in_years`, `project_id`, `owner_contact_id`, `auto_renew`, `dnssec`, `owner_contact` (list, max 1). `owner_contact.extension_fr` has sub-blocks `association_info`, `code_auth_afnic_info`, `duns_info`, `individual_info`, `trademark_info`; `extension_eu`; attributes `extension_nl`, `fax_number`. Computed: `ds_record`, `task_id`, `administrative_contact`, `technical_contact`. No `status`/`expired_at`/`epp_code` (docs only) | `extension_fr` sub-blocks added except `code_auth_afnic_info`; `extension_nl`/`fax_number` rejected |
| `scaleway_domain_zone` | `domain`, `subdomain` required; computed `ns`, `ns_default`, `ns_master`, `status`, `message`, `updated_at` | unchanged |
| `scaleway_domain_record` | `data`, `dns_zone`, `type` required; `name`, `ttl`, `priority` (optional; `priority` also computed), blocks `geo_ip` (max 1, `matches`), `http_service` (max 1), `view`, `weighted` | unchanged arguments; `data` becomes a typed-required input |
| data `scaleway_account_project` | removed from the module | n/a |

Deferred items of `2026-10-31-update-provider-2-89` revisited: floor raise (done: `~> 2.89`, major anyway); `administrative_contact_id`/`technical_contact_id` removal (done); record key scheme (done); `priority` default `null` vs provider `0` (kept, see below); status/expired_at/epp_code (still rejected: schema); `ns_master`, `registrar`, `task_id`, `srn` (still rejected: no consumer need); multiple domains, data sources, dnssec-zone validation (still rejected, same reasons).

## Goals / Non-Goals

**Goals**: provider floor `~> 2.89`; one project input; no dual or ignored inputs; stable record addresses independent of order; smaller output surface; FR extension coverage for registrations.

**Non-Goals**: new resources; tags/region (not supported by the product); secrets handling (none exist); a `tofu apply` against a real account in this change.

## Decisions

1. **Provider floor `~> 2.89`**, `required_version` unchanged at `>= 1.10.7`: nothing uses write-only or ephemeral features (`terraform-providers`: minimum the design needs). Alternative: lower the version floor; rejected, no benefit and a risk for existing pipelines.
2. **Project**: delete `data.tf`, `organization_id`, `project_name` and `local.project_id`; `project_id = var.project_id` on registration and zone (`null` = provider default). Keep the UUID validation. Alternative: keep the name lookup; rejected, it is the cross-module convention to drop it and costs a data source per module call. `project_id` output removed: it only echoed the input.
3. **Registration switch**: `registration` (object, default `null`) alone enables registration: `count = var.registration != null ? 1 : 0`. The `register_domain` variable and its cross-validation go. Resource address `scaleway_domain_registration.this[0]` is unchanged.
4. **Contacts**: remove `administrative_contact_id`, `technical_contact_id` and `check "registration_contact_ids_ignored"` (computed-only in the schema). `owner_contact_id` OR `owner_contact` stays with the existing at-least-one validation; exclusivity is not added because neither schema nor docs state a conflict.
5. **FR extension**: `extension_fr = optional(object({ mode, individual_info = optional(object({ whois_opt_in })), association_info = optional(object({ publication_jo, publication_jo_page })), duns_info = optional(object({ duns_id, local_id })), trademark_info = optional(object({ trademark_inpi })) }))`, each emitted by a `dynamic` block only when set. `code_auth_afnic_info` is left out (credential, no write-only form). Attribute names mirror the provider (documented deviation from `enable_` style, as before).
6. **Records map**: `records = map(object)`, `for_each = var.records`, address key = consumer key. Removes `local.records_map`, the index in the key and the "append only" rule. Alternative: derive a key from `type`+`name`+`data`; rejected, `data` changes would replace the record and duplicates (two MX at the root) need a discriminator anyway.
7. **Record shape**: `name = optional(string, "")`; `data = string` (required, replaces the `data != null` validation); `geo_ip = optional(list(object({ data, countries, continents })))` rendered as one `geo_ip` block with one `matches` block per element (`for_each = geo_ip != null ? [1] : []`). `view[*].subnet` validated with `can(cidrhost(subnet, 0))`. Existing type, TTL, MX/SRV priority and `http_service.strategy` validations keep their messages and iterate over `values(var.records)`.
8. **Outputs**: keep `registration_id`, `registration_ds_record`, `dns_zone`, `zone_id`, `zone_ns`, `zone_ns_default`, `zone_status`, `records`; drop `record_ids`, `record_fqdns` (derivable from `records`, which already carries `id` and `fqdn`) and `project_id`. Alternative: keep them as aliases; rejected as redundant (`quality-simplicity`).
9. **`depends_on = [scaleway_domain_zone.this]`** on records stays: `dns_zone` is a computed local with no reference to the zone resource, so the ordering is not implicit.
10. **Not applicable conventions** (exception to the cross-module list, recorded): no `tags`, no `region`/`zone`, no name prefix, no ephemeral inputs: the three domain resources have no such arguments (verified in the 2.89.0 schema) and the module has no secret.

## Perpetual diff avoidance

- Registration and zone arguments are sent exactly as in v1.3.0 (defaults `auto_renew = false`, `dnssec = false`, `lang = "en_US"` unchanged), so the second plan stays empty.
- New FR sub-blocks are `null` unless set, so no block is rendered for existing callers. Their values are sent as read back (strings and a bool).
- `priority` stays `null` when unset: the attribute is optional+computed, so the server value (`0`) is kept in state without a diff. Not defaulted to `0` to avoid sending a priority for types that have none.
- Records: `ttl` defaults to `3600` (the provider default); `name` defaults to `""`.

## State migration

- Registration, zone: same addresses, no `moved` block, no replacement. Only the enabling expression changes (`registration != null`); a v1 config with `register_domain = true` and `registration` set keeps the instance.
- Data source `scaleway_account_project.this`: removed from configuration; state drops it on the next apply, no cloud effect.
- Records: the module cannot ship `moved` blocks (keys are consumer-chosen). Without action every record is **destroyed and recreated** (brief resolution gap, new IDs). The README upgrade section gives a root-level snippet per record:
  ```hcl
  moved {
    from = module.dns.scaleway_domain_record.this["A_@_0"]
    to   = module.dns.scaleway_domain_record.this["root"]
  }
  ```
  Verification: `tofu plan` after adding the blocks shows only moves and no create/destroy; a second plan is empty. Consumers must keep the old keys (`<type>_<name>_<index>`, `@` for root) as `from`.
- Dynamic block renames (`geo_ip`) change only input shape, not state.

## Deviations found while applying

- Object type conversion drops attributes the type does not declare, so `extension_fr.code_auth_afnic_info` is silently ignored rather than rejected (spec scenario "Authorisation code" updated). The value is never sent to the provider.
- Variable type-conversion errors (missing `data`, old `geo_ip` shape) are not catchable by `expect_failures`; no test run covers them (tasks 4.4).

## Risks / Trade-offs

- Records recreation if a consumer forgets the `moved` blocks: documented prominently; a `tofu plan` shows it before apply.
- FR sub-blocks come from the schema only (docs silent): shape validated by mock-provider tests and `tofu validate`; real behaviour is unverified until the real-account check.
- Dropping `project_id`/`record_ids` outputs breaks consumers that read them: listed with replacement expressions.
- Mock provider returns generated computed values: tests assert shape, not provider-real content.
