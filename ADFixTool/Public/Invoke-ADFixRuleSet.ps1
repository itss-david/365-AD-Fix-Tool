function Invoke-ADFixRuleSet {
    <#
        .SYNOPSIS
            Runs every rule in the catalog against every supplied AD user and returns
            the resulting issue records.

        .PARAMETER User
            AD user objects from Get-ADFixDomainUser.

        .PARAMETER RuleDefinition
            The rule catalog from Get-ADFixRuleDefinition. Defaults to the built-in set.

        .PARAMETER SyncScope
            Result of Get-ADFixSyncScope. Users outside scope still get evaluated but
            their issues are recorded with InSyncScope = $false so the report can
            separate "will break sync" from "not synced anyway".

        .EXAMPLE
            $users = Get-ADFixDomainUser
            Invoke-ADFixRuleSet -User $users
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$User,

        [object]$RuleDefinition = (Get-ADFixRuleDefinition),

        [object]$SyncScope
    )

    $duplicateIndex = Build-ADFixDuplicateIndex -Users $User
    $context = @{
        Config          = $RuleDefinition
        DuplicateIndex  = $duplicateIndex
    }

    $issues = [System.Collections.Generic.List[object]]::new()

    foreach ($adUser in $User) {
        $inScope = $true
        if ($SyncScope -and $SyncScope.IncludedOU.Count -gt 0) {
            $inScope = [bool]($SyncScope.IncludedOU | Where-Object { $adUser.DistinguishedName -like "*$_" } | Select-Object -First 1)
        }
        if ($SyncScope -and $SyncScope.ExcludedOU.Count -gt 0) {
            if ($SyncScope.ExcludedOU | Where-Object { $adUser.DistinguishedName -like "*$_" } | Select-Object -First 1) {
                $inScope = $false
            }
        }

        foreach ($rule in $RuleDefinition.Rules) {
            $checkFunction = Get-Command -Name $rule.Check -ErrorAction SilentlyContinue
            if (-not $checkFunction) {
                Write-ADFixLog "Rule '$($rule.Id)' references unknown check function '$($rule.Check)' - skipping." -Level Warning
                continue
            }

            $violated = & $checkFunction -User $adUser -Context $context -Rule $rule
            if (-not $violated) { continue }

            $issues.Add((New-ADFixIssueRecord -RuleId $rule.Id -Attribute $rule.Attribute -Severity $rule.Severity `
                -Description $rule.Description -SamAccountName $adUser.sAMAccountName `
                -DistinguishedName $adUser.DistinguishedName -UserPrincipalName $adUser.UserPrincipalName `
                -CurrentValue ([string]($adUser.($rule.Attribute) -join '; ')) -InSyncScope $inScope))
        }
    }

    return $issues
}
