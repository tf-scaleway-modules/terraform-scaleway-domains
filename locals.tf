# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              LOCAL VALUES                                    ║
# ║                                                                              ║
# ║  Computed values and transformations used throughout the module.             ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

locals {
  # ==============================================================================
  # Project ID Resolution
  # ------------------------------------------------------------------------------
  # Priority: project_id > data source lookup > null (provider default)
  # ==============================================================================

  project_id = coalesce(
    var.project_id,
    try(data.scaleway_account_project.this[0].id, null)
  )

  # ==============================================================================
  # DNS Zone
  # ==============================================================================

  # Compute the full DNS zone name
  dns_zone = var.subdomain != "" ? "${var.subdomain}.${var.domain}" : var.domain

  # ==============================================================================
  # DNS Records Map
  # ==============================================================================

  # Transform records list into a map for for_each
  # Key format: "{type}_{name}" or "{type}_@" for root records
  records_map = {
    for idx, record in var.records :
    "${record.type}_${record.name != "" ? record.name : "@"}_${idx}" => record
  }
}
