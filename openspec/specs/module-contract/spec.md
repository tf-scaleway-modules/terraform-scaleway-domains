# module-contract Specification

## Purpose
Cross-cutting contract: supported tooling and provider, no provider or backend blocks, inputs and defaults, project resolution and outputs.

## Requirements

### Requirement: Supported tooling and providers
The module SHALL declare a single `required_version = ">= 1.11.0"`, read by both OpenTofu and Terraform, and SHALL pin `scaleway/scaleway ~> 2.89` in `versions.tf`. The examples under `examples/` SHALL declare the same `required_version` and the same scaleway constraint as the root. It SHALL work on OpenTofu and Terraform. It SHALL NOT contain `provider {}` or `backend {}` blocks.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.89 and no provider or backend configuration comes from the module

#### Scenario: Older toolchain
- **WHEN** the module is used with a Terraform or OpenTofu release older than 1.11.0
- **THEN** initialisation fails on the `required_version` constraint

#### Scenario: Both tools validate
- **WHEN** `tofu validate` and `terraform validate` run in the root and in each example
- **THEN** both succeed

### Requirement: Inputs and defaults
The module SHALL expose the inputs `project_id` (string, default `null`), `create_zone` (bool, default `false`), `registration` (object, default `null`), `subdomain` (string, default `""`), `records` (map of objects, default `{}`) and `domain` (string, required). It SHALL NOT expose `organization_id`, `project_name` or `register_domain`. It SHALL create no managed resource until `registration`, `create_zone` or `records` asks for one.

#### Scenario: Only the domain is given
- **WHEN** the module is called with only `domain = "example.com"`
- **THEN** the plan contains no domain registration, no DNS zone and no DNS record

#### Scenario: Domain omitted
- **WHEN** the module is called without `domain`
- **THEN** the plan fails because the required variable has no value

#### Scenario: Removed input
- **WHEN** a caller sets `project_name` or `register_domain`
- **THEN** the plan fails with an unsupported-argument error

### Requirement: Outputs
The module SHALL expose the outputs `registration_id`, `registration_ds_record`, `dns_zone`, `zone_id`, `zone_ns`, `zone_ns_default`, `zone_status` and `records`. Every output SHALL carry a description. No output SHALL be marked sensitive, and none exposes a secret. It SHALL NOT expose `project_id`, `record_ids` or `record_fqdns`.

#### Scenario: Optional features disabled
- **WHEN** `registration = null`, `create_zone = false` and `records = {}`
- **THEN** `registration_id`, `registration_ds_record`, `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` are `null`, `records` is an empty map and `dns_zone` is still set from the inputs

### Requirement: Project applied unchanged
The module SHALL apply `project_id` unchanged as `project_id` on the domain registration and on the DNS zone, and SHALL read no data source. With `project_id = null` the provider default project applies.

#### Scenario: Project ID given
- **WHEN** `project_id` is a UUID and a zone is planned
- **THEN** the zone carries that `project_id`

#### Scenario: No project given
- **WHEN** `project_id = null`
- **THEN** the plan succeeds and no project is set by the module, so the provider default project applies

### Requirement: Project ID validation
`project_id` SHALL be `null` or a lowercase UUID (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`).

#### Scenario: Project ID that is not a UUID
- **WHEN** `project_id = "my-project"`
- **THEN** the plan fails with "Project ID must be a valid UUID format."

#### Scenario: Valid project ID
- **WHEN** `project_id = "22222222-2222-2222-2222-222222222222"`
- **THEN** the input is accepted

### Requirement: Upgrade guide
The README SHALL contain a section "Upgrading from v1 to v2" listing every breaking change with the consumer-side edit, including the `moved` block that keeps each record when `records` becomes a map.

#### Scenario: Consumer upgrades
- **WHEN** a v1 caller follows the section and adds one `moved` block per record
- **THEN** `tofu plan` shows only moves, no record is created or destroyed, and a second plan is empty
