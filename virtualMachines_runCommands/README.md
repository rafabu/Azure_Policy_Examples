# Policy which assigns members to built-in Windows security groups.

Implemented by deploying a  `Managed Run Commands` "Microsoft.Compute/virtualMachines/runCommands" resource if

- Windows Comuter
- Domain joined by extension `JsonADDomainExtension`

Allows adding members of either local or domain user and group type.

Reference several members in `groupMember` parameter like (including the double quotes, comma and backslash):

- "DOMAINNAME\Group Name", "DOMAINNAME\samAccountName"

# Deploy
## For defining a policy in a subscription
az rest --method 'put' --uri "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"


## For defining a policy in a management group
 az rest --method PUT --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"

 # Remove
 az rest --method DELETE --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01"

