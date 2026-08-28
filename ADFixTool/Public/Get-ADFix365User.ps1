function Get-ADFix365User {
    <#
        .SYNOPSIS
            Retrieves synced (and unsynced) Microsoft 365/Entra ID users with the
            attributes needed to compare against on-prem AD.

        .DESCRIPTION
            Requires an active Connect-ADFix365Session. Only returns users that have
            OnPremisesSyncEnabled = $true unless -IncludeCloudOnly is specified.

        .EXAMPLE
            Get-ADFix365User
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeCloudOnly
    )

    Assert-ADFixPrerequisite -ModuleName 'Microsoft.Graph.Users' -InstallHint 'Install-Module Microsoft.Graph.Users -Scope CurrentUser'

    if (-not (Get-MgContext)) {
        throw 'Not connected to Microsoft Graph. Run Connect-ADFix365Session first.'
    }

    $properties = @(
        'Id', 'UserPrincipalName', 'Mail', 'ProxyAddresses', 'DisplayName',
        'AccountEnabled', 'OnPremisesSyncEnabled', 'OnPremisesImmutableId',
        'OnPremisesLastSyncDateTime', 'OnPremisesSamAccountName'
    )

    $cloudUsers = Get-MgUser -All -Property $properties -ConsistencyLevel eventual

    if (-not $IncludeCloudOnly) {
        $cloudUsers = $cloudUsers | Where-Object { $_.OnPremisesSyncEnabled }
    }

    return $cloudUsers
}
