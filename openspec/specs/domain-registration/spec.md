# domain-registration Specification

## Purpose
Registers the domain with Scaleway Domains, with an owner contact given by ID or inline, for a validated duration.

## Requirements

### Requirement: Optional domain registration
The module SHALL create one `scaleway_domain_registration` named `this` only when `register_domain = true` (default `false`). It SHALL register the single domain `var.domain`, for `registration.duration_in_years` years (default `1`), in the resolved project.

#### Scenario: Registration disabled
- **WHEN** `register_domain = false`
- **THEN** no domain registration is planned and the `registration_id` output is `null`

#### Scenario: Registration enabled
- **WHEN** `register_domain = true`, `domain = "my-new-domain.com"` and `registration` carries an owner contact
- **THEN** one registration is planned for `my-new-domain.com` for one year and `registration_id` is its ID

#### Scenario: Registration enabled without registration details
- **WHEN** `register_domain = true` and `registration = null`
- **THEN** the plan fails

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
