function Test-ADFixAttributeLength {
    <#
        .SYNOPSIS
            Rule check: violates when the rule's target attribute is longer than
            $Rule.Param characters. Blank values are not flagged here (use
            Test-ADFixBlankAttribute for that).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    $value = $User.($Rule.Attribute)
    if ([string]::IsNullOrEmpty($value)) { return $false }

    return $value.Length -gt [int]$Rule.Param
}
