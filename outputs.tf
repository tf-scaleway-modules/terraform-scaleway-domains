# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MODULE OUTPUTS                                  ║
# ║                                                                              ║
# ║  Outputs for domain registration, DNS zones, and records.                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Output
# ==============================================================================

output "project_id" {
  description = "The ID of the Scaleway project (resolved from project_name or provided directly)."
  value       = local.project_id
}

# ==============================================================================
# Domain Registration Outputs
# ==============================================================================

output "registration_id" {
  description = "The ID of the domain registration (null if register_domain = false)."
  value       = var.register_domain ? scaleway_domain_registration.this[0].id : null
}

# ==============================================================================
# DNS Zone Outputs
# ==============================================================================

output "dns_zone" {
  description = "The full DNS zone name (domain or subdomain.domain)."
  value       = local.dns_zone
}

output "zone_id" {
  description = "The ID of the created DNS zone (null if create_zone = false)."
  value       = var.create_zone ? scaleway_domain_zone.this[0].id : null
}

output "zone_ns" {
  description = "The nameservers for the created DNS zone."
  value       = var.create_zone ? scaleway_domain_zone.this[0].ns : null
}

output "zone_ns_default" {
  description = "The default nameservers for the created DNS zone."
  value       = var.create_zone ? scaleway_domain_zone.this[0].ns_default : null
}

output "zone_status" {
  description = "The status of the created DNS zone."
  value       = var.create_zone ? scaleway_domain_zone.this[0].status : null
}

# ==============================================================================
# DNS Records Outputs
# ==============================================================================

output "records" {
  description = "Map of all DNS records created by this module."
  value = {
    for key, record in scaleway_domain_record.this : key => {
      id       = record.id
      name     = record.name
      type     = record.type
      data     = record.data
      ttl      = record.ttl
      priority = record.priority
      fqdn     = record.fqdn
    }
  }
}

output "record_ids" {
  description = "List of all DNS record IDs."
  value       = [for record in scaleway_domain_record.this : record.id]
}

output "record_fqdns" {
  description = "Map of record keys to their fully qualified domain names."
  value       = { for key, record in scaleway_domain_record.this : key => record.fqdn }
}
