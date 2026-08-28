function Test-ADFixMailFormat {
    <#
        .SYNOPSIS
            Rule check: violates when a non-blank mail attribute isn't a plausible
            SMTP address (basic local@domain.tld shape).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $mail = $User.mail
    if ([string]::IsNullOrWhiteSpace($mail)) { return $false }

    return $mail -notmatch $Context.Config.Patterns.ValidEmailFormat
}
