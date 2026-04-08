# ─── General ──────────────────────────────────────────────────────────────────

variable "resource_group_name" {
  description = "Name of the resource group where Container App resources will be created."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}

# ─── Container App Environment ────────────────────────────────────────────────

variable "environment_name" {
  description = "Name of the Container App Environment."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace used by the environment."
  type        = string
}

variable "infrastructure_subnet_id" {
  description = "Resource ID of the subnet for the Container App Environment (VNET integration). Set to null for a public environment."
  type        = string
  default     = null
}

variable "internal_load_balancer_enabled" {
  description = "When true the environment uses an internal load balancer (requires infrastructure_subnet_id)."
  type        = bool
  default     = false
}

variable "zone_redundancy_enabled" {
  description = "Enable zone redundancy for the Container App Environment."
  type        = bool
  default     = false
}

variable "workload_profiles" {
  description = "Workload profiles for the environment. Leave empty for the Consumption-only plan."
  type = list(object({
    name                  = string
    workload_profile_type = string          # e.g. D4, D8, D16, E4, E8, E16, Consumption
    minimum_count         = optional(number, 0)
    maximum_count         = optional(number, 10)
  }))
  default = []
}

# ─── Container Apps ───────────────────────────────────────────────────────────

variable "container_apps" {
  description = "Map of Container Apps to deploy within the environment."
  type = map(object({
    revision_mode = optional(string, "Single") # Single | Multiple

    # Ingress
    ingress = optional(object({
      external_enabled = optional(bool, true)
      target_port      = number
      transport        = optional(string, "auto") # auto | http | http2 | tcp
      traffic_weights = optional(list(object({
        label          = optional(string, null)
        latest_revision = optional(bool, true)
        revision_suffix = optional(string, null)
        percentage      = number
      })), [{ latest_revision = true, percentage = 100 }])
      allow_insecure_connections = optional(bool, false)
    }), null)

    # Containers
    containers = list(object({
      name    = string
      image   = string
      cpu     = number
      memory  = string # e.g. "0.5Gi", "1Gi"
      command = optional(list(string), null)
      args    = optional(list(string), null)

      env = optional(list(object({
        name        = string
        value       = optional(string, null)
        secret_name = optional(string, null)
      })), [])

      liveness_probe = optional(object({
        transport               = string # HTTP | HTTPS | TCP
        port                    = number
        path                    = optional(string, null)
        initial_delay           = optional(number, 10)
        period_seconds          = optional(number, 10)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
      }), null)

      readiness_probe = optional(object({
        transport               = string
        port                    = number
        path                    = optional(string, null)
        initial_delay           = optional(number, 5)
        period_seconds          = optional(number, 5)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
        success_count_threshold = optional(number, 1)
      }), null)

      startup_probe = optional(object({
        transport               = string
        port                    = number
        path                    = optional(string, null)
        initial_delay           = optional(number, 0)
        period_seconds          = optional(number, 10)
        timeout                 = optional(number, 1)
        failure_count_threshold = optional(number, 3)
      }), null)

      volume_mounts = optional(list(object({
        name = string
        path = string
      })), [])
    }))

    # Init containers
    init_containers = optional(list(object({
      name    = string
      image   = string
      cpu     = optional(number, 0.25)
      memory  = optional(string, "0.5Gi")
      command = optional(list(string), null)
      args    = optional(list(string), null)
      env = optional(list(object({
        name        = string
        value       = optional(string, null)
        secret_name = optional(string, null)
      })), [])
    })), [])

    # Scaling
    min_replicas = optional(number, 0)
    max_replicas = optional(number, 10)

    scale_rules = optional(list(object({
      name             = string
      type             = string           # http | azure-queue | custom | cpu | memory
      metadata         = map(string)
      authentication = optional(list(object({
        secret_name       = string
        trigger_parameter = string
      })), [])
    })), [])

    # Secrets
    secrets = optional(list(object({
      name  = string
      value = string
    })), [])

    # Registries
    registries = optional(list(object({
      server               = string
      username             = optional(string, null)
      password_secret_name = optional(string, null)
      identity             = optional(string, null)
    })), [])

    # Volumes
    volumes = optional(list(object({
      name         = string
      storage_type = optional(string, "EmptyDir") # EmptyDir | AzureFile | Secret
      storage_name = optional(string, null)
    })), [])

    # Identity
    identity = optional(object({
      type         = string                    # SystemAssigned | UserAssigned | SystemAssigned, UserAssigned
      identity_ids = optional(list(string), [])
    }), null)

    # Dapr
    dapr = optional(object({
      app_id       = string
      app_port     = optional(number, null)
      app_protocol = optional(string, "http")
    }), null)

    # Workload profile (Dedicated plan only)
    workload_profile_name = optional(string, null)

    revision_suffix = optional(string, null)
  }))
  default = {}
}
