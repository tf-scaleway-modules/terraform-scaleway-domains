## ADDED Requirements

### Requirement: Auto-renewal and DNSSEC options
`registration.auto_renew` and `registration.dnssec` SHALL be optional booleans defaulting to `false`, and SHALL be forwarded unchanged to the domain registration. Omitting them SHALL yield the same registration as before they existed.

#### Scenario: Options omitted
- **WHEN** `registration` sets neither `auto_renew` nor `dnssec`
- **THEN** the registration is planned with auto-renewal disabled and DNSSEC disabled

#### Scenario: Auto-renewal and DNSSEC enabled
- **WHEN** `registration = { owner_contact_id = "<contact id>", auto_renew = true, dnssec = true }`
- **THEN** the registration is planned with auto-renewal enabled and DNSSEC enabled

#### Scenario: Not a boolean
- **WHEN** `registration.auto_renew = "yes"`
- **THEN** the plan fails on the object type

### Requirement: Registration DS record output
The module SHALL expose the registration's DNSSEC DS record as the output `registration_ds_record`. It SHALL be `null` when `register_domain = false`. The module SHALL NOT output the EPP (transfer authorisation) code.

#### Scenario: Registration disabled
- **WHEN** `register_domain = false`
- **THEN** `registration_ds_record` is `null`

#### Scenario: Registration enabled
- **WHEN** `register_domain = true` with an owner contact
- **THEN** `registration_ds_record` carries the value of the planned registration

#### Scenario: Transfer code
- **WHEN** the module outputs are listed
- **THEN** none exposes the EPP code
