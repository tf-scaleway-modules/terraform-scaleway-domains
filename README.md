# Scaleway Domains Terraform Module

[![Apache 2.0][apache-shield]][apache]
[![Terraform][terraform-badge]][terraform-url]
[![Scaleway Provider][scaleway-badge]][scaleway-url]

A **production-ready** Terraform/OpenTofu module for managing Scaleway domain registration, DNS zones, and records. Each feature can be used independently.

## Features

- **Domain Registration** - Register new domains with Scaleway (optional)
- **DNS Zone Management** - Create and manage DNS zones for domains and subdomains
- **Standard DNS Records** - A, AAAA, MX, CNAME, TXT, NS, PTR, SRV, DNAME, ALIAS, TLSA, CAA
- **Geo IP Routing** - Route traffic based on user geographic location
- **Weighted DNS Routing** - Return IPs in proportion to their weight
- **View-based Routing** - Return different IPs based on client subnet (split-horizon)
- **HTTP Health-Checked DNS** - Automatic failover with health checks
- **Input Validation** - Comprehensive validation for all inputs
- **Type Safety** - Full type definitions with optional parameters

## Quick Start

### Prerequisites

- Terraform >= 1.10 or OpenTofu >= 1.10
- Scaleway account with DNS API access
- Domain registered or transferred to Scaleway

### Basic Usage

```hcl
module "dns" {
  source = "path/to/scaleway-domains"

  domain = "example.com"

  records = {
    root = {
      type = "A"
      data = "93.184.216.34"
    }
    www = {
      name = "www"
      type = "CNAME"
      data = "example.com."
    }
    mx = {
      type     = "MX"
      data     = "mail.example.com."
      priority = 10
    }
  }
}
```

### Using a Project

```hcl
module "dns" {
  source = "path/to/scaleway-domains"

  # Omit project_id to use the default project of the provider configuration
  project_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

  domain      = "example.com"
  subdomain   = "staging"
  create_zone = true

  records = {
    root = {
      type = "A"
      data = "10.0.0.1"
    }
  }
}
```

### Record keys

Each record is keyed by the key you choose in `records`, which becomes its address (`module.dns.scaleway_domain_record.this["www"]`). Keep a key stable once applied; adding, removing or reordering other entries does not touch it. `name` defaults to `""` (the zone root).

## Domain Registration

Register a new domain with Scaleway:

```hcl
module "my_domain" {
  source = "path/to/scaleway-domains"

  domain = "my-new-domain.com"

  # Setting registration enables the registration (null, the default, disables it)
  registration = {
    duration_in_years = 1
    auto_renew        = true # renew automatically (billed); default false
    dnssec            = true # needs Scaleway DNS (create_zone); default false

    owner_contact = {
      legal_form     = "individual"
      firstname      = "John"
      lastname       = "Doe"
      email          = "john.doe@example.com"
      phone_number   = "+33123456789"
      address_line_1 = "123 Main Street"
      zip            = "75001"
      city           = "Paris"
      country        = "FR"
    }
  }

  # Optionally create DNS zone and records
  create_zone = true
  records = {
    root = { type = "A", data = "93.184.216.34" }
  }
}
```

For `.fr` domains, `owner_contact.extension_fr` takes `mode` plus one of `individual_info`, `association_info`, `duns_info` or `trademark_info`; `code_auth_afnic_info` is not supported.

`auto_renew` renews the domain before it expires and bills the owner at each renewal. `dnssec` enables DNSSEC: the domain's DNS must be served by Scaleway DNS, and the DS record to publish at the registrar is the `registration_ds_record` output (empty until DNSSEC is enabled). Both default to `false`. The EPP transfer code is never output.

Compatibility: tested with scaleway provider 2.89.0 (constraint `~> 2.89`).

## Advanced Features

### Geo IP Routing

Route users to the nearest datacenter based on their location (`geo_ip` is a list of matches):

```hcl
records = {
  cdn = {
    name = "cdn"
    type = "A"
    data = "10.0.0.1" # Default fallback (required)
    geo_ip = [
      {
        data       = "10.0.1.1" # EU datacenter
        continents = ["EU"]
      },
      {
        data       = "10.0.2.1" # NA datacenter
        continents = ["NA"]
      },
      {
        data = "10.0.0.1" # Default fallback
      }
    ]
  }
}
```

