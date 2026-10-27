## ADDED Requirements

### Requirement: Optional DNS zone
The module SHALL create one `scaleway_domain_zone` named `this` only when `create_zone = true` (default `false`), for `domain` and `subdomain` in the resolved project. With `create_zone = false` the module SHALL manage records in a zone that already exists.

#### Scenario: Zone creation enabled
- **WHEN** `create_zone = true`, `domain = "example.com"` and `subdomain = "staging"`
- **THEN** one zone is planned for domain `example.com` and subdomain `staging`

#### Scenario: Zone creation disabled
- **WHEN** `create_zone = false`
- **THEN** no zone is planned and `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` are `null`

### Requirement: Zone name
The `dns_zone` output SHALL be `domain` when `subdomain` is empty, and `<subdomain>.<domain>` otherwise. Records SHALL be created in that zone whether or not the module creates it.

#### Scenario: Root domain
- **WHEN** `domain = "example.com"` and `subdomain = ""`
- **THEN** `dns_zone` is `example.com`

#### Scenario: Subdomain
- **WHEN** `domain = "example.com"` and `subdomain = "api"`
- **THEN** `dns_zone` is `api.example.com`

### Requirement: Domain name validation
`domain` SHALL be a lowercase dotted name: at least two labels of lowercase letters, digits and inner hyphens, each starting and ending with a letter or digit.

#### Scenario: Single label
- **WHEN** `domain = "localhost"`
- **THEN** the plan fails with "Domain must be a valid domain name (e.g., example.com)."

#### Scenario: Uppercase domain
- **WHEN** `domain = "Example.com"`
- **THEN** the plan fails with "Domain must be a valid domain name (e.g., example.com)."

### Requirement: Subdomain validation
`subdomain` SHALL be empty (the default) or a single lowercase label of letters, digits and inner hyphens, starting and ending with a letter or digit.

#### Scenario: Subdomain with a dot
- **WHEN** `subdomain = "a.b"`
- **THEN** the plan fails with "Subdomain must be empty or a valid subdomain name (lowercase alphanumeric with hyphens)."

#### Scenario: Subdomain with a leading hyphen
- **WHEN** `subdomain = "-api"`
- **THEN** the plan fails with "Subdomain must be empty or a valid subdomain name (lowercase alphanumeric with hyphens)."

### Requirement: Zone outputs
When the module creates the zone, `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` SHALL expose the ID, nameservers, default nameservers and status of that zone.

#### Scenario: Zone created
- **WHEN** `create_zone = true`
- **THEN** `zone_ns` lists the zone's nameservers and `zone_status` reports its status
