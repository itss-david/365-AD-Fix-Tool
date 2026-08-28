function Get-ADFixSyncScope {
    <#
        .SYNOPSIS
            Determines which OUs are actually in scope of Azure AD Connect / Entra
            Connect sync, so users outside that scope aren't flagged as sync errors
            (they're simply not being synced on purpose).

        .DESCRIPTION
            Tries two sources, in order:
              1. The ADSync module (only present when run ON the Entra Connect
                 server) - reads the AD connector's configured OU inclusion/exclusion
                 list directly from the sync engine.
              2. Manually supplied -IncludedOU/-ExcludedOU parameters, for when this
                 tool is run from an admin workstation instead of the sync server.

            If neither source yields data, every OU is treated as in-scope and a
            warning is written so the operator knows scope detection was skipped.

        .PARAMETER IncludedOU
            Fallback: OU distinguishedNames known to be in the sync scope.

        .PARAMETER ExcludedOU
            Fallback: OU distinguishedNames known to be excluded from the sync scope.

        .OUTPUTS
            pscustomobject with IncludedOU, ExcludedOU, and Source ('ADSyncModule',
            'ManualParameters', or 'Unrestricted').
    #>
    [CmdletBinding()]
    param(
        [string[]]$IncludedOU,
        [string[]]$ExcludedOU
    )

    if (Get-Module -ListAvailable -Name 'ADSync') {
        try {
            Import-Module ADSync -ErrorAction Stop
            $connector = Get-ADSyncConnector | Where-Object { $_.ConnectorTypeName -eq 'AD' } | Select-Object -First 1

            if ($connector) {
                $scope = $connector.Partitions | ForEach-Object { $_.ConnectorPartitionScope }
                return [pscustomobject]@{
                    IncludedOU = @($scope.ContainerInclusionList)
                    ExcludedOU = @($scope.ContainerExclusionList)
                    Source     = 'ADSyncModule'
                }
            }
        }
        catch {
            Write-ADFixLog "ADSync module present but scope lookup failed: $_. Falling back to manual OU parameters." -Level Warning
        }
    }

    if ($IncludedOU -or $ExcludedOU) {
        return [pscustomobject]@{
            IncludedOU = @($IncludedOU)
            ExcludedOU = @($ExcludedOU)
            Source     = 'ManualParameters'
        }
    }

    Write-ADFixLog 'Could not detect Entra Connect sync scope (not running on the sync server, and no -IncludedOU/-ExcludedOU supplied). Treating all users as in-scope.' -Level Warning
    return [pscustomobject]@{
        IncludedOU = @()
        ExcludedOU = @()
        Source     = 'Unrestricted'
    }
}
