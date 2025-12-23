# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              INPUT VARIABLES                                  ║
# ║                                                                               ║
# ║  Configurable parameters for Scaleway DNS Zone and Record management.        ║
# ║  Variables are organized by category with comprehensive validation.          ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Organization & Project Configuration
# ==============================================================================

variable "organization_id" {
  description = <<-EOT
    Scaleway Organization ID.

    Required when using project_name to look up the project.
    The organization is the top-level entity in Scaleway's hierarchy.
    Find this in the Scaleway Console under Organization Settings.

    Format: UUID (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.organization_id == null || can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.organization_id))
    error_message = "Organization ID must be a valid UUID format."
  }
}

variable "project_name" {
  description = <<-EOT
    Scaleway Project name where resources will be created.

    Use this with organization_id to look up the project by name.
    The project ID will be automatically resolved from this name.

    Naming rules:
    - Must start with a lowercase letter
    - Can contain lowercase letters, numbers, and hyphens
    - Must be 1-63 characters long
  EOT
  type        = string
  default     = null

  validation {
    condition     = var.project_name == null || can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.project_name)) || (var.project_name != null && length(var.project_name) == 1)
    error_message = "Project name must be lowercase alphanumeric with hyphens, start with a letter, and be 1-63 characters."
  }
}

variable "project_id" {
  description = <<-EOT
    Scaleway Project ID where the DNS zone will be created.

    Either provide project_id directly, or use organization_id + project_name
    to look up the project. If neither is provided, uses the default project
    from provider configuration.

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
# DNS Zone Configuration
# ==============================================================================

variable "domain" {
  description = <<-EOT
    The root domain name for DNS management.

    This is the main domain where DNS zones and records will be created.
    The domain must already be registered or transferred to Scaleway.

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
    List of DNS records to create in the zone.

    Each record supports standard DNS attributes plus Scaleway's dynamic DNS features:
    - geo_ip: Route traffic based on user location
    - weighted: Distribute traffic by weight
    - view: Return different IPs based on client subnet
    - http_service: Health-checked DNS with automatic failover

    Record Types: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA
  EOT
  type = list(object({
    # Core record attributes
    name     = string                 # Record name (empty string for root)
    type     = string                 # DNS record type
    data     = optional(string, null) # Record data (required for standard records)
    ttl      = optional(number, 3600) # Time to live in seconds
    priority = optional(number, null) # Priority (for MX, SRV records)

    # Dynamic DNS: Geo IP routing
    geo_ip = optional(object({
      matches = list(object({
        data       = string                 # IP to return for this match
        countries  = optional(list(string)) # Country codes (FR, US, GB, etc.)
        continents = optional(list(string)) # Continent codes (EU, NA, AS, etc.)
      }))
    }))

    # Dynamic DNS: Weighted load balancing
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
  default = []

  validation {
    condition = alltrue([
      for r in var.records : contains(
        ["A", "AAAA", "MX", "CNAME", "DNAME", "ALIAS", "NS", "PTR", "SRV", "TXT", "TLSA", "CAA"],
        r.type
      )
    ])
    error_message = "Record type must be one of: A, AAAA, MX, CNAME, DNAME, ALIAS, NS, PTR, SRV, TXT, TLSA, CAA."
  }

  validation {
    condition = alltrue([
      for r in var.records : r.ttl >= 60 && r.ttl <= 86400
    ])
    error_message = "TTL must be between 60 and 86400 seconds."
  }

  validation {
    condition = alltrue([
      for r in var.records : (
        !contains(["MX", "SRV"], r.type) || r.priority != null
      )
    ])
    error_message = "Priority is required for MX and SRV record types."
  }

  validation {
    condition = alltrue([
      for r in var.records : (
        r.data != null ||
        r.geo_ip != null ||
        r.weighted != null ||
        r.view != null ||
        r.http_service != null
      )
    ])
    error_message = "Each record must have either 'data' or a dynamic DNS configuration (geo_ip, weighted, view, http_service)."
  }

  validation {
    condition = alltrue([
      for r in var.records : (
        r.http_service == null ||
        contains(["random", "hashed", "all"], r.http_service.strategy)
      )
    ])
    error_message = "http_service.strategy must be one of: random, hashed, all."
  }
}
