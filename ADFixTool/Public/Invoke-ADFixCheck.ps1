function Invoke-ADFixCheck {
    <#
        .SYNOPSIS
            End-to-end entry point: checks on-prem AD users for errors that would
            block or corrupt Microsoft 365/Entra ID sync, optionally compares synced
            users against 365, and writes CSV/HTML reports.

        .PARAMETER SearchBase
            A single OU/container distinguishedName to search under. Omit to search
            the whole domain.

        .PARAMETER IncludedOU
            OU distinguishedNames to include (also used as Entra Connect sync-scope
            fallback when not run on the sync server - see Get-ADFixSyncScope).

        .PARAMETER ExcludedOU
            OU distinguishedNames to exclude.

        .PARAMETER SkipCloudCheck
            Skip connecting to Microsoft Graph and comparing against 365; only run
            the local AD attribute/error checks.

        .PARAMETER SkipSyncScopeDetection
            Skip Entra Connect sync-scope detection; treat every user as in-scope.

        .PARAMETER RulesConfigPath
            Path to a custom rule catalog .psd1. Defaults to the built-in one.

        .PARAMETER ReportPath
            Folder to write the CSV/HTML reports into. Defaults to .\Reports.

        .PARAMETER TenantId
            Optional tenant ID/domain for Connect-ADFix365Session.

        .EXAMPLE
            Invoke-ADFixCheck
            Full run: AD checks + 365 comparison, reports written to .\Reports.

        .EXAMPLE
            Invoke-ADFixCheck -SkipCloudCheck -IncludedOU 'OU=Staff,DC=contoso,DC=com'
            AD-only checks, scoped to one OU.
    #>
    [CmdletBinding()]
    param(
        [string]$SearchBase,
        [string[]]$IncludedOU,
        [string[]]$ExcludedOU,
        [switch]$SkipCloudCheck,
        [switch]$SkipSyncScopeDetection,
        [string]$RulesConfigPath,
        [string]$ReportPath = '.\Reports',
        [string]$TenantId
    )

    Write-ADFixLog 'Loading rule catalog...'
    $ruleParams = @{}
    if ($RulesConfigPath) { $ruleParams.Path = $RulesConfigPath }
    $ruleDefinition = Get-ADFixRuleDefinition @ruleParams

    Write-ADFixLog 'Retrieving AD users...'
    $adUsers = Get-ADFixDomainUser -SearchBase $SearchBase -IncludedOU $IncludedOU -ExcludedOU $ExcludedOU
    Write-ADFixLog "Retrieved $($adUsers.Count) AD users." -Level Success

    $syncScope = $null
    if (-not $SkipSyncScopeDetection) {
        Write-ADFixLog 'Detecting Entra Connect sync scope...'
        $syncScope = Get-ADFixSyncScope -IncludedOU $IncludedOU -ExcludedOU $ExcludedOU
        Write-ADFixLog "Sync scope source: $($syncScope.Source)" -Level Info
    }

    Write-ADFixLog 'Running attribute/error rule checks...'
    $issues = [System.Collections.Generic.List[object]]::new()
    Invoke-ADFixRuleSet -User $adUsers -RuleDefinition $ruleDefinition -SyncScope $syncScope | ForEach-Object { $issues.Add($_) }
    Write-ADFixLog "Found $($issues.Count) AD-side issues." -Level $(if ($issues.Count -gt 0) { 'Warning' } else { 'Success' })

    if (-not $SkipCloudCheck) {
        Write-ADFixLog 'Connecting to Microsoft Graph...'
        Connect-ADFix365Session -TenantId $TenantId

        Write-ADFixLog 'Retrieving synced Microsoft 365 users...'
        $cloudUsers = Get-ADFix365User
        Write-ADFixLog "Retrieved $($cloudUsers.Count) synced cloud users." -Level Success

        Write-ADFixLog 'Comparing AD users against Microsoft 365...'
        Compare-ADFix365Identity -ADUser $adUsers -CloudUser $cloudUsers | ForEach-Object { $issues.Add($_) }
    }
    else {
        Write-ADFixLog 'Skipping Microsoft 365 comparison (-SkipCloudCheck).' -Level Warning
    }

    return Export-ADFixReport -Issue $issues -OutputPath $ReportPath
}
