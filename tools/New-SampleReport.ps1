<#
.SYNOPSIS
    Regenerates docs/sample-report.html and docs/sample-report.png from DemoMode (synthetic data).
.DESCRIPTION
    Run from the repository root with PowerShell 7. The screenshot step needs Python with Playwright
    (pip install playwright; playwright install chromium). Skip it with -SkipScreenshot.
#>
[CmdletBinding()]
param([switch]$SkipScreenshot)

$root = Split-Path -Parent $PSScriptRoot
Import-Module (Join-Path $root 'src' 'M365EntraAudit' 'M365EntraAudit.psd1') -Force

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('m365-sample-' + [guid]::NewGuid().ToString('N'))
try {
    $result = Invoke-SecurityAudit -DemoMode -OutputPath $tmp -ReportFileName 'sample-report.html' -Quiet
    Copy-Item -LiteralPath $result.ReportPath -Destination (Join-Path $root 'docs' 'sample-report.html') -Force
    Write-Output "Wrote docs/sample-report.html"
}
finally {
    if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Recurse -Force }
}

if (-not $SkipScreenshot) {
    python3 (Join-Path $root 'tools' 'capture_screenshot.py')
}
