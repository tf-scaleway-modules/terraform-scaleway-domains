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

  # coalesce() fails when every argument is null, so use a conditional.
  project_id = var.project_id != null ? var.project_id : try(data.scaleway_account_project.this[0].id, null)

  # ==============================================================================
  # DNS Zone
  # ==============================================================================

  # Compute the full DNS zone name
  dns_zone = var.subdomain != "" ? "${var.subdomain}.${var.domain}" : var.domain

  # ==============================================================================
  # DNS Records Map
  # ==============================================================================

  # Transform records list into a map for for_each
  # Key format: "{type}_{name}_{index}", with "@" as name for root records.
  # The index is the list position: inserting or reordering records changes the
  # keys of the shifted ones (they are replaced). Append new records at the end.
  records_map = {
    for idx, record in var.records :
    "${record.type}_${record.name != "" ? record.name : "@"}_${idx}" => record
  }
}
