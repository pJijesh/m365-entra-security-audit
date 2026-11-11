BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
    $script:AsOf = [datetime]'2026-06-01'
}

Describe 'Get-GuestUsers' {
    BeforeAll {
        Mock -ModuleName M365EntraAudit Get-AuditUser { $global:AuditTestData.TestUsers }
        $a = $script:AsOf
        $users = @(
            (New-TestUser -Name 'Member' -Upn 'member@northwind.example')
            (New-TestUser -Name 'Active' -Upn 'active_fabrikam.example#EXT#@northwind.example' -UserType Guest -Created $a.AddDays(-400) -LastSignIn $a.AddDays(-10) -State Accepted)
            (New-TestUser -Name 'Stale' -Upn 'stale_fabrikam.example#EXT#@northwind.example' -UserType Guest -Created $a.AddDays(-400) -LastSignIn $a.AddDays(-200) -State Accepted)
            (New-TestUser -Name 'NoSignIn' -Upn 'nosignin_tailspin.example#EXT#@northwind.example' -UserType Guest -Created $a.AddDays(-300) -LastSignIn $null -State Accepted)
            (New-TestUser -Name 'PendingOld' -Upn 'old_adatum.example#EXT#@northwind.example' -UserType Guest -Created $a.AddDays(-100) -State PendingAcceptance -StateChange $a.AddDays(-100))
            (New-TestUser -Name 'PendingNew' -Upn 'new_adatum.example#EXT#@northwind.example' -UserType Guest -Created $a.AddDays(-3) -State PendingAcceptance -StateChange $a.AddDays(-3))
            (New-TestUser -Name 'DisabledGuest' -Upn 'dis_litware.example#EXT#@northwind.example' -UserType Guest -Enabled $false -Created $a.AddDays(-400) -LastSignIn $a.AddDays(-300))
        )
        # Mail is blank for these, so the source domain must come from the #EXT# user principal name.
        foreach ($u in $users) { $u.Mail = '' }
        Set-AuditTestData -Name TestUsers -Value $users
        $script:Result = Get-GuestUsers -AsOf $a
        $script:ByName = @{}
        foreach ($r in $script:Result.Records) { $script:ByName[$r.DisplayName] = $r }
    }

    It 'only includes guests' {
        $script:Result.Summary.TotalGuests | Should -Be 6
        $script:ByName.ContainsKey('Member') | Should -BeFalse
    }
    It 'classifies each guest' {
        $script:ByName['Active'].Status | Should -Be 'Active'
        $script:ByName['Stale'].Status | Should -Be 'Stale'
        $script:ByName['NoSignIn'].Status | Should -Be 'No sign-in recorded'
        $script:ByName['PendingOld'].Status | Should -Be 'Pending invitation (overdue)'
        $script:ByName['PendingNew'].Status | Should -Be 'Pending invitation'
        $script:ByName['DisabledGuest'].Status | Should -Be 'Disabled'
    }
    It 'derives the source domain from the #EXT# user principal name' {
        $script:ByName['Stale'].SourceDomain | Should -Be 'fabrikam.example'
    }
    It 'calculates age and days since sign-in' {
        $script:ByName['Stale'].AgeDays | Should -Be 400
        $script:ByName['Stale'].DaysSinceSignIn | Should -Be 200
    }
    It 'raises findings with the right counts' {
        ($script:Result.Findings | Where-Object Id -eq 'GUEST-001').AffectedCount | Should -Be 2
        ($script:Result.Findings | Where-Object Id -eq 'GUEST-002').AffectedCount | Should -Be 1
    }
    It 'summarises pending invitations' {
        $script:Result.Summary.PendingInvitations | Should -Be 2
        $script:Result.Summary.PendingOverdue | Should -Be 1
    }
    It 'respects a custom pending-invitation window' {
        $r = Get-GuestUsers -AsOf $script:AsOf -PendingInvitationDays 1
        $r.Summary.PendingOverdue | Should -Be 2
    }
}
