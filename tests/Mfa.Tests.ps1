BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
}

Describe 'Get-MfaCoverage' {
    BeforeAll {
        Mock -ModuleName M365EntraAudit Get-AuditMfaRegistration { $global:AuditTestData.TestRegistrations }
        $regs = @(
            (New-TestRegistration -Upn 'a@northwind.example' -Methods 'microsoftAuthenticatorPush', 'softwareOneTimePasscode')
            (New-TestRegistration -Upn 'b@northwind.example' -Methods 'fido2SecurityKey')
            (New-TestRegistration -Upn 'c@northwind.example' -Registered $false -Methods @())
            (New-TestRegistration -Upn 'd@northwind.example' -Methods 'mobilePhone')
            (New-TestRegistration -Upn 'e@northwind.example' -Registered $false -Methods 'email')
            (New-TestRegistration -Upn 'admin1@northwind.example' -IsAdmin $true -Registered $false -Methods @())
            (New-TestRegistration -Upn 'admin2@northwind.example' -IsAdmin $true -Methods 'microsoftAuthenticatorPush')
            (New-TestRegistration -Upn 'g@fabrikam.example' -UserType 'guest' -Registered $false -Methods @())
        )
        Set-AuditTestData -Name TestRegistrations -Value $regs
        $script:Result = Get-MfaCoverage
    }

    It 'counts members and guests separately' {
        $script:Result.Summary.Members | Should -Be 7
        $script:Result.Summary.Guests | Should -Be 1
    }
    It 'calculates member coverage' {
        # 4 of 7 members have MFA registered: a, b, d, admin2.
        $script:Result.Summary.MembersWithMfa | Should -Be 4
        $script:Result.Summary.MembersCoveragePercent | Should -Be 57.1
    }
    It 'flags administrators without MFA as a High finding' {
        $f = $script:Result.Findings | Where-Object Id -eq 'MFA-001'
        $f.Severity | Should -Be 'High'
        $f.AffectedCount | Should -Be 1
        $f.Detail | Should -Match 'admin1@northwind.example'
    }
    It 'does not double count administrators in the member finding' {
        ($script:Result.Findings | Where-Object Id -eq 'MFA-002').AffectedCount | Should -Be 2
    }
    It 'treats email as not being a second factor' {
        ($script:Result.Records | Where-Object UserPrincipalName -eq 'e@northwind.example').Status | Should -Be 'No MFA'
    }
    It 'identifies phone-only users' {
        ($script:Result.Records | Where-Object UserPrincipalName -eq 'd@northwind.example').Status | Should -Be 'Phone only'
        ($script:Result.Findings | Where-Object Id -eq 'MFA-003').AffectedCount | Should -Be 1
    }
    It 'raises no findings when everyone is covered' {
        Set-AuditTestData -Name TestRegistrations -Value @((New-TestRegistration -Methods 'microsoftAuthenticatorPush'))
        $r = Get-MfaCoverage
        $r.Findings | Should -BeNullOrEmpty
        $r.Summary.MembersCoveragePercent | Should -Be 100
    }
    It 'handles an empty tenant without dividing by zero' {
        Set-AuditTestData -Name TestRegistrations -Value @()
        (Get-MfaCoverage).Summary.MembersCoveragePercent | Should -Be 0
    }
}
