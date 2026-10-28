## MODIFIED Requirements

### Requirement: Records from a list
The module SHALL create one `scaleway_domain_record` per element of `records` (default `[]`), in the zone named by the `dns_zone` output, after the zone resource when the module creates it. Each element SHALL have `name` (empty string for the zone root) and `type`, and MAY set `data` (default `null`), `ttl` (default `3600`) and `priority` (default `null`). The record key SHALL be `<type>_<name>_<index>`, with `@` as name for the root and `<index>` the position in the list, so inserting or reordering elements changes the keys of the shifted records.

#### Scenario: Root and named record
- **WHEN** `records = [{ name = "", type = "A", data = "93.184.216.34" }, { name = "www", type = "CNAME", data = "example.com." }]`
- **THEN** two records are planned with keys `A_@_0` and `CNAME_www_1`, both with TTL 3600

#### Scenario: No records
- **WHEN** `records = []`
- **THEN** no record is planned

#### Scenario: Custom TTL and priority
- **WHEN** a record sets `ttl = 300` and an MX record sets `priority = 10`
- **THEN** the records carry TTL 300 and priority 10

#### Scenario: Record inserted before another
- **WHEN** a record is inserted at index 0 of an existing list
- **THEN** every later record gets a new key, so its previous address is destroyed and recreated; appending at the end leaves existing keys unchanged

## RENAMED Requirements
- FROM: `### Requirement: Weighted load balancing`
- TO: `### Requirement: Weighted DNS routing`
