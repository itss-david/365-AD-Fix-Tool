function Test-ADFixUPNCharacter {
    <#
        .SYNOPSIS
            Rule check: violates when UserPrincipalName contains characters Entra ID
            doesn't accept in the local part, or has a leading/trailing/doubled dot.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $upn = $User.UserPrincipalName
    if ([string]::IsNullOrWhiteSpace($upn) -or $upn -notmatch '@') { return $false }

    $localPart = $upn.Substring(0, $upn.LastIndexOf('@'))
    $patterns = $Context.Config.Patterns

    if ($localPart -notmatch $patterns.ValidUPNLocalPart) { return $true }
    if ($localPart -match $patterns.UPNLeadingTrailingDot) { return $true }

    return $false
}
