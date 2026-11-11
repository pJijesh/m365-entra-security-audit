function Invoke-SecurityAudit {
    <#
    .SYNOPSIS
        Runs every audit area and writes an HTML report plus CSV files.
    .DESCRIPTION
        Runs Get-MfaCoverage, Get-StaleAccounts, Get-PrivilegedRoleHolders, Get-GuestUsers and
        Export-ConditionalAccessPolicies, then writes one self-contained HTML report, one CSV per area, a
        findings CSV and the Conditional Access JSON export into OutputPath. If one area fails (for example
        a missing permission), the others still run and the report says which area was not assessed.
        Read-only: nothing is changed in the tenant. Output stays on the local machine.
    .PARAMETER OutputPath
        Folder for the output files. Created if missing. Default: .\audit-output
    .PARAMETER DemoMode
        Use synthetic data (fictional organisation northwind.example) instead of connecting to a tenant.
    .PARAMETER InactiveDays
        Days without sign-in before an enabled member account is reported. Default 90.
    .PARAMETER GuestStaleDays
        Days without sign-in before a guest account is reported. Default 90.
    .PARAMETER PendingInvitationDays
        Days before an unaccepted guest invitation is reported. Default 30.
    .PARAMETER MaxPermanentGlobalAdmins
        Permanent Global Administrators allowed before a finding is raised. Default 4.
    .PARAMETER EmergencyAccount
        User principal names of break-glass accounts. They are excluded from stale-account and
        privileged-count thresholds.
    .PARAMETER ReportFileName
        Name of the HTML file. Default: m365-entra-audit-report.html
    .PARAMETER Quiet
        Do not print the console summary. The result object is still returned.
    .PARAMETER MaxRowsInReport
        Maximum rows per table in the HTML report. CSV files always contain every row.
    .EXAMPLE
        Connect-MgGraph -Scopes (Get-AuditRequiredScope)
        Invoke-SecurityAudit -EmergencyAccount 'breakglass1@contoso.example','breakglass2@contoso.example'
    .EXAMPLE
        Invoke-SecurityAudit -DemoMode -OutputPath .\demo-output
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OutputPath = (Join-Path (Get-Location) 'audit-output'),
        [switch]$DemoMode,
        [ValidateRange(1, 3650)][int]$InactiveDays = 90,
        [ValidateRange(1, 3650)][int]$GuestStaleDays = 90,
        [ValidateRange(1, 3650)][int]$PendingInvitationDays = 30,
        [ValidateRange(1, 100)][int]$MaxPermanentGlobalAdmins = 4,
        [string[]]$EmergencyAccount = @(),
        [string]$ReportFileName = 'm365-entra-audit-report.html',
        [ValidateRange(5, 1000)][int]$MaxRowsInReport = 40,
        [switch]$Quiet
    )

    $started = Get-Date
    $tenant = 'Northwind Traders (synthetic demo data)'
    if ($DemoMode) {
        if (-not $PSBoundParameters.ContainsKey('EmergencyAccount')) { $EmergencyAccount = (Get-AuditDemoDataset).EmergencyAccounts }
    }
    else {
        $context = Assert-AuditConnection
        $tenant = "$($context.TenantId)$(if ($context.Account) { ' (' + $context.Account + ')' })"
    }

    if (-not (Test-Path -LiteralPath $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
    $out = (Resolve-Path -LiteralPath $OutputPath).Path

    $errors = New-Object System.Collections.Generic.List[object]
    $areas = [ordered]@{}
    $runArea = {
        param([string]$Name, [scriptblock]$Script)
        Write-Verbose "Running: $Name"
        try { $areas[$Name] = & $Script }
        catch {
            $errors.Add([pscustomobject]@{ Area = $Name; Message = $_.Exception.Message })
            Write-Warning "$Name could not be assessed: $($_.Exception.Message)"
        }
    }

    & $runArea 'MFA' { Get-MfaCoverage -DemoMode:$DemoMode }
    & $runArea 'Stale accounts' { Get-StaleAccounts -InactiveDays $InactiveDays -ExcludeUserPrincipalName $EmergencyAccount -AsOf $started -DemoMode:$DemoMode }
    & $runArea 'Privileged roles' { Get-PrivilegedRoleHolders -MaxPermanentGlobalAdmins $MaxPermanentGlobalAdmins -EmergencyAccount $EmergencyAccount -DemoMode:$DemoMode }
    & $runArea 'Guest users' { Get-GuestUsers -StaleDays $GuestStaleDays -PendingInvitationDays $PendingInvitationDays -AsOf $started -DemoMode:$DemoMode }
    & $runArea 'Conditional Access' { Export-ConditionalAccessPolicies -OutputPath $out -DemoMode:$DemoMode }

    $findings = @($areas.Values | ForEach-Object { $_.Findings } | Where-Object { $_ } |
            Sort-Object @{ Expression = { $script:SeverityOrder[$_.Severity] } }, Id)

    $audit = [pscustomobject]@{
        PSTypeName  = 'M365EntraAudit.AuditResult'
        DemoMode    = [bool]$DemoMode
        Tenant      = $tenant
        GeneratedAt = $started
        ToolVersion = (Get-Module M365EntraAudit).Version.ToString()
        Areas       = $areas
        Findings    = $findings
        FindingCounts = [pscustomobject]@{
            High   = @($findings | Where-Object Severity -eq 'High').Count
            Medium = @($findings | Where-Object Severity -eq 'Medium').Count
            Low    = @($findings | Where-Object Severity -eq 'Low').Count
            Info   = @($findings | Where-Object Severity -eq 'Info').Count
        }
        Errors      = $errors.ToArray()
    }

    $files = [ordered]@{}
    $csvMap = [ordered]@{
        'MFA'                = 'mfa-coverage.csv'
        'Stale accounts'     = 'stale-accounts.csv'
        'Privileged roles'   = 'privileged-role-holders.csv'
        'Guest users'        = 'guest-users.csv'
        'Conditional Access' = 'conditional-access-policies.csv'
    }
    foreach ($name in $csvMap.Keys) {
        if ($areas.Contains($name)) {
            $p = Join-Path $out $csvMap[$name]
            Export-AuditCsv -Path $p -Record @($areas[$name].Records | ForEach-Object { $_ | Select-Object * -ExcludeProperty PrincipalId, RoleDefinitionId })
            $files[$name] = $p
        }
    }
    $findingsCsv = Join-Path $out 'findings.csv'
    Export-AuditCsv -Path $findingsCsv -Record @($findings | Select-Object Id, Severity, Area, Title, AffectedCount, Detail, Remediation)
    $files['Findings'] = $findingsCsv
    if ($areas.Contains('Conditional Access') -and $areas['Conditional Access'].Summary.JsonPath) {
        $files['Conditional Access JSON'] = $areas['Conditional Access'].Summary.JsonPath
    }

    $reportPath = Join-Path $out $ReportFileName
    $null = New-AuditHtmlReport -Audit $audit -Path $reportPath -MaxRows $MaxRowsInReport
    $files['Report'] = $reportPath

    $audit | Add-Member -NotePropertyName Files -NotePropertyValue $files
    $audit | Add-Member -NotePropertyName OutputPath -NotePropertyValue $out
    $audit | Add-Member -NotePropertyName ReportPath -NotePropertyValue $reportPath

    if (-not $Quiet) {
        $c = $audit.FindingCounts
        $lines = @(
            "M365EntraAudit $($audit.ToolVersion) | $tenant"
            "Findings: $($c.High) High, $($c.Medium) Medium, $($c.Low) Low, $($c.Info) Info"
        )
        foreach ($f in $findings) { $lines += ('  [{0,-6}] {1,-9} {2}' -f $f.Severity, $f.Id, $f.Title) }
        foreach ($err in $errors) { $lines += "  Not assessed: $($err.Area) ($($err.Message))" }
        $lines += "Report: $reportPath"
        foreach ($line in $lines) { Write-Information $line -InformationAction Continue }
    }
    return $audit
}
