# ==============================================================================
# Outputs
# ==============================================================================

output "project_id" {
  description = "The resolved project ID"
  value       = module.dns.project_id
}

output "dns_zone" {
  description = "The DNS zone being managed"
  value       = module.dns.dns_zone
}

output "zone_id" {
  description = "The DNS zone ID"
  value       = module.dns.zone_id
}

output "zone_nameservers" {
  description = "Nameservers for the zone"
  value       = module.dns.zone_ns
}

output "records" {
  description = "All created DNS records"
  value       = module.dns.records
}

output "record_fqdns" {
  description = "FQDNs for all records"
  value       = module.dns.record_fqdns
}
