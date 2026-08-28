@{
    RootModule        = 'ADFixTool.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '3f0c5b0a-6e0a-4b6b-9b0c-9f8f1a6e6b1b'
    Author            = 'itss-david'
    CompanyName       = 'ITSS'
    Copyright         = '(c) itss-david. MIT License.'
    Description       = 'On-prem AD / Azure AD (Entra ID) sync error checker and 365 identity verifier, built to replace the deprecated Microsoft IdFix tool.'
    PowerShellVersion = '5.1'

    FunctionsToExport = @(
        'Get-ADFixRuleDefinition'
        'Get-ADFixDomainUser'
        'Get-ADFixSyncScope'
        'Invoke-ADFixRuleSet'
        'Connect-ADFix365Session'
        'Get-ADFix365User'
        'Compare-ADFix365Identity'
        'Export-ADFixReport'
        'Invoke-ADFixCheck'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags       = @('ActiveDirectory', 'AzureAD', 'EntraID', 'Microsoft365', 'IdFix', 'DirSync')
            ProjectUri = 'https://github.com/itss-david/365-ad-fix-tool'
        }
    }
}
