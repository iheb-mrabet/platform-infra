variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Main platform resource group"
  type        = string
  default     = "platform-eng-rg"
}

variable "project_prefix" {
  description = "Prefix used for resource names"
  type        = string
  default     = "ihebplat"
}

variable "acr_name" {
  description = "Globally unique ACR name"
  type        = string
}

variable "key_vault_name" {
  description = "Globally unique Key Vault name"
  type        = string
}