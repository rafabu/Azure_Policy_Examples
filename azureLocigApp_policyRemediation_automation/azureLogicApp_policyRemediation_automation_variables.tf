variable "tenant_id" {
  type        = string
  description = "azure tenant id"
  default = "09275de1-a3a2-4bb9-9e15-daaacf85c455"
}
variable "subscription_id" {
  type        = string
  description = "Azure subscription id"
  default = "73e7819b-1f47-457c-b6d0-ddcc1627c6ce"
}
variable "resource_location" {
  type        = string
  description = "Resource location (defaults to eastus)"
  default     = "eastus"
}
variable "resource_name_environment" {
  type        = string
  description = "Resource naming: envorinment prefix (defaults to cslz-c9)"
  default     = "cslz-c9"
}
variable "resource_name_service" {
  type        = string
  description = "Resource naming: service code (defaults to cslz-c9)"
  default     = "ccc-azpol"
}
variable "policy_definition_id_list" {
  type        = list(string)
  description = "List of Azure Policy Definition Id substrings (defaults to [\"/cccPaaSFirewall-tag-\"])"
  default     = [
        "/cccPaaSFirewall-tag-"
      ]
}

