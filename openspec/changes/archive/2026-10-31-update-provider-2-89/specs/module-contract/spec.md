## MODIFIED Requirements

### Requirement: Outputs
The module SHALL expose the outputs `project_id`, `registration_id`, `registration_ds_record`, `dns_zone`, `zone_id`, `zone_ns`, `zone_ns_default`, `zone_status`, `records`, `record_ids` and `record_fqdns`. Every output SHALL carry a description. No output SHALL be marked sensitive, and none exposes a secret.

#### Scenario: Optional features disabled
- **WHEN** `register_domain = false`, `create_zone = false` and `records = []`
- **THEN** `registration_id`, `registration_ds_record`, `zone_id`, `zone_ns`, `zone_ns_default` and `zone_status` are `null`, `records` and `record_fqdns` are empty maps, `record_ids` is an empty list, and `dns_zone` and `project_id` are still set from the inputs
