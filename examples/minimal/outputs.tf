# ==============================================================================
# Outputs
# ==============================================================================

output "dns_zone" {
  description = "The DNS zone being managed"
  value       = module.dns.dns_zone
}

output "records" {
  description = "Created DNS records"
  value       = module.dns.records
}