### Weighted DNS Routing

Return IPs in proportion to their weight:

```hcl
records = {
  api = {
    name = "api"
    type = "A"
    data = "10.1.0.1" # Default fallback (required)
    weighted = [
      { ip = "10.1.0.1", weight = 70 }, # 70% traffic
      { ip = "10.1.0.2", weight = 20 }, # 20% traffic
      { ip = "10.1.0.3", weight = 10 }  # 10% traffic
    ]
  }
}
```

### View-based Routing

Return different IPs based on client subnet (split-horizon DNS); each `subnet` must be a CIDR block:

```hcl
records = {
  db = {
    name = "db"
    type = "A"
    data = "203.0.113.10" # Default for external clients
    view = [
      {
        subnet = "10.0.0.0/8"
        data   = "10.100.0.10" # Internal network
      },
      {
        subnet = "192.168.0.0/16"
        data   = "10.100.0.11" # Office network
      }
    ]
  }
}
```

### HTTP Health-Checked DNS

Automatic failover based on health checks:

```hcl
records = {
  api = {
    name = "api"
    type = "A"
    data = "10.2.0.1" # Default fallback (required)
    http_service = {
      ips          = ["10.2.0.1", "10.2.0.2", "10.2.0.3"]
      url          = "http://api.example.com/health"
      must_contain = "healthy"
      strategy     = "hashed" # random, hashed, or all
    }
  }
}
```

## Upgrading from v1 to v2

v2 requires the scaleway provider `~> 2.89`. Every caller changes its inputs:

| v1 | v2 |
|----|----|
| `organization_id` + `project_name` | Removed. Pass `project_id = "<uuid>"`, or nothing for the provider default project |
| `register_domain = true` | Removed. Registration exists when `registration != null`: delete the line, keep `registration = {...}` |
| `registration.administrative_contact_id`, `technical_contact_id` | Removed (they were ignored since v1.2.0): delete both |
| `records = [ {...}, {...} ]` | `records = { <key> = {...} }`: a map keyed by a name you choose (see below) |
| `geo_ip = { matches = X }` | `geo_ip = X` (the list of matches) |
| `view[*].subnet` | Must be a CIDR block (e.g. `10.0.0.0/8`) |
| Record `name` | Optional, defaults to `""` (the zone root) |
| Output `project_id` | Removed: use the value you passed in |
| Output `record_ids` | `[for r in module.dns.records : r.id]` |
| Output `record_fqdns` | `{ for k, r in module.dns.records : k => r.fqdn }` |

### Keep the records (moved blocks)

Records were addressed `scaleway_domain_record.this["<type>_<name>_<index>"]` (`@` for the root name, `index` the position in the list). The new addresses use your map keys. Without action OpenTofu **destroys and recreates** every record (new IDs, a short resolution gap). The module cannot ship the `moved` blocks (the new keys are yours), so add one per record at the root of your configuration, with the old key as `from`:

```hcl
moved {
  from = module.dns.scaleway_domain_record.this["A_@_0"]
  to   = module.dns.scaleway_domain_record.this["root"]
}

moved {
  from = module.dns.scaleway_domain_record.this["CNAME_www_1"]
  to   = module.dns.scaleway_domain_record.this["www"]
}
```

`tofu plan` must then show only moves ("moved from"), with no create or destroy, and a second plan is empty. Alternative without `moved` blocks: `tofu state mv 'module.dns.scaleway_domain_record.this["A_@_0"]' 'module.dns.scaleway_domain_record.this["root"]'` for each record. The registration and the zone keep their addresses (`this[0]`); the removed project data source disappears from state without effect on the cloud.

## Examples

