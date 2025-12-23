# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║             COMPLETE EXAMPLE - SCALEWAY DNS MODULE                           ║
# ║                                                                              ║
# ║  Advanced usage demonstrating all DNS features including:                    ║
# ║  - Zone creation                                                             ║
# ║  - Standard DNS records                                                      ║
# ║  - Geo IP routing                                                            ║
# ║  - Weighted load balancing                                                   ║
# ║  - View-based routing                                                        ║
# ║  - HTTP health-checked DNS                                                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Variables
# ==============================================================================

variable "organization_id" {
  description = "Your Scaleway Organization ID"
  type        = string
}

variable "project_name" {
  description = "Your Scaleway Project name"
  type        = string
}

# ==============================================================================
# Provider Configuration
# ==============================================================================

provider "scaleway" {
  region = "fr-par"
}

# ==============================================================================
# DNS Module - Full Featured Setup
# ==============================================================================

module "dns" {
  source = "../../"

  # Project configuration (lookup by name)
  organization_id = var.organization_id
  project_name    = var.project_name

  # Zone configuration
  domain      = "test.net"
  subdomain   = "staging"
  create_zone = true

  records = [
    # -------------------------------------------------------------------------
    # Standard Records
    # -------------------------------------------------------------------------

    # Root A record for the zone
    {
      name = ""
      type = "A"
      data = "93.184.216.34"
      ttl  = 3600
    },

    # WWW CNAME pointing to root
    {
      name = "www"
      type = "CNAME"
      data = "staging.example.com."
    },

    # Mail server with priority
    {
      name     = ""
      type     = "MX"
      data     = "mail.example.com."
      priority = 10
      ttl      = 3600
    },

    # Backup mail server
    {
      name     = ""
      type     = "MX"
      data     = "mail-backup.example.com."
      priority = 20
      ttl      = 3600
    },

    # SPF record for email authentication
    {
      name = ""
      type = "TXT"
      data = "v=spf1 include:_spf.example.com ~all"
    },

    # CAA record for certificate authority authorization
    {
      name = ""
      type = "CAA"
      data = "0 issue \"letsencrypt.org\""
    },

    # -------------------------------------------------------------------------
    # Geo IP Routing
    # Route users to nearest datacenter based on location
    # -------------------------------------------------------------------------
    {
      name = "cdn"
      type = "A"
      data = "10.0.0.1" # Default fallback IP
      geo_ip = {
        matches = [
          {
            data       = "10.0.1.1" # EU datacenter
            continents = ["EU"]
          },
          {
            data       = "10.0.2.1" # NA datacenter
            continents = ["NA"]
          },
          {
            data      = "10.0.3.1" # FR specific
            countries = ["FR"]
          },
          {
            data = "10.0.0.1" # Default (no geo match)
          }
        ]
      }
    },

    # -------------------------------------------------------------------------
    # Weighted Load Balancing
    # Distribute traffic across multiple servers by weight
    # -------------------------------------------------------------------------
    {
      name = "lb"
      type = "A"
      data = "10.1.0.1" # Default fallback IP
      weighted = [
        {
          ip     = "10.1.0.1"
          weight = 70 # 70% of traffic
        },
        {
          ip     = "10.1.0.2"
          weight = 20 # 20% of traffic
        },
        {
          ip     = "10.1.0.3"
          weight = 10 # 10% of traffic
        }
      ]
    },

    # -------------------------------------------------------------------------
    # View-based Routing
    # Return different IPs based on client subnet (internal vs external)
    # -------------------------------------------------------------------------
    {
      name = "db"
      type = "A"
      data = "203.0.113.10" # Default public IP for external clients
      view = [
        {
          subnet = "10.0.0.0/8"  # Internal network
          data   = "10.100.0.10" # Internal DB IP
        },
        {
          subnet = "192.168.0.0/16" # Office network
          data   = "10.100.0.11"    # Office DB IP
        }
      ]
    },

    # -------------------------------------------------------------------------
    # HTTP Health-Checked DNS
    # Automatic failover based on health checks
    # -------------------------------------------------------------------------
    {
      name = "api"
      type = "A"
      data = "10.2.0.1" # Default fallback IP
      http_service = {
        ips          = ["10.2.0.1", "10.2.0.2", "10.2.0.3"]
        url          = "http://api.staging.example.com/health"
        must_contain = "\"status\":\"healthy\""
        strategy     = "hashed" # Consistent hashing for session affinity
      }
    }
  ]
}
