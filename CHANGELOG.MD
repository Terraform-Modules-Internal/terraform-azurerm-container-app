# Changelog

All notable changes to this module will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this module adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-04-08

### Added

- Initial release of the `terraform-azurerm-container-app` module.
- `azurerm_container_app_environment` resource with support for:
  - Log Analytics Workspace integration
  - VNET integration via `infrastructure_subnet_id`
  - Internal load balancer toggle
  - Zone redundancy
  - Workload profiles (Consumption and Dedicated plans)
- `azurerm_container_app` resource (map-driven, supports multiple apps) with support for:
  - Single and Multiple revision modes
  - Ingress configuration with traffic weight splitting
  - Secrets management
  - Container registry credentials
  - System-Assigned and User-Assigned Managed Identity
  - Dapr sidecar configuration
  - HTTP, Azure Queue, and Custom auto-scaling rules
  - Volumes (`EmptyDir`, `AzureFile`, `Secret`)
  - Container liveness, readiness, and startup probes
  - Init containers
  - Volume mounts
  - Workload profile assignment (Dedicated plan)
- Module outputs for environment ID, domain, static IP, CIDR ranges, and per-app IDs, FQDNs, identities, and outbound IPs.
- `examples/basic` — working example with a public API app and a queue-driven worker app.
- `tests/` — automated test suite using `pytest` and `tftest`.
