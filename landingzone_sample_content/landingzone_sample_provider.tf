# Provider
terraform {
  required_version = ">= 1.5"
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.7"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.63"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "~>1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.5"
    }
     time = {
      source  = "hashicorp/time"
    }
  }
}

provider "azapi" {
  environment     = "public"
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
provider "azuread" {
  environment = "public"
  tenant_id   = var.tenant_id
  use_cli     = true
  use_oidc    = true
}
provider "azurerm" {
  environment         = "public"
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
  storage_use_azuread = true
  use_cli             = true
  use_oidc            = true
  features {}
}
provider "azurecaf" {
}
provider "random" {
}
provider "time" {
}