# module-contract Specification

## Purpose
Cross-cutting contract: supported tooling and provider, no provider or backend blocks, inputs and defaults, project resolution and outputs.

## Requirements

### Requirement: Supported tooling and providers
The module SHALL declare `required_version = ">= 1.10.7"` and SHALL pin `scaleway/scaleway ~> 2.86` in `versions.tf`. It SHALL work on OpenTofu and Terraform. It SHALL NOT contain `provider {}` or `backend {}` blocks.

#### Scenario: Provider resolution
- **WHEN** the module is initialised
- **THEN** the scaleway provider resolves to a 2.x release at or above 2.86 and no provider or backend configuration comes from the module

#### Scenario: Older toolchain
- **WHEN** the module is used with a Terraform or OpenTofu release older than 1.10.7
- **THEN** initialisation fails on the `required_version` constraint

### Requirement: Inputs and defaults
The module SHALL expose the inputs `organization_id`, `project_name` and `project_id` (strings, default `null`), `register_domain` and `create_zone` (bools, default `false`), `registration` (object, default `null`), `subdomain` (string, default `""`), `records` (list of objects, default `[]`) and `domain` (string, required, no default). It SHALL create no managed resource until `register_domain`, `create_zone` or `records` asks for one.

#### Scenario: Only the domain is given
- **WHEN** the module is called with only `domain = "example.com"` and the project resolves
- **THEN** the plan contains no domain registration, no DNS zone and no DNS record

#### Scenario: Domain omitted
- **WHEN** the module is called without `domain`
- **THEN** the plan fails because the required variable has no value

### Requirement: Project identifier validation
`organization_id` and `project_id` SHALL each be `null` or a lowercase UUID (`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`). `project_name` SHALL be `null` or start with a lowercase letter, contain only lowercase letters, digits and hyphens, end with a letter or digit and be at most 63 characters.

#### Scenario: Organization ID that is not a UUID
- **WHEN** `organization_id = "not-a-uuid"`
- **THEN** the plan fails with "Organization ID must be a valid UUID format."

#### Scenario: Project ID that is not a UUID
- **WHEN** `project_id = "my-project"`
- **THEN** the plan fails with "Project ID must be a valid UUID format."

#### Scenario: Project name with uppercase or underscore
- **WHEN** `project_name = "My_Project"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."

#### Scenario: Single-character project name that is not a lowercase letter
- **WHEN** `project_name = "A"` or `project_name = "1"`
- **THEN** the plan fails with "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."

#### Scenario: Single lowercase letter project name
- **WHEN** `project_name = "a"`
- **THEN** the input is accepted

#### Scenario: Valid project name
- **WHEN** `project_name = "my-project-1"`
- **THEN** the input is accepted

### Requirement: Project resolution
The module SHALL resolve the project ID from `project_id` when it is set. Otherwise, when both `organization_id` and `project_name` are set, it SHALL look the project up by name with a `scaleway_account_project` data source and use its ID. The data source SHALL NOT be read unless both inputs are set. The resolved ID, or `null` when none resolves, SHALL be applied as `project_id` on the domain registration and on the DNS zone.

#### Scenario: Project ID given
- **WHEN** `project_id` is a UUID
- **THEN** no project lookup is made and the `project_id` output equals that UUID

#### Scenario: Lookup by name
- **WHEN** `project_id` is `null`, and `organization_id` and `project_name` are set
- **THEN** the project is looked up in that organization and the `project_id` output is the ID found

#### Scenario: Only a project name
- **WHEN** `project_name` is set but `organization_id` is `null` and `project_id` is `null`
- **THEN** no project lookup is made

#### Scenario: No project resolved
- **WHEN** `project_id`, `organization_id` and `project_name` are all `null`
- **THEN** the plan succeeds, the `project_id` output is `null` and the provider default project applies to the resources

### Requirement: Outputs
The module SHALL expose the outputs `project_id`, `registration_id`, `registration_ds_record`, `dns_zone`, `zone_id`, `zone_ns`, `zone_ns_default`, `zone_status`, `records`, `record_ids` and `record_fqdns`. Every output SHALL carry a description. No output SHALL be marked sensitive, and none exposes a secret.

#### Scenario: Optional features disabled
- **WHEN** `register_domain = false`, `create_zone = false` and `records = []`
- **THEN** `registration_id`, `registration_ds_record`, `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` are `null`, `records` and `record_fqdns` are empty maps, `record_ids` is an empty list, and `dns_zone` and `project_id` are still set from the inputs
