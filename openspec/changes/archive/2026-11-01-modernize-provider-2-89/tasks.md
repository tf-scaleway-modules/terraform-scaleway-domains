# Tasks

Run every tool through `mise exec --` from the module root (`tofu` 1.11.6 is pinned in `mise.toml`).

## 1. Provider and project

- [x] 1.1 `versions.tf`: set `scaleway/scaleway` to `~> 2.89`; keep `required_version = ">= 1.10.7"`
- [x] 1.2 Delete `data.tf`; in `variables.tf` remove `organization_id` and `project_name`, reword `project_id` (single optional UUID, `null` = provider default project)
- [x] 1.3 `locals.tf`: remove `project_id` and `records_map`, keep `dns_zone`; use `var.project_id` on the registration and zone in `main.tf`

## 2. Registration

- [x] 2.1 Remove `register_domain` (variable, cross-validation); `count = var.registration != null ? 1 : 0`; reword the `registration` description (null disables it)
- [x] 2.2 Remove `administrative_contact_id`, `technical_contact_id` and `check "registration_contact_ids_ignored"`
- [x] 2.3 Extend `owner_contact.extension_fr` with `individual_info`, `association_info`, `duns_info`, `trademark_info` (optional objects) and the matching `dynamic` blocks in `main.tf`; no `code_auth_afnic_info`
- [x] 2.4 Outputs `registration_id` and `registration_ds_record` use `var.registration != null` / `one(...[*].x)` instead of `register_domain`

## 3. Records

- [x] 3.1 `records` becomes `map(object)`: `name = optional(string, "")`, `data = string`, `geo_ip = optional(list(object({ data, countries, continents })))`; `for_each = var.records`; render `geo_ip` as one block with a `matches` block per element
- [x] 3.2 Validations iterate over `values(var.records)`; drop the `data != null` validation; add the `view` subnet CIDR validation (`can(cidrhost(subnet, 0))`, message "view subnet must be a CIDR block (e.g., 10.0.0.0/8).")
- [x] 3.3 `outputs.tf`: remove `project_id`, `record_ids`, `record_fqdns`; keep `records` (id, name, type, data, ttl, priority, fqdn); order outputs per `terraform-outputs`
- [x] 3.4 Confirm against the docs/schema before coding: `priority` stays `null` when unset (optional+computed, no diff on second plan)

## 4. Tests (`tests/main.tftest.hcl`, mock_provider "scaleway")

- [x] 4.1 Remove `override_data` and the project-lookup runs; add `project_id_applied` (zone carries it) and `project_id_invalid_rejected`
- [x] 4.2 Registration: planned when `registration != null`, absent when null (removed inputs are unsupported-argument errors, not testable in a run)
- [x] 4.3 Remove the `registration_contact_ids_ignored` run; add `extension_fr` runs (duns_info rendered, mode only renders no nested block)
- [x] 4.4 Records: map keys become addresses, reorder keeps keys, `name` default `""`, `geo_ip` list renders matches, a rejected-input run per validation (type, TTL, MX priority, `http_service.strategy`, `view` subnet CIDR). Type-conversion failures (missing `data`, old `geo_ip` shape) cannot be asserted: `expect_failures` does not catch them, so those two scenarios are checked by the object type only
- [x] 4.5 Outputs: `records` keys, `registration_ds_record` null/non-null, no `record_ids`/`record_fqdns`/`project_id`

## 5. Examples

- [x] 5.1 `examples/minimal`: new inputs shape (no project lookup, map records)
- [x] 5.2 `examples/complete`: `project_id`, map records with all four dynamic types and the new `geo_ip` shape, outputs updated
- [x] 5.3 `examples/registration`: `registration` only (no `register_domain`), `extension_fr` sample, outputs updated

## 6. Documentation

- [x] 6.1 README (outside `BEGIN_TF_DOCS`/`END_TF_DOCS`): replace "Using Project Name Lookup" by `project_id`, rewrite "Record keys", update registration and record examples, compatibility note (tested with 2.89.0, constraint `~> 2.89`)
- [x] 6.2 README "Upgrading from v1 to v2": one row per breaking change in proposal.md with the consumer edit, the `moved` snippet per record (old key `<type>_<name>_<index>`, `@` for root), the `record_ids`/`record_fqdns` replacements
- [x] 6.3 `openspec/config.yaml` `context`: provider `~> 2.89`, layout without `data.tf`, project convention (`project_id` only)

## 7. Verification

- [x] 7.1 Move any local `.terraform.lock.hcl` aside (terraform-docs would print the locked version)
- [x] 7.2 `mise exec -- tofu fmt -recursive`
- [x] 7.3 `mise exec -- tofu init -backend=false && mise exec -- tofu validate` (also in each example); delete `.terraform.lock.hcl` and `.terraform/` produced
- [x] 7.4 `mise exec -- tflint --recursive`
- [x] 7.5 `mise exec -- tofu test`
- [x] 7.6 `mise exec -- pre-commit run -a` (README regeneration)
- [x] 7.7 `mise exec -- openspec validate --all --strict`
- [x] 7.8 Commit subject (becomes the CHANGELOG line, `.cliff.toml` keeps the subject verbatim): `Key DNS records by map, enable registration from the registration object and replace the project lookup with project_id`, body `BREAKING:` with the list from the README upgrade section; do not edit `CHANGELOG.md`

## 8. Real-account checks (separate, skipped unless the user asks)

- [ ] 8.1 On a test zone: apply a v1.3.0 config, upgrade, add the `moved` blocks, confirm plan = moves only and a second plan is empty
- [ ] 8.2 Confirm `extension_fr` sub-blocks round-trip on a read (no diff after apply) and the provider release that introduced them (changelog)
- [ ] 8.3 Confirm `view` CIDR check accepts IPv6 subnets the API accepts
- [ ] 8.4 No registration is created against a real account (billed)
