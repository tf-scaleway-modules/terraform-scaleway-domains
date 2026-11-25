# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              VERSION CONSTRAINTS                             ║
# ║                                                                              ║
# ║  Terraform/OpenTofu and provider version requirements.                       ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

terraform {
  required_version = ">= 1.11.0" # OpenTofu or Terraform 1.11.0+

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.89"
    }
  }
}
