variable "resource_group_name" {
  description = "Name of the resource group where Container App resources will be created."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics Workspace used by the Container App Environment."
  type        = string
}
