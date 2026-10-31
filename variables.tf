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
  description = <<-EOT
    Scaleway Project ID applied to the domain registration and the DNS zone.

    Leave null to use the default project of the provider configuration.

    Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  EOT
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

variable "registration" {
  description = <<-EOT
    Domain registration configuration.

    Set to enable the registration of var.domain; null (default) registers
    nothing. Configures the registration period, the owner contact, auto-renewal and DNSSEC.

    auto_renew: renew the domain automatically before it expires. The owner
    is billed at each renewal, so it defaults to false.

    dnssec: enable DNSSEC. The domain's DNS must be served by Scaleway DNS
    (see create_zone) and the DS record, exposed as registration_ds_record,
    must be published at the registrar. Enabling it without Scaleway DNS can
    break resolution, so it defaults to false.

    owner_contact.extension_fr carries the .fr details: mode plus one of
    individual_info, association_info, duns_info or trademark_info.
  EOT
  type = object({
    # Registration period
    duration_in_years = optional(number, 1) # 1-10 years

    # DEVIATION(terraform-variables): no enable_ prefix; attributes of this object mirror provider argument names
    auto_renew = optional(bool, false) # Renew automatically (billed)
    dnssec     = optional(bool, false) # Enable DNSSEC (requires Scaleway DNS)

    # Owner contact - Required for registration
    # Either provide owner_contact_id OR owner_contact details
    owner_contact_id = optional(string) # ID of existing contact

    owner_contact = optional(object({
      # Legal information
      legal_form   = string                 # individual, company, association, etc.
      firstname    = string                 # First name
      lastname     = string                 # Last name
      company_name = optional(string, null) # Company name (if applicable)

      # Contact information
      email        = string # Email address
      phone_number = string # Phone number with country code (+33...)

      # Address
      address_line_1 = string                 # Street address
      address_line_2 = optional(string, null) # Additional address info
      zip            = string                 # Postal/ZIP code
      city           = string                 # City
      state          = optional(string, null) # State/Province
      country        = string                 # ISO country code (FR, US, etc.)

      # Business identifiers (required for companies)
      vat_identification_code     = optional(string, null) # VAT number
      company_identification_code = optional(string, null) # Company registration number

      # Privacy and additional options
      whois_opt_in = optional(bool, false)     # Opt-in to WHOIS publication
      email_alt    = optional(string, null)    # Alternative email
      lang         = optional(string, "en_US") # Contact language
      resale       = optional(bool, false)     # Reseller flag

      # Extensions for specific TLDs
      extension_fr = optional(object({
        mode = optional(string) # individual, company, trademark, etc.

        individual_info = optional(object({
          whois_opt_in = optional(bool) # Publish contact in WHOIS
        }))

        association_info = optional(object({
          publication_jo      = optional(string) # Journal officiel publication date
          publication_jo_page = optional(number) # Journal officiel page
        }))

        duns_info = optional(object({
          duns_id  = optional(string) # D-U-N-S number
          local_id = optional(string) # Local company ID
        }))

        trademark_info = optional(object({
          trademark_inpi = optional(string) # INPI trademark number
        }))
      }))

      extension_eu = optional(object({
        european_citizenship = optional(string) # EU citizenship country
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
}

# ==============================================================================
# DNS Zone Configuration
# ==============================================================================

variable "domain" {
  description = <<-EOT
    The root domain name for DNS management.

    This is the main domain where DNS zones and records will be created.
    The domain can be registered via this module (registration)
    or must already be registered/transferred to Scaleway.

    Examples: "example.com", "mycompany.io"
  EOT
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.domain))
    error_message = "Domain must be a valid domain name (e.g., example.com)."
  }
}

variable "subdomain" {
  description = <<-EOT
    The subdomain (zone name) to create within the domain.

    Leave empty ("") to manage records directly on the root domain.
    Use a subdomain name to create a delegated zone.

    Examples: "", "api", "staging"
  EOT
  type        = string
  default     = ""

  validation {
    condition     = var.subdomain == "" || can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.subdomain))
    error_message = "Subdomain must be empty or a valid subdomain name (lowercase alphanumeric with hyphens)."
  }
}

variable "create_zone" {
  description = <<-EOT
    Whether to create the DNS zone.

    Set to true to create a new DNS zone for the domain/subdomain.
    Set to false if the zone already exists and you only want to manage records.
  EOT
  type        = bool
  default     = false
}

# ==============================================================================
# DNS Records Configuration
# ==============================================================================

variable "records" {
  description = <<-EOT
    DNS records to create in the zone, keyed by a name of your choice.

    The key becomes the resource address (scaleway_domain_record.this["<key>"]):
    keep it stable, and reorder or add entries freely.

    Each record supports standard DNS attributes plus Scaleway's dynamic DNS features:
    - geo_ip: Route traffic based on user location (list of matches)
    - weighted: Return IPs in proportion to their weight
    - view: Return different IPs based on client subnet (CIDR)
    - http_service: Health-checked DNS with automatic failover

    Record Types: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA

    data is required on every record; for dynamic DNS it is the fallback value.
  EOT
  type = map(object({
    # Core record attributes
    type     = string                 # DNS record type
    data     = string                 # Record data (fallback value for dynamic DNS)
    name     = optional(string, "")   # Record name (empty string for root)
    ttl      = optional(number, 3600) # Time to live in seconds
    priority = optional(number, null) # Priority (for MX, SRV records)

    # Dynamic DNS: Geo IP routing (one geo_ip block, one matches block per element)
    geo_ip = optional(list(object({
      data       = string                 # IP to return for this match
      countries  = optional(list(string)) # Country codes (FR, US, GB, etc.)
      continents = optional(list(string)) # Continent codes (EU, NA, AS, etc.)
    })))

    # Dynamic DNS: Weighted routing
    weighted = optional(list(object({
      ip     = string # Target IP address
      weight = number # Weight for traffic distribution
    })))

    # Dynamic DNS: View-based routing (by client subnet)
    view = optional(list(object({
      subnet = string # Client subnet in CIDR notation
      data   = string # IP to return for this subnet
    })))

    # Dynamic DNS: HTTP health-checked DNS
    http_service = optional(object({
      ips          = list(string)           # IPs to health check
      must_contain = string                 # String that must be in response
      url          = string                 # Health check URL
      strategy     = string                 # random, hashed, or all
      user_agent   = optional(string, null) # Custom user agent
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
