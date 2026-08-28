<#
    .SYNOPSIS
        Convenience entry point for 365-AD-Fix-Tool: imports the ADFixTool module
        and runs a full check without requiring the module to be installed first.

    .DESCRIPTION
        Replacement for Microsoft's deprecated IdFix tool. Checks on-prem AD users
        for attribute errors that would block/corrupt Microsoft 365 (Entra ID) sync,
        and (unless -SkipCloudCheck is used) compares synced users against 365.

        For anything beyond a one-off run - scripting, scheduling, or extending the
        rule set - import the ADFixTool module directly and call its functions
        (Invoke-ADFixCheck, Get-ADFixRuleDefinition, etc.) instead of this wrapper.

    .PARAMETER SearchBase
        A single OU/container distinguishedName to search under. Omit to search the
        whole domain.

    .PARAMETER IncludedOU
        OU distinguishedNames to include (also used as Entra Connect sync-scope
        fallback when this isn't run on the sync server).

    .PARAMETER ExcludedOU
        OU distinguishedNames to exclude.

    .PARAMETER SkipCloudCheck
        Skip the Microsoft Graph connection and 365 comparison; AD checks only.

    .PARAMETER SkipSyncScopeDetection
        Treat every AD user as in Entra Connect's sync scope.

    .PARAMETER RulesConfigPath
        Path to a custom rule catalog .psd1, instead of the built-in one at
        ADFixTool\Config\ADFixRules.psd1.

    .PARAMETER ReportPath
        Folder to write the CSV/HTML report into. Defaults to .\Reports.

    .PARAMETER TenantId
        Optional tenant ID/domain to pass to Connect-ADFix365Session.

    .EXAMPLE
        .\Start-ADFixTool.ps1
        Full run against the whole domain: AD checks + 365 comparison.

    .EXAMPLE
        .\Start-ADFixTool.ps1 -SkipCloudCheck -IncludedOU 'OU=Staff,DC=contoso,DC=com'
        AD-only checks, scoped to one OU, no Graph sign-in required.
#>
[CmdletBinding()]
param(
    [string]$SearchBase,
    [string[]]$IncludedOU,
    [string[]]$ExcludedOU,
    [switch]$SkipCloudCheck,
    [switch]$SkipSyncScopeDetection,
    [string]$RulesConfigPath,
    [string]$ReportPath = (Join-Path $PSScriptRoot 'Reports'),
    [string]$TenantId
)

Import-Module (Join-Path $PSScriptRoot 'ADFixTool\ADFixTool.psd1') -Force

Invoke-ADFixCheck -SearchBase $SearchBase -IncludedOU $IncludedOU -ExcludedOU $ExcludedOU `
    -SkipCloudCheck:$SkipCloudCheck -SkipSyncScopeDetection:$SkipSyncScopeDetection `
    -RulesConfigPath $RulesConfigPath -ReportPath $ReportPath -TenantId $TenantId
