# Shared constants for M365EntraAudit. Nothing in this file talks to Microsoft Graph.

# Every scope below is read-only. Each one is documented in docs/permissions.md.
$script:RequiredScopes = [ordered]@{
    'User.Read.All'               = 'Read user profiles, account state, licence assignments, guest status and (with AuditLog.Read.All) sign-in activity.'
    'AuditLog.Read.All'           = 'Read the signInActivity property and the authentication methods registration report.'
    'RoleManagement.Read.Directory' = 'Read directory role definitions, active assignments, PIM eligibility and activation schedules.'
    'Policy.Read.All'             = 'Read Conditional Access policies.'
    'GroupMember.Read.All'        = 'Expand the members of groups that hold directory roles.'
    'LicenseAssignment.Read.All'  = 'Translate licence SKU identifiers into readable product names.'
}

# Built-in roles treated as high privilege. IDs are the published Microsoft Entra role template IDs.
# Source: https://learn.microsoft.com/entra/identity/role-based-access-control/permissions-reference
$script:HighPrivilegeRoles = [ordered]@{
    '62e90394-69f5-4237-9190-012177145e10' = 'Global Administrator'
    'e8611ab8-c189-46e8-94e1-60213ab1f814' = 'Privileged Role Administrator'
    '194ae4cb-b126-40b2-bd5b-6091b380977d' = 'Security Administrator'
    'fe930be7-5e62-47db-91af-98c3a49a38b1' = 'User Administrator'
    '29232cdf-9323-42fd-ade2-1d097af3e4de' = 'Exchange Administrator'
    'f28a1f50-f6e7-4571-818b-6a12f2af6b6c' = 'SharePoint Administrator'
    'b1be1c3e-b65d-4f19-8427-f6fa0d97feb9' = 'Conditional Access Administrator'
    '9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3' = 'Application Administrator'
    '158c047a-c907-4556-b7ef-446551a6b5f7' = 'Cloud Application Administrator'
    'c4e39bd9-1100-46d3-8c65-fb160da0071f' = 'Authentication Administrator'
    '7be44c8a-adaf-4e2a-84d6-ab2649e08a13' = 'Privileged Authentication Administrator'
    '729827e3-9c14-49f7-bb1b-9608f156bbb8' = 'Helpdesk Administrator'
    '3a2c62db-5318-420d-8d74-23affee5d9d5' = 'Intune Administrator'
    '8ac3fc64-6eca-42ea-9e69-59f4c7b60eb2' = 'Hybrid Identity Administrator'
}

$script:GlobalAdministratorRoleId = '62e90394-69f5-4237-9190-012177145e10'

# Registered methods that rely on the telephone network (weaker than app-based or hardware methods).
$script:PhoneMethods = @('mobilePhone', 'alternateMobilePhone', 'officePhone')

# Registered methods that cannot count as a second factor on their own.
$script:NonMfaMethods = @('email', 'securityQuestion')

$script:SeverityOrder = @{ High = 0; Medium = 1; Low = 2; Info = 3 }
