# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                              MODULE OUTPUTS                                   ║
# ║                                                                                ║
# ║  Outputs for secrets, secret versions, and encryption keys.                   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

# ==============================================================================
# Project Output
# ==============================================================================

output "project_id" {
  description = "The ID of the Scaleway project (resolved from project_name)."
  value       = local.project_id
}
