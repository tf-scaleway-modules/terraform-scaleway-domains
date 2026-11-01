# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║           REGISTRATION EXAMPLE - SCALEWAY DOMAINS MODULE                     ║
# ║                                                                              ║
# ║  Demonstrates domain registration with Scaleway, including:                  ║
# ║  - Domain registration with contact details                                  ║
# ║  - DNS zone creation                                                         ║
# ║  - Basic DNS records                                                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Variables
# ==============================================================================

variable "project_id" {
  description = "Your Scaleway Project ID (null = provider default project)"
  type        = string
  default     = null
}

variable "domain_to_register" {
  description = "The domain name to register (e.g., my-new-domain.com)"
  type        = string
}

# ==============================================================================
# Provider Configuration
# ==============================================================================

provider "scaleway" {
  region = "fr-par"
}

# ==============================================================================
# Domain Registration + DNS Setup
# ==============================================================================

module "my_domain" {
  source = "../../"

  # Project configuration
  project_id = var.project_id

  # Domain to register
  domain = var.domain_to_register

  # Setting registration enables the domain registration (null disables it)
  registration = {
    duration_in_years = 1

    # Renew automatically before expiry (the owner is billed at each renewal)
    auto_renew = true

    # Enable DNSSEC: needs the zone served by Scaleway DNS (create_zone below);
    # publish registration_ds_record at the registrar
    dnssec = true

    # Owner contact details
    owner_contact = {
      # Legal information
      legal_form = "individual"
      firstname  = "A"
      lastname   = "B"

      # Contact information
      email        = "a.b@example.com"
      phone_number = "+33111111111"

      # Address
      address_line_1 = "123 Main Street"
      zip            = "75001"
      city           = "Paris"
      country        = "FR"

      # .fr domains of companies, associations and trademarks need details
      # in extension_fr: individual_info, association_info, duns_info or
      # trademark_info (one of them, next to mode).
      extension_fr = {
        mode = "individual"
      }
    }
  }

  # Create DNS zone for the registered domain
  create_zone = true

  # Basic DNS records
  records = {
    root = {
      type = "A"
      data = "192.168.1.100"
    }
    www = {
      name = "www"
      type = "CNAME"
      data = "${var.domain_to_register}."
    }
  }
}
