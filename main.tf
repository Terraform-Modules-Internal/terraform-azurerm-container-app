# ─── Container App Environment ────────────────────────────────────────────────

resource "azurerm_container_app_environment" "this" {
  name                           = var.environment_name
  location                       = var.location
  resource_group_name            = var.resource_group_name
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  infrastructure_subnet_id       = var.infrastructure_subnet_id
  internal_load_balancer_enabled = var.internal_load_balancer_enabled
  zone_redundancy_enabled        = var.zone_redundancy_enabled

  dynamic "workload_profile" {
    for_each = var.workload_profiles
    content {
      name                  = workload_profile.value.name
      workload_profile_type = workload_profile.value.workload_profile_type
      minimum_count         = workload_profile.value.minimum_count
      maximum_count         = workload_profile.value.maximum_count
    }
  }

  tags = var.tags
}

# ─── Container Apps ───────────────────────────────────────────────────────────

resource "azurerm_container_app" "this" {
  for_each = var.container_apps

  name                         = each.key
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = var.resource_group_name
  revision_mode                = each.value.revision_mode
  workload_profile_name        = each.value.workload_profile_name

  # ── Secrets ────────────────────────────────────────────────────────────────
  dynamic "secret" {
    for_each = each.value.secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  # ── Registry credentials ────────────────────────────────────────────────────
  dynamic "registry" {
    for_each = each.value.registries
    content {
      server               = registry.value.server
      username             = registry.value.username
      password_secret_name = registry.value.password_secret_name
      identity             = registry.value.identity
    }
  }

  # ── Identity ────────────────────────────────────────────────────────────────
  dynamic "identity" {
    for_each = each.value.identity != null ? [each.value.identity] : []
    content {
      type         = identity.value.type
      identity_ids = identity.value.identity_ids
    }
  }

  # ── Dapr ────────────────────────────────────────────────────────────────────
  dynamic "dapr" {
    for_each = each.value.dapr != null ? [each.value.dapr] : []
    content {
      app_id       = dapr.value.app_id
      app_port     = dapr.value.app_port
      app_protocol = dapr.value.app_protocol
    }
  }

  # ── Ingress ─────────────────────────────────────────────────────────────────
  dynamic "ingress" {
    for_each = each.value.ingress != null ? [each.value.ingress] : []
    content {
      external_enabled           = ingress.value.external_enabled
      target_port                = ingress.value.target_port
      transport                  = ingress.value.transport
      allow_insecure_connections = ingress.value.allow_insecure_connections

      dynamic "traffic_weight" {
        for_each = ingress.value.traffic_weights
        content {
          label           = traffic_weight.value.label
          latest_revision = traffic_weight.value.latest_revision
          revision_suffix = traffic_weight.value.revision_suffix
          percentage      = traffic_weight.value.percentage
        }
      }
    }
  }

  # ── Template ────────────────────────────────────────────────────────────────
  template {
    revision_suffix = each.value.revision_suffix
    min_replicas    = each.value.min_replicas
    max_replicas    = each.value.max_replicas

    # Volumes
    dynamic "volume" {
      for_each = each.value.volumes
      content {
        name         = volume.value.name
        storage_type = volume.value.storage_type
        storage_name = volume.value.storage_name
      }
    }

    # Scale rules
    dynamic "azure_queue_scale_rule" {
      for_each = [for r in each.value.scale_rules : r if r.type == "azure-queue"]
      content {
        name         = azure_queue_scale_rule.value.name
        queue_name   = azure_queue_scale_rule.value.metadata["queueName"]
        queue_length = tonumber(azure_queue_scale_rule.value.metadata["queueLength"])

        dynamic "authentication" {
          for_each = azure_queue_scale_rule.value.authentication
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "http_scale_rule" {
      for_each = [for r in each.value.scale_rules : r if r.type == "http"]
      content {
        name                = http_scale_rule.value.name
        concurrent_requests = http_scale_rule.value.metadata["concurrentRequests"]

        dynamic "authentication" {
          for_each = http_scale_rule.value.authentication
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    dynamic "custom_scale_rule" {
      for_each = [for r in each.value.scale_rules : r if r.type == "custom"]
      content {
        name             = custom_scale_rule.value.name
        custom_rule_type = custom_scale_rule.value.metadata["type"]
        metadata         = custom_scale_rule.value.metadata

        dynamic "authentication" {
          for_each = custom_scale_rule.value.authentication
          content {
            secret_name       = authentication.value.secret_name
            trigger_parameter = authentication.value.trigger_parameter
          }
        }
      }
    }

    # Init containers
    dynamic "init_container" {
      for_each = each.value.init_containers
      content {
        name    = init_container.value.name
        image   = init_container.value.image
        cpu     = init_container.value.cpu
        memory  = init_container.value.memory
        command = init_container.value.command
        args    = init_container.value.args

        dynamic "env" {
          for_each = init_container.value.env
          content {
            name        = env.value.name
            value       = env.value.secret_name == null ? env.value.value : null
            secret_name = env.value.secret_name
          }
        }
      }
    }

    # Containers
    dynamic "container" {
      for_each = each.value.containers
      content {
        name    = container.value.name
        image   = container.value.image
        cpu     = container.value.cpu
        memory  = container.value.memory
        command = container.value.command
        args    = container.value.args

        dynamic "env" {
          for_each = container.value.env
          content {
            name        = env.value.name
            value       = env.value.secret_name == null ? env.value.value : null
            secret_name = env.value.secret_name
          }
        }

        dynamic "liveness_probe" {
          for_each = container.value.liveness_probe != null ? [container.value.liveness_probe] : []
          content {
            transport               = liveness_probe.value.transport
            port                    = liveness_probe.value.port
            path                    = liveness_probe.value.path
            initial_delay           = liveness_probe.value.initial_delay
            period_seconds          = liveness_probe.value.period_seconds
            timeout                 = liveness_probe.value.timeout
            failure_count_threshold = liveness_probe.value.failure_count_threshold
          }
        }

        dynamic "readiness_probe" {
          for_each = container.value.readiness_probe != null ? [container.value.readiness_probe] : []
          content {
            transport               = readiness_probe.value.transport
            port                    = readiness_probe.value.port
            path                    = readiness_probe.value.path
            initial_delay           = readiness_probe.value.initial_delay
            period_seconds          = readiness_probe.value.period_seconds
            timeout                 = readiness_probe.value.timeout
            failure_count_threshold = readiness_probe.value.failure_count_threshold
            success_count_threshold = readiness_probe.value.success_count_threshold
          }
        }

        dynamic "startup_probe" {
          for_each = container.value.startup_probe != null ? [container.value.startup_probe] : []
          content {
            transport               = startup_probe.value.transport
            port                    = startup_probe.value.port
            path                    = startup_probe.value.path
            initial_delay           = startup_probe.value.initial_delay
            period_seconds          = startup_probe.value.period_seconds
            timeout                 = startup_probe.value.timeout
            failure_count_threshold = startup_probe.value.failure_count_threshold
          }
        }

        dynamic "volume_mounts" {
          for_each = container.value.volume_mounts
          content {
            name = volume_mounts.value.name
            path = volume_mounts.value.path
          }
        }
      }
    }
  }

  tags = var.tags
}
