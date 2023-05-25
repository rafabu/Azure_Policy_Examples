Policy which assigns members to built-in Windows security groups.

Implemented by deploying a  `Managed Run Commands` "Microsoft.Compute/virtualMachines/runCommands" resource if

- Windows Comuter
- Domain joined by extension `JsonADDomainExtension`

Allows adding members of either local or domain user and group type.

Reference several members in `groupMember` parameter like (including the double quotes, comma and backslash):

- "DOMAINNAME\Group Name", "DOMAINNAME\samAccountName"