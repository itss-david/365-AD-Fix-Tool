function Connect-ADFix365Session {
    <#
        .SYNOPSIS
            Connects to Microsoft Graph with the scopes this tool needs to read user
            and directory sync data, using interactive delegated sign-in.

        .PARAMETER TenantId
            Optional tenant ID/domain to target, for multi-tenant admins.

        .EXAMPLE
            Connect-ADFix365Session
    #>
    [CmdletBinding()]
    param(
        [string]$TenantId
    )

    Assert-ADFixPrerequisite -ModuleName 'Microsoft.Graph.Authentication' -InstallHint 'Install-Module Microsoft.Graph.Authentication -Scope CurrentUser'
    Assert-ADFixPrerequisite -ModuleName 'Microsoft.Graph.Users' -InstallHint 'Install-Module Microsoft.Graph.Users -Scope CurrentUser'

    $connectParams = @{
        Scopes      = @('User.Read.All', 'Directory.Read.All')
        NoWelcome   = $true
    }
    if ($TenantId) { $connectParams.TenantId = $TenantId }

    Connect-MgGraph @connectParams
    Write-ADFixLog "Connected to Microsoft Graph as $((Get-MgContext).Account)" -Level Success
}
