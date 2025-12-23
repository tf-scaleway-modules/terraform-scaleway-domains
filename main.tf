# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              SCALEWAY DNS MODULE                             ║
# ║                                                                              ║
# ║  Manages Scaleway DNS zones and records with support for:                    ║
# ║  - Standard DNS records (A, AAAA, MX, CNAME, TXT, etc.)                     ║
# ║  - Geo IP routing                                                            ║
# ║  - Weighted load balancing                                                   ║
# ║  - View-based routing (client subnet)                                        ║
# ║  - HTTP health-checked DNS                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

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

  # Ensure zone exists before creating records
  depends_on = [scaleway_domain_zone.this]
}
