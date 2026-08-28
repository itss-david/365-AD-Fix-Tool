#Requires -Version 5.1

$ErrorActionPreference = 'Stop'

$privateFunctions = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -ErrorAction SilentlyContinue)
$publicFunctions  = @(Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter '*.ps1' -ErrorAction SilentlyContinue)

foreach ($file in @($privateFunctions + $publicFunctions)) {
    try {
        . $file.FullName
    }
    catch {
        throw "Failed to dot-source $($file.FullName): $_"
    }
}

Export-ModuleMember -Function $publicFunctions.BaseName
