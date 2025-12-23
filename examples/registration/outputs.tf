# ==============================================================================
# Outputs
# ==============================================================================

output "registration_id" {
  description = "The domain registration ID"
  value       = module.my_domain.registration_id
}

output "dns_zone" {
  description = "The DNS zone"
  value       = module.my_domain.dns_zone
}

output "zone_nameservers" {
  description = "Nameservers to configure at your registrar"
  value       = module.my_domain.zone_ns
}

output "records" {
  description = "Created DNS records"
  value       = module.my_domain.records
}
