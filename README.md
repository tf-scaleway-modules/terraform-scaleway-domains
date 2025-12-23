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
- **Weighted Load Balancing** - Distribute traffic across servers by weight
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

  records = [
    {
      name = ""
      type = "A"
      data = "93.184.216.34"
    },
    {
      name = "www"
      type = "CNAME"
      data = "example.com."
    },
    {
      name     = ""
      type     = "MX"
      data     = "mail.example.com."
      priority = 10
    }
  ]
}
```

### Using Project Name Lookup

```hcl
module "dns" {
  source = "path/to/scaleway-domains"

  # Lookup project by name
  organization_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  project_name    = "my-project"

  domain      = "example.com"
  subdomain   = "staging"
  create_zone = true

  records = [
    {
      name = ""
      type = "A"
      data = "10.0.0.1"
    }
  ]
}
```

## Domain Registration

Register a new domain with Scaleway:

```hcl
module "my_domain" {
  source = "path/to/scaleway-domains"

  domain          = "my-new-domain.com"
  register_domain = true

  registration = {
    duration_in_years = 1

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
  records = [
    { name = "", type = "A", data = "93.184.216.34" }
  ]
}
```

## Advanced Features

### Geo IP Routing

Route users to the nearest datacenter based on their location:

```hcl
records = [
  {
    name = "cdn"
    type = "A"
    geo_ip = {
      matches = [
        {
          data       = "10.0.1.1"  # EU datacenter
          continents = ["EU"]
        },
        {
          data       = "10.0.2.1"  # NA datacenter
          continents = ["NA"]
        },
        {
          data = "10.0.0.1"  # Default fallback
        }
      ]
    }
  }
]
```

### Weighted Load Balancing

Distribute traffic across multiple servers:

```hcl
records = [
  {
    name = "api"
    type = "A"
    weighted = [
      { ip = "10.1.0.1", weight = 70 },  # 70% traffic
      { ip = "10.1.0.2", weight = 20 },  # 20% traffic
      { ip = "10.1.0.3", weight = 10 }   # 10% traffic
    ]
  }
]
```

### View-based Routing

Return different IPs based on client subnet (split-horizon DNS):

```hcl
records = [
  {
    name = "db"
    type = "A"
    data = "203.0.113.10"  # Default for external clients
    view = [
      {
        subnet = "10.0.0.0/8"
        data   = "10.100.0.10"  # Internal network
      },
      {
        subnet = "192.168.0.0/16"
        data   = "10.100.0.11"  # Office network
      }
    ]
  }
]
```

### HTTP Health-Checked DNS

Automatic failover based on health checks:

```hcl
records = [
  {
    name = "api"
    type = "A"
    http_service = {
      ips          = ["10.2.0.1", "10.2.0.2", "10.2.0.3"]
      url          = "http://api.example.com/health"
      must_contain = "healthy"
      strategy     = "hashed"  # random, hashed, or all
    }
  }
]
```

## Examples

- [Minimal](./examples/minimal/) - Basic A, CNAME, and MX records
- [Complete](./examples/complete/) - All DNS features including dynamic DNS
- [Registration](./examples/registration/) - Domain registration with DNS setup

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.10.7 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.64 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | 2.65.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_domain_record.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_record) | resource |
| [scaleway_domain_registration.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_registration) | resource |
| [scaleway_domain_zone.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_zone) | resource |
| [scaleway_account_project.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/data-sources/account_project) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether to create the DNS zone.<br/><br/>Set to true to create a new DNS zone for the domain/subdomain.<br/>Set to false if the zone already exists and you only want to manage records. | `bool` | `false` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | The root domain name for DNS management.<br/><br/>This is the main domain where DNS zones and records will be created.<br/>The domain can be registered via this module (register\_domain = true)<br/>or must already be registered/transferred to Scaleway.<br/><br/>Examples: "example.com", "mycompany.io" | `string` | n/a | yes |
| <a name="input_organization_id"></a> [organization\_id](#input\_organization\_id) | Scaleway Organization ID.<br/><br/>Required when using project\_name to look up the project.<br/>The organization is the top-level entity in Scaleway's hierarchy.<br/>Find this in the Scaleway Console under Organization Settings.<br/><br/>Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway Project ID where the DNS zone will be created.<br/><br/>Either provide project\_id directly, or use organization\_id + project\_name<br/>to look up the project. If neither is provided, uses the default project<br/>from provider configuration.<br/><br/>Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx) | `string` | `null` | no |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Scaleway Project name where resources will be created.<br/><br/>Use this with organization\_id to look up the project by name.<br/>The project ID will be automatically resolved from this name.<br/><br/>Naming rules:<br/>- Must start with a lowercase letter<br/>- Can contain lowercase letters, numbers, and hyphens<br/>- Must be 1-63 characters long | `string` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | List of DNS records to create in the zone.<br/><br/>Each record supports standard DNS attributes plus Scaleway's dynamic DNS features:<br/>- geo\_ip: Route traffic based on user location<br/>- weighted: Distribute traffic by weight<br/>- view: Return different IPs based on client subnet<br/>- http\_service: Health-checked DNS with automatic failover<br/><br/>Record Types: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA | <pre>list(object({<br/>    # Core record attributes<br/>    name     = string                 # Record name (empty string for root)<br/>    type     = string                 # DNS record type<br/>    data     = optional(string, null) # Record data (required for standard records)<br/>    ttl      = optional(number, 3600) # Time to live in seconds<br/>    priority = optional(number, null) # Priority (for MX, SRV records)<br/><br/>    # Dynamic DNS: Geo IP routing<br/>    geo_ip = optional(object({<br/>      matches = list(object({<br/>        data       = string                 # IP to return for this match<br/>        countries  = optional(list(string)) # Country codes (FR, US, GB, etc.)<br/>        continents = optional(list(string)) # Continent codes (EU, NA, AS, etc.)<br/>      }))<br/>    }))<br/><br/>    # Dynamic DNS: Weighted load balancing<br/>    weighted = optional(list(object({<br/>      ip     = string # Target IP address<br/>      weight = number # Weight for traffic distribution<br/>    })))<br/><br/>    # Dynamic DNS: View-based routing (by client subnet)<br/>    view = optional(list(object({<br/>      subnet = string # Client subnet in CIDR notation<br/>      data   = string # IP to return for this subnet<br/>    })))<br/><br/>    # Dynamic DNS: HTTP health-checked DNS<br/>    http_service = optional(object({<br/>      ips          = list(string)           # IPs to health check<br/>      must_contain = string                 # String that must be in response<br/>      url          = string                 # Health check URL<br/>      strategy     = string                 # random, hashed, or all<br/>      user_agent   = optional(string, null) # Custom user agent<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_register_domain"></a> [register\_domain](#input\_register\_domain) | Whether to register the domain with Scaleway.<br/><br/>Set to true to register a new domain or manage an existing registration.<br/>Set to false if the domain is already registered elsewhere.<br/><br/>IMPORTANT: Domain registration incurs costs and is subject to registrar policies. | `bool` | `false` | no |
| <a name="input_registration"></a> [registration](#input\_registration) | Domain registration configuration.<br/><br/>Required when register\_domain = true.<br/>Configures registration period, contacts, auto-renewal, and DNSSEC. | <pre>object({<br/>    # Registration period<br/>    duration_in_years = optional(number, 1) # 1-10 years<br/><br/>    # Owner contact - Required for registration<br/>    # Either provide owner_contact_id OR owner_contact details<br/>    owner_contact_id = optional(string) # ID of existing contact<br/><br/>    owner_contact = optional(object({<br/>      # Legal information<br/>      legal_form   = string                 # individual, company, association, etc.<br/>      firstname    = string                 # First name<br/>      lastname     = string                 # Last name<br/>      company_name = optional(string, null) # Company name (if applicable)<br/><br/>      # Contact information<br/>      email        = string # Email address<br/>      phone_number = string # Phone number with country code (+33...)<br/><br/>      # Address<br/>      address_line_1 = string                 # Street address<br/>      address_line_2 = optional(string, null) # Additional address info<br/>      zip            = string                 # Postal/ZIP code<br/>      city           = string                 # City<br/>      state          = optional(string, null) # State/Province<br/>      country        = string                 # ISO country code (FR, US, etc.)<br/><br/>      # Business identifiers (required for companies)<br/>      vat_identification_code     = optional(string, null) # VAT number<br/>      company_identification_code = optional(string, null) # Company registration number<br/><br/>      # Privacy and additional options<br/>      whois_opt_in = optional(bool, false)     # Opt-in to WHOIS publication<br/>      email_alt    = optional(string, null)    # Alternative email<br/>      lang         = optional(string, "en_US") # Contact language<br/>      resale       = optional(bool, false)     # Reseller flag<br/><br/>      # Extensions for specific TLDs<br/>      extension_fr = optional(object({<br/>        mode = optional(string) # individual, company, trademark, etc.<br/>      }))<br/><br/>      extension_eu = optional(object({<br/>        european_citizenship = optional(string) # EU citizenship country<br/>      }))<br/>    }))<br/><br/>    # Administrative contact (optional - defaults to owner)<br/>    administrative_contact_id = optional(string)<br/><br/>    # Technical contact (optional - defaults to owner)<br/>    technical_contact_id = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | The subdomain (zone name) to create within the domain.<br/><br/>Leave empty ("") to manage records directly on the root domain.<br/>Use a subdomain name to create a delegated zone.<br/><br/>Examples: "", "api", "staging" | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dns_zone"></a> [dns\_zone](#output\_dns\_zone) | The full DNS zone name (domain or subdomain.domain). |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | The ID of the Scaleway project (resolved from project\_name or provided directly). |
| <a name="output_record_fqdns"></a> [record\_fqdns](#output\_record\_fqdns) | Map of record keys to their fully qualified domain names. |
| <a name="output_record_ids"></a> [record\_ids](#output\_record\_ids) | List of all DNS record IDs. |
| <a name="output_records"></a> [records](#output\_records) | Map of all DNS records created by this module. |
| <a name="output_registration_id"></a> [registration\_id](#output\_registration\_id) | The ID of the domain registration (null if register\_domain = false). |
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

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run validation:
   ```bash
   tofu fmt -recursive
   tofu validate
   ```
5. Pre-commit hooks will automatically run on commit
6. Submit a merge request

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) for details.

## Disclaimer

This module is provided "as is" without warranty. Always test in non-production environments first.

---

[apache]: https://opensource.org/licenses/Apache-2.0
[apache-shield]: https://img.shields.io/badge/License-Apache%202.0-blue.svg
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.10-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.64-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
