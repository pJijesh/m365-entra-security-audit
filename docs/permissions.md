# Permissions

`M365EntraAudit` is read-only. It requests six Microsoft Graph delegated scopes, every one of which is a `*.Read.*` permission. It never requests a `ReadWrite` scope, and its test suite fails if one is added (see `tests/Module.Tests.ps1`).

Get the list at any time:

```powershell
Get-AuditRequiredScope -Detailed | Format-Table -AutoSize -Wrap
```

## Scopes and why each is needed

| Scope | Used by | Why it is needed |
| --- | --- | --- |
| `User.Read.All` | Stale accounts, guests, privileged roles | Reads users: account state, user type, creation date, licence assignments, guest invitation state, and the details of users who hold directory roles. |
| `AuditLog.Read.All` | MFA coverage, stale accounts, guests | Required for the `signInActivity` property on users, and for the authentication methods registration report (`userRegistrationDetails`). |
| `RoleManagement.Read.Directory` | Privileged roles | Reads role definitions, active role assignments, PIM eligibility schedule instances and PIM assignment schedule instances. |
| `Policy.Read.All` | Conditional Access | Reads Conditional Access policies. |
| `GroupMember.Read.All` | Privileged roles | Expands the members of groups that hold a directory role, so group-based administrators are not missed. |
| `LicenseAssignment.Read.All` | Stale accounts | Reads subscribed SKUs so licence IDs can be shown as product names. Optional: if it is missing, IDs are shown instead. |

## Graph calls and SDK cmdlets

| Area | Graph endpoint | SDK cmdlet (Microsoft.Graph 2.x) |
| --- | --- | --- |
| Users and sign-in activity | `GET /users?$select=...,signInActivity` | `Get-MgUser -All -Property ...` |
| MFA registration | `GET /reports/authenticationMethods/userRegistrationDetails` | `Get-MgReportAuthenticationMethodUserRegistrationDetail` |
| Licence names | `GET /subscribedSkus` | `Get-MgSubscribedSku` |
| Role definitions | `GET /roleManagement/directory/roleDefinitions` | `Get-MgRoleManagementDirectoryRoleDefinition` |
| Active assignments | `GET /roleManagement/directory/roleAssignments?$expand=principal` | `Get-MgRoleManagementDirectoryRoleAssignment -ExpandProperty principal` |
| PIM eligibility | `GET /roleManagement/directory/roleEligibilityScheduleInstances` | `Get-MgRoleManagementDirectoryRoleEligibilityScheduleInstance` |
| PIM activations and time-bound assignments | `GET /roleManagement/directory/roleAssignmentScheduleInstances` | `Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance` |
| Group role holders | `GET /groups/{id}/transitiveMembers` | `Get-MgGroupTransitiveMember` |
| Conditional Access | `GET /identity/conditionalAccess/policies` | `Get-MgIdentityConditionalAccessPolicy` |

Every call is an HTTP `GET`. All of them live in one file, `src/M365EntraAudit/Private/30-GraphData.ps1`, so the surface that talks to Microsoft is easy to review.

## What was verified, and how

- Cmdlet names were checked by installing Microsoft.Graph 2.41.2 from the PowerShell Gallery and confirming each command exists (`Get-Command`).
- The permission for each endpoint was taken from the Microsoft Learn Graph API reference, using the least-privileged permission listed on each page. Permissions can change, so confirm against the current pages before relying on this table.
- This has not been run against a live tenant. Treat the first run in your own tenant as a verification step, and check the warnings it prints.

## Scopes that are deliberately not requested

| Scope | Why it is left out |
| --- | --- |
| `Directory.Read.All` | Broader than needed. The narrower scopes above cover each call. |
| `UserAuthenticationMethod.Read.All` | Would allow reading each user's individual authentication methods. The registration report gives the same MFA answer without it, and without per-user calls. |
| `Reports.Read.All` | Not needed. The registration report is covered by `AuditLog.Read.All`. |
| Any `ReadWrite` scope | The tool never changes anything. |

Because `Application.Read.All` and `Group.Read.All` are also left out, the names of groups and service principals that hold a role may appear as object IDs in some tenants. This is cosmetic. The role assignment itself is still listed.

## Which account to sign in with

With delegated scopes, the signed-in account must also hold an Entra role that allows the reads. **Global Reader** is the simplest single role that covers every call here. Using it avoids signing in as a Global Administrator for a read-only task. Security Reader plus Reports Reader covers most of it, but check the Microsoft Learn pages above for each endpoint if you want a narrower custom role.

Consent for these scopes is granted to Microsoft Graph Command Line Tools in your tenant the first time you sign in. An administrator can review or revoke it under Enterprise applications in the Entra admin centre.

## Licences

| Data | Needs |
| --- | --- |
| `signInActivity` | Microsoft Entra ID P1 or P2. Without it, last sign-in values are empty and the stale-account results will be unreliable. |
| PIM eligibility and schedules | Microsoft Entra ID P2 or Governance. Without it, the module continues and raises finding `PRIV-004`. |
| Conditional Access | Microsoft Entra ID P1 or higher. Sign-in and user risk conditions need P2. |

## App-only use

The module is written for interactive delegated sign-in. It will also run with certificate-based app-only authentication if the app registration is granted the same permissions as application permissions. That path has not been tested here, and the signed-in-role guidance above does not apply to it.
