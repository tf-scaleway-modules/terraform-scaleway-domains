## ADDED Requirements

### Requirement: Records from a list
The module SHALL create one `scaleway_domain_record` per element of `records` (default `[]`), in the zone named by the `dns_zone` output, after the zone resource when the module creates it. Each element SHALL have `name` (empty string for the zone root) and `type`, and MAY set `data` (default `null`), `ttl` (default `3600`) and `priority` (default `null`). The record key SHALL be `<type>_<name>_<index>`, with `@` as name for the root and `<index>` the position in the list.

#### Scenario: Root and named record
- **WHEN** `records = [{ name = "", type = "A", data = "93.184.216.34" }, { name = "www", type = "CNAME", data = "example.com." }]`
- **THEN** two records are planned with keys `A_@_0` and `CNAME_www_1`, both with TTL 3600

#### Scenario: No records
- **WHEN** `records = []`
- **THEN** no record is planned

#### Scenario: Custom TTL and priority
- **WHEN** a record sets `ttl = 300` and an MX record sets `priority = 10`
- **THEN** the records carry TTL 300 and priority 10

### Requirement: Record type validation
Every record `type` SHALL be one of `A`, `AAAA`, `MX`, `CNAME`, `DNAME`, `ALIAS`, `NS`, `PTR`, `SRV`, `TXT`, `TLSA`, `CAA`.

#### Scenario: Unsupported type
- **WHEN** a record has `type = "SOA"`
- **THEN** the plan fails with "Record type must be one of: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA."

### Requirement: TTL validation
Every record `ttl` SHALL be between 60 and 86400 seconds inclusive.

#### Scenario: TTL too low
- **WHEN** a record has `ttl = 59`
- **THEN** the plan fails with "TTL must be between 60 and 86400 seconds."

#### Scenario: TTL too high
- **WHEN** a record has `ttl = 86401`
- **THEN** the plan fails with "TTL must be between 60 and 86400 seconds."

### Requirement: Priority required for MX and SRV
Every record of type `MX` or `SRV` SHALL set `priority`.

#### Scenario: MX without priority
- **WHEN** a record has `type = "MX"` and no `priority`
- **THEN** the plan fails with "Priority is required for MX and SRV record types."

#### Scenario: SRV without priority
- **WHEN** a record has `type = "SRV"` and no `priority`
- **THEN** the plan fails with "Priority is required for MX and SRV record types."

### Requirement: Data required on every record
Every record SHALL set `data`, including dynamic DNS records, where it serves as the fallback value.

#### Scenario: Record without data
- **WHEN** a record omits `data`
- **THEN** the plan fails with "The 'data' attribute is required for all records. For dynamic DNS (geo_ip, weighted, http_service), it serves as the fallback value."

### Requirement: Geo IP routing
A record MAY set `geo_ip` with a list of `matches`, each with a `data` IP and optional `countries` and `continents` lists. The record SHALL carry one `geo_ip` block with one `matches` block per entry, and no `geo_ip` block when it is unset.

#### Scenario: Geo IP record
- **WHEN** a record sets `geo_ip.matches` with a `continents = ["EU"]` entry and a `countries = ["FR"]` entry
- **THEN** the record carries one `geo_ip` block with two `matches` blocks holding those values

### Requirement: Weighted load balancing
A record MAY set `weighted` as a list of `{ ip, weight }` objects. The record SHALL carry one `weighted` block per entry, and none when it is unset.

#### Scenario: Weighted record
- **WHEN** a record sets `weighted` with weights 70, 20 and 10
- **THEN** the record carries three `weighted` blocks with those IPs and weights

### Requirement: View-based routing
A record MAY set `view` as a list of `{ subnet, data }` objects. The record SHALL carry one `view` block per entry, and none when it is unset.

#### Scenario: View record
- **WHEN** a record sets `view` with subnets `10.0.0.0/8` and `192.168.0.0/16`
- **THEN** the record carries two `view` blocks with those subnets and data

### Requirement: HTTP health-checked DNS
A record MAY set `http_service` with `ips`, `must_contain`, `url`, `strategy` and an optional `user_agent` (default `null`). The record SHALL carry one `http_service` block when it is set. `strategy` SHALL be one of `random`, `hashed`, `all`.

#### Scenario: HTTP service record
- **WHEN** a record sets `http_service` with `strategy = "hashed"`, three `ips`, a `url` and `must_contain`
- **THEN** the record carries one `http_service` block with those values

#### Scenario: Unsupported strategy
- **WHEN** a record sets `http_service.strategy = "round-robin"`
- **THEN** the plan fails with "http_service.strategy must be one of: random, hashed, all."

### Requirement: Record outputs
`records` SHALL map each record key to an object with `id`, `name`, `type`, `data`, `ttl`, `priority` and `fqdn`. `record_ids` SHALL list the IDs of all records and `record_fqdns` SHALL map each key to the record's FQDN.

#### Scenario: Two records created
- **WHEN** two records are created
- **THEN** `records` and `record_fqdns` each have two keys and `record_ids` has two entries
