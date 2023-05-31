# Policy which adds WIndows Server Features using Install-WindowsFeature.

Implemented by deploying a  `Managed Run Commands` "Microsoft.Compute/virtualMachines/runCommands" resource if

- Windows Server Computer

takes parameter `featureNameMatch` with a regex matching the name of packages as listed by `Get-WindowsFeature`.

# Deploy
## For defining a policy in a subscription
az rest --method 'put' --uri "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"


## For defining a policy in a management group
 az rest --method PUT --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"

 # Remove
 az rest --method DELETE --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01"

