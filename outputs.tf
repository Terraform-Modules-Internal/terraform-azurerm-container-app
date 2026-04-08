# ─── Container App Environment ────────────────────────────────────────────────

output "environment_id" {
  description = "Resource ID of the Container App Environment."
  value       = azurerm_container_app_environment.this.id
}

output "environment_name" {
  description = "Name of the Container App Environment."
  value       = azurerm_container_app_environment.this.name
}

output "environment_default_domain" {
  description = "Default domain of the Container App Environment."
  value       = azurerm_container_app_environment.this.default_domain
}

output "environment_static_ip" {
  description = "Static IP of the Container App Environment (VNET-integrated environments only)."
  value       = azurerm_container_app_environment.this.static_ip_address
}

output "environment_docker_bridge_cidr" {
  description = "Docker bridge CIDR of the Container App Environment."
  value       = azurerm_container_app_environment.this.docker_bridge_cidr
}

output "environment_platform_reserved_cidr" {
  description = "Platform reserved CIDR of the Container App Environment."
  value       = azurerm_container_app_environment.this.platform_reserved_cidr
}

output "environment_platform_reserved_dns_ip" {
  description = "Platform reserved DNS IP of the Container App Environment."
  value       = azurerm_container_app_environment.this.platform_reserved_dns_ip_address
}

# ─── Container Apps ───────────────────────────────────────────────────────────

output "container_app_ids" {
  description = "Map of Container App name → resource ID."
  value       = { for k, v in azurerm_container_app.this : k => v.id }
}

output "container_app_fqdns" {
  description = "Map of Container App name → ingress FQDN (null if ingress not configured)."
  value       = { for k, v in azurerm_container_app.this : k => try(v.ingress[0].fqdn, null) }
}

output "container_app_identities" {
  description = "Map of Container App name → identity block (principal_id, tenant_id)."
  value = {
    for k, v in azurerm_container_app.this : k => try({
      principal_id = v.identity[0].principal_id
      tenant_id    = v.identity[0].tenant_id
    }, null)
  }
}

output "container_app_outbound_ip_addresses" {
  description = "Map of Container App name → list of outbound IP addresses."
  value       = { for k, v in azurerm_container_app.this : k => v.outbound_ip_addresses }
}
