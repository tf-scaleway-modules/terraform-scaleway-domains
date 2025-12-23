# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                           SCALEWAY DOMAINS MODULE                            ║
# ║                                                                              ║
# ║  Manages Scaleway domain resources (can be used independently):              ║
# ║                                                                              ║
# ║  1. Domain Registration (optional)                                           ║
# ║     - Register new domains with Scaleway                                     ║
# ║     - Configure owner/admin/technical contacts                               ║
# ║                                                                              ║
# ║  2. DNS Zone Management (optional)                                           ║
# ║     - Create DNS zones for domains/subdomains                                ║
# ║                                                                              ║
# ║  3. DNS Records (optional)                                                   ║
# ║     - Standard records (A, AAAA, MX, CNAME, TXT, etc.)                      ║
# ║     - Geo IP routing                                                         ║
# ║     - Weighted load balancing                                                ║
# ║     - View-based routing (split-horizon DNS)                                 ║
# ║     - HTTP health-checked DNS                                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Domain Registration
# ------------------------------------------------------------------------------
# Registers a new domain with Scaleway Domains.
# Set register_domain = true and provide registration details.
# ==============================================================================

resource "scaleway_domain_registration" "this" {
  count = var.register_domain ? 1 : 0

  domain_names      = [var.domain]
  duration_in_years = var.registration.duration_in_years
  project_id        = local.project_id

  lifecycle {
    precondition {
      condition     = var.registration != null
      error_message = "The 'registration' variable must be provided when 'register_domain' is true."
    }
  }

  # Owner contact - either by ID or inline definition
  owner_contact_id = var.registration.owner_contact_id

  dynamic "owner_contact" {
    for_each = var.registration.owner_contact != null ? [var.registration.owner_contact] : []

    content {
      legal_form                  = owner_contact.value.legal_form
      firstname                   = owner_contact.value.firstname
      lastname                    = owner_contact.value.lastname
      company_name                = owner_contact.value.company_name
      email                       = owner_contact.value.email
      phone_number                = owner_contact.value.phone_number
      address_line_1              = owner_contact.value.address_line_1
      address_line_2              = owner_contact.value.address_line_2
      zip                         = owner_contact.value.zip
      city                        = owner_contact.value.city
      state                       = owner_contact.value.state
      country                     = owner_contact.value.country
      vat_identification_code     = owner_contact.value.vat_identification_code
      company_identification_code = owner_contact.value.company_identification_code
      whois_opt_in                = owner_contact.value.whois_opt_in
      email_alt                   = owner_contact.value.email_alt
      lang                        = owner_contact.value.lang
      resale                      = owner_contact.value.resale

      # FR extension
      dynamic "extension_fr" {
        for_each = owner_contact.value.extension_fr != null ? [owner_contact.value.extension_fr] : []

        content {
          mode = extension_fr.value.mode
        }
      }

      # EU extension
      dynamic "extension_eu" {
        for_each = owner_contact.value.extension_eu != null ? [owner_contact.value.extension_eu] : []

        content {
          european_citizenship = extension_eu.value.european_citizenship
        }
      }
    }
  }
}

# ==============================================================================
# DNS Zone
# ------------------------------------------------------------------------------
# Creates a DNS zone for the specified domain/subdomain.
# Set create_zone = true to create a new zone, or false to use an existing one.
# ==============================================================================

resource "scaleway_domain_zone" "this" {
  count = var.create_zone ? 1 : 0

  domain     = var.domain
  subdomain  = var.subdomain
  project_id = local.project_id
}

# ==============================================================================
# DNS Records
# ------------------------------------------------------------------------------
# Creates DNS records with support for standard and dynamic DNS features.
# Each record can use either simple data or advanced routing options.
# ==============================================================================

resource "scaleway_domain_record" "this" {
  for_each = local.records_map

  dns_zone = local.dns_zone
  name     = each.value.name
  type     = each.value.type
  ttl      = each.value.ttl

  # Standard record data (mutually exclusive with dynamic DNS blocks)
  data = each.value.data

  # Priority for MX/SRV records
  priority = each.value.priority

  # ---------------------------------------------------------------------------
  # Dynamic DNS: Geo IP Routing
  # ---------------------------------------------------------------------------
  dynamic "geo_ip" {
    for_each = each.value.geo_ip != null ? [each.value.geo_ip] : []

    content {
      dynamic "matches" {
        for_each = geo_ip.value.matches

        content {
          data       = matches.value.data
          countries  = matches.value.countries
          continents = matches.value.continents
        }
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Dynamic DNS: Weighted Load Balancing
  # ---------------------------------------------------------------------------
  dynamic "weighted" {
    for_each = each.value.weighted != null ? each.value.weighted : []

    content {
      ip     = weighted.value.ip
      weight = weighted.value.weight
    }
  }

  # ---------------------------------------------------------------------------
  # Dynamic DNS: View-based Routing (by client subnet)
  # ---------------------------------------------------------------------------
  dynamic "view" {
    for_each = each.value.view != null ? each.value.view : []

    content {
      subnet = view.value.subnet
      data   = view.value.data
    }
  }

  # ---------------------------------------------------------------------------
  # Dynamic DNS: HTTP Health-checked DNS
  # ---------------------------------------------------------------------------
  dynamic "http_service" {
    for_each = each.value.http_service != null ? [each.value.http_service] : []

    content {
      ips          = http_service.value.ips
      must_contain = http_service.value.must_contain
      url          = http_service.value.url
      strategy     = http_service.value.strategy
      user_agent   = http_service.value.user_agent
    }
  }

  # Ensure zone exists before creating records (if zone is being created)
  depends_on = [scaleway_domain_zone.this]
}
