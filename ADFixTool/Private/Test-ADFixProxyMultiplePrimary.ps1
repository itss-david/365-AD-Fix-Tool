function Test-ADFixProxyMultiplePrimary {
    <#
        .SYNOPSIS
            Rule check: violates when more than one proxyAddresses entry uses the
            uppercase "SMTP:" (primary) prefix. Only one primary is allowed.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $primaryCount = @(@($User.proxyAddresses) | Where-Object { $_ -cmatch '^SMTP:' }).Count
    return $primaryCount -gt 1
}
