function Get-ADFixDomainUser {
    <#
        .SYNOPSIS
            Retrieves AD users with the attribute set the rule engine and 365
            comparison need, optionally scoped to specific OUs.

        .PARAMETER SearchBase
            A single OU/container distinguishedName to search under. Omit to search
            the whole domain.

        .PARAMETER IncludedOU
            One or more OU distinguishedNames to include. If supplied, only users in
            these OUs (or their sub-OUs) are returned.

        .PARAMETER ExcludedOU
            One or more OU distinguishedNames to exclude, applied after IncludedOU.

        .PARAMETER IncludeDisabled
            Include disabled accounts. By default only enabled accounts are returned,
            since disabled accounts are usually intentionally left out of 365 sync.

        .EXAMPLE
            Get-ADFixDomainUser
            All enabled users in the domain.

        .EXAMPLE
            Get-ADFixDomainUser -IncludedOU 'OU=Staff,DC=contoso,DC=com' -ExcludedOU 'OU=ServiceAccounts,OU=Staff,DC=contoso,DC=com'
    #>
    [CmdletBinding()]
    param(
        [string]$SearchBase,
        [string[]]$IncludedOU,
        [string[]]$ExcludedOU,
        [switch]$IncludeDisabled
    )

    Assert-ADFixPrerequisite -ModuleName 'ActiveDirectory' -InstallHint 'Install the RSAT: Active Directory Domain Services tools on this machine.'

    $properties = @(
        'UserPrincipalName', 'mail', 'proxyAddresses', 'sAMAccountName',
        'DisplayName', 'GivenName', 'Surname', 'Enabled', 'DistinguishedName',
        'ObjectGUID', 'ms-DS-ConsistencyGuid', 'whenChanged'
    )

    $filter = if ($IncludeDisabled) { '*' } else { 'Enabled -eq $true' }

    $params = @{
        Filter     = $filter
        Properties = $properties
    }
    if ($SearchBase) { $params.SearchBase = $SearchBase }

    $users = Get-ADUser @params

    if ($IncludedOU) {
        $users = $users | Where-Object {
            $dn = $_.DistinguishedName
            $IncludedOU | Where-Object { $dn -like "*$_" } | Select-Object -First 1
        }
    }

    if ($ExcludedOU) {
        $users = $users | Where-Object {
            $dn = $_.DistinguishedName
            -not ($ExcludedOU | Where-Object { $dn -like "*$_" } | Select-Object -First 1)
        }
    }

    return $users
}
