# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║                     MINIMAL EXAMPLE - OUTPUTS                                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

output "project_id" {
  description = "The resolved project ID"
  value       = module.secrets_and_keys.project_id
}
