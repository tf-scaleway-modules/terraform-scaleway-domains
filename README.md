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

- OpenTofu >= 1.11.0 or Terraform >= 1.11.0
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

### Input reference

#### registration

Registers `domain` with Scaleway. `null` (default) registers nothing. Either `owner_contact_id` or `owner_contact` is required.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `duration_in_years` | `number` | `1` | Registration period, 1 to 10 years. |
| `auto_renew` | `bool` | `false` | Renew the domain automatically before it expires. The owner is billed at each renewal. |
| `dnssec` | `bool` | `false` | Enable DNSSEC. The domain's DNS must be served by Scaleway DNS (see `create_zone`) and the DS record, exposed as `registration_ds_record`, must be published at the registrar. Enabling it without Scaleway DNS can break resolution. |
| `owner_contact_id` | `string` | `null` | ID of an existing owner contact. |
| `owner_contact` | `object` | `null` | Owner contact details, see below. |

`auto_renew` and `dnssec` have no `enable_` prefix because the attributes of this object mirror the provider argument names.

`owner_contact` attributes:

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `legal_form` | `string` | required | Legal form, validated: `individual`, `corporate`, `association` or `other`. |
| `firstname` | `string` | required | First name. |
| `lastname` | `string` | required | Last name. |
| `company_name` | `string` | `null` | Company name, if applicable. |
| `email` | `string` | required | Email address. |
| `phone_number` | `string` | required | Phone number with country code, for example `+33123456789`. |
| `address_line_1` | `string` | required | Street address. |
| `address_line_2` | `string` | `null` | Additional address information. |
| `zip` | `string` | required | Postal or ZIP code. |
| `city` | `string` | required | City. |
| `state` | `string` | `null` | State or province. |
| `country` | `string` | required | ISO country code, for example `FR` or `US`. |
| `vat_identification_code` | `string` | `null` | VAT number (required for companies). |
| `company_identification_code` | `string` | `null` | Company registration number (required for companies). |
| `whois_opt_in` | `bool` | `false` | Opt in to WHOIS publication. |
| `email_alt` | `string` | `null` | Alternative email address. |
| `lang` | `string` | `"en_US"` | Contact language. |
| `resale` | `bool` | `false` | Reseller flag. |
| `extension_fr` | `object` | `null` | `.fr` details, see below. |
| `extension_eu` | `object` | `null` | `.eu` details: `european_citizenship` (`string`, EU citizenship country). |

`owner_contact.extension_fr` carries the `.fr` details: `mode` plus one of `individual_info`, `association_info`, `duns_info` or `trademark_info`.

| Attribute | Type | Description |
|-----------|------|-------------|
| `mode` | `string` | Mode, validated: `individual`, `company_identification_code`, `duns`, `local`, `association` or `trademark`. |
| `individual_info.whois_opt_in` | `bool` | Publish the contact in WHOIS. |
| `association_info.publication_jo` | `string` | Journal officiel publication date. |
| `association_info.publication_jo_page` | `number` | Journal officiel page. |
| `duns_info.duns_id` | `string` | D-U-N-S number. |
| `duns_info.local_id` | `string` | Local company ID. |
| `trademark_info.trademark_inpi` | `string` | INPI trademark number. |

#### records

Map of DNS records to create in the zone, keyed by a name of your choice (default `{}`). The key becomes the resource address (`scaleway_domain_record.this["<key>"]`): keep it stable, and reorder or add entries freely.

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `type` | `string` | required | One of `A`, `AAAA`, `MX`, `CNAME`, `DNAME`, `ALIAS`, `NS`, `PTR`, `SRV`, `TXT`, `TLSA`, `CAA`. |
| `data` | `string` | required | Record data. For dynamic DNS it is the fallback value. |
| `name` | `string` | `""` | Record name; the empty string is the zone root. |
| `ttl` | `number` | `3600` | Time to live in seconds, 60 to 86400. |
| `priority` | `number` | `null` | Priority, required for `MX` and `SRV` records. |
| `geo_ip` | `list(object)` | `null` | Route traffic by user location, see below. |
| `weighted` | `list(object)` | `null` | Return IPs in proportion to their weight, see below. |
| `view` | `list(object)` | `null` | Return different IPs by client subnet, see below. |
| `http_service` | `object` | `null` | Health-checked DNS with automatic failover, see below. |

