function New-ADFixIssueRecord {
    <#
        .SYNOPSIS
            Builds a single standardized issue record used throughout the report pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$RuleId,
        [Parameter(Mandatory)] [string]$Attribute,
        [Parameter(Mandatory)] [ValidateSet('Error', 'Warning', 'Info')] [string]$Severity,
        [Parameter(Mandatory)] [string]$Description,
        [Parameter(Mandatory)] [AllowEmptyString()] [AllowNull()] [string]$SamAccountName,
        [Parameter(Mandatory)] [AllowEmptyString()] [AllowNull()] [string]$DistinguishedName,
        [string]$UserPrincipalName,
        [string]$CurrentValue,
        [bool]$InSyncScope = $true,
        [ValidateSet('ActiveDirectory', 'Comparison')]
        [string]$Source = 'ActiveDirectory'
    )

    [pscustomobject]@{
        RuleId            = $RuleId
        Attribute         = $Attribute
        Severity          = $Severity
        Description       = $Description
        SamAccountName    = $SamAccountName
        UserPrincipalName = $UserPrincipalName
        DistinguishedName = $DistinguishedName
        CurrentValue      = $CurrentValue
        InSyncScope       = $InSyncScope
        Source            = $Source
    }
}
