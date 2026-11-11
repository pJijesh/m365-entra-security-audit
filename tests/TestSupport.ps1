# Shared helpers for the Pester tests. Dot-sourced from each test file's BeforeAll.

function Import-AuditModuleForTest {
    $manifest = Join-Path $PSScriptRoot '..' 'src' 'M365EntraAudit' 'M365EntraAudit.psd1'
    Import-Module $manifest -Force -ErrorAction Stop
}

function Set-AuditTestData {
    # Mock bodies run in a different scope from the test, so shared test data lives in one global hashtable.
    param([Parameter(Mandatory)][string]$Name, $Value)
    if ($global:AuditTestData -isnot [hashtable]) { $global:AuditTestData = @{} }
    $global:AuditTestData[$Name] = $Value
}

function New-TestUser {
    param(
        [string]$Name = 'Test User',
        [string]$Upn = 'test.user@northwind.example',
        [string]$UserType = 'Member',
        [bool]$Enabled = $true,
        [datetime]$Created = ([datetime]'2024-01-01'),
        $LastSignIn = $null,
        [string[]]$Skus = @(),
        [string]$State = '',
        $StateChange = $null
    )
    [pscustomobject]@{
        Id = [guid]::NewGuid().ToString(); DisplayName = $Name; UserPrincipalName = $Upn; Mail = $Upn
        AccountEnabled = $Enabled; UserType = $UserType; CreatedDateTime = $Created; LastSignInDateTime = $LastSignIn
        LicenceSkuIds = $Skus; ExternalUserState = $State; ExternalUserStateChangeDateTime = $StateChange
        SyncedFromOnPremises = $false
    }
}

function New-TestRegistration {
    param(
        [string]$Upn = 'test.user@northwind.example',
        [string]$UserType = 'member',
        [bool]$IsAdmin = $false,
        [bool]$Registered = $true,
        [string[]]$Methods = @('microsoftAuthenticatorPush')
    )
    [pscustomobject]@{
        UserId = [guid]::NewGuid().ToString(); UserPrincipalName = $Upn; DisplayName = $Upn; UserType = $UserType
        IsAdmin = $IsAdmin; IsMfaRegistered = $Registered; IsMfaCapable = $Registered
        IsPasswordlessCapable = $false; MethodsRegistered = $Methods; DefaultMfaMethod = ''
    }
}

function New-TestPrincipal {
    param(
        [string]$Id = ([guid]::NewGuid().ToString()),
        [string]$Type = 'user',
        [string]$Name = 'Test Admin',
        [string]$Upn = 'test.admin@northwind.example',
        [string]$UserType = 'Member',
        $Enabled = $true
    )
    [pscustomobject]@{
        PrincipalId = $Id; PrincipalType = $Type; PrincipalDisplayName = $Name; PrincipalUpn = $Upn
        PrincipalUserType = $UserType; PrincipalAccountEnabled = $Enabled
    }
}

function New-TestRoleAssignment {
    param($Principal, [string]$RoleId, [string]$Scope = '/', $End = $null)
    $a = $Principal.PSObject.Copy()
    $a | Add-Member -NotePropertyName RoleDefinitionId -NotePropertyValue $RoleId
    $a | Add-Member -NotePropertyName DirectoryScopeId -NotePropertyValue $Scope
    $a | Add-Member -NotePropertyName EndDateTime -NotePropertyValue $End
    $a
}

function New-TestCaPolicy {
    # Builds a policy in Graph REST shape and maps it with the module's own converter.
    param(
        [string]$Name = 'Test policy',
        [string]$State = 'enabled',
        [string[]]$IncludeUsers = @('All'),
        [string[]]$ExcludeGroups = @(),
        [string[]]$IncludeRoles = @(),
        [string[]]$Apps = @('All'),
        [string[]]$ClientAppTypes = @('all'),
        [string[]]$Controls = @('mfa'),
        [string]$Operator = 'OR',
        [switch]$Guests,
        [string[]]$SignInRisk = @(),
        [switch]$WithPlatforms
    )
    $users = @{ includeUsers = $IncludeUsers; excludeUsers = @(); includeGroups = @(); excludeGroups = $ExcludeGroups; includeRoles = $IncludeRoles; excludeRoles = @() }
    if ($Guests) { $users['includeGuestsOrExternalUsers'] = @{ guestOrExternalUserTypes = 'b2bCollaborationGuest' } }
    $conditions = @{ users = $users; applications = @{ includeApplications = $Apps }; clientAppTypes = $ClientAppTypes; signInRiskLevels = $SignInRisk }
    if ($WithPlatforms) { $conditions['platforms'] = @{ includePlatforms = @('windows') } }
    $json = @{
        id = [guid]::NewGuid().ToString(); displayName = $Name; state = $State
        createdDateTime = '2026-01-01T00:00:00Z'; modifiedDateTime = '2026-02-01T00:00:00Z'
        conditions = $conditions
        grantControls = @{ operator = $Operator; builtInControls = $Controls }
    } | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    InModuleScope M365EntraAudit -Parameters @{ P = $json } { param($P) ConvertFrom-AuditCaPolicy -Policy $P }
}
