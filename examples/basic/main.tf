module "container_app" {
  source = "../../"

  resource_group_name        = var.resource_group_name
  location                   = var.location
  environment_name           = "cae-bdt-dev"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Optional: VNET integration
  # infrastructure_subnet_id       = "/subscriptions/<sub>/resourceGroups/rg-bdt-networking-dev/providers/Microsoft.Network/virtualNetworks/vnet-bdt-dev/subnets/snet-aca"
  # internal_load_balancer_enabled = true

  zone_redundancy_enabled = false

  container_apps = {
    "app-bdt-api" = {
      revision_mode = "Single"

      ingress = {
        external_enabled = true
        target_port      = 8080
        transport        = "auto"
        traffic_weights  = [{ latest_revision = true, percentage = 100 }]
      }

      containers = [
        {
          name   = "api"
          image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          cpu    = 0.5
          memory = "1Gi"

          env = [
            { name = "ASPNETCORE_ENVIRONMENT", value = "Production" },
            { name = "DB_CONNECTION_STRING", secret_name = "db-connection-string" }
          ]

          liveness_probe = {
            transport        = "HTTP"
            port             = 8080
            path             = "/health"
            initial_delay    = 15
            interval_seconds = 20
          }

          readiness_probe = {
            transport        = "HTTP"
            port             = 8080
            path             = "/ready"
            interval_seconds = 10
          }
        }
      ]

      secrets = [
        {
          name  = "db-connection-string"
          value = "Server=sql-bdt-dev.database.windows.net;Database=bdt;Authentication=Active Directory Managed Identity;"
        }
      ]

      min_replicas = 1
      max_replicas = 5

      scale_rules = [
        {
          name = "http-scale"
          type = "http"
          metadata = {
            concurrentRequests = "50"
          }
          authentication = []
        }
      ]

      identity = {
        type         = "SystemAssigned"
        identity_ids = []
      }
    }

    "app-bdt-worker" = {
      revision_mode = "Single"

      containers = [
        {
          name   = "worker"
          image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
          cpu    = 0.25
          memory = "0.5Gi"

          env = [
            { name = "WORKER_MODE", value = "background" }
          ]
        }
      ]

      min_replicas = 0
      max_replicas = 10

      scale_rules = [
        {
          name = "queue-scale"
          type = "azure-queue"
          metadata = {
            queueName   = "bdt-work-queue"
            queueLength = "5"
          }
          authentication = [
            {
              secret_name       = "storage-connection-string"
              trigger_parameter = "connection"
            }
          ]
        }
      ]

      secrets = [
        {
          name  = "storage-connection-string"
          value = "DefaultEndpointsProtocol=https;AccountName=stbdtdev;AccountKey=<key>"
        }
      ]

      identity = {
        type         = "SystemAssigned"
        identity_ids = []
      }
    }
  }

  tags = {
    environment = "dev"
    project     = "bdt"
    managed_by  = "terraform"
  }
}

output "api_fqdn" {
  value = module.container_app.container_app_fqdns["app-bdt-api"]
}

output "environment_domain" {
  value = module.container_app.environment_default_domain
}
