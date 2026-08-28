function Get-ADFixRuleDefinition {
    <#
        .SYNOPSIS
            Loads the rule catalog and shared config (limits/patterns) from
            Config/ADFixRules.psd1, or a custom path if you keep your own copy.

        .PARAMETER Path
            Path to a rules .psd1 file. Defaults to the module's built-in catalog.

        .EXAMPLE
            Get-ADFixRuleDefinition
            Returns the built-in rule set.

        .EXAMPLE
            Get-ADFixRuleDefinition -Path C:\ADFix\CustomRules.psd1
            Loads a customized rule catalog instead, with no code changes required.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = (Join-Path (Split-Path $PSScriptRoot -Parent) 'Config\ADFixRules.psd1')
    )

    if (-not (Test-Path -Path $Path)) {
        throw "Rule definition file not found at '$Path'."
    }

    return Import-PowerShellDataFile -Path $Path
}
