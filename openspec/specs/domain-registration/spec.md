# domain-registration Specification

## Purpose
Registers the domain with Scaleway Domains, with an owner contact given by ID or inline, for a validated duration.

## Requirements

### Requirement: Registration duration
`registration.duration_in_years` SHALL be a number from 1 to 10 inclusive, and SHALL default to `1` when omitted.

#### Scenario: Duration above the maximum
- **WHEN** `registration = { duration_in_years = 11, owner_contact_id = "abc" }`
- **THEN** the plan fails with "Registration duration must be between 1 and 10 years."

#### Scenario: Duration below the minimum
- **WHEN** `registration = { duration_in_years = 0, owner_contact_id = "abc" }`
- **THEN** the plan fails with "Registration duration must be between 1 and 10 years."

#### Scenario: Duration omitted
- **WHEN** `registration` is set without `duration_in_years`
- **THEN** the registration is for one year

### Requirement: Owner contact by ID or inline
A non-null `registration` SHALL provide `owner_contact_id` (an existing contact) or an inline `owner_contact` object. An inline `owner_contact` SHALL require `legal_form`, `firstname`, `lastname`, `email`, `phone_number`, `address_line_1`, `zip`, `city` and `country`.

#### Scenario: Neither contact form given
- **WHEN** `registration = { duration_in_years = 1 }`
- **THEN** the plan fails with "Either owner_contact_id or owner_contact must be provided for domain registration."

#### Scenario: Existing contact
- **WHEN** `registration = { owner_contact_id = "<contact id>" }`
- **THEN** the registration uses that contact ID and carries no inline `owner_contact` block

#### Scenario: Inline contact missing a required field
- **WHEN** `owner_contact` omits `email`
- **THEN** the plan fails on the object type

### Requirement: Optional contact attributes
An inline `owner_contact` SHALL accept the optional attributes `company_name`, `address_line_2`, `state`, `vat_identification_code`, `company_identification_code`, `email_alt` (default `null`), `whois_opt_in` (default `false`), `lang` (default `"en_US"`) and `resale` (default `false`), plus an `extension_fr` object (`mode`) and an `extension_eu` object (`european_citizenship`) whose blocks SHALL be emitted only when set.

#### Scenario: Inline contact with defaults
- **WHEN** `registration.owner_contact` sets only the required fields
- **THEN** the registration carries one `owner_contact` block with `whois_opt_in = false`, `lang = "en_US"`, `resale = false` and no extension block

#### Scenario: Inline contact with extensions
- **WHEN** `owner_contact.extension_fr = { mode = "individual" }` and `owner_contact.extension_eu = { european_citizenship = "FR" }` are set
- **THEN** the owner contact carries one `extension_fr` block and one `extension_eu` block with those values

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
