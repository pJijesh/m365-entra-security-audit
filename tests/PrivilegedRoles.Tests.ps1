BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
    $script:GA = '62e90394-69f5-4237-9190-012177145e10'
    $script:Helpdesk = '729827e3-9c14-49f7-bb1b-9608f156bbb8'
    $script:Exchange = '29232cdf-9323-42fd-ade2-1d097af3e4de'
}

Describe 'Get-PrivilegedRoleHolders' {
    BeforeAll {
        Mock -ModuleName M365EntraAudit Get-AuditRoleDefinition { @() }
        Mock -ModuleName M365EntraAudit Get-AuditRoleAssignment { $global:AuditTestData.TestAssignments }
        Mock -ModuleName M365EntraAudit Get-AuditRoleEligibility { $global:AuditTestData.TestEligibility }
        Mock -ModuleName M365EntraAudit Get-AuditRoleScheduleInstance { $global:AuditTestData.TestSchedules }
        Mock -ModuleName M365EntraAudit Get-AuditGroupMember { $global:AuditTestData.TestGroupMembers }

        # Permanent GAs: five named users plus one emergency account.
        $gaUsers = 1..5 | ForEach-Object { New-TestPrincipal -Name "GA $_" -Upn "ga$_@northwind.example" }
        $emergency = New-TestPrincipal -Name 'Emergency' -Upn 'emergency@northwind.example'
        $eligibleUser = New-TestPrincipal -Name 'Eligible GA' -Upn 'eligible@northwind.example'
        $activated = New-TestPrincipal -Name 'Activated' -Upn 'activated@northwind.example'
        $timeBound = New-TestPrincipal -Name 'Timebound' -Upn 'timebound@northwind.example'
        $guest = New-TestPrincipal -Name 'Guest Admin' -Upn 'guest_fabrikam.example#EXT#@northwind.example' -UserType 'Guest'
        $leaver = New-TestPrincipal -Name 'Leaver' -Upn 'leaver@northwind.example' -Enabled $false
        $group = New-TestPrincipal -Type group -Name 'Ops Admins' -Upn ''
        $app = New-TestPrincipal -Type servicePrincipal -Name 'automation-app' -Upn ''
        $member = New-TestPrincipal -Name 'Group Member' -Upn 'member@northwind.example'

        $assign = @()
        foreach ($u in $gaUsers) { $assign += New-TestRoleAssignment -Principal $u -RoleId $script:GA }
        $assign += New-TestRoleAssignment -Principal $emergency -RoleId $script:GA
        $assign += New-TestRoleAssignment -Principal $activated -RoleId $script:GA
        $assign += New-TestRoleAssignment -Principal $timeBound -RoleId $script:Helpdesk
        $assign += New-TestRoleAssignment -Principal $guest -RoleId $script:Helpdesk
        $assign += New-TestRoleAssignment -Principal $leaver -RoleId $script:Helpdesk
        $assign += New-TestRoleAssignment -Principal $group -RoleId $script:Exchange
        $assign += New-TestRoleAssignment -Principal $app -RoleId $script:Exchange
        Set-AuditTestData -Name TestAssignments -Value $assign
        Set-AuditTestData -Name TestEligibility -Value @((New-TestRoleAssignment -Principal $eligibleUser -RoleId $script:GA -End ([datetime]'2027-01-01')))
        Set-AuditTestData -Name TestSchedules -Value @(
            [pscustomobject]@{ PrincipalId = $activated.PrincipalId; RoleDefinitionId = $script:GA; AssignmentType = 'Activated'; EndDateTime = [datetime]'2026-06-01' }
            [pscustomobject]@{ PrincipalId = $timeBound.PrincipalId; RoleDefinitionId = $script:Helpdesk; AssignmentType = 'Assigned'; EndDateTime = [datetime]'2026-12-31' }
        )
        Set-AuditTestData -Name TestGroupMembers -Value @($member)
        $script:Result = Get-PrivilegedRoleHolders -EmergencyAccount 'EMERGENCY@northwind.example'
        $script:Records = $script:Result.Records
    }

    It 'classifies permanent, activated, time-bound and eligible holders' {
        ($script:Records | Where-Object DisplayName -eq 'GA 1').AssignmentType | Should -Be 'Permanent'
        ($script:Records | Where-Object DisplayName -eq 'Activated').AssignmentType | Should -Be 'Active (PIM activation)'
        ($script:Records | Where-Object DisplayName -eq 'Timebound').AssignmentType | Should -Be 'Time-bound'
        ($script:Records | Where-Object DisplayName -eq 'Eligible GA').AssignmentType | Should -Be 'Eligible'
    }
    It 'expands group-based assignments and records the group' {
        $m = $script:Records | Where-Object DisplayName -eq 'Group Member'
        $m.ViaGroup | Should -Be 'Ops Admins'
        $m.Role | Should -Be 'Exchange Administrator'
    }
    It 'matches emergency accounts case-insensitively and flags them' {
        ($script:Records | Where-Object DisplayName -eq 'Emergency').IsEmergencyAccount | Should -BeTrue
    }
    It 'excludes emergency accounts from the permanent Global Administrator count' {
        $script:Result.Summary.GlobalAdministratorsPermanent | Should -Be 5
    }
    It 'raises PRIV-001 above the threshold and not at it' {
        ($script:Result.Findings | Where-Object Id -eq 'PRIV-001').AffectedCount | Should -Be 5
        (Get-PrivilegedRoleHolders -EmergencyAccount 'emergency@northwind.example' -MaxPermanentGlobalAdmins 5).Findings.Id | Should -Not -Contain 'PRIV-001'
    }
    It 'raises PRIV-003 for standing privilege when PIM is available' {
        $script:Result.Summary.PimAvailable | Should -BeTrue
        $script:Result.Findings.Id | Should -Contain 'PRIV-003'
    }
    It 'flags guests, disabled accounts, groups and applications' {
        $script:Result.Findings.Id | Should -Contain 'PRIV-005'
        $script:Result.Findings.Id | Should -Contain 'PRIV-006'
        $script:Result.Findings.Id | Should -Contain 'PRIV-007'
        $script:Result.Findings.Id | Should -Contain 'PRIV-008'
    }
    It 'counts eligible-only Global Administrators' {
        $script:Result.Summary.GlobalAdministratorsEligibleOnly | Should -Be 1
    }
    It 'degrades gracefully and raises PRIV-004 when PIM data is unavailable' {
        Mock -ModuleName M365EntraAudit Get-AuditRoleEligibility { throw 'Forbidden' }
        $r = Get-PrivilegedRoleHolders
        $r.Summary.PimAvailable | Should -BeFalse
        $r.Findings.Id | Should -Contain 'PRIV-004'
        $r.Findings.Id | Should -Not -Contain 'PRIV-003'
        $r.Records | Should -Not -BeNullOrEmpty
    }
    It 'raises PRIV-002 when fewer than two Global Administrators exist' {
        Set-AuditTestData -Name TestAssignments -Value @((New-TestRoleAssignment -Principal (New-TestPrincipal) -RoleId $script:GA))
        Set-AuditTestData -Name TestEligibility -Value @()
        Set-AuditTestData -Name TestSchedules -Value @()
        (Get-PrivilegedRoleHolders).Findings.Id | Should -Contain 'PRIV-002'
    }
}
