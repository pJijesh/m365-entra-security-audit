BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
}

Describe 'Invoke-SecurityAudit -DemoMode' {
    BeforeAll {
        $script:Out = Join-Path $TestDrive 'demo'
        $script:Audit = Invoke-SecurityAudit -DemoMode -OutputPath $script:Out -Quiet
        $script:Html = Get-Content (Join-Path $script:Out 'm365-entra-audit-report.html') -Raw
    }

    It 'does not need a Graph connection' {
        Mock -ModuleName M365EntraAudit Get-AuditContext { $null }
        { Invoke-SecurityAudit -DemoMode -OutputPath (Join-Path $TestDrive 'noconn') -Quiet } | Should -Not -Throw
        Should -Not -Invoke -ModuleName M365EntraAudit Get-AuditContext
    }
    It 'writes the report, the findings file, the JSON export and one CSV per area' {
        foreach ($f in 'm365-entra-audit-report.html', 'findings.csv', 'conditional-access-policies.json', 'mfa-coverage.csv',
            'stale-accounts.csv', 'privileged-role-holders.csv', 'guest-users.csv', 'conditional-access-policies.csv') {
            Join-Path $script:Out $f | Should -Exist
        }
    }
    It 'produces findings in every area, sorted by severity' {
        $script:Audit.Findings.Area | Select-Object -Unique | Should -HaveCount 5
        $order = @{ High = 0; Medium = 1; Low = 2; Info = 3 }
        $sev = $script:Audit.Findings | ForEach-Object { $order[$_.Severity] }
        $sev | Should -Be ($sev | Sort-Object)
    }
    It 'labels the report as synthetic' {
        $script:Html | Should -Match 'DEMO: synthetic data'
        $script:Html | Should -Match 'northwind\.example'
    }
    It 'is self-contained with no scripts or external requests' {
        $script:Html | Should -Not -Match '<script'
        $script:Html | Should -Not -Match '(src|href)\s*=\s*"https?:'
        $script:Html | Should -Not -Match '@import|url\(https?:'
    }
    It 'has well-formed top-level structure' {
        $script:Html | Should -Match '^<!DOCTYPE html>'
        $script:Html | Should -Match '</html>\s*$'
        ([regex]::Matches($script:Html, '<table')).Count | Should -Be ([regex]::Matches($script:Html, '</table>')).Count
    }
    It 'contains only fictional example domains' {
        $domains = [regex]::Matches($script:Html, '@([a-z0-9.-]+\.[a-z]{2,})') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
        foreach ($d in $domains) { $d | Should -Match '\.example$' }
    }
    It 'is deterministic in what it finds' {
        $again = Invoke-SecurityAudit -DemoMode -OutputPath (Join-Path $TestDrive 'again') -Quiet
        ($again.Findings | ForEach-Object { "$($_.Id):$($_.AffectedCount)" }) | Should -Be ($script:Audit.Findings | ForEach-Object { "$($_.Id):$($_.AffectedCount)" })
    }
}

