function Test-ADFixProxyAddressFormat {
    <#
        .SYNOPSIS
            Rule check: violates when any proxyAddresses entry lacks a recognized
            "TYPE:" prefix (SMTP/smtp, X500/x500, SIP/sip, SPO, smsms).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $pattern = $Context.Config.Patterns.ProxyAddressPrefix
    foreach ($proxy in @($User.proxyAddresses)) {
        if ([string]::IsNullOrWhiteSpace($proxy)) { continue }
        if ($proxy -notmatch $pattern) { return $true }
    }

    return $false
}
