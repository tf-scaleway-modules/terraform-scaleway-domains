## MODIFIED Requirements

### Requirement: Optional domain registration
The module SHALL create one `scaleway_domain_registration` named `this` only when `register_domain = true` (default `false`). It SHALL register the single domain `var.domain`, for `registration.duration_in_years` years (default `1`), in the resolved project. `register_domain = true` SHALL require a non-null `registration`.

#### Scenario: Registration disabled
- **WHEN** `register_domain = false`
- **THEN** no domain registration is planned and the `registration_id` output is `null`

#### Scenario: Registration enabled
- **WHEN** `register_domain = true`, `domain = "my-new-domain.com"` and `registration` carries an owner contact
- **THEN** one registration is planned for `my-new-domain.com` for one year and `registration_id` is its ID

#### Scenario: Registration enabled without registration details
- **WHEN** `register_domain = true` and `registration = null`
- **THEN** the plan fails with "The 'registration' variable must be provided when 'register_domain' is true."

## ADDED Requirements

### Requirement: Administrative and technical contact IDs are ignored
`registration.administrative_contact_id` and `registration.technical_contact_id` SHALL remain accepted for compatibility, are deprecated, and SHALL NOT be sent to the provider, which has no such arguments. The module SHALL emit a `check` warning named `registration_contact_ids_ignored` when either is set.

#### Scenario: Contact IDs set
- **WHEN** `registration` sets `administrative_contact_id` or `technical_contact_id`
- **THEN** the plan succeeds and the check warns that the value is ignored

#### Scenario: Contact IDs unset
- **WHEN** `registration` sets neither attribute, or is `null`
- **THEN** the check passes without a warning
