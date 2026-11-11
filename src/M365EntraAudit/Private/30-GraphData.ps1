# Data-access layer. These are the only functions that call the Microsoft Graph PowerShell SDK.
# Every call is a read (Get-Mg*). Each function maps SDK objects into small, flat records so that
# the audit logic, the tests and DemoMode all work on the same shape.

function Get-AuditUser {
    [CmdletBinding()]
    param()

    $property = @(
        'id', 'displayName', 'userPrincipalName', 'mail', 'accountEnabled', 'userType', 'createdDateTime',
        'assignedLicenses', 'signInActivity', 'externalUserState', 'externalUserStateChangeDateTime',
        'onPremisesSyncEnabled'
    )
    $users = Get-MgUser -All -Property $property -PageSize 500

    foreach ($u in $users) {
        $stamps = @(
            $u.SignInActivity.LastSuccessfulSignInDateTime,
            $u.SignInActivity.LastSignInDateTime,
            $u.SignInActivity.LastNonInteractiveSignInDateTime
        ) | Where-Object { $null -ne $_ }
        $last = $stamps | Sort-Object -Descending | Select-Object -First 1

        [pscustomobject]@{
            Id                = [string]$u.Id
            DisplayName       = [string]$u.DisplayName
            UserPrincipalName = [string]$u.UserPrincipalName
            Mail              = [string]$u.Mail
            AccountEnabled    = [bool]$u.AccountEnabled
            UserType          = [string]$u.UserType
            CreatedDateTime   = $u.CreatedDateTime
            LastSignInDateTime = $last
            LicenceSkuIds     = [string[]]@($u.AssignedLicenses | ForEach-Object { [string]$_.SkuId })
            ExternalUserState = [string]$u.ExternalUserState
            ExternalUserStateChangeDateTime = $u.ExternalUserStateChangeDateTime
            SyncedFromOnPremises = [bool]$u.OnPremisesSyncEnabled
        }
    }
}

function Get-AuditMfaRegistration {
    [CmdletBinding()]
    param()

    Get-MgReportAuthenticationMethodUserRegistrationDetail -All | ForEach-Object {
        [pscustomobject]@{
            UserId              = [string]$_.Id
            UserPrincipalName   = [string]$_.UserPrincipalName
            DisplayName         = [string]$_.UserDisplayName
            UserType            = [string]$_.UserType
            IsAdmin             = [bool]$_.IsAdmin
            IsMfaRegistered     = [bool]$_.IsMfaRegistered
            IsMfaCapable        = [bool]$_.IsMfaCapable
            IsPasswordlessCapable = [bool]$_.IsPasswordlessCapable
            MethodsRegistered   = [string[]]@($_.MethodsRegistered)
            DefaultMfaMethod    = [string]$_.UserPreferredMethodForSecondaryAuthentication
        }
    }
}

function Get-AuditSubscribedSku {
    [CmdletBinding()]
    param()

    Get-MgSubscribedSku -All | ForEach-Object {
        [pscustomobject]@{
            SkuId         = [string]$_.SkuId
            SkuPartNumber = [string]$_.SkuPartNumber
        }
    }
}

function Get-AuditRoleDefinition {
    [CmdletBinding()]
    param()

    Get-MgRoleManagementDirectoryRoleDefinition -All | ForEach-Object {
        [pscustomobject]@{
            Id          = [string]$_.Id
            DisplayName = [string]$_.DisplayName
        }
    }
}

function ConvertTo-AuditPrincipal {
    <#
    .SYNOPSIS
        Flattens an expanded 'principal' directory object (user, group or service principal).
    #>
    [CmdletBinding()]
    param($Principal, [string]$PrincipalId)

    $odataType = [string](Get-AuditProp $Principal '@odata.type')
    $type = switch -Wildcard ($odataType) {
        '*user'             { 'user' }
        '*group'            { 'group' }
        '*servicePrincipal' { 'servicePrincipal' }
        default             { 'unknown' }
    }
    $accountEnabled = Get-AuditProp $Principal 'accountEnabled'

    [pscustomobject]@{
        PrincipalId             = $PrincipalId
        PrincipalType           = $type
        PrincipalDisplayName    = [string](Get-AuditProp $Principal 'displayName')
        PrincipalUpn            = [string](Get-AuditProp $Principal 'userPrincipalName')
        PrincipalUserType       = [string](Get-AuditProp $Principal 'userType')
        PrincipalAccountEnabled = $(if ($null -eq $accountEnabled) { $null } else { [bool]$accountEnabled })
    }
}