- [Minimal](./examples/minimal/) - Basic A, CNAME, and MX records
- [Complete](./examples/complete/) - All DNS features including dynamic DNS
- [Registration](./examples/registration/) - Domain registration with DNS setup

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [scaleway_domain_record.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_record) | resource |
| [scaleway_domain_registration.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_registration) | resource |
| [scaleway_domain_zone.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether to create the DNS zone.<br/><br/>Set to true to create a new DNS zone for the domain/subdomain.<br/>Set to false if the zone already exists and you only want to manage records. | `bool` | `false` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The root domain name for DNS management.<br/><br/>This is the main domain where DNS zones and records will be created.<br/>The domain can be registered via this module (registration)<br/>or must already be registered/transferred to Scaleway.<br/><br/>Examples: "example.com", "mycompany.io" | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway Project ID applied to the domain registration and the DNS zone.<br/><br/>Leave null to use the default project of the provider configuration.<br/><br/>Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) | `string` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | DNS records to create in the zone, keyed by a name of your choice.<br/><br/>The key becomes the resource address (scaleway\_domain\_record.this["<key>"]):<br/>keep it stable, and reorder or add entries freely.<br/><br/>Each record supports standard DNS attributes plus Scaleway's dynamic DNS features:<br/>- geo\_ip: Route traffic based on user location (list of matches)<br/>- weighted: Return IPs in proportion to their weight<br/>- view: Return different IPs based on client subnet (CIDR)<br/>- http\_service: Health-checked DNS with automatic failover<br/><br/>Record Types: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA<br/><br/>data is required on every record; for dynamic DNS it is the fallback value. | <pre>map(object({<br/>    # Core record attributes<br/>    type     = string                 # DNS record type<br/>    data     = string                 # Record data (fallback value for dynamic DNS)<br/>    name     = optional(string, "")   # Record name (empty string for root)<br/>    ttl      = optional(number, 3600) # Time to live in seconds<br/>    priority = optional(number, null) # Priority (for MX, SRV records)<br/><br/>    # Dynamic DNS: Geo IP routing (one geo_ip block, one matches block per element)<br/>    geo_ip = optional(list(object({<br/>      data       = string                 # IP to return for this match<br/>      countries  = optional(list(string)) # Country codes (FR, US, GB, etc.)<br/>      continents = optional(list(string)) # Continent codes (EU, NA, AS, etc.)<br/>    })))<br/><br/>    # Dynamic DNS: Weighted routing<br/>    weighted = optional(list(object({<br/>      ip     = string # Target IP address<br/>      weight = number # Weight for traffic distribution<br/>    })))<br/><br/>    # Dynamic DNS: View-based routing (by client subnet)<br/>    view = optional(list(object({<br/>      subnet = string # Client subnet in CIDR notation<br/>      data   = string # IP to return for this subnet<br/>    })))<br/><br/>    # Dynamic DNS: HTTP health-checked DNS<br/>    http_service = optional(object({<br/>      ips          = list(string)           # IPs to health check<br/>      must_contain = string                 # String that must be in response<br/>      url          = string                 # Health check URL<br/>      strategy     = string                 # random, hashed, or all<br/>      user_agent   = optional(string, null) # Custom user agent<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_registration"></a> [registration](#input\_registration) | Domain registration configuration.<br/><br/>Set to enable the registration of var.domain; null (default) registers<br/>nothing. Configures the registration period, the owner contact, auto-renewal and DNSSEC.<br/><br/>auto\_renew: renew the domain automatically before it expires. The owner<br/>is billed at each renewal, so it defaults to false.<br/><br/>dnssec: enable DNSSEC. The domain's DNS must be served by Scaleway DNS<br/>(see create\_zone) and the DS record, exposed as registration\_ds\_record,<br/>must be published at the registrar. Enabling it without Scaleway DNS can<br/>break resolution, so it defaults to false.<br/><br/>owner\_contact.extension\_fr carries the .fr details: mode plus one of<br/>individual\_info, association\_info, duns\_info or trademark\_info. | <pre>object({<br/>    # Registration period<br/>    duration_in_years = optional(number, 1) # 1-10 years<br/><br/>    # DEVIATION(terraform-variables): no enable_ prefix; attributes of this object mirror provider argument names<br/>    auto_renew = optional(bool, false) # Renew automatically (billed)<br/>    dnssec     = optional(bool, false) # Enable DNSSEC (requires Scaleway DNS)<br/><br/>    # Owner contact - Required for registration<br/>    # Either provide owner_contact_id OR owner_contact details<br/>    owner_contact_id = optional(string) # ID of existing contact<br/><br/>    owner_contact = optional(object({<br/>      # Legal information<br/>      legal_form   = string                 # individual, corporate, association or other<br/>      firstname    = string                 # First name<br/>      lastname     = string                 # Last name<br/>      company_name = optional(string, null) # Company name (if applicable)<br/><br/>      # Contact information<br/>      email        = string # Email address<br/>      phone_number = string # Phone number with country code (+33...)<br/><br/>      # Address<br/>      address_line_1 = string                 # Street address<br/>      address_line_2 = optional(string, null) # Additional address info<br/>      zip            = string                 # Postal/ZIP code<br/>      city           = string                 # City<br/>      state          = optional(string, null) # State/Province<br/>      country        = string                 # ISO country code (FR, US, etc.)<br/><br/>      # Business identifiers (required for companies)<br/>      vat_identification_code     = optional(string, null) # VAT number<br/>      company_identification_code = optional(string, null) # Company registration number<br/><br/>      # Privacy and additional options<br/>      whois_opt_in = optional(bool, false)     # Opt-in to WHOIS publication<br/>      email_alt    = optional(string, null)    # Alternative email<br/>      lang         = optional(string, "en_US") # Contact language<br/>      resale       = optional(bool, false)     # Reseller flag<br/><br/>      # Extensions for specific TLDs<br/>      extension_fr = optional(object({<br/>        mode = optional(string) # individual, company_identification_code, duns, local, association or trademark<br/><br/>        individual_info = optional(object({<br/>          whois_opt_in = optional(bool) # Publish contact in WHOIS<br/>        }))<br/><br/>        association_info = optional(object({<br/>          publication_jo      = optional(string) # Journal officiel publication date<br/>          publication_jo_page = optional(number) # Journal officiel page<br/>        }))<br/><br/>        duns_info = optional(object({<br/>          duns_id  = optional(string) # D-U-N-S number<br/>          local_id = optional(string) # Local company ID<br/>        }))<br/><br/>        trademark_info = optional(object({<br/>          trademark_inpi = optional(string) # INPI trademark number<br/>        }))<br/>      }))<br/><br/>      extension_eu = optional(object({<br/>        european_citizenship = optional(string) # EU citizenship country<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | The subdomain (zone name) to create within the domain.<br/><br/>Leave empty ("") to manage records directly on the root domain.<br/>Use a subdomain name to create a delegated zone.<br/><br/>Examples: "", "api", "staging" | `string` | `""` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_dns_zone"></a> [dns\_zone](#output\_dns\_zone) | The full DNS zone name (domain or subdomain.domain). |
| <a name="output_records"></a> [records](#output\_records) | Map of DNS records created by this module, keyed like the records input. |
| <a name="output_registration_ds_record"></a> [registration\_ds\_record](#output\_registration\_ds\_record) | The DNSSEC DS record to publish at the registrar; empty until dnssec is enabled (null if registration = null). |
| <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id) | The ID of the domain registration (null if registration = null). |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The ID of the created DNS zone (null if create\_zone = false). |
| <a name="output_zone_ns"></a> [zone\_ns](#output\_zone\_ns) | The nameservers for the created DNS zone. |
| <a name="output_zone_ns_default"></a> [zone\_ns\_default](#output\_zone\_ns\_default) | The default nameservers for the created DNS zone. |
| <a name="output_zone_status"></a> [zone\_status](#output\_zone\_status) | The status of the created DNS zone. |
<!-- END_TF_DOCS -->

## Contributing

### Prerequisites

This module uses [mise](https://mise.jdx.dev/) for tool management:

```bash
# Install mise (if not already installed)
curl https://mise.run | sh

# Install required tools
mise install

# Install pre-commit hooks
pre-commit install --install-hooks
```

### Development Workflow

Changes are planned with [OpenSpec](https://github.com/Fission-AI/OpenSpec): `openspec/specs/` is the module's current contract and [AGENTS.md](AGENTS.md) routes to the engineering standards. Behaviour changes, new inputs, outputs or resources go through a change proposal (`/openspec-propose`) before any code.

1. Fork the repository
2. Create a feature branch
3. Register the OpenSpec standards stores once per machine: `mise run spec-setup`
4. Make your changes
5. Run validation:
   ```bash
   tofu fmt -recursive
   tofu validate
   mise run spec-validate
   ```
6. Pre-commit hooks will automatically run on commit
7. Submit a merge request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Disclaimer

This module is provided "as is" without warranty. Always test in non-production environments first.

---

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
