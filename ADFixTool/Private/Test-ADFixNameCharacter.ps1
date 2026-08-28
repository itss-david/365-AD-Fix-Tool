function Test-ADFixNameCharacter {
    <#
        .SYNOPSIS
            Rule check: violates when the target attribute has a leading/trailing space,
            which Entra ID silently trims and can cause soft-match/sync inconsistencies.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $value = $User.($Rule.Attribute)
    if ([string]::IsNullOrEmpty($value)) { return $false }

    return $value -match $Context.Config.Patterns.LeadingTrailingSpace
}
