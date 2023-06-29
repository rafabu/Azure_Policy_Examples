$body = @"
{
    "properties": {
      "metadata": {
        "version": "1.0.0",
        "category": "Network"
      },
      "parameters": {
        "effect": {
          "type": "String",
          "metadata": {
            "displayName": "Effect",
            "description": "Enable or disable the execution of the policy"
          },
          "allowedValues": [
            "Modify",
            "Disabled"
          ],
          "defaultValue": "Modify"
        },
        "paasFirewallEnableTagName": {
          "type": "String",
          "metadata": {
            "displayName": "PaaS Firewall Enable Tag Name",
            "description": "Name of the tag that enable or disable the PaaS firewall. Value must be 'Enable' or 'Disable'."
          },
          "defaultValue": "cccPaaSFirewall"
        }
      },
      "description": "Assures that public internet access is disabled on PaaS resources. Considers resource tag value.",
      "policyDefinitions": [
       
          {
            "policyDefinitionReferenceId": "cccPaaSFirewall-tag-functionapps_1",
            "policyDefinitionId": "/subscriptions/73e7819b-1f47-457c-b6d0-ddcc1627c6ce/providers/Microsoft.Authorization/policyDefinitions/cccPaaSFirewall-tag-functionapps",
            "parameters": {
              "paasFirewallEnableTagName": {
                "value": "[parameters('paasFirewallEnableTagName')]"
              },
              "effect": {
                "value": "[parameters('effect')]"
              }
            },
            "groupNames": []
          }
                ],
      "displayName": "[Custom] Configure resource public network access (PaaS firewall)",
      "policyDefinitionGroups": null
    }
  }
"@

az rest --method 'put' --uri 'https://management.azure.com/subscriptions/73e7819b-1f47-457c-b6d0-ddcc1627c6ce/providers/Microsoft.Authorization/policySetDefinitions/ccc-testing?api-version=2021-06-01' --body ('{0}' -f ($body -replace '"', '\"'))

az rest --method "put" --uri "https://management.azure.com/subscriptions/73e7819b-1f47-457c-b6d0-ddcc1627c6ce/providers/Microsoft.Authorization/policySetDefinitions/ccc-testing?api-version=2021-06-01" --body "@policy.json"