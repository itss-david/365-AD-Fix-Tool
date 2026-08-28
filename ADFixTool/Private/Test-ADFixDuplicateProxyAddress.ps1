function Test-ADFixDuplicateProxyAddress {
    <#
        .SYNOPSIS
            Rule check: violates when any of the user's proxyAddresses values is also
            present on another user, per the pre-built duplicate index.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $bucket = $Context.DuplicateIndex.ProxyAddress
    foreach ($proxy in @($User.proxyAddresses)) {
        if ([string]::IsNullOrWhiteSpace($proxy)) { continue }
        $key = $proxy.Trim().ToLowerInvariant()
        if ([int]$bucket[$key] -gt 1) { return $true }
    }

    return $false
}
