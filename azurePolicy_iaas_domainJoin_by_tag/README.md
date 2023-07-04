# Windows Domain Join (based on tag values)

Initiative that joins newly deployed Windows VMs and VM Scale Set nodes to a Windows Domain or Azure AD Domain Services.

Policy uses the VM extension `JsonADDomainExtension`.

Tags are used to configure
- Domain FQDN: _cccWindowsDomainFQDN_
- Domain OU: _cccWindowsDomainOUPath_

*Note": Policy assignment needs custom RBAC role on key vault in order to enable the JsonAADDomainExtension to read the secrets in the key vault.

```
{
    "properties": {
        "roleName": "[Custom] Key Vault ARM Deploy Action",
        "description": "",
        "assignableScopes": [
        ],
        "permissions": [
            {
                "actions": [
                    "Microsoft.KeyVault/vaults/deploy/action"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    }
}

```