Describe 'Invoke-SecurityAudit against a tenant (mocked)' {
    It 'stops with guidance when not connected' {
        Mock -ModuleName M365EntraAudit Get-AuditContext { $null }
        { Invoke-SecurityAudit -OutputPath (Join-Path $TestDrive 'x') } | Should -Throw '*Connect-MgGraph*'
    }
    It 'warns about missing scopes but continues' {
        Mock -ModuleName M365EntraAudit Get-AuditContext { [pscustomobject]@{ TenantId = '00000000-0000-0000-0000-000000000000'; Account = 'auditor@northwind.example'; Scopes = @('User.Read.All') } }
        InModuleScope M365EntraAudit { Assert-AuditConnection -WarningVariable w -WarningAction SilentlyContinue | Out-Null; $w | Should -Not -BeNullOrEmpty }
    }
    It 'completes the other areas when one fails, and says so in the report' {
        Mock -ModuleName M365EntraAudit Get-AuditContext { [pscustomobject]@{ TenantId = '00000000-0000-0000-0000-000000000000'; Account = 'auditor@northwind.example'; Scopes = @() } }
        Mock -ModuleName M365EntraAudit Get-AuditMfaRegistration { throw 'Forbidden: AuditLog.Read.All' }
        Mock -ModuleName M365EntraAudit Get-AuditUser { @() }
        Mock -ModuleName M365EntraAudit Get-AuditSubscribedSku { @() }
        Mock -ModuleName M365EntraAudit Get-AuditRoleDefinition { @() }
        Mock -ModuleName M365EntraAudit Get-AuditRoleAssignment { @() }
        Mock -ModuleName M365EntraAudit Get-AuditRoleEligibility { @() }
        Mock -ModuleName M365EntraAudit Get-AuditRoleScheduleInstance { @() }
        Mock -ModuleName M365EntraAudit Get-AuditConditionalAccessPolicy { @() }
        $out = Join-Path $TestDrive 'partial'
        $r = Invoke-SecurityAudit -OutputPath $out -WarningAction SilentlyContinue -Quiet
        $r.Errors.Area | Should -Contain 'MFA'
        $r.Areas.Keys | Should -Not -Contain 'MFA'
        $r.Areas.Keys | Should -Contain 'Conditional Access'
        (Get-Content (Join-Path $out 'm365-entra-audit-report.html') -Raw) | Should -Match 'Not fully assessed'
    }
}

Describe 'Output safety' {
    It 'HTML-encodes directory values' {
        InModuleScope M365EntraAudit {
            $evil = '<script>alert(1)</script>'
            $audit = [pscustomobject]@{
                DemoMode = $false; Tenant = $evil; GeneratedAt = (Get-Date); ToolVersion = '0.0.0'; Errors = @()
                Findings = @((New-AuditFinding -Id 'MFA-002' -AffectedCount 1 -Detail $evil))
                Areas = @{ 'MFA' = [pscustomobject]@{
                        Summary = [pscustomobject]@{ MembersCoveragePercent = 50; Members = 2; MembersWithMfa = 1; UsersInReport = 2; Guests = 0; Administrators = 0; AdministratorsWithoutMfa = 0; MembersWithoutMfa = 1; PhoneOnlyUsers = 0; PasswordlessCapable = 0 }
                        Records = @([pscustomobject]@{ DisplayName = $evil; UserPrincipalName = 'x@northwind.example'; UserType = 'member'; IsAdmin = $false; Status = 'No MFA'; MethodsRegistered = @() })
                    } }
            }
            $path = Join-Path $TestDrive 'evil.html'
            New-AuditHtmlReport -Audit $audit -Path $path | Out-Null
            $html = Get-Content $path -Raw
            $html | Should -Not -Match '<script>alert'
            $html | Should -Match '&lt;script&gt;'
        }
    }
    It 'neutralises spreadsheet formulas in CSV output' {
        InModuleScope M365EntraAudit {
            $rec = [pscustomobject]@{ DisplayName = '=HYPERLINK("http://example.test","x")'; Other = '+1'; Minus = '-cmd'; At = '@SUM(A1)'; Safe = 'Normal'; Count = -5; When = [datetime]'2026-01-02' }
            $safe = $rec | ConvertTo-SafeCsvRecord
            $safe.DisplayName | Should -Be "'=HYPERLINK(""http://example.test"",""x"")"
            $safe.Other | Should -Be "'+1"
            $safe.Minus | Should -Be "'-cmd"
            $safe.At | Should -Be "'@SUM(A1)"
            $safe.Safe | Should -Be 'Normal'
            $safe.Count | Should -Be -5
            $safe.When | Should -Be '2026-01-02 00:00'
        }
    }
    It 'joins array values for CSV' {
        InModuleScope M365EntraAudit {
            ([pscustomobject]@{ M = @('a', 'b') } | ConvertTo-SafeCsvRecord).M | Should -Be 'a; b'
        }
    }
}
