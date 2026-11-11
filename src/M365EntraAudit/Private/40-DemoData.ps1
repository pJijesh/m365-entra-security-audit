# Synthetic dataset for -DemoMode. Everything here is invented: the organisation is a fictional
# "Northwind Traders" using the reserved example domains (RFC 2606), people are generated from name
# lists, and GUIDs are random. No real tenant, user or organisation is represented.

function New-DemoGuid {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds an in-memory GUID only.')]
    [CmdletBinding()]
    param([System.Random]$Random)
    $bytes = New-Object byte[] 16
    $Random.NextBytes($bytes)
    return ([guid]::new($bytes)).ToString()
}

function Get-AuditDemoDataset {
    [CmdletBinding()]
    param([datetime]$AsOf = (Get-Date))

    $rng = [System.Random]::new(20260401)
    $domain = 'northwind.example'

    $first = @('Amara', 'Beatriz', 'Callum', 'Dewi', 'Elif', 'Farid', 'Grace', 'Hiro', 'Ingrid', 'Jamal',
        'Keira', 'Liam', 'Mei', 'Nadia', 'Oskar', 'Priya', 'Quinn', 'Rosa', 'Sven', 'Tariq',
        'Una', 'Viktor', 'Wen', 'Xavier', 'Yasmin', 'Zane', 'Aisha', 'Bruno', 'Chloe', 'Declan',
        'Esme', 'Felix', 'Gwen', 'Hassan', 'Isla', 'Jonas', 'Kavya', 'Leon', 'Maya', 'Nico')
    $last = @('Abbott', 'Banerjee', 'Castillo', 'Dubois', 'Edwards', 'Fofana', 'Garcia', 'Hughes', 'Ivanov', 'Jensen',
        'Kowalski', 'Lindqvist', 'Mensah', 'Nakamura', 'Okafor', 'Petrov', 'Quigley', 'Rahman', 'Sato', 'Tanaka',
        'Underhill', 'Varga', 'Walsh', 'Xu', 'Yilmaz', 'Zielinski', 'Adeyemi', 'Brennan', 'Choi', 'Dlamini',
        'Eriksen', 'Ferreira', 'Gallagher', 'Haddad', 'Iyer', 'Jovanovic', 'Khan', 'Lopez', 'Moreau', 'Novak')

    $skuE3 = New-DemoGuid $rng
    $skuF3 = New-DemoGuid $rng
    $skuPowerBi = New-DemoGuid $rng
    $skus = @(
        [pscustomobject]@{ SkuId = $skuE3; SkuPartNumber = 'SPE_E3' }
        [pscustomobject]@{ SkuId = $skuF3; SkuPartNumber = 'SPE_F1' }
        [pscustomobject]@{ SkuId = $skuPowerBi; SkuPartNumber = 'POWER_BI_PRO' }
    )

    $used = @{}
    $newName = {
        param([int]$i)
        $f = $first[$i % $first.Count]
        $l = $last[($i * 7 + 3) % $last.Count]
        $upn = ("{0}.{1}@{2}" -f $f, $l, $domain).ToLower()
        $n = 1
        while ($used.ContainsKey($upn)) { $n++; $upn = ("{0}.{1}{2}@{3}" -f $f, $l, $n, $domain).ToLower() }
        $used[$upn] = $true
        [pscustomobject]@{ Name = "$f $l"; Upn = $upn }
    }

    $users = New-Object System.Collections.Generic.List[object]
    $addUser = {
        param($Name, $Upn, $UserType, $Enabled, [int]$CreatedDaysAgo, $LastSignInDaysAgo, [string[]]$Skus, [string]$State = '', $StateChangeDaysAgo = $null)
        $users.Add([pscustomobject]@{
                Id                = New-DemoGuid $rng
                DisplayName       = $Name
                UserPrincipalName = $Upn
                Mail              = $(if ($UserType -eq 'Guest') { $Upn -replace '#EXT#.*$', '' } else { $Upn })
                AccountEnabled    = $Enabled
                UserType          = $UserType
                CreatedDateTime   = $AsOf.AddDays(-$CreatedDaysAgo)
                LastSignInDateTime = $(if ($null -eq $LastSignInDaysAgo) { $null } else { $AsOf.AddDays(-$LastSignInDaysAgo) })
                LicenceSkuIds     = [string[]]@($Skus)
                ExternalUserState = $State
                ExternalUserStateChangeDateTime = $(if ($null -eq $StateChangeDaysAgo) { $null } else { $AsOf.AddDays(-$StateChangeDaysAgo) })
                SyncedFromOnPremises = $false
            })
        return $users[$users.Count - 1]
    }

    # --- Named administrator and emergency-access accounts (indices 0-11) ---
    $admins = @{}
    $adminSpecs = @(
        @{ Key = 'bg1'; Name = 'Emergency Access 01'; Upn = "emergency01@$domain"; Lic = @() }
        @{ Key = 'bg2'; Name = 'Emergency Access 02'; Upn = "emergency02@$domain"; Lic = @() }
        @{ Key = 'ga1'; Name = 'Priya Raman (admin)'; Upn = "adm.priya@$domain"; Lic = @() }
        @{ Key = 'ga2'; Name = 'Marcus Oyelaran (admin)'; Upn = "adm.marcus@$domain"; Lic = @() }
        @{ Key = 'ga3'; Name = 'Sofia Lindgren (admin)'; Upn = "adm.sofia@$domain"; Lic = @() }
        @{ Key = 'ga4'; Name = 'Tomas Havel (admin)'; Upn = "adm.tomas@$domain"; Lic = @() }
        @{ Key = 'ga5'; Name = 'Hannah Whitcombe (admin)'; Upn = "adm.hannah@$domain"; Lic = @() }
        @{ Key = 'ga6'; Name = 'Idris Karimi (admin)'; Upn = "adm.idris@$domain"; Lic = @() }
        @{ Key = 'sec1'; Name = 'Noor Fathima (security)'; Upn = "sec.noor@$domain"; Lic = @() }
        @{ Key = 'sec2'; Name = 'Ewan Sinclair (security)'; Upn = "sec.ewan@$domain"; Lic = @() }
        @{ Key = 'hd1'; Name = 'Helpdesk Agent 01'; Upn = "helpdesk01@$domain"; Lic = @($skuE3) }
        @{ Key = 'hd2'; Name = 'Helpdesk Agent 02'; Upn = "helpdesk02@$domain"; Lic = @($skuE3) }
        @{ Key = 'hd3'; Name = 'Helpdesk Agent 03'; Upn = "helpdesk03@$domain"; Lic = @($skuE3) }
        @{ Key = 'spo'; Name = 'Callista Moreno (SharePoint)'; Upn = "adm.callista@$domain"; Lic = @() }
        @{ Key = 'leaver'; Name = 'Former Admin (leaver)'; Upn = "adm.leaver@$domain"; Lic = @() }
    )
    foreach ($spec in $adminSpecs) {
        $disabled = $spec.Key -eq 'leaver'
        $lastSignIn = if ($disabled) { 140 } elseif ($spec.Key -like 'bg*') { 62 } else { $rng.Next(0, 4) }
        $admins[$spec.Key] = & $addUser $spec.Name $spec.Upn 'Member' (-not $disabled) $rng.Next(600, 2200) $lastSignIn $spec.Lic
    }

    # --- Ordinary members ---
    $memberCount = 170
    $members = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $memberCount; $i++) {
        $nm = & $newName $i
        $lic = if ($i % 6 -eq 0) { @($skuF3) } elseif ($i % 19 -eq 0) { @($skuE3, $skuPowerBi) } else { @($skuE3) }
        $created = $rng.Next(150, 2800)
        $signIn = $rng.Next(0, 25)
        $enabled = $true

        # Scenario groups by index range.
        if ($i -ge 150 -and $i -lt 161) { $signIn = $rng.Next(105, 410) }                   # stale members (11)
        if ($i -ge 161 -and $i -lt 165) { $signIn = $null; $created = $rng.Next(130, 300) }  # never signed in (4)
        if ($i -ge 165 -and $i -lt 170) {                                                       # leavers: disabled, still licensed (5)
            $enabled = $false; $signIn = $rng.Next(95, 330)
        }
        $members.Add((& $addUser $nm.Name $nm.Upn 'Member' $enabled $created $signIn $lic))
    }
    # Two further disabled leavers with no licence.
    foreach ($i in 170..171) {
        $nm = & $newName $i
        $members.Add((& $addUser $nm.Name $nm.Upn 'Member' $false ($rng.Next(400, 1500)) ($rng.Next(200, 500)) @()))
    }

    # --- Guests ---
    $partnerDomains = @('fabrikam.example', 'tailspin.example', 'adatum.example', 'litware.example', 'wingtip.example', 'proseware.example')
    $guests = New-Object System.Collections.Generic.List[object]
    for ($g = 0; $g -lt 36; $g++) {
        $nm = & $newName (200 + $g)
        $pd = $partnerDomains[$g % $partnerDomains.Count]
        $mail = ("{0}.{1}@{2}" -f $nm.Name.Split(' ')[0], $nm.Name.Split(' ')[1], $pd).ToLower()
        $upn = ($mail -replace '@', '_') + "#EXT#@$domain"
        $created = $rng.Next(40, 900); $signIn = $rng.Next(0, 55); $state = 'Accepted'; $stateChange = $created - 1
        if ($g -ge 24 -and $g -lt 29) { $signIn = $rng.Next(120, 420); $created = $rng.Next(450, 900) }      # stale guests (5)
        if ($g -ge 29 -and $g -lt 32) { $signIn = $null; $created = $rng.Next(100, 300) }                       # accepted, never signed in (3)
        if ($g -ge 32 -and $g -lt 35) { $state = 'PendingAcceptance'; $signIn = $null; $created = $rng.Next(45, 210); $stateChange = $created }  # old pending (3)
        if ($g -eq 35) { $state = 'PendingAcceptance'; $signIn = $null; $created = 6; $stateChange = 6 }       # new pending (1)
        $u = & $addUser $nm.Name $upn 'Guest' $true $created $signIn @() $state $stateChange
        $u.Mail = $mail
        $guests.Add($u)
    }

    # --- Authentication method registration (disabled users are not in this report) ---
    $adminKeysNoMfa = @('hd2', 'hd3')                          # administrators with no MFA (2)
    $memberNoMfa = @(20, 41, 57, 63, 88, 102, 117, 131, 144, 152, 158, 163)  # members with no MFA (12)
    $memberPhoneOnly = @(7, 12, 33, 49, 70, 95, 120, 138, 149)               # phone-only (9)
    $regs = New-Object System.Collections.Generic.List[object]
    $adminIds = @{}
    foreach ($k in $admins.Keys) { $adminIds[$admins[$k].Id] = $k }

    $addReg = {
        param($User, [bool]$IsAdmin, [string[]]$Methods)
        $registered = @($Methods | Where-Object { $_ -notin @('email', 'securityQuestion') }).Count -gt 0
        $passwordless = @($Methods | Where-Object { $_ -in @('fido2SecurityKey', 'windowsHelloForBusiness', 'microsoftAuthenticatorPasswordless', 'passKeyDeviceBound') }).Count -gt 0
        $regs.Add([pscustomobject]@{
                UserId = $User.Id; UserPrincipalName = $User.UserPrincipalName; DisplayName = $User.DisplayName
                UserType = $User.UserType.ToLower(); IsAdmin = $IsAdmin; IsMfaRegistered = $registered
                IsMfaCapable = $registered; IsPasswordlessCapable = $passwordless
                MethodsRegistered = [string[]]@($Methods); DefaultMfaMethod = $(if ($Methods.Count -gt 0) { $Methods[0] } else { '' })
            })
    }

    $activeAdminKeys = @('bg1', 'bg2', 'ga1', 'ga2', 'ga3', 'ga4', 'ga5', 'sec1', 'hd1', 'hd2', 'hd3', 'spo')
    foreach ($k in $admins.Keys) {
        $u = $admins[$k]
        if (-not $u.AccountEnabled) { continue }
        $isAdmin = $k -in $activeAdminKeys
        $methods = @(if ($k -in $adminKeysNoMfa) { @() }
            elseif ($k -like 'bg*') { 'fido2SecurityKey' }
            elseif ($k -in @('ga1', 'ga2', 'ga3')) { 'fido2SecurityKey', 'microsoftAuthenticatorPush' }
            else { 'microsoftAuthenticatorPush', 'softwareOneTimePasscode' })
        & $addReg $u $isAdmin $methods
    }
    for ($i = 0; $i -lt $members.Count; $i++) {
        $u = $members[$i]
        if (-not $u.AccountEnabled) { continue }
        $methods = @(if ($i -in $memberNoMfa) { if ($i % 2 -eq 0) { @() } else { 'email' } }
            elseif ($i -in $memberPhoneOnly) { 'mobilePhone' }
            elseif ($i % 5 -eq 0) { 'microsoftAuthenticatorPush', 'softwareOneTimePasscode', 'windowsHelloForBusiness' }
            else { 'microsoftAuthenticatorPush', 'softwareOneTimePasscode' })
        & $addReg $u $false $methods
    }
    for ($g = 0; $g -lt $guests.Count; $g++) {
        $methods = @(if ($g -in @(3, 9, 14, 22, 27, 30)) { @() } else { 'microsoftAuthenticatorPush' })
        & $addReg $guests[$g] $false $methods
    }

    # --- Directory roles ---
    $roleDefinitions = @(
        foreach ($id in $script:HighPrivilegeRoles.Keys) { [pscustomobject]@{ Id = $id; DisplayName = $script:HighPrivilegeRoles[$id] } }
        [pscustomobject]@{ Id = 'f2ef992c-3afb-46b9-b7cf-a126ee74c451'; DisplayName = 'Global Reader' }
        [pscustomobject]@{ Id = '5f2222b1-57c3-48ba-8ad5-d4759f1fde6f'; DisplayName = 'Security Operator' }
    )
    $role = @{}
    foreach ($id in $script:HighPrivilegeRoles.Keys) { $role[$script:HighPrivilegeRoles[$id]] = $id }

    $asPrincipal = {
        param($User)
        [pscustomobject]@{
            PrincipalId = $User.Id; PrincipalType = 'user'; PrincipalDisplayName = $User.DisplayName
            PrincipalUpn = $User.UserPrincipalName; PrincipalUserType = $User.UserType; PrincipalAccountEnabled = $User.AccountEnabled
        }
    }
    $roleAssignments = New-Object System.Collections.Generic.List[object]
    $addAssign = {
        param($Principal, [string]$RoleName)
        $a = $Principal.PSObject.Copy()
        $a | Add-Member -NotePropertyName RoleDefinitionId -NotePropertyValue $role[$RoleName]
        $a | Add-Member -NotePropertyName DirectoryScopeId -NotePropertyValue '/'
        $roleAssignments.Add($a)
    }

    # Permanent Global Administrators (seven, including two emergency accounts).
    foreach ($k in 'bg1', 'bg2', 'ga1', 'ga2', 'ga3', 'ga4', 'ga5') { & $addAssign (& $asPrincipal $admins[$k]) 'Global Administrator' }
    # ga6 is eligible for Global Administrator through PIM only (see below).
    & $addAssign (& $asPrincipal $admins['sec1']) 'Security Administrator'     # activated now
    & $addAssign (& $asPrincipal $admins['hd1']) 'Helpdesk Administrator'
    & $addAssign (& $asPrincipal $admins['hd2']) 'Helpdesk Administrator'
    & $addAssign (& $asPrincipal $admins['hd3']) 'Helpdesk Administrator'
    & $addAssign (& $asPrincipal $admins['spo']) 'SharePoint Administrator'
    & $addAssign (& $asPrincipal $admins['leaver']) 'User Administrator'

    # A role-assignable group holding Exchange Administrator.
    $groupId = New-DemoGuid $rng
    $groupPrincipal = [pscustomobject]@{
        PrincipalId = $groupId; PrincipalType = 'group'; PrincipalDisplayName = 'Cloud Operations Admins'
        PrincipalUpn = ''; PrincipalUserType = ''; PrincipalAccountEnabled = $null
    }
    & $addAssign $groupPrincipal 'Exchange Administrator'
    $groupMembers = @{}
    $groupMembers[$groupId] = @(
        (& $asPrincipal $members[3]), (& $asPrincipal $members[18]), (& $asPrincipal $members[44])
    )

    # An application (service principal) holding Application Administrator.
    $spnPrincipal = [pscustomobject]@{
        PrincipalId = New-DemoGuid $rng; PrincipalType = 'servicePrincipal'; PrincipalDisplayName = 'northwind-provisioning-automation'
        PrincipalUpn = ''; PrincipalUserType = ''; PrincipalAccountEnabled = $null
    }
    & $addAssign $spnPrincipal 'Application Administrator'

    # A guest consultant holding Cloud Application Administrator.
    & $addAssign (& $asPrincipal $guests[1]) 'Cloud Application Administrator'

    # PIM eligibility.
    $eligibility = New-Object System.Collections.Generic.List[object]
    $addElig = {
        param($Principal, [string]$RoleName)
        $e = $Principal.PSObject.Copy()
        $e | Add-Member -NotePropertyName RoleDefinitionId -NotePropertyValue $role[$RoleName]
        $e | Add-Member -NotePropertyName DirectoryScopeId -NotePropertyValue '/'
        $e | Add-Member -NotePropertyName EndDateTime -NotePropertyValue $AsOf.AddDays(180)
        $eligibility.Add($e)
    }
    & $addElig (& $asPrincipal $admins['ga6']) 'Global Administrator'
    & $addElig (& $asPrincipal $admins['sec1']) 'Security Administrator'
    & $addElig (& $asPrincipal $admins['sec2']) 'Security Administrator'
    & $addElig (& $asPrincipal $admins['ga6']) 'Privileged Role Administrator'
    & $addElig (& $asPrincipal $admins['sec2']) 'Conditional Access Administrator'

    # Schedule instances: sec1 has activated Security Administrator; the time-bound assignment is hd1.
    $scheduleInstances = @(
        [pscustomobject]@{ PrincipalId = $admins['sec1'].Id; RoleDefinitionId = $role['Security Administrator']; AssignmentType = 'Activated'; EndDateTime = $AsOf.AddHours(6) }
        [pscustomobject]@{ PrincipalId = $admins['hd1'].Id; RoleDefinitionId = $role['Helpdesk Administrator']; AssignmentType = 'Assigned'; EndDateTime = $AsOf.AddDays(60) }
    )
    # Every other assignment is permanent: add 'Assigned' instances with no end date.
    foreach ($a in $roleAssignments) {
        $already = $scheduleInstances | Where-Object { $_.PrincipalId -eq $a.PrincipalId -and $_.RoleDefinitionId -eq $a.RoleDefinitionId }
        if (-not $already) {
            $scheduleInstances += [pscustomobject]@{ PrincipalId = $a.PrincipalId; RoleDefinitionId = $a.RoleDefinitionId; AssignmentType = 'Assigned'; EndDateTime = $null }
        }
    }

    # --- Conditional Access policies (Graph REST shape) ---
    $bgGroup = New-DemoGuid $rng
    $svcGroup = New-DemoGuid $rng
    $adminRoles = ($script:HighPrivilegeRoles.Keys | Select-Object -First 7 | ForEach-Object { '"' + $_ + '"' }) -join ','
    $created = $AsOf.AddDays(-400).ToString('o')
    $modified = $AsOf.AddDays(-35).ToString('o')
    $caJson = @"
