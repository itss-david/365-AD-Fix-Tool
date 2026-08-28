function Test-ADFixDuplicateValue {
    <#
        .SYNOPSIS
            Rule check: violates when the rule's target attribute (a single-value
            attribute such as UserPrincipalName or mail) is shared by more than one
            user in the pre-built duplicate index.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $value = $User.($Rule.Attribute)
    if ([string]::IsNullOrWhiteSpace($value)) { return $false }

    $bucket = $Context.DuplicateIndex.SingleValue[$Rule.Attribute]
    if (-not $bucket) { return $false }

    $key = $value.Trim().ToLowerInvariant()
    return [int]$bucket[$key] -gt 1
}
