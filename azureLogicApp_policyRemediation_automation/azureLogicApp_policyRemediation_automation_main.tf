######################################################
# Deploy Logic App complete with
#     Event Grid subscription
#     to support automated Azure policy remediation
######################################################

# Provider
terraform {
  required_providers {
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

  }
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
data "azuread_client_config" "aad" {
}
data "azurerm_subscription" "sub" {
}

######################################################
# Resource Group
######################################################
data "azurecaf_name" "rg" {
  name          = var.resource_name_service
  resource_type = "azurerm_resource_group"
  prefixes = [
    var.resource_name_environment
  ]
  random_length = 0
  separator     = "-"
  clean_input   = true
  use_slug      = true
}
resource "azurerm_resource_group" "rg" {
  name     = data.azurecaf_name.rg.result
  location = var.resource_location

  tags = var.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

######################################################
# System Event Grid (subscription)
######################################################
data "azurecaf_name" "egst" {
  name          = var.resource_name_service
  resource_type = "azurerm_eventgrid_topic"
  prefixes = [
    var.resource_name_environment
  ]
  random_length = 0
  separator     = "-"
  clean_input   = true
  use_slug      = true
}
resource "azurerm_eventgrid_system_topic" "egst" {
  name                   = format("%s-policystates", data.azurecaf_name.egst.result)
  location               = "Global"
  resource_group_name    = azurerm_resource_group.rg.name
  source_arm_resource_id = data.azurerm_subscription.sub.id
  topic_type             = "Microsoft.PolicyInsights.PolicyStates"
  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.rg.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_eventgrid_system_topic_event_subscription" "egss" {
  name                = format("PolicyStateChanged-webhook-%s", azurerm_logic_app_workflow.lapp.name)
  system_topic        = azurerm_eventgrid_system_topic.egst.name
  resource_group_name = azurerm_eventgrid_system_topic.egst.resource_group_name

  event_delivery_schema = "EventGridSchema"
  included_event_types = [
    "Microsoft.PolicyInsights.PolicyStateChanged",
    "Microsoft.PolicyInsights.PolicyStateCreated"
  ]
  # subject_filter {}
  advanced_filter {
    string_in {
      key = "topic"
      values = [
        data.azurerm_subscription.sub.id
      ]
    }
    string_in {
      key = "data.complianceState"
      values = [
        "NonCompliant"
      ]
    }
    string_contains {
      key    = "data.policyDefinitionId"
      values = var.policy_definition_id_list
    }
  }
  advanced_filtering_on_arrays_enabled = true

  retry_policy {
    max_delivery_attempts = 30
    event_time_to_live    = 1440
  }

  webhook_endpoint {
    url                               = azurerm_logic_app_trigger_http_request.lapp.callback_url
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }
}

######################################################
# Logic App
######################################################
data "azurecaf_name" "lapp" {
  name          = var.resource_name_service
  resource_type = "azurerm_logic_app_workflow"
  prefixes = [
    var.resource_name_environment
  ]
  random_length = 0
  separator     = "-"
  clean_input   = true
  use_slug      = true
}
resource "azurerm_logic_app_workflow" "lapp" {
  name                = format("%s-remediation", data.azurecaf_name.lapp.result)
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  enabled          = true
  workflow_version = "1.0.0.0"

  identity {
    type = "SystemAssigned"
  }

  tags = azurerm_resource_group.rg.tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
resource "azurerm_logic_app_trigger_http_request" "lapp" {
  name         = "Microsoft.PolicyInsights.PolicyStates"
  logic_app_id = azurerm_logic_app_workflow.lapp.id

  schema = <<HTTP_TRIGGER_SCHEMA
{
    "type": "object",
    "properties": {
        "EventGridTrigger": {
            "inputs": {
                "schema": {
                    "items": {
                        "properties": {
                            "data": {
                                "properties": {
                                    "complianceReasonCode": {
                                        "type": "string"
                                    },
                                    "complianceState": {
                                        "type": "string"
                                    },
                                    "policyAssignmentId": {
                                        "type": "string"
                                    },
                                    "policyDefinitionId": {
                                        "type": "string"
                                    },
                                    "policyDefinitionReferenceId": {
                                        "type": "string"
                                    },
                                    "subscriptionId": {
                                        "type": "string"
                                    },
                                    "timestamp": {
                                        "type": "string"
                                    }
                                },
                                "type": "object"
                            },
                            "dataVersion": {
                                "type": "string"
                            },
                            "eventTime": {
                                "type": "string"
                            },
                            "eventType": {
                                "type": "string"
                            },
                            "id": {
                                "type": "string"
                            },
                            "metadataVersion": {
                                "type": "string"
                            },
                            "subject": {
                                "type": "string"
                            },
                            "topic": {
                                "type": "string"
                            }
                        },
                        "required": [
                            "id",
                            "topic",
                            "subject",
                            "data",
                            "eventType",
                            "eventTime",
                            "dataVersion",
                            "metadataVersion"
                        ],
                        "type": "object"
                    },
                    "type": "array"
                }
            },
            "kind": "Http",
            "type": "Request"
        }
    }
}
HTTP_TRIGGER_SCHEMA

}
resource "azurerm_logic_app_action_custom" "lapp" {
  name         = "foreach_policy_state_change"
  logic_app_id = azurerm_logic_app_workflow.lapp.id

  body = <<CUSTOM_ACTION_SCHEMA
{
    "description": "trigger Azure Policy remediation",
    "actions": {
        "Condition": {
            "actions": {
                "Azure_API_-_Create_Policy_Remediation_(quick_-_ExistingNonCompliant)": {
                    "inputs": {
                        "authentication": {
                            "type": "ManagedServiceIdentity"
                        },
                        "body": {
                            "properties": {
                                "policyAssignmentId": "@{items('foreach_policy_state_change')?['data']?['policyAssignmentId']}",
                                "policyDefinitionReferenceId": "@items('foreach_policy_state_change')?['data']?['policyDefinitionReferenceId']",
                                "resourceDiscoveryMode": "ExistingNonCompliant"
                            }
                        },
                        "headers": {
                            "Content-Type": "application/json"
                        },
                        "method": "PUT",
                        "queries": {
                            "api-version": "2021-10-01"
                        },
                        "uri": "https://management.azure.com@{first(split(items('foreach_policy_state_change')?['data']?['policyAssignmentId'], '/providers/microsoft.authorization/policyassignments/'))}/providers/microsoft.policyinsights/remediations/@{guid()}"
                    },
                    "runAfter": {},
                    "type": "Http"
                },
                "Azure_API_-_Trigger_Policy_Evaluation": {
                    "inputs": {
                        "authentication": {
                            "type": "ManagedServiceIdentity"
                        },
                        "headers": {
                            "Content-Type": "application/json"
                        },
                        "method": "POST",
                        "queries": {
                            "api-version": "2019-10-01"
                        },
                        "uri": "https://management.azure.com@{items('foreach_policy_state_change')['subject']}/providers/microsoft.policyinsights/policyStates/latest/triggerEvaluation"
                    },
                    "runAfter": {
                        "Until_-_Remediation_finishes_(Succeeded)": [
                            "Succeeded"
                        ]
                    },
                    "type": "Http"
                },
                "Until_-_Remediation_finishes_(Succeeded)": {
                    "actions": {
                        "Azure_API_-_Check_Remediation": {
                            "inputs": {
                                "authentication": {
                                    "type": "ManagedServiceIdentity"
                                },
                                "headers": {
                                    "Content-Type": "application/json"
                                },
                                "method": "GET",
                                "queries": {
                                    "api-version": "2021-10-01"
                                },
                                "uri": "https://management.azure.com@{body('Azure_API_-_Create_Policy_Remediation_(quick_-_ExistingNonCompliant)')?['id']}"
                            },
                            "runAfter": {},
                            "type": "Http"
                        }
                    },
                    "expression": "@contains(createArray('Complete','Succeeded'), body('Azure_API_-_Create_Policy_Remediation_(quick_-_ExistingNonCompliant)')?['properties']?['provisioningState'])",
                    "limit": {
                        "count": 60,
                        "timeout": "PT1H"
                    },
                    "runAfter": {
                        "Azure_API_-_Create_Policy_Remediation_(quick_-_ExistingNonCompliant)": [
                            "Succeeded"
                        ]
                    },
                    "type": "Until"
                }
            },
            "expression": {
                "and": [
                    {
                        "equals": [
                            "@items('foreach_policy_state_change')?['data']?['complianceState']",
                            "NonCompliant"
                        ]
                    }
                ]
            },
            "runAfter": {},
            "type": "If"
        }
    },
    "foreach": "@triggerBody()",
    "runAfter": {},
    "type": "Foreach"
}
CUSTOM_ACTION_SCHEMA

}
######################################################
# RBAC Permission
######################################################
resource "azurerm_role_assignment" "lapp" {
  scope                = data.azurerm_subscription.sub.id
  role_definition_name = "Resource Policy Contributor"
  principal_id         = azurerm_logic_app_workflow.lapp.identity[0].principal_id
}
