## MODIFIED Requirements

### Requirement: Optional DNS zone
The module SHALL create one `scaleway_domain_zone` named `this` only when `create_zone = true` (default `false`), for `domain` and `subdomain` in `project_id` (`null` = provider default project). With `create_zone = false` the module SHALL manage records in a zone that already exists.

#### Scenario: Zone creation enabled
- **WHEN** `create_zone = true`, `domain = "example.com"` and `subdomain = "staging"`
- **THEN** one zone is planned for domain `example.com` and subdomain `staging`

#### Scenario: Zone creation disabled
- **WHEN** `create_zone = false`
- **THEN** no zone is planned and `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` are `null`

#### Scenario: Zone in a given project
- **WHEN** `create_zone = true` and `project_id` is a UUID
- **THEN** the planned zone carries that `project_id`
