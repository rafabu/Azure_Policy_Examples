# Configure PaaS Resource Public Access (PaaS Firewall).

Modify policies that assure `publicNetworkAccess` attribute of PaaS resources is set in line with a tag value. The policies consider resource tags with the name (key) as set by the policy assignment parameter at the following levels and priorities:

- Resource (e.g. `Microsoft.Storage/storageAccounts`)
- Resource Group
- Subscription

If no value is assigned at the resource level, first the resource group, then the subscription is considered. If a valid setting of values for `publicNetworkAccess` is found, the policies are applied setting the attribute accordingly.

# Resource Tag

Tag name can be configured and defaults to `cccPaaSFirewall`. Valid values are:
- `Enable`
- `Disable`
Evaluation is case-insensitive. If no value is set on any of the levels, the policies do not apply.

_Important_: Consider using these policies in conjunction with `modify` policies, forcing inheritance of the tag `cccPaaSFirewall` from subscription to resource group to resource. If not, resource contributors get to control over enablement of public network access to their PaaS resources by modifying the value of the tag.

# Deploy policies (as initiative) to a subscription (script supported)

`az login`
`azurePolicyInitiative_deploy.ps1 -managementGroupId {managementGroupName} `

The command will deploy all policies and the initiative found in this directory to the given managementGroup or subscription. The initiative's references are being compiled automatically, based on the number of policies present and will link their ids accordingly. This works by replacing the text tags `<policyDefinitionReferenceId>` and `<policyDefinitionId>` in the initiative's JSON code.

# Manually deploy policies

- `az rest --method 'put' --uri "https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"`
- `az rest --method PUT --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01" --body "@azurepolicy.json"`

 # Manually delete policies
 - `az rest --method DELETE --uri "https://management.azure.com/providers/Microsoft.Management/managementgroups/{managementGroupId}/providers/Microsoft.Authorization/policyDefinitions/{policyName}?api-version=2021-06-01"`

