function Test-ADFixBlankAttribute {
    <#
        .SYNOPSIS
            Rule check: violates when the rule's target attribute has no value.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] $User,
        [Parameter(Mandatory)] $Context,
        [Parameter(Mandatory)] $Rule
    )

    return [string]::IsNullOrWhiteSpace($User.($Rule.Attribute))
}
