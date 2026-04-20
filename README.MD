# terraform-azurerm-container-app

Terraform module for deploying an **Azure Container App Environment** and one or more **Azure Container Apps** within it.

The module is designed to be opinionated yet flexible — all optional features default to safe values so that a minimal invocation requires only the required inputs.

---

## Usage

```hcl
module "container_app" {
  source = "git::https://dev.azure.com/<org>/<project>/_git/terraform-azurerm-container-app"

  resource_group_name        = "rg-my-app-prod"
  location                   = "eastus"
  environment_name           = "cae-my-app-prod"
  log_analytics_workspace_id = "/subscriptions/.../workspaces/law-my-app-prod"

  container_apps = {
    "app-my-api" = {
      ingress = {
        external_enabled = true
        target_port      = 8080
      }
      containers = [
        {
          name   = "api"
          image  = "myregistry.azurecr.io/my-api:1.0.0"
          cpu    = 0.5
          memory = "1Gi"
        }
      ]
    }
  }

  tags = {
    environment = "prod"
    managed_by  = "terraform"
  }
}
```

See the [`examples/basic`](./examples/basic) directory for a full working example.

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.85.0 |

---

## Providers

| Name | Source |
|------|--------|
| azurerm | hashicorp/azurerm |

---

## Resources

| Name | Type |
|------|------|
| `azurerm_container_app_environment.this` | resource |
| `azurerm_container_app.this` | resource |

---

## Inputs

### General

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `resource_group_name` | Name of the resource group where resources will be created. | `string` | — | yes |
| `location` | Azure region for all resources. | `string` | — | yes |
| `tags` | Map of tags to apply to all resources. | `map(string)` | `{}` | no |

### Container App Environment

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `environment_name` | Name of the Container App Environment. | `string` | — | yes |
| `log_analytics_workspace_id` | Resource ID of the Log Analytics Workspace. | `string` | — | yes |
| `infrastructure_subnet_id` | Subnet resource ID for VNET integration. `null` = public environment. | `string` | `null` | no |
| `internal_load_balancer_enabled` | Use an internal load balancer (requires `infrastructure_subnet_id`). | `bool` | `false` | no |
| `zone_redundancy_enabled` | Enable zone redundancy for the environment. | `bool` | `false` | no |
| `workload_profiles` | List of workload profiles (omit for Consumption-only plan). | `list(object)` | `[]` | no |

**`workload_profiles` object schema:**

```hcl
{
  name                  = string          # Profile name
  workload_profile_type = string          # D4, D8, D16, E4, E8, E16, Consumption
  minimum_count         = optional(number, 0)
  maximum_count         = optional(number, 10)
}
```

### Container Apps

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `container_apps` | Map of Container Apps to deploy. Key = app name. | `map(object)` | `{}` | no |

**`container_apps` object schema (per app):**

```hcl
{
  revision_mode         = optional(string, "Single")   # Single | Multiple
  workload_profile_name = optional(string, null)
  revision_suffix       = optional(string, null)
  min_replicas          = optional(number, 0)
  max_replicas          = optional(number, 10)

  ingress = optional(object({
    external_enabled           = optional(bool, true)
    target_port                = number
    transport                  = optional(string, "auto")  # auto | http | http2 | tcp
    allow_insecure_connections = optional(bool, false)
    traffic_weights = optional(list(object({
      label           = optional(string, null)
      latest_revision = optional(bool, true)
      revision_suffix = optional(string, null)
      percentage      = number
    })), [{ latest_revision = true, percentage = 100 }])
  }), null)

  containers = list(object({
    name    = string
    image   = string
    cpu     = number          # e.g. 0.25, 0.5, 1, 2
    memory  = string          # e.g. "0.5Gi", "1Gi", "2Gi"
    command = optional(list(string), null)
    args    = optional(list(string), null)

    env = optional(list(object({
      name        = string
      value       = optional(string, null)
      secret_name = optional(string, null)   # reference a secret by name
    })), [])

    liveness_probe  = optional(object({ ... }), null)
    readiness_probe = optional(object({ ... }), null)
    startup_probe   = optional(object({ ... }), null)

    volume_mounts = optional(list(object({
      name = string
      path = string
    })), [])
  }))

  init_containers = optional(list(object({ ... })), [])

  scale_rules = optional(list(object({
    name           = string
    type           = string        # http | azure-queue | custom
    metadata       = map(string)
    authentication = optional(list(object({
      secret_name       = string
      trigger_parameter = string
    })), [])
  })), [])

  secrets = optional(list(object({
    name  = string
    value = string
  })), [])

  registries = optional(list(object({
    server               = string
    username             = optional(string, null)
    password_secret_name = optional(string, null)
    identity             = optional(string, null)
  })), [])

  volumes = optional(list(object({
    name         = string
    storage_type = optional(string, "EmptyDir")  # EmptyDir | AzureFile | Secret
    storage_name = optional(string, null)
  })), [])

  identity = optional(object({
    type         = string                          # SystemAssigned | UserAssigned | SystemAssigned, UserAssigned
    identity_ids = optional(list(string), [])
  }), null)

  dapr = optional(object({
    app_id       = string
    app_port     = optional(number, null)
    app_protocol = optional(string, "http")
  }), null)
}
```

---

## Outputs

| Name | Description |
|------|-------------|
| `environment_id` | Resource ID of the Container App Environment. |
| `environment_name` | Name of the Container App Environment. |
| `environment_default_domain` | Default domain of the environment. |
| `environment_static_ip` | Static IP address (VNET-integrated environments only). |
| `environment_docker_bridge_cidr` | Docker bridge CIDR of the environment. |
| `environment_platform_reserved_cidr` | Platform reserved CIDR. |
| `environment_platform_reserved_dns_ip` | Platform reserved DNS IP. |
| `container_app_ids` | Map of app name → resource ID. |
| `container_app_fqdns` | Map of app name → ingress FQDN (`null` if ingress not configured). |
| `container_app_identities` | Map of app name → `{ principal_id, tenant_id }` (`null` if no identity). |
| `container_app_outbound_ip_addresses` | Map of app name → list of outbound IP addresses. |

---

## Examples

| Example | Description |
|---------|-------------|
| [`examples/basic`](./examples/basic) | Public API app with HTTP scaling + queue-driven worker app. |

---

## Notes

- **Consumption plan**: omit `workload_profiles` entirely (default `[]`).
- **Dedicated plan**: add at least one `workload_profiles` entry and set `workload_profile_name` on each app.
- **VNET integration**: set `infrastructure_subnet_id` to a delegated subnet. The subnet must be delegated to `Microsoft.App/environments`.
- **Internal load balancer**: requires `infrastructure_subnet_id` and `internal_load_balancer_enabled = true`.
- **Secrets**: define secrets under each app's `secrets` block and reference them by name in `env[*].secret_name` or `registries[*].password_secret_name`.

---

## Maintained By

| Name | Email |
|------|-------|
| Raghavendiran N | raghavendirann@presidio.com |
| Sakthivel Manohar | smanohar@presidio.com |
