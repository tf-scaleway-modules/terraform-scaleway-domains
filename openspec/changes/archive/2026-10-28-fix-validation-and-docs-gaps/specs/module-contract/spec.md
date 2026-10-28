## MODIFIED Requirements

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
The module SHALL resolve the project ID from `project_id` when it is set. Otherwise, when both `organization_id` and `project_name` are set, it SHALL look the project up by name with a `scaleway_account_project` data source and use its ID. The data source SHALL NOT be read unless both inputs are set. The resolved ID SHALL be applied as `project_id` on the domain registration and on the DNS zone. When no project is resolved, the resolved ID SHALL be `null` so the provider default project applies, and the module SHALL NOT fail.

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