[
 {"id":"$(New-DemoGuid $rng)","displayName":"CA001 Block legacy authentication","state":"enabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":["All"],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup"],"includeRoles":[],"excludeRoles":[]},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["exchangeActiveSync","other"]},
  "grantControls":{"operator":"OR","builtInControls":["block"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA002 Require MFA for administrator roles","state":"enabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":[],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup"],"includeRoles":[$adminRoles],"excludeRoles":[]},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["all"]},
  "grantControls":{"operator":"OR","builtInControls":["mfa"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA003 Require MFA for all users","state":"enabledForReportingButNotEnforced","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":["All"],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup","$svcGroup"],"includeRoles":[],"excludeRoles":[]},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["all"]},
  "grantControls":{"operator":"OR","builtInControls":["mfa"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA004 Require MFA for guests and external users","state":"enabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":[],"excludeUsers":[],"includeGroups":[],"excludeGroups":[],"includeRoles":[],"excludeRoles":[],
    "includeGuestsOrExternalUsers":{"guestOrExternalUserTypes":"b2bCollaborationGuest,b2bCollaborationMember","externalTenants":{"membershipKind":"all"}}},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["all"]},
  "grantControls":{"operator":"OR","builtInControls":["mfa"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA005 Require compliant device for Microsoft 365","state":"enabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":["All"],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup"],"includeRoles":[],"excludeRoles":[]},
   "applications":{"includeApplications":["Office365"]},"clientAppTypes":["browser","mobileAppsAndDesktopClients"],"platforms":{"includePlatforms":["windows","macOS"]}},
  "grantControls":{"operator":"OR","builtInControls":["compliantDevice"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA006 Block sign-in from unapproved countries","state":"disabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":["All"],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup"],"includeRoles":[],"excludeRoles":[]},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["all"],"locations":{"includeLocations":["All"],"excludeLocations":["AllTrusted"]}},
  "grantControls":{"operator":"OR","builtInControls":["block"]}},
 {"id":"$(New-DemoGuid $rng)","displayName":"CA007 Require MFA for medium and high sign-in risk","state":"enabled","createdDateTime":"$created","modifiedDateTime":"$modified",
  "conditions":{"users":{"includeUsers":["All"],"excludeUsers":[],"includeGroups":[],"excludeGroups":["$bgGroup"],"includeRoles":[],"excludeRoles":[]},
   "applications":{"includeApplications":["All"]},"clientAppTypes":["all"],"signInRiskLevels":["high","medium"]},
  "grantControls":{"operator":"OR","builtInControls":["mfa"]}}
]
"@
    $caPolicies = @(($caJson | ConvertFrom-Json) | ForEach-Object { ConvertFrom-AuditCaPolicy -Policy $_ })

    [pscustomobject]@{
        TenantLabel         = 'Northwind Traders (synthetic demo data)'
        EmergencyAccounts   = @("emergency01@$domain", "emergency02@$domain")
        Domain              = $domain
        Users               = $users.ToArray()
        MfaRegistrations    = $regs.ToArray()
        SubscribedSkus      = $skus
        RoleDefinitions     = $roleDefinitions
        RoleAssignments     = $roleAssignments.ToArray()
        RoleEligibility     = $eligibility.ToArray()
        ScheduleInstances   = $scheduleInstances
        GroupMembers        = $groupMembers
        ConditionalAccess   = $caPolicies
    }
}
