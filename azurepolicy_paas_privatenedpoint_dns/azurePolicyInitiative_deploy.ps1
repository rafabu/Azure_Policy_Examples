param (
    [
    Parameter(
        Mandatory = $false,
        ValueFromPipeline = $false,
        HelpMessage = "Subscription Id"
    )
    ]
    [string]$subscriptionId,
    [
    Parameter(
        Mandatory = $false,
        ValueFromPipeline = $false,
        HelpMessage = "ManagementGroup Id"
    )
    ]
    [string]$managementGroupId,
    [
    Parameter(
        Mandatory = $false,
        HelpMessage = "Directory Path with policy and policy initiative files"
    )
    ]
    [string]$sourcePath = $pwd.Path,
    [
    Parameter(
        Mandatory = $false,
        HelpMessage = "file filter for policy source code"
    )
    ]
    [string]$sourceFilterPolicy = 'azurepolicy_*.json',
    [
    Parameter(
        Mandatory = $false,
        HelpMessage = "file filter for policyInitiative source code"
    )
    ]
    [string]$sourceFilterPolicyInitiative = 'azurepolicyInitiative_*.json'
)

function Deploy-AzurePolicyDefinition {
    param(
        [string]$target,
        [string]$policyDefinitionFilePath,
        [string]$policyName
    )
    $uri = "https://management.azure.com{0}/providers/Microsoft.Authorization/policyDefinitions/{1}?api-version=2021-06-01" -f $target, $policyName
    $result = az rest --method "put" `
        --uri $uri `
        --body "@$policyDefinitionFilePath" `
        --output "json" | ConvertFrom-Json
    return $result
}

function Deploy-AzurePolicyInitiativeDefinition {
    param(
        [string]$target,
        [string]$policyInitiativeDefinitionFilePath,
        [string]$policyInitiativeName
    )
    $uri = "https://management.azure.com{0}/providers/Microsoft.Authorization/policySetDefinitions/{1}?api-version=2021-06-01" -f $target, $policyInitiativeName
    $result = az rest --method "put" `
        --uri $uri `
        --body "@$policyInitiativeDefinitionFilePath" `
        --output "json" | ConvertFrom-Json
    return $result
}