Dynamic DNS attributes (examples in [Advanced Features](#advanced-features)):

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `geo_ip[*].data` | `string` | required | IP to return for this match. |
| `geo_ip[*].countries` | `list(string)` | `null` | Country codes, for example `FR`, `US`, `GB`. |
| `geo_ip[*].continents` | `list(string)` | `null` | Continent codes, for example `EU`, `NA`, `AS`. |
| `weighted[*].ip` | `string` | required | Target IP address. |
| `weighted[*].weight` | `number` | required | Weight for the traffic distribution. |
| `view[*].subnet` | `string` | required | Client subnet in CIDR notation, for example `10.0.0.0/8`. |
| `view[*].data` | `string` | required | IP to return for this subnet. |
| `http_service.ips` | `list(string)` | required | IPs to health check. |
| `http_service.must_contain` | `string` | required | String that must be in the response. |
| `http_service.url` | `string` | required | Health check URL. |
| `http_service.strategy` | `string` | required | One of `random`, `hashed` or `all`. |
| `http_service.user_agent` | `string` | `null` | Custom user agent. |

`geo_ip` is one block with one match per list element.

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
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_scaleway"></a> [scaleway](#requirement\_scaleway) | ~> 2.89 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_scaleway"></a> [scaleway](#provider\_scaleway) | ~> 2.89 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [scaleway_domain_record.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_record) | resource |
| [scaleway_domain_registration.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_registration) | resource |
| [scaleway_domain_zone.this](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs/resources/domain_zone) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_zone"></a> [create\_zone](#input\_create\_zone) | Whether to create the DNS zone for `domain` and `subdomain`. Set to `false` (default) if the zone already exists and you only manage records. | `bool` | `false` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Root domain name for DNS management, for example `example.com`. It is registered by this module when `registration` is set, otherwise it must already be registered or transferred to Scaleway. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Scaleway Project ID (UUID) applied to the domain registration and the DNS zone. `null` uses the default project of the provider configuration. | `string` | `null` | no |
| <a name="input_records"></a> [records](#input\_records) | Map of DNS records to create in the zone, keyed by a stable name of your choice that becomes the resource address. Supports standard records and dynamic DNS (`geo_ip`, `weighted`, `view`, `http_service`). See Input reference in the README for every attribute. | <pre>map(object({<br/>    type     = string<br/>    data     = string<br/>    name     = optional(string, "")<br/>    ttl      = optional(number, 3600)<br/>    priority = optional(number, null)<br/><br/>    geo_ip = optional(list(object({<br/>      data       = string<br/>      countries  = optional(list(string))<br/>      continents = optional(list(string))<br/>    })))<br/><br/>    weighted = optional(list(object({<br/>      ip     = string<br/>      weight = number<br/>    })))<br/><br/>    view = optional(list(object({<br/>      subnet = string<br/>      data   = string<br/>    })))<br/><br/>    http_service = optional(object({<br/>      ips          = list(string)<br/>      must_contain = string<br/>      url          = string<br/>      strategy     = string<br/>      user_agent   = optional(string, null)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_registration"></a> [registration](#input\_registration) | Domain registration of `domain`: registration period, owner contact, auto-renewal and DNSSEC. `null` (default) registers nothing. See Input reference in the README for every attribute. | <pre>object({<br/>    duration_in_years = optional(number, 1)<br/>    auto_renew        = optional(bool, false)<br/>    dnssec            = optional(bool, false)<br/>    owner_contact_id  = optional(string)<br/><br/>    owner_contact = optional(object({<br/>      legal_form                  = string<br/>      firstname                   = string<br/>      lastname                    = string<br/>      company_name                = optional(string, null)<br/>      email                       = string<br/>      phone_number                = string<br/>      address_line_1              = string<br/>      address_line_2              = optional(string, null)<br/>      zip                         = string<br/>      city                        = string<br/>      state                       = optional(string, null)<br/>      country                     = string<br/>      vat_identification_code     = optional(string, null)<br/>      company_identification_code = optional(string, null)<br/>      whois_opt_in                = optional(bool, false)<br/>      email_alt                   = optional(string, null)<br/>      lang                        = optional(string, "en_US")<br/>      resale                      = optional(bool, false)<br/><br/>      extension_fr = optional(object({<br/>        mode = optional(string)<br/><br/>        individual_info = optional(object({<br/>          whois_opt_in = optional(bool)<br/>        }))<br/><br/>        association_info = optional(object({<br/>          publication_jo      = optional(string)<br/>          publication_jo_page = optional(number)<br/>        }))<br/><br/>        duns_info = optional(object({<br/>          duns_id  = optional(string)<br/>          local_id = optional(string)<br/>        }))<br/><br/>        trademark_info = optional(object({<br/>          trademark_inpi = optional(string)<br/>        }))<br/>      }))<br/><br/>      extension_eu = optional(object({<br/>        european_citizenship = optional(string)<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain (zone name) within `domain`, for example `api` or `staging`. An empty string (default) manages records directly on the root domain; a name creates a delegated zone. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
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
[terraform-badge]: https://img.shields.io/badge/Terraform-%3E%3D1.11.0-623CE4
[terraform-url]: https://www.terraform.io
[scaleway-badge]: https://img.shields.io/badge/Scaleway%20Provider-%3E%3D2.89-4f0599
[scaleway-url]: https://registry.terraform.io/providers/scaleway/scaleway/
