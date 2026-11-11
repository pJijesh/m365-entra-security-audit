# Finding catalogue. Severity is a triage default, not a risk score: it reflects how much a gap
# typically matters if left open, and should be adjusted to your own context.
# Framework text is a plain-English paraphrase, not a quotation or a certification claim.

$script:FindingCatalog = @{
    'MFA-001' = @{
        Area = 'MFA'; Severity = 'High'
        Title = 'Administrator accounts have no MFA method registered'
        Remediation = 'Register a phishing-resistant or app-based method for each administrator, then enforce MFA for administrator roles with a Conditional Access policy.'
        ZeroTrust = 'Verify explicitly: the accounts that can change everything need the strongest proof of identity.'
        CyberEssentials = 'User access control: multi-factor authentication is expected for administrative accounts on cloud services.'
        CisStyle = 'Identity: require MFA for all administrative roles.'
    }
    'MFA-002' = @{
        Area = 'MFA'; Severity = 'Medium'
        Title = 'Member users have no MFA method registered'
        Remediation = 'Run a registration campaign, then enforce MFA for all users with Conditional Access. Prioritise accounts that are enabled and licensed.'
        ZeroTrust = 'Verify explicitly: a password alone is not enough evidence that the right person is signing in.'
        CyberEssentials = 'User access control: multi-factor authentication is expected for all users of cloud services.'
        CisStyle = 'Identity: ensure MFA is enabled for all users.'
    }
    'MFA-003' = @{
        Area = 'MFA'; Severity = 'Low'
        Title = 'Users rely only on phone-based MFA (SMS or voice)'
        Remediation = 'Encourage the authenticator app or a passkey. Phone-based methods remain better than no MFA, but are more exposed to SIM-swap and phishing attacks.'
        ZeroTrust = 'Verify explicitly: prefer stronger, phishing-resistant factors where you can.'
        CyberEssentials = 'User access control: MFA should be a method that is hard for an attacker to intercept.'
        CisStyle = 'Identity: prefer authenticator-app or phishing-resistant methods over SMS and voice.'
    }
    'STALE-001' = @{
        Area = 'Stale accounts'; Severity = 'Medium'
        Title = 'Enabled member accounts with no recent sign-in'
        Remediation = 'Confirm with line managers whether each account is still needed. Disable accounts that are not, then remove licences and delete after your retention period.'
        ZeroTrust = 'Assume breach: an unused account is a quiet way in that nobody would notice being used.'
        CyberEssentials = 'User access control: accounts that are no longer required should be disabled or removed.'
        CisStyle = 'Identity: review and remove inactive accounts.'
    }
    'STALE-002' = @{
        Area = 'Stale accounts'; Severity = 'Low'
        Title = 'Enabled member accounts that have never signed in'
        Remediation = 'Check whether these are unused joiner accounts, shared mailboxes with a sign-in enabled, or service accounts. Disable or convert them as appropriate.'
        ZeroTrust = 'Use least-privilege access: accounts nobody uses should not be able to sign in.'
        CyberEssentials = 'User access control: only accounts that are needed should exist and be enabled.'
        CisStyle = 'Identity: review accounts with no recorded sign-in activity.'
    }
    'STALE-003' = @{
        Area = 'Stale accounts'; Severity = 'Low'
        Title = 'Disabled accounts that still hold licences'
        Remediation = 'Remove the licences, once any mailbox or data retention needs are met. This reduces cost and the amount of data attached to dormant identities.'
        ZeroTrust = 'Use least-privilege access: a disabled identity should not keep entitlements.'
        CyberEssentials = 'User access control: leaver processes should remove access completely.'
        CisStyle = 'Identity: tidy leaver accounts, including their licences.'
    }
    'PRIV-001' = @{
        Area = 'Privileged roles'; Severity = 'High'
        Title = 'Many permanent Global Administrators'
        Remediation = 'Reduce permanent Global Administrators to the minimum (Microsoft guidance suggests fewer than five). Use narrower roles for day-to-day work and make the rest eligible through PIM.'
        ZeroTrust = 'Use least-privilege access: fewer people with the most powerful role means fewer high-value targets.'
        CyberEssentials = 'User access control: administrative rights should be limited to those who need them.'
        CisStyle = 'Identity: keep the number of Global Administrators small.'
    }
    'PRIV-002' = @{
        Area = 'Privileged roles'; Severity = 'Medium'
        Title = 'Fewer than two Global Administrators'
        Remediation = 'Keep at least two Global Administrators, including emergency (break-glass) access accounts held outside normal Conditional Access, so a single lost account cannot lock you out.'
        ZeroTrust = 'Assume breach: plan for the loss of any one account without losing control of the tenant.'
        CyberEssentials = 'User access control: administrative access should be managed and recoverable.'
        CisStyle = 'Identity: maintain emergency access accounts.'
    }
    'PRIV-003' = @{
        Area = 'Privileged roles'; Severity = 'Medium'
        Title = 'Standing (permanent) assignments to high-privilege roles'
        Remediation = 'Convert permanent assignments to PIM-eligible where possible, so privileges are active only when needed and each activation is logged.'
        ZeroTrust = 'Use least-privilege access: grant privilege just in time, not all the time.'
        CyberEssentials = 'User access control: administrative rights should be time-limited where practical.'
        CisStyle = 'Identity: use just-in-time activation for privileged roles.'
    }
    'PRIV-004' = @{
        Area = 'Privileged roles'; Severity = 'Info'
        Title = 'PIM eligibility data was not available'
        Remediation = 'Permanent versus eligible assignments could not be distinguished. This normally means the tenant has no Entra ID P2 or Governance licence, or the session lacks RoleManagement.Read.Directory.'
        ZeroTrust = 'Use least-privilege access: without PIM, consider other ways to limit standing privilege.'
        CyberEssentials = 'User access control: know who holds administrative rights.'
        CisStyle = 'Identity: understand how privileged access is granted.'
    }
    'PRIV-005' = @{
        Area = 'Privileged roles'; Severity = 'Low'
        Title = 'Directory roles granted through groups'
        Remediation = 'Treat the owners and members of these groups as administrators. Restrict who can change membership and review it regularly.'
        ZeroTrust = 'Use least-privilege access: access granted indirectly is easy to forget.'
        CyberEssentials = 'User access control: review who can grant administrative access.'
        CisStyle = 'Identity: protect and review role-assignable groups.'
    }
    'PRIV-006' = @{
        Area = 'Privileged roles'; Severity = 'Low'
        Title = 'Service principals hold directory roles'
        Remediation = 'Confirm each application needs the role, that its credentials are managed and expire, and that someone owns it.'
        ZeroTrust = 'Assume breach: non-human identities with admin roles are attractive targets.'
        CyberEssentials = 'User access control: all identities with administrative rights need an owner.'
        CisStyle = 'Identity: review application permissions and role assignments.'
    }
    'PRIV-007' = @{
        Area = 'Privileged roles'; Severity = 'High'
        Title = 'Guest accounts hold privileged roles'
        Remediation = 'Confirm the business need. Where it is genuine, make the assignment eligible and time-limited, and make sure Conditional Access covers the guest.'
        ZeroTrust = 'Use least-privilege access: external identities should rarely hold administrative power.'
        CyberEssentials = 'User access control: administrative rights for people outside the organisation need strong justification.'
        CisStyle = 'Identity: restrict privileged roles for guest users.'
    }
    'PRIV-008' = @{
        Area = 'Privileged roles'; Severity = 'Medium'
        Title = 'Disabled accounts still hold role assignments'
        Remediation = 'Remove the role assignments from disabled accounts so re-enabling one by mistake does not restore administrator access.'
        ZeroTrust = 'Use least-privilege access: no entitlements should remain on an identity that is switched off.'
        CyberEssentials = 'User access control: leaver processes should remove access completely.'
        CisStyle = 'Identity: remove privileges when accounts are disabled.'
    }
    'GUEST-001' = @{
        Area = 'Guest users'; Severity = 'Medium'
        Title = 'Guest accounts with no recent sign-in'
        Remediation = 'Ask the internal sponsor whether the collaboration continues. Remove guests that are no longer needed, and consider access reviews to repeat this automatically.'
        ZeroTrust = 'Assume breach: external accounts you no longer use still carry access you granted.'
        CyberEssentials = 'User access control: remove access for people who no longer need it, including external parties.'
        CisStyle = 'Identity: review guest users regularly.'
    }
    'GUEST-002' = @{
        Area = 'Guest users'; Severity = 'Low'
        Title = 'Guest invitations pending for a long time'
        Remediation = 'Cancel invitations that were never accepted or resend them if still wanted. Unaccepted invitations are clutter and can be redeemed later by the wrong person.'
        ZeroTrust = 'Use least-privilege access: do not leave open offers of access lying around.'
        CyberEssentials = 'User access control: access that is not in use should not remain available.'
        CisStyle = 'Identity: clear stale guest invitations.'
    }
    'CA-001' = @{
        Area = 'Conditional Access'; Severity = 'High'
        Title = 'No enforced Conditional Access policy requires MFA for administrators'
        Remediation = 'Create a policy that targets administrator roles for all cloud apps and requires MFA or an authentication strength. Test in report-only mode, then enable it.'
        ZeroTrust = 'Verify explicitly: enforce strong authentication for the highest-risk accounts.'
        CyberEssentials = 'User access control: multi-factor authentication for administrative accounts, enforced by policy.'
        CisStyle = 'Conditional Access: require MFA for administrative roles.'
    }
    'CA-002' = @{
        Area = 'Conditional Access'; Severity = 'High'
        Title = 'Legacy authentication is not blocked by an enforced policy'
        Remediation = 'Block legacy authentication protocols for all users with a Conditional Access policy. These protocols cannot do MFA, so they bypass it.'
        ZeroTrust = 'Verify explicitly: close the doors that cannot ask for a second factor.'
        CyberEssentials = 'Secure configuration: switch off older, weaker services that you do not need.'
        CisStyle = 'Conditional Access: block legacy authentication.'
    }
    'CA-003' = @{
        Area = 'Conditional Access'; Severity = 'High'
        Title = 'No enforced Conditional Access policy requires MFA for all users'
        Remediation = 'Create a policy that requires MFA for all users and all cloud apps, excluding only emergency access accounts. Use report-only mode first.'
        ZeroTrust = 'Verify explicitly: apply strong authentication to every sign-in, not only some.'
        CyberEssentials = 'User access control: multi-factor authentication for all users of cloud services, enforced by policy.'
        CisStyle = 'Conditional Access: require MFA for all users.'
    }
    'CA-004' = @{
        Area = 'Conditional Access'; Severity = 'Low'
        Title = 'Conditional Access policies that are not enforcing'
        Remediation = 'Review policies in report-only or disabled state. Either finish testing and enable them, or remove them so the policy set reflects what is really enforced.'
        ZeroTrust = 'Verify explicitly: a policy only protects you when it is switched on.'
        CyberEssentials = 'Secure configuration: settings should be applied, not just drafted.'
        CisStyle = 'Conditional Access: keep the enforced policy set current.'
    }
    'CA-005' = @{
        Area = 'Conditional Access'; Severity = 'Low'
        Title = 'Enforced MFA or legacy-block policies have exclusions'
        Remediation = 'Keep exclusions to emergency access accounts only, document each one, and review them regularly. Every excluded account is outside the control.'
        ZeroTrust = 'Verify explicitly: exceptions to a control should be few, justified and reviewed.'
        CyberEssentials = 'User access control: exceptions to access rules should be controlled and recorded.'
        CisStyle = 'Conditional Access: minimise policy exclusions.'
    }
    'CA-006' = @{
        Area = 'Conditional Access'; Severity = 'Medium'
        Title = 'No enforced MFA policy covers guest and external users'
        Remediation = 'Add a policy that requires MFA for guests and external users, or extend the all-users policy to cover them.'
        ZeroTrust = 'Verify explicitly: external identities are not more trustworthy than internal ones.'
        CyberEssentials = 'User access control: multi-factor authentication for external users who access your cloud services.'
        CisStyle = 'Conditional Access: require MFA for guest users.'
    }
}

function New-AuditFinding {
    <#
    .SYNOPSIS
        Builds a finding object from the catalogue.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds an in-memory object only.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [int]$AffectedCount = 0,
        [string]$Detail = '',
        [ValidateSet('High', 'Medium', 'Low', 'Info')][string]$Severity
    )

    $def = $script:FindingCatalog[$Id]
    if (-not $def) { throw "Unknown finding id '$Id'." }

    [pscustomobject]@{
        PSTypeName      = 'M365EntraAudit.Finding'
        Id              = $Id
        Area            = $def.Area
        Severity        = $(if ($Severity) { $Severity } else { $def.Severity })
        Title           = $def.Title
        AffectedCount   = $AffectedCount
        Detail          = $Detail
        Remediation     = $def.Remediation
        ZeroTrust       = $def.ZeroTrust
        CyberEssentials = $def.CyberEssentials
        CisStyle        = $def.CisStyle
    }
}

function Get-AuditFindingCatalog {
    # Used by tests and documentation tooling.
    [CmdletBinding()]
    param()
    $script:FindingCatalog.Keys | Sort-Object
}
