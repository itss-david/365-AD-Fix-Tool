function Test-ADFixProxyPrimaryMissing {
    <#
        .SYNOPSIS
            Rule check: violates when a mail-enabled user (has an SMTP proxy address
            at all) has no primary address, i.e. no entry using an uppercase "SMTP:" prefix.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $smtpAddresses = @($User.proxyAddresses) | Where-Object { $_ -match '^smtp:' }
    if (-not $smtpAddresses) { return $false }

    $primaryCount = @($smtpAddresses | Where-Object { $_ -cmatch '^SMTP:' }).Count
    return $primaryCount -eq 0
}
