# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║              MINIMAL EXAMPLE - SCALEWAY DNS MODULE                           ║
# ║                                                                              ║
# ║  Basic usage: Create simple A and CNAME records for an existing domain.     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Provider Configuration
# ==============================================================================

provider "scaleway" {
  region = "fr-par"
}

# ==============================================================================
# DNS Module - Basic Records
# ==============================================================================

module "dns" {
  source = "../../"

  domain = "example.com"

  records = [
    # Root A record
    {
      name = ""
      type = "A"
      data = "93.184.216.34"
    },
    # WWW subdomain
    {
      name = "www"
      type = "CNAME"
      data = "example.com."
    },
    # API subdomain with custom TTL
    {
      name = "api"
      type = "A"
      data = "93.184.216.35"
      ttl  = 300
    },
    # Mail server
    {
      name     = ""
      type     = "MX"
      data     = "mail.example.com."
      priority = 10
    }
  ]
}

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
