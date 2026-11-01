# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              LOCAL VALUES                                    ║
# ║                                                                              ║
# ║  Computed values and transformations used throughout the module.             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # Full DNS zone name
  dns_zone = var.subdomain != "" ? "${var.subdomain}.${var.domain}" : var.domain
}
