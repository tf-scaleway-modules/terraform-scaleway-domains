## ADDED Requirements

### Requirement: Records from a map
The module SHALL create one `scaleway_domain_record` per entry of `records` (map of objects, default `{}`), keyed by a consumer-chosen key that becomes the resource address key, in the zone named by the `dns_zone` output, after the zone resource when the module creates it. Each value SHALL set `type` and `data` and MAY set `name` (default `""`, the zone root), `ttl` (default `3600`) and `priority` (default `null`).

#### Scenario: Root and named record
- **WHEN** `records = { root = { type = "A", data = "93.184.216.34" }, www = { name = "www", type = "CNAME", data = "example.com." } }`
- **THEN** two records are planned with keys `root` and `www`, both with TTL 3600, the first at the zone root

#### Scenario: No records
- **WHEN** `records = {}`
- **THEN** no record is planned

#### Scenario: Custom TTL and priority
- **WHEN** a record sets `ttl = 300` and an MX record sets `priority = 10`
- **THEN** the records carry TTL 300 and priority 10

#### Scenario: Entry added or reordered
- **WHEN** an entry is added to the map or the entries are written in another order
- **THEN** the keys of the other records are unchanged and none is replaced


## MODIFIED Requirements

### Requirement: Data required on every record
Every record SHALL set `data`, including dynamic DNS records, where it serves as the fallback value. `data` is a required attribute of the `records` object type; no `validation` block checks it.

#### Scenario: Record without data
- **WHEN** a record omits `data`
- **THEN** the plan fails on the object type with an attribute-required error

### Requirement: Geo IP routing
A record MAY set `geo_ip` as a list of match objects, each with a `data` IP and optional `countries` and `continents` lists. The record SHALL carry one `geo_ip` block with one `matches` block per element, and no `geo_ip` block when it is unset.

#### Scenario: Geo IP record
- **WHEN** a record sets `geo_ip` with a `continents = ["EU"]` element and a `countries = ["FR"]` element
- **THEN** the record carries one `geo_ip` block with two `matches` blocks holding those values

#### Scenario: Old nested shape
- **WHEN** a record sets `geo_ip = { matches = [...] }`
- **THEN** the plan fails on the object type

### Requirement: View-based routing
A record MAY set `view` as a list of `{ subnet, data }` objects, where `subnet` SHALL be a CIDR block. The record SHALL carry one `view` block per entry, and none when it is unset.

#### Scenario: View record
- **WHEN** a record sets `view` with subnets `10.0.0.0/8` and `192.168.0.0/16`
- **THEN** the record carries two `view` blocks with those subnets and data

#### Scenario: Subnet not a CIDR
- **WHEN** a record sets a `view` subnet `10.0.0.0`
- **THEN** the plan fails with "view subnet must be a CIDR block (e.g., 10.0.0.0/8)."

### Requirement: Record outputs
`records` SHALL map each record key to an object with `id`, `name`, `type`, `data`, `ttl`, `priority` and `fqdn`. The module SHALL NOT expose `record_ids` or `record_fqdns`.

#### Scenario: Two records created
- **WHEN** two records are created
- **THEN** `records` has two keys, each with its `id` and `fqdn`

## REMOVED Requirements

### Requirement: Records from a list
**Reason**: `records` is a map keyed by a consumer-chosen key; the index-based key `<type>_<name>_<index>` and its append-only rule are gone ("Records from a map").
**Migration**: Convert the list to a map and add one `moved` block per record (README "Upgrading from v1 to v2").
