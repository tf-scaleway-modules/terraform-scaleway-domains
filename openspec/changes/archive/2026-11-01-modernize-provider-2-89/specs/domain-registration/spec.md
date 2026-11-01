## MODIFIED Requirements

### Requirement: Auto-renewal and DNSSEC options
`registration.auto_renew` and `registration.dnssec` SHALL be optional booleans defaulting to `false`, and SHALL be forwarded unchanged to the domain registration.

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
The module SHALL expose the registration's DNSSEC DS record as the output `registration_ds_record`. It SHALL be `null` when `registration = null`. The module SHALL NOT output the EPP (transfer authorisation) code.

#### Scenario: Registration disabled
- **WHEN** `registration = null`
- **THEN** `registration_ds_record` is `null`

#### Scenario: Registration enabled
- **WHEN** `registration` is set with an owner contact
- **THEN** `registration_ds_record` carries the value of the planned registration

#### Scenario: Transfer code
- **WHEN** the module outputs are listed
- **THEN** none exposes the EPP code

## ADDED Requirements

### Requirement: Registration enabled by registration object
The module SHALL create one `scaleway_domain_registration` named `this` only when `registration` is not `null` (default `null`). It SHALL register the single domain `var.domain` for `registration.duration_in_years` years (default `1`) in `project_id` (`null` = provider default project). The module SHALL NOT expose a `register_domain` input.

#### Scenario: Registration disabled
- **WHEN** `registration = null`
- **THEN** no domain registration is planned and the `registration_id` output is `null`

#### Scenario: Registration enabled
- **WHEN** `domain = "my-new-domain.com"` and `registration` carries an owner contact
- **THEN** one registration is planned for `my-new-domain.com` for one year and `registration_id` is its ID


### Requirement: FR extension details
`owner_contact.extension_fr` SHALL accept `mode` and the optional objects `individual_info` (`whois_opt_in`), `association_info` (`publication_jo`, `publication_jo_page`), `duns_info` (`duns_id`, `local_id`) and `trademark_info` (`trademark_inpi`). Each nested block SHALL be emitted only when set. The module SHALL NOT accept `code_auth_afnic_info`.

#### Scenario: Company with DUNS
- **WHEN** `extension_fr = { mode = "company", duns_info = { duns_id = "123456789" } }`
- **THEN** the owner contact carries one `extension_fr` block with one `duns_info` block and no other nested block

#### Scenario: Mode only
- **WHEN** `extension_fr = { mode = "individual" }`
- **THEN** the `extension_fr` block carries no nested block

#### Scenario: Authorisation code
- **WHEN** `extension_fr` sets `code_auth_afnic_info`
- **THEN** the attribute is not part of the input type, so it is dropped by the type conversion and never sent to the provider

## REMOVED Requirements

### Requirement: Administrative and technical contact IDs are ignored
**Reason**: The provider cannot set these contacts (computed-only); the inputs were ignored since v1.2.0 and their removal was announced for the next major release.
**Migration**: Delete `registration.administrative_contact_id` and `registration.technical_contact_id`; the check `registration_contact_ids_ignored` no longer exists.

### Requirement: Optional domain registration
**Reason**: Registration is enabled by a non-null `registration`; the `register_domain` input and its cross-validation are removed ("Registration enabled by registration object").
**Migration**: Delete `register_domain = true`; keep `registration`.
