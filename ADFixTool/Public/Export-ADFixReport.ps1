function Export-ADFixReport {
    <#
        .SYNOPSIS
            Writes a console summary plus CSV and HTML reports for a set of issue
            records produced by Invoke-ADFixRuleSet and/or Compare-ADFix365Identity.

        .PARAMETER Issue
            Issue records to report on.

        .PARAMETER OutputPath
            Folder to write CSV/HTML reports into. Created if it doesn't exist.

        .PARAMETER Basename
            Base file name (without extension) for the report files. Defaults to a
            timestamped name.

        .EXAMPLE
            Export-ADFixReport -Issue $allIssues -OutputPath .\Reports
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Issue,

        [Parameter(Mandatory)]
        [string]$OutputPath,

        [string]$Basename = "ADFixReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    )

    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $csvPath = Join-Path $OutputPath "$Basename.csv"
    $htmlPath = Join-Path $OutputPath "$Basename.html"

    $Issue | Sort-Object Severity, RuleId, SamAccountName | Export-Csv -Path $csvPath -NoTypeInformation

    $errorCount = @($Issue | Where-Object { $_.Severity -eq 'Error' }).Count
    $warningCount = @($Issue | Where-Object { $_.Severity -eq 'Warning' }).Count
    $infoCount = @($Issue | Where-Object { $_.Severity -eq 'Info' }).Count
    $outOfScopeCount = @($Issue | Where-Object { -not $_.InSyncScope }).Count

    Write-ADFixLog "Errors: $errorCount | Warnings: $warningCount | Info: $infoCount | Out-of-sync-scope: $outOfScopeCount" -Level $(if ($errorCount -gt 0) { 'Error' } elseif ($warningCount -gt 0) { 'Warning' } else { 'Success' })

    $rows = $Issue | Sort-Object Severity, RuleId, SamAccountName | ForEach-Object {
        $rowClass = switch ($_.Severity) { 'Error' { 'severity-error' } 'Warning' { 'severity-warning' } default { 'severity-info' } }
        "<tr class='$rowClass'><td>$($_.Severity)</td><td>$($_.RuleId)</td><td>$($_.SamAccountName)</td><td>$($_.UserPrincipalName)</td><td>$($_.Attribute)</td><td>$([System.Net.WebUtility]::HtmlEncode($_.CurrentValue))</td><td>$($_.Description)</td><td>$($_.InSyncScope)</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
<meta charset='utf-8'>
<title>365 AD Fix Tool Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</title>
<style>
  body { font-family: Segoe UI, Arial, sans-serif; margin: 2rem; color: #1a1a1a; }
  h1 { font-size: 1.4rem; }
  table { border-collapse: collapse; width: 100%; font-size: 0.85rem; }
  th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; }
  th { background: #2d2d2d; color: #fff; position: sticky; top: 0; }
  tr.severity-error { background: #fde8e8; }
  tr.severity-warning { background: #fff6e0; }
  tr.severity-info { background: #eef4fb; }
  .summary { margin-bottom: 1rem; }
  .summary span { display: inline-block; margin-right: 1.5rem; font-weight: 600; }
</style>
</head>
<body>
<h1>365 AD Fix Tool Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</h1>
<div class='summary'>
  <span style='color:#b00020'>Errors: $errorCount</span>
  <span style='color:#8a6100'>Warnings: $warningCount</span>
  <span style='color:#0b5394'>Info: $infoCount</span>
  <span>Out of sync scope: $outOfScopeCount</span>
</div>
<table>
<thead><tr><th>Severity</th><th>Rule</th><th>sAMAccountName</th><th>UserPrincipalName</th><th>Attribute</th><th>Current Value</th><th>Description</th><th>In Sync Scope</th></tr></thead>
<tbody>
$($rows -join "`n")
</tbody>
</table>
</body>
</html>
"@

    Set-Content -Path $htmlPath -Value $html -Encoding UTF8

    Write-ADFixLog "CSV report: $csvPath" -Level Info
    Write-ADFixLog "HTML report: $htmlPath" -Level Info

    return [pscustomobject]@{
        CsvPath  = $csvPath
        HtmlPath = $htmlPath
    }
}