function Get-AuditRoleAssignment {
    [CmdletBinding()]
    param()

    Get-MgRoleManagementDirectoryRoleAssignment -All -ExpandProperty 'principal' | ForEach-Object {
        $p = ConvertTo-AuditPrincipal -Principal $_.Principal -PrincipalId ([string]$_.PrincipalId)
        $p | Add-Member -NotePropertyName RoleDefinitionId -NotePropertyValue ([string]$_.RoleDefinitionId) -PassThru |
            Add-Member -NotePropertyName DirectoryScopeId -NotePropertyValue ([string]$_.DirectoryScopeId) -PassThru
    }
}

function Get-AuditRoleEligibility {
    [CmdletBinding()]
    param()

    Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance -All -ExpandProperty 'principal' | ForEach-Object {
        $p = ConvertTo-AuditPrincipal -Principal $_.Principal -PrincipalId ([string]$_.PrincipalId)
        $p | Add-Member -NotePropertyName RoleDefinitionId -NotePropertyValue ([string]$_.RoleDefinitionId) -PassThru |
            Add-Member -NotePropertyName DirectoryScopeId -NotePropertyValue ([string]$_.DirectoryScopeId) -PassThru |
            Add-Member -NotePropertyName EndDateTime -NotePropertyValue $_.EndDateTime -PassThru
    }
}

function Get-AuditRoleScheduleInstance {
    # Active assignment schedule instances: AssignmentType is 'Assigned' or 'Activated'.
    [CmdletBinding()]
    param()

    Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance -All | ForEach-Object {
        [pscustomobject]@{
            PrincipalId      = [string]$_.PrincipalId
            RoleDefinitionId = [string]$_.RoleDefinitionId
            AssignmentType   = [string]$_.AssignmentType
            EndDateTime      = $_.EndDateTime
        }
    }
}

function Get-AuditGroupMember {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$GroupId)

    Get-MgGroupTransitiveMember -GroupId $GroupId -All | ForEach-Object {
        $p = ConvertTo-AuditPrincipal -Principal $_ -PrincipalId ([string]$_.Id)
        if ($p.PrincipalType -in 'user', 'servicePrincipal') { $p }
    }
}

function ConvertFrom-AuditCaPolicy {
    <#
    .SYNOPSIS
        Maps a Conditional Access policy in Graph REST (camelCase JSON) shape to a flat record.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Policy)

    $cond   = $Policy.conditions
    $users  = $cond.users
    $apps   = $cond.applications
    $grant  = $Policy.grantControls
    $strength = $grant.authenticationStrength

    [pscustomobject]@{
        Id                       = [string]$Policy.id
        DisplayName              = [string]$Policy.displayName
        State                    = [string]$Policy.state
        CreatedDateTime          = $Policy.createdDateTime
        ModifiedDateTime         = $Policy.modifiedDateTime
        IncludeUsers             = ConvertTo-StringArray $users.includeUsers
        ExcludeUsers             = ConvertTo-StringArray $users.excludeUsers
        IncludeGroups            = ConvertTo-StringArray $users.includeGroups
        ExcludeGroups            = ConvertTo-StringArray $users.excludeGroups
        IncludeRoles             = ConvertTo-StringArray $users.includeRoles
        ExcludeRoles             = ConvertTo-StringArray $users.excludeRoles
        IncludesGuests           = [bool]($null -ne $users.includeGuestsOrExternalUsers)
        ExcludesGuests           = [bool]($null -ne $users.excludeGuestsOrExternalUsers)
        IncludeApplications      = ConvertTo-StringArray $apps.includeApplications
        ClientAppTypes           = ConvertTo-StringArray $cond.clientAppTypes
        Platforms                = [bool]($null -ne $cond.platforms)
        HasLocationCondition     = [bool]($null -ne $cond.locations)
        HasDeviceFilter          = [bool]($null -ne $cond.devices)
        SignInRiskLevels         = ConvertTo-StringArray $cond.signInRiskLevels
        UserRiskLevels           = ConvertTo-StringArray $cond.userRiskLevels
        BuiltInControls          = ConvertTo-StringArray $grant.builtInControls
        GrantOperator            = [string]$grant.operator
        HasAuthenticationStrength = [bool]($null -ne $strength)
        AuthenticationStrength   = $(if ($strength) { [string]$strength.displayName } else { '' })
        Raw                      = $Policy
    }
}

function Get-AuditConditionalAccessPolicy {
    [CmdletBinding()]
    param()

    foreach ($policy in (Get-MgIdentityConditionalAccessPolicy -All)) {
        # ToJsonString() gives the Graph wire format, which the mapping above expects.
        $json = $null
        try { $json = $policy.ToJsonString() | ConvertFrom-Json -Depth 20 } catch { Write-Verbose "ToJsonString failed: $($_.Exception.Message)" }
        if (-not $json) { $json = ($policy | ConvertTo-Json -Depth 10 | ConvertFrom-Json) }
        ConvertFrom-AuditCaPolicy -Policy $json
    }
}
