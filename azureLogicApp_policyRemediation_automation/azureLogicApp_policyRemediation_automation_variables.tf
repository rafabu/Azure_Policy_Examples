variable "tenant_id" {
  type        = string
  description = "azure tenant id"
  default = "09275de1-a3a2-4bb9-9e15-daaacf85c455"
}
variable "subscription_id" {
  type        = string
  description = "Azure subscription id"
}
variable "resource_location" {
  type        = string
  description = "Resource location (defaults to eastus)"
  default     = "eastus"
}
variable "resource_name_environment" {
  type        = string
  description = "Resource naming: envorinment prefix (example: abcd-c1)"
}
variable "resource_name_service" {
  type        = string
  description = "Resource naming: service code (defaults to ccc-azpol)"
  default     = "ccc-azpol"
}
variable "policy_definition_id_list" {
  type        = list(string)
  description = "List of Azure Policy Definition Id substrings. Used for the advanced filter definition of the eventgrid subscription (defaults to [\"/cccPaaSFirewall-tag-\"])"
  default     = [
        "/cccPaaSFirewall-tag-"
      ]
}
variable "tags" {
  type        = map(string)
  description = "Azure resource tags"
  default     = {
    businessUnit = "ccc"
    costCenter = "ccc"
    createdBy = "terraform script"
    workloadName = "ccc-azpol"
    workloadOwner = "admin@cslsbx.onmicrosoft.com"
    workloadEnvironment = "cslz-c9"

  }
}

