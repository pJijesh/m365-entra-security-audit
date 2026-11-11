function Get-PrivilegedRoleHolders {
    <#
    .SYNOPSIS
        Lists who holds Microsoft Entra directory roles, and how the role is held.
    .DESCRIPTION
        Combines active role assignments, PIM eligibility and PIM assignment schedules. Each record says
        whether the holder has the role permanently, time-bound, through a PIM activation, as eligible
        only, or through a group (group members are expanded). PIM data needs Entra ID P2 or Governance;
        when it is unavailable the function continues and raises finding PRIV-004. Read-only.
    .PARAMETER MaxPermanentGlobalAdmins
        Permanent Global Administrators allowed before PRIV-001 is raised (Microsoft guidance suggests
        fewer than five). Default 4, so five or more are reported.
    .PARAMETER EmergencyAccount
        User principal names of emergency (break-glass) accounts. They are listed, but not counted against
        the permanent Global Administrator and standing-privilege thresholds.
    .PARAMETER DemoMode
        Use synthetic data instead of connecting to a tenant.
    .NOTES
        Required scopes: RoleManagement.Read.Directory, GroupMember.Read.All, User.Read.All (see docs/permissions.md).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateRange(1, 100)][int]$MaxPermanentGlobalAdmins = 4,
        [string[]]$EmergencyAccount = @(),
        [switch]$DemoMode
    )

    $emergency = @($EmergencyAccount | ForEach-Object { $_.ToLowerInvariant() })
    $pimAvailable = $true
    $scheduleKnown = $true

    if ($DemoMode) {
        $demo = Get-AuditDemoDataset
        $definitions = $demo.RoleDefinitions
        $assignments = $demo.RoleAssignments
        $eligibility = $demo.RoleEligibility
        $schedules = $demo.ScheduleInstances
        $demoGroupMembers = $demo.GroupMembers
    }
    else {
        $definitions = @(Get-AuditRoleDefinition)
        $assignments = @(Get-AuditRoleAssignment)
        $eligibility = @()
        $schedules = @()
        try { $eligibility = @(Get-AuditRoleEligibility) }
        catch { $pimAvailable = $false; Write-Verbose "PIM eligibility unavailable: $($_.Exception.Message)" }
        try { $schedules = @(Get-AuditRoleScheduleInstance) }
        catch { $scheduleKnown = $false; $pimAvailable = $false; Write-Verbose "Role schedules unavailable: $($_.Exception.Message)" }
        $demoGroupMembers = $null
    }

    $roleName = @{}
    foreach ($d in @($definitions)) { $roleName[$d.Id] = $d.DisplayName }
    foreach ($id in $script:HighPrivilegeRoles.Keys) { if (-not $roleName.ContainsKey($id)) { $roleName[$id] = $script:HighPrivilegeRoles[$id] } }

    $groupCache = @{}
    $getMembers = {
        param([string]$GroupId)
        if (-not $groupCache.ContainsKey($GroupId)) {
            $groupCache[$GroupId] = if ($DemoMode) { @($demoGroupMembers[$GroupId]) }
            else { try { @(Get-AuditGroupMember -GroupId $GroupId) } catch { Write-Warning "Could not expand group ${GroupId}: $($_.Exception.Message)"; @() } }
        }
        return , $groupCache[$GroupId]
    }

    $newRecord = {
        param($Role, $Principal, [string]$Type, [string]$Via, $Scope, $Expires)
        $upn = [string]$Principal.PrincipalUpn
        $isGuest = ($Principal.PrincipalUserType -eq 'Guest') -or ($upn -match '#EXT#')
        [pscustomobject]@{
            PSTypeName         = 'M365EntraAudit.RoleHolderRecord'
            Role               = $roleName[$Role]
            IsHighPrivilege    = $script:HighPrivilegeRoles.Contains($Role)
            PrincipalType      = $Principal.PrincipalType
            DisplayName        = $Principal.PrincipalDisplayName
            UserPrincipalName  = $upn
            IsGuest            = [bool]$isGuest
            AccountEnabled     = $Principal.PrincipalAccountEnabled
            AssignmentType     = $Type
            ViaGroup           = $Via
            Scope              = $(if ($Scope -and $Scope -ne '/') { $Scope } else { 'Tenant' })
            Expires            = $Expires
            IsEmergencyAccount = [bool]($upn -and $upn.ToLowerInvariant() -in $emergency)
            PrincipalId        = $Principal.PrincipalId
            RoleDefinitionId   = $Role
        }
    }

    $records = New-Object System.Collections.Generic.List[object]

    foreach ($a in @($assignments)) {
        $type = 'Permanent'
        $expires = $null
        if (-not $scheduleKnown) {
            $type = 'Active (permanence unknown)'
        }
        else {
            $match = @($schedules | Where-Object { $_.PrincipalId -eq $a.PrincipalId -and $_.RoleDefinitionId -eq $a.RoleDefinitionId }) | Select-Object -First 1
            if ($match -and $match.AssignmentType -eq 'Activated') { $type = 'Active (PIM activation)'; $expires = $match.EndDateTime }
            elseif ($match -and $match.AssignmentType -eq 'Assigned' -and $match.EndDateTime) { $type = 'Time-bound'; $expires = $match.EndDateTime }
        }
        $records.Add((& $newRecord $a.RoleDefinitionId $a $type '' $a.DirectoryScopeId $expires))
        if ($a.PrincipalType -eq 'group') {
            foreach ($m in (& $getMembers $a.PrincipalId)) {
                $records.Add((& $newRecord $a.RoleDefinitionId $m $type $a.PrincipalDisplayName $a.DirectoryScopeId $expires))
            }
        }
    }

    foreach ($e in @($eligibility)) {
        $records.Add((& $newRecord $e.RoleDefinitionId $e 'Eligible' '' $e.DirectoryScopeId $e.EndDateTime))
        if ($e.PrincipalType -eq 'group') {
            foreach ($m in (& $getMembers $e.PrincipalId)) {
                $records.Add((& $newRecord $e.RoleDefinitionId $m 'Eligible' $e.PrincipalDisplayName $e.DirectoryScopeId $e.EndDateTime))
            }
        }
    }

    $all = @($records | Sort-Object @{ Expression = { -not $_.IsHighPrivilege } }, Role, AssignmentType, DisplayName)
    $users = @($all | Where-Object { $_.PrincipalType -eq 'user' })
    $high = @($all | Where-Object { $_.IsHighPrivilege })
    $gaRole = $script:GlobalAdministratorRoleId

    $isCounted = { param($r) -not $r.IsEmergencyAccount }
    $gaPermanentUsers = @($users | Where-Object { $_.RoleDefinitionId -eq $gaRole -and $_.AssignmentType -eq 'Permanent' } | Where-Object { & $isCounted $_ } | Select-Object -ExpandProperty PrincipalId -Unique)
    $gaAnyUsers = @($users | Where-Object { $_.RoleDefinitionId -eq $gaRole } | Select-Object -ExpandProperty PrincipalId -Unique)
    $gaEligibleOnly = @($gaAnyUsers | Where-Object { $id = $_; -not (@($users | Where-Object { $_.PrincipalId -eq $id -and $_.RoleDefinitionId -eq $gaRole -and $_.AssignmentType -ne 'Eligible' })) })
    $standing = @($users | Where-Object { $_.IsHighPrivilege -and $_.AssignmentType -eq 'Permanent' } | Where-Object { & $isCounted $_ } | Select-Object -ExpandProperty PrincipalId -Unique)
    $groupHolders = @($all | Where-Object { $_.PrincipalType -eq 'group' } | Select-Object -ExpandProperty PrincipalId -Unique)
    $spHolders = @($all | Where-Object { $_.PrincipalType -eq 'servicePrincipal' } | Select-Object -ExpandProperty PrincipalId -Unique)
    $guestHolders = @($users | Where-Object { $_.IsGuest } | Select-Object -ExpandProperty PrincipalId -Unique)
    $disabledHolders = @($users | Where-Object { $_.AccountEnabled -eq $false -and $_.AssignmentType -ne 'Eligible' } | Select-Object -ExpandProperty PrincipalId -Unique)

    $summary = [pscustomobject]@{
        PimAvailable                  = $pimAvailable
        RoleAssignmentRecords         = $all.Count
        HighPrivilegeRecords          = $high.Count
        DistinctUsersWithAnyRole      = @($users | Select-Object -ExpandProperty PrincipalId -Unique).Count
        GlobalAdministratorsTotal     = $gaAnyUsers.Count
        GlobalAdministratorsPermanent = $gaPermanentUsers.Count
        GlobalAdministratorsEligibleOnly = $gaEligibleOnly.Count
        EmergencyAccountsListed       = @($users | Where-Object IsEmergencyAccount | Select-Object -ExpandProperty PrincipalId -Unique).Count
        UsersWithStandingHighPrivilege = $standing.Count
        GroupsHoldingRoles            = $groupHolders.Count
        ServicePrincipalsHoldingRoles = $spHolders.Count
        GuestsHoldingRoles            = $guestHolders.Count
        DisabledAccountsHoldingRoles  = $disabledHolders.Count
        MaxPermanentGlobalAdminsAllowed = $MaxPermanentGlobalAdmins
    }

    $findings = New-Object System.Collections.Generic.List[object]
    if ($gaPermanentUsers.Count -gt $MaxPermanentGlobalAdmins) {
        $findings.Add((New-AuditFinding -Id 'PRIV-001' -AffectedCount $gaPermanentUsers.Count -Detail "$($gaPermanentUsers.Count) permanent Global Administrators, excluding emergency accounts. Threshold: more than $MaxPermanentGlobalAdmins."))
    }
    if ($gaAnyUsers.Count -lt 2) {
        $findings.Add((New-AuditFinding -Id 'PRIV-002' -AffectedCount $gaAnyUsers.Count -Detail "Found $($gaAnyUsers.Count) Global Administrator user(s)."))
    }
    if (-not $pimAvailable) {
        $findings.Add((New-AuditFinding -Id 'PRIV-004' -AffectedCount 0 -Detail 'PIM eligibility or schedule calls failed or returned nothing usable.'))
    }
    elseif ($standing.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'PRIV-003' -AffectedCount $standing.Count -Detail "$($standing.Count) user(s) hold at least one high-privilege role permanently (emergency accounts excluded)."))
    }
    if ($groupHolders.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'PRIV-005' -AffectedCount $groupHolders.Count -Detail "Groups holding roles: $((@($all | Where-Object { $_.PrincipalType -eq 'group' } | Select-Object -ExpandProperty DisplayName -Unique)) -join ', ')."))
    }
    if ($spHolders.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'PRIV-006' -AffectedCount $spHolders.Count -Detail "Applications holding roles: $((@($all | Where-Object { $_.PrincipalType -eq 'servicePrincipal' } | Select-Object -ExpandProperty DisplayName -Unique)) -join ', ')."))
    }
    if ($guestHolders.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'PRIV-007' -AffectedCount $guestHolders.Count -Detail "Guest account(s) with a directory role: $((@($users | Where-Object IsGuest | Select-Object -ExpandProperty DisplayName -Unique)) -join ', ')."))
    }
    if ($disabledHolders.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'PRIV-008' -AffectedCount $disabledHolders.Count -Detail "Disabled account(s) with an assignment: $((@($users | Where-Object { $_.AccountEnabled -eq $false -and $_.AssignmentType -ne 'Eligible' } | Select-Object -ExpandProperty DisplayName -Unique)) -join ', ')."))
    }

    [pscustomobject]@{
        PSTypeName = 'M365EntraAudit.PrivilegedRoleResult'
        Area       = 'Privileged roles'
        Summary    = $summary
        Findings   = $findings.ToArray()
        Records    = $all
    }
}
