locals {
  # Flatten secrets per app for iteration
  app_secrets = flatten([
    for app_name, app in var.container_apps : [
      for secret in app.secrets : {
        app_name = app_name
        name     = secret.name
        value    = secret.value
      }
    ]
  ])

  # Determine if the environment is VNET-integrated
  is_vnet_integrated = var.infrastructure_subnet_id != null
}
