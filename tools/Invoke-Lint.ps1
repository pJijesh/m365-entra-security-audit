<#
.SYNOPSIS
    Runs PSScriptAnalyzer over the repository with the settings in PSScriptAnalyzerSettings.psd1.
.DESCRIPTION
    The module and tools are checked with every rule in the settings file. The tests share fixtures
    through one global variable, because Pester mock bodies run in a different scope, and their helper
    functions use the verb New-, so two rules (PSAvoidGlobalVars and PSUseShouldProcessForStateChangingFunctions)
    are excluded for tests only. Exits with code 1 if anything is reported.
#>
[CmdletBinding()]
param()

$root = Split-Path -Parent $PSScriptRoot
$settings = Join-Path $root 'PSScriptAnalyzerSettings.psd1'

$results = @()
$results += Invoke-ScriptAnalyzer -Path (Join-Path $root 'src') -Recurse -Settings $settings
$results += Invoke-ScriptAnalyzer -Path (Join-Path $root 'tools') -Recurse -Settings $settings
$results += Invoke-ScriptAnalyzer -Path (Join-Path $root 'tests') -Recurse -Settings $settings `
    -ExcludeRule 'PSAvoidGlobalVars', 'PSUseShouldProcessForStateChangingFunctions'

if ($results.Count -gt 0) {
    $results | ForEach-Object { '{0} [{1}] {2}:{3} {4}' -f $_.RuleName, $_.Severity, $_.ScriptName, $_.Line, $_.Message }
    exit 1
}
Write-Output 'PSScriptAnalyzer: no findings.'
