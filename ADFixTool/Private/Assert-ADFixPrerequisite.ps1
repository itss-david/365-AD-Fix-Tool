function Assert-ADFixPrerequisite {
    <#
        .SYNOPSIS
            Verifies a required PowerShell module is installed/importable and gives an
            actionable error message when it isn't, instead of a generic import failure.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [Parameter(Mandatory)]
        [string]$InstallHint
    )

    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        throw "Required module '$ModuleName' is not installed. $InstallHint"
    }

    Import-Module -Name $ModuleName -ErrorAction Stop
}
