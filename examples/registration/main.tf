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

variable "organization_id" {
  description = "Your Scaleway Organization ID"
  type        = string
}

variable "project_name" {
  description = "Your Scaleway Project name"
  type        = string
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
  organization_id = var.organization_id
  project_name    = var.project_name

  # Domain to register
  domain = var.domain_to_register

  # Enable domain registration
  register_domain = true

  registration = {
    duration_in_years = 1

    # Owner contact details
    owner_contact = {
      # Legal information
      legal_form = "individual"
      firstname  = "John"
      lastname   = "Doe"

      # Contact information
      email        = "john.doe@example.com"
      phone_number = "+33123456789"

      # Address
      address_line_1 = "123 Main Street"
      zip            = "75001"
      city           = "Paris"
      country        = "FR"
    }
  }

  # Create DNS zone for the registered domain
  create_zone = true

  # Basic DNS records
  records = [
    {
      name = ""
      type = "A"
      data = "93.184.216.34"
    },
    {
      name = "www"
      type = "CNAME"
      data = "${var.domain_to_register}."
    }
  ]
}