if ($subscriptionId.length -gt 0) { $targetId = "/subscriptions/$subscriptionId" }
elseif ($managementGroupId.length -gt 0) { $targetId = "/providers/Microsoft.Management/managementgroups/$managementGroupId" }
Write-Output ("===============================")
Write-Output ("deployment target: '{0}'" -f $targetId)
$policyInitiativeDefinitions = Get-ChildItem -Path $sourcePath -Include $sourceFilterPolicyInitiative -Depth 0
foreach ($policyInitiativeDefinition in $policyInitiativeDefinitions) {

    $policyInitiativeDefinitionJson = $policyInitiativeDefinition | Get-Content -Raw
    $policyInitiativeDefinitionObject = $policyInitiativeDefinitionJson | ConvertFrom-Json -Depth 09
    # get policyDefinitionFragment that need replacement
    $policyDefinitionFragments = New-Object System.Collections.Generic.List[System.Object]
    $policyDefinitionFragmentsStaticObjects = $policyInitiativeDefinitionObject.properties.policyDefinitions | Where-Object { $_.policyDefinitionReferenceId -inotmatch "<.+>" -and $_.policyDefinitionId -inotmatch "<.+>" }
    foreach ($policyDefinitionFragmentsStaticObject in $policyDefinitionFragmentsStaticObjects) {
        $policyDefinitionFragments.Add($policyDefinitionFragmentsStaticObject)
    }
    $policyDefinitionFragmentsInputJsonObjects = $policyInitiativeDefinitionObject.properties.policyDefinitions | Where-Object { $_.policyDefinitionReferenceId -imatch "<.+>" -or $_.policyDefinitionId -imatch "<.+>" } | ForEach-Object { ConvertTo-Json -InputObject $_ -Depth 09 }
   
    # deploy policyDefinition, get name & id and replace those in fragment
    Write-Output ("===============================")
    $policyDefinitions = Get-ChildItem -Path $sourcePath -Include $sourceFilterPolicy -Depth 0
    foreach ($policyDefinition in $policyDefinitions) {
        try { $policyName = ($policyDefinition | Get-Content -Raw | ConvertFrom-Json).name }
        catch { $policyName = $null }
        if ($policyName.length -le 0) { $policyName = [guid]::NewGuid() }
       
        $policyDefinition = Deploy-AzurePolicyDefinition -target $targetId -policyDefinitionFilePath $policyDefinition.FullName -policyName $policyName
        foreach ($policyDefinitionFragmentsInputJsonObject in $policyDefinitionFragmentsInputJsonObjects) {
            # replace in named references
            if ($policyDefinitionFragmentsInputJsonObject -imatch ("<{0}>" -f $policyDefinition.name)) {
                $policyDefinitionFragmentsJsonObject = $policyDefinitionFragmentsInputJsonObject -replace ("<{0}>" -f $policyDefinition.name), ("{0}" -f $policyDefinition.name)
                $policyDefinitionFragmentsJsonObject = $policyDefinitionFragmentsJsonObject -replace "<policyDefinitionId>", $policyDefinition.id
                $policyDefinitionFragments.Add(($policyDefinitionFragmentsJsonObject | ConvertFrom-Json -Depth 09))
            }
            # replace on general reference (valid for any rule)
            if ($policyDefinitionFragmentsInputJsonObject -imatch "<policyDefinitionReferenceId>") {
                $policyDefinitionFragmentsJsonObject = $policyDefinitionFragmentsInputJsonObject -replace "<policyDefinitionReferenceId>", ("{0}" -f $policyDefinition.name)
                $policyDefinitionFragmentsJsonObject = $policyDefinitionFragmentsJsonObject -replace "<policyDefinitionId>", $policyDefinition.id
                $policyDefinitionFragments.Add(($policyDefinitionFragmentsJsonObject | ConvertFrom-Json -Depth 09))
            }
           
        }
        Write-Output ("policyDefinition deployed / updated: '{0}' - '{1}'" -f $policyDefinition.name, $policyDefinition.properties.displayName)
    }
   
    # build updated initiative definition
    Write-Output ("===============================")
    try { $policyInitiativeName = $policyInitiativeDefinitionObject.name }
    catch { $policyInitiativeName = $null }
    if ($policyInitiativeName.length -le 0) { $policyName = [guid]::NewGuid() }
    $policyInitiativeDefinitionObjectExpandedJSON = @{
        "properties" = @{
            "displayName"            = $policyInitiativeDefinitionObject.properties.displayName;
            "description"            = $policyInitiativeDefinitionObject.properties.description;
            "metadata"               = $policyInitiativeDefinitionObject.properties.metadata;
            "parameters"             = $policyInitiativeDefinitionObject.properties.parameters;
            "policyDefinitions"      = $policyDefinitionFragments
            "policyDefinitionGroups" = $policyInitiativeDefinitionObject.properties.policyDefinitionGroups
        }
    } | ConvertTo-Json -Depth 09

    # drop policy initiative as file (to ease az rest use through @bodyfile.json)
    $policyInitiativeTempFile = New-TemporaryFile

    $policyInitiativeDefinitionObjectExpandedJSON | Out-File -FilePath $policyInitiativeTempFile

    $policyInitiativeDefinition = Deploy-AzurePolicyInitiativeDefinition -target $targetId -policyInitiativeDefinitionFilePath $policyInitiativeTempFile.FullName -policyInitiativeName $policyInitiativeName
    Remove-Item -Path $policyInitiativeTempFile.FullName -Force
    Write-Output ("policySetDefinition deployed / updated: '{0}' - '{1}'" -f $policyInitiativeDefinition.name, $policyInitiativeDefinition.properties.displayName)
    Write-Output ("===============================")
}
