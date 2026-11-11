BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
    $script:GA = '62e90394-69f5-4237-9190-012177145e10'
    function script:Test-Check($Name, $Policy) {
        InModuleScope M365EntraAudit -Parameters @{ N = $Name; P = $Policy } { param($N, $P) & $N $P }
    }
}

Describe 'Conditional Access policy checks' {
    Context 'MFA detection' {
        It 'accepts a lone mfa control' {
            Test-Check Test-CaPolicyRequiresMfa (New-TestCaPolicy -Controls mfa) | Should -BeTrue
        }
        It 'rejects mfa OR compliantDevice because the device alone can satisfy it' {
            Test-Check Test-CaPolicyRequiresMfa (New-TestCaPolicy -Controls mfa, compliantDevice -Operator OR) | Should -BeFalse
        }
        It 'accepts mfa AND compliantDevice' {
            Test-Check Test-CaPolicyRequiresMfa (New-TestCaPolicy -Controls mfa, compliantDevice -Operator AND) | Should -BeTrue
        }
        It 'rejects a block control' {
            Test-Check Test-CaPolicyRequiresMfa (New-TestCaPolicy -Controls block) | Should -BeFalse
        }
    }
    Context 'Administrator MFA' {
        It 'passes for an enforced all-apps policy targeting Global Administrator' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy -IncludeUsers @() -IncludeRoles $script:GA) | Should -BeTrue
        }
        It 'passes for an enforced all-users MFA policy' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy) | Should -BeTrue
        }
        It 'fails when the policy is report-only' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy -State enabledForReportingButNotEnforced) | Should -BeFalse
        }
        It 'fails when the policy only covers one app' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy -Apps @('00000003-0000-0ff1-ce00-000000000000')) | Should -BeFalse
        }
        It 'fails when narrowed by platform' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy -WithPlatforms) | Should -BeFalse
        }
        It 'fails when the policy targets other roles but not Global Administrator' {
            Test-Check Test-CaAdminMfaPolicy (New-TestCaPolicy -IncludeUsers @() -IncludeRoles 'f28a1f50-f6e7-4571-818b-6a12f2af6b6c') | Should -BeFalse
        }
    }
    Context 'Legacy authentication' {
        It 'passes for an enforced block of exchangeActiveSync and other clients' {
            Test-Check Test-CaLegacyBlockPolicy (New-TestCaPolicy -Controls block -ClientAppTypes exchangeActiveSync, other) | Should -BeTrue
        }
        It 'fails when only one legacy client type is covered' {
            Test-Check Test-CaLegacyBlockPolicy (New-TestCaPolicy -Controls block -ClientAppTypes exchangeActiveSync) | Should -BeFalse
        }
        It 'fails when disabled' {
            Test-Check Test-CaLegacyBlockPolicy (New-TestCaPolicy -State disabled -Controls block -ClientAppTypes exchangeActiveSync, other) | Should -BeFalse
        }
    }
    Context 'Risk-based policies' {
        It 'does not count a sign-in-risk policy as MFA for all users' {
            Test-Check Test-CaAllUsersMfaPolicy (New-TestCaPolicy -SignInRisk high, medium) | Should -BeFalse
        }
    }
}

Describe 'Export-ConditionalAccessPolicies' {
    BeforeAll {
        Mock -ModuleName M365EntraAudit Get-AuditConditionalAccessPolicy { $global:AuditTestData.TestPolicies }
    }

    It 'reports every gap when no policies exist' {
        Set-AuditTestData -Name TestPolicies -Value @()
        $r = Export-ConditionalAccessPolicies -NoExport
        $r.Findings.Id | Should -Contain 'CA-001'
        $r.Findings.Id | Should -Contain 'CA-002'
        $r.Findings.Id | Should -Contain 'CA-003'
        ($r.Checks | Where-Object Id -eq 'CA-001').Detail | Should -Match 'Security defaults'
    }
    It 'passes all four checks for a well-formed baseline' {
        Set-AuditTestData -Name TestPolicies -Value @(
            (New-TestCaPolicy -Name 'Block legacy' -Controls block -ClientAppTypes exchangeActiveSync, other)
            (New-TestCaPolicy -Name 'MFA all users')
        )
        $r = Export-ConditionalAccessPolicies -NoExport
        $r.Summary.ChecksPassed | Should -Be 4
        $r.Findings | Should -BeNullOrEmpty
    }
    It 'names report-only policies that would close a gap' {
        Set-AuditTestData -Name TestPolicies -Value @((New-TestCaPolicy -Name 'Pilot MFA' -State enabledForReportingButNotEnforced))
        $r = Export-ConditionalAccessPolicies -NoExport
        ($r.Checks | Where-Object Id -eq 'CA-003').Detail | Should -Match 'Pilot MFA'
        $r.Findings.Id | Should -Contain 'CA-004'
    }
    It 'raises CA-005 when an enforced MFA policy has exclusions' {
        Set-AuditTestData -Name TestPolicies -Value @((New-TestCaPolicy -Name 'MFA with exclusion' -ExcludeGroups ([guid]::NewGuid().ToString())))
        (Export-ConditionalAccessPolicies -NoExport).Findings.Id | Should -Contain 'CA-005'
    }
    It 'writes valid JSON to the output folder' {
        Set-AuditTestData -Name TestPolicies -Value @((New-TestCaPolicy -Name 'MFA all users'), (New-TestCaPolicy -Name 'Second'))
        $r = Export-ConditionalAccessPolicies -OutputPath (Join-Path $TestDrive 'ca')
        Test-Path $r.Summary.JsonPath | Should -BeTrue
        $parsed = Get-Content $r.Summary.JsonPath -Raw | ConvertFrom-Json
        @($parsed).Count | Should -Be 2
        $parsed[0].displayName | Should -Be 'MFA all users'
    }
    It 'writes nothing when -NoExport is used' {
        Set-AuditTestData -Name TestPolicies -Value @()
        $dir = Join-Path $TestDrive 'none'
        Export-ConditionalAccessPolicies -OutputPath $dir -NoExport | Out-Null
        Test-Path $dir | Should -BeFalse
    }
}
