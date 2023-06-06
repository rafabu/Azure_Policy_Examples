# Policy which assigns a policy to the resource group, based on tag value

Policy deploys "Microsoft.Authorization/policyAssignments" resource if

- Resource Group's tag value matches

In oder to also enable initial remediation also deploys
- `Microsoft.Authorization/policyAssignments`
- `Microsoft.Authorization/roleAssignments`
- `Microsoft.PolicyInsights/remediations`

# Hints
As policyAssignments are deployed at subscription level even if the scope is a resource group, assigning one to a resource group requires to set
`{
    "then": {
        "details": {
          "deploymentScope": "resourceGroup",
          "existenceScope": "subscription",
        }
    } 
}`


# Deploy
## For defining a policy in a subscription
az rest --method 'put' --uri "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"


## For defining a policy in a management group
 az rest --method PUT --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"

 # Remove
 az rest --method DELETE --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01"

