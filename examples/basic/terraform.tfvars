# ── Required inputs ────────────────────────────────────────────────────────────
# Replace placeholder values with real resource identifiers before running.

resource_group_name = "rg-bdt-containerapp-dev-eus2-001"

location = "eastus2"

log_analytics_workspace_id = "/subscriptions/<subscription-id>/resourceGroups/rg-bdt-monitoring-dev-eus2-001/providers/Microsoft.OperationalInsights/workspaces/law-bdt-dev-eus2-001"

tags = {
  Application         = "BDT-ContainerApp"
  CreationDate        = "04/20/2026"
  DevOwner            = "raghavendirann@presidio.com"
  BusinessOwner       = "smanohar@presidio.com"
  Environment         = "dev"
  CostCenter          = "BDT-001"
  DataClassification  = "Sensitive"
  BusinessCriticality = "Low"
  Compliance          = "CIS"
}
