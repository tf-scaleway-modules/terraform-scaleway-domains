# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MODULE OUTPUTS                                  ║
# ║                                                                              ║
# ║  Outputs for domain registration, DNS zones, and records.                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Domain Registration Outputs
# ==============================================================================

output "registration_id" {
  description = "The ID of the domain registration (null if registration = null)."
  value       = one(scaleway_domain_registration.this[*].id)
}

output "registration_ds_record" {
  description = "The DNSSEC DS record to publish at the registrar; empty until dnssec is enabled (null if registration = null)."
  value       = one(scaleway_domain_registration.this[*].ds_record)
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
  description = "Map of DNS records created by this module, keyed like the records input."
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
