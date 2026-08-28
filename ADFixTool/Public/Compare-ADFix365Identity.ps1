function Compare-ADFix365Identity {
    <#
        .SYNOPSIS
            Matches on-prem AD users to their synced Microsoft 365/Entra ID
            counterpart and flags mismatches or missing sync.

        .DESCRIPTION
            Matches primarily by ImmutableID (Base64 of the AD source-anchor
            attribute - ObjectGUID by default, or ms-DS-ConsistencyGuid if your
            Entra Connect config uses that anchor), falling back to UserPrincipalName
            when no ImmutableID match is found. Reports:
              - AD users in sync scope with no matching cloud user (not synced yet)
              - Cloud synced users with no matching AD user (orphaned/stale)
              - Attribute mismatches (mail, proxyAddresses, DisplayName, enabled state)

        .PARAMETER ADUser
            AD user objects from Get-ADFixDomainUser.

        .PARAMETER CloudUser
            Cloud user objects from Get-ADFix365User.

        .PARAMETER SourceAnchorAttribute
            Which AD attribute Entra Connect uses as the sync source anchor.
            Defaults to 'ObjectGUID' (the Entra Connect default). Set to
            'ms-DS-ConsistencyGuid' if your tenant was configured to use that instead.

        .EXAMPLE
            Compare-ADFix365Identity -ADUser $adUsers -CloudUser $cloudUsers
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object[]]$ADUser,

        [Parameter(Mandatory)]
        [object[]]$CloudUser,

        [ValidateSet('ObjectGUID', 'ms-DS-ConsistencyGuid')]
        [string]$SourceAnchorAttribute = 'ObjectGUID'
    )

    $cloudByImmutableId = @{}
    $cloudByUpn = @{}
    foreach ($cloud in $CloudUser) {
        if ($cloud.OnPremisesImmutableId) { $cloudByImmutableId[$cloud.OnPremisesImmutableId] = $cloud }
        if ($cloud.UserPrincipalName) { $cloudByUpn[$cloud.UserPrincipalName.ToLowerInvariant()] = $cloud }
    }

    $matchedCloudIds = [System.Collections.Generic.HashSet[string]]::new()
    $results = [System.Collections.Generic.List[object]]::new()

    foreach ($ad in $ADUser) {
        $anchorBytes = $ad.($SourceAnchorAttribute)
        $immutableId = $null
        if ($anchorBytes) { $immutableId = Convert-ADFixImmutableId -SourceAnchor $anchorBytes }

        $cloud = $null
        if ($immutableId -and $cloudByImmutableId.ContainsKey($immutableId)) {
            $cloud = $cloudByImmutableId[$immutableId]
        }
        elseif ($ad.UserPrincipalName -and $cloudByUpn.ContainsKey($ad.UserPrincipalName.ToLowerInvariant())) {
            $cloud = $cloudByUpn[$ad.UserPrincipalName.ToLowerInvariant()]
        }

        if (-not $cloud) {
            $results.Add((New-ADFixIssueRecord -RuleId 'Sync-NotFoundInCloud' -Attribute 'UserPrincipalName' -Severity 'Warning' `
                -Description 'AD user has no matching synced Microsoft 365 user (not yet synced, or blocked by another error).' `
                -SamAccountName $ad.sAMAccountName -DistinguishedName $ad.DistinguishedName `
                -UserPrincipalName $ad.UserPrincipalName -CurrentValue $ad.UserPrincipalName -Source 'Comparison'))
            continue
        }

        $matchedCloudIds.Add($cloud.Id) | Out-Null

        if ($ad.mail -and $cloud.Mail -and ($ad.mail -ne $cloud.Mail)) {
            $results.Add((New-ADFixIssueRecord -RuleId 'Sync-MailMismatch' -Attribute 'mail' -Severity 'Warning' `
                -Description "mail differs between AD ('$($ad.mail)') and 365 ('$($cloud.Mail)')." `
                -SamAccountName $ad.sAMAccountName -DistinguishedName $ad.DistinguishedName `
                -UserPrincipalName $ad.UserPrincipalName -CurrentValue $ad.mail -Source 'Comparison'))
        }

        $adProxies = @($ad.proxyAddresses) | Sort-Object
        $cloudProxies = @($cloud.ProxyAddresses) | Sort-Object
        if (($adProxies -join ';').ToLowerInvariant() -ne ($cloudProxies -join ';').ToLowerInvariant()) {
            $results.Add((New-ADFixIssueRecord -RuleId 'Sync-ProxyAddressMismatch' -Attribute 'proxyAddresses' -Severity 'Info' `
                -Description 'proxyAddresses in 365 do not exactly match AD (may lag behind the last sync cycle).' `
                -SamAccountName $ad.sAMAccountName -DistinguishedName $ad.DistinguishedName `
                -UserPrincipalName $ad.UserPrincipalName -CurrentValue ($adProxies -join '; ') -Source 'Comparison'))
        }

        if ($ad.Enabled -ne $cloud.AccountEnabled) {
            $results.Add((New-ADFixIssueRecord -RuleId 'Sync-EnabledStateMismatch' -Attribute 'Enabled' -Severity 'Warning' `
                -Description "Account enabled state differs between AD ($($ad.Enabled)) and 365 ($($cloud.AccountEnabled))." `
                -SamAccountName $ad.sAMAccountName -DistinguishedName $ad.DistinguishedName `
                -UserPrincipalName $ad.UserPrincipalName -CurrentValue ([string]$ad.Enabled) -Source 'Comparison'))
        }
    }

    foreach ($cloud in $CloudUser) {
        if (-not $matchedCloudIds.Contains($cloud.Id)) {
            $results.Add((New-ADFixIssueRecord -RuleId 'Sync-OrphanedCloudUser' -Attribute 'UserPrincipalName' -Severity 'Info' `
                -Description 'Synced Microsoft 365 user has no matching AD user (deleted/moved on-prem but not yet reconciled).' `
                -SamAccountName $cloud.OnPremisesSamAccountName -DistinguishedName '' `
                -UserPrincipalName $cloud.UserPrincipalName -CurrentValue $cloud.UserPrincipalName -Source 'Comparison'))
        }
    }

    return $results
}
