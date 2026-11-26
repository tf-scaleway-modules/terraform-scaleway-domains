# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              INPUT VARIABLES                                  ║
# ║                                                                               ║
# ║  Configurable parameters for Scaleway DNS Zone and Record management.        ║
# ║  Variables are organized by category with comprehensive validation.          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Configuration
# ==============================================================================

variable "project_id" {
  description = "Scaleway Project ID (UUID) applied to the domain registration and the DNS zone. `null` uses the default project of the provider configuration."
  type        = string
  default     = null

  validation {
    condition     = var.project_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.project_id))
    error_message = "Project ID must be a valid UUID format."
  }
}

# ==============================================================================
# Domain Registration Configuration
# ==============================================================================

# DEVIATION(terraform-variables): no enable_ prefix on auto_renew and dnssec; attributes of this object mirror provider argument names
variable "registration" {
  description = "Domain registration of `domain`: registration period, owner contact, auto-renewal and DNSSEC. `null` (default) registers nothing. See Input reference in the README for every attribute."
  type = object({
    duration_in_years = optional(number, 1)
    auto_renew        = optional(bool, false)
    dnssec            = optional(bool, false)
    owner_contact_id  = optional(string)

    owner_contact = optional(object({
      legal_form                  = string
      firstname                   = string
      lastname                    = string
      company_name                = optional(string, null)
      email                       = string
      phone_number                = string
      address_line_1              = string
      address_line_2              = optional(string, null)
      zip                         = string
      city                        = string
      state                       = optional(string, null)
      country                     = string
      vat_identification_code     = optional(string, null)
      company_identification_code = optional(string, null)
      whois_opt_in                = optional(bool, false)
      email_alt                   = optional(string, null)
      lang                        = optional(string, "en_US")
      resale                      = optional(bool, false)

      extension_fr = optional(object({
        mode = optional(string)

        individual_info = optional(object({
          whois_opt_in = optional(bool)
        }))

        association_info = optional(object({
          publication_jo      = optional(string)
          publication_jo_page = optional(number)
        }))

        duns_info = optional(object({
          duns_id  = optional(string)
          local_id = optional(string)
        }))

        trademark_info = optional(object({
          trademark_inpi = optional(string)
        }))
      }))

      extension_eu = optional(object({
        european_citizenship = optional(string)
      }))
    }))
  })
  default = null

  validation {
    condition     = var.registration == null || (var.registration.duration_in_years >= 1 && var.registration.duration_in_years <= 10)
    error_message = "Registration duration must be between 1 and 10 years."
  }

  validation {
    condition = var.registration == null || (
      var.registration.owner_contact_id != null ||
      var.registration.owner_contact != null
    )
    error_message = "Either owner_contact_id or owner_contact must be provided for domain registration."
  }

  validation {
    condition = (
      try(var.registration.owner_contact.legal_form, null) == null ||
      contains(["individual", "corporate", "association", "other"], try(var.registration.owner_contact.legal_form, ""))
    )
    error_message = "owner_contact.legal_form must be one of: individual, corporate, association, other."
  }

  validation {
    condition = (
      try(var.registration.owner_contact.extension_fr.mode, null) == null ||
      contains(["individual", "company_identification_code", "duns", "local", "association", "trademark"], try(var.registration.owner_contact.extension_fr.mode, ""))
    )
    error_message = "owner_contact.extension_fr.mode must be one of: individual, company_identification_code, duns, local, association, trademark."
  }
}

# ==============================================================================
# DNS Zone Configuration
# ==============================================================================

variable "domain" {
  description = "Root domain name for DNS management, for example `example.com`. It is registered by this module when `registration` is set, otherwise it must already be registered or transferred to Scaleway."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.domain))
    error_message = "Domain must be a valid domain name (e.g., example.com)."
  }
}

variable "subdomain" {
  description = "Subdomain (zone name) within `domain`, for example `api` or `staging`. An empty string (default) manages records directly on the root domain; a name creates a delegated zone."
  type        = string
  default     = ""

  validation {
    condition     = var.subdomain == "" || can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.subdomain))
    error_message = "Subdomain must be empty or a valid subdomain name (lowercase alphanumeric with hyphens)."
  }
}

variable "create_zone" {
  description = "Whether to create the DNS zone for `domain` and `subdomain`. Set to `false` (default) if the zone already exists and you only manage records."
  type        = bool
  default     = false
}

# ==============================================================================
# DNS Records Configuration
# ==============================================================================

variable "records" {
  description = "Map of DNS records to create in the zone, keyed by a stable name of your choice that becomes the resource address. Supports standard records and dynamic DNS (`geo_ip`, `weighted`, `view`, `http_service`). See Input reference in the README for every attribute."
  type = map(object({
    type     = string
    data     = string
    name     = optional(string, "")
    ttl      = optional(number, 3600)
    priority = optional(number, null)

    geo_ip = optional(list(object({
      data       = string
      countries  = optional(list(string))
      continents = optional(list(string))
    })))

    weighted = optional(list(object({
      ip     = string
      weight = number
    })))

    view = optional(list(object({
      subnet = string
      data   = string
    })))

    http_service = optional(object({
      ips          = list(string)
      must_contain = string
      url          = string
      strategy     = string
      user_agent   = optional(string, null)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for r in values(var.records) : contains(
        ["A", "AAAA", "MX", "CNAME", "DNAME", "ALIAS", "NS", "PTR", "SRV", "TXT", "TLSA", "CAA"],
        r.type
      )
    ])
    error_message = "Record type must be one of: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) : r.ttl >= 60 && r.ttl <= 86400
    ])
    error_message = "TTL must be between 60 and 86400 seconds."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) : (
        !contains(["MX", "SRV"], r.type) || r.priority != null
      )
    ])
    error_message = "Priority is required for MX and SRV record types."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) : (
        r.http_service == null ||
        contains(["random", "hashed", "all"], r.http_service.strategy)
      )
    ])
    error_message = "http_service.strategy must be one of: random, hashed, all."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) : r.view == null || alltrue([
        for v in r.view : can(cidrhost(v.subnet, 0))
      ])
    ])
    error_message = "view subnet must be a CIDR block (e.g., 10.0.0.0/8)."
  }
}
