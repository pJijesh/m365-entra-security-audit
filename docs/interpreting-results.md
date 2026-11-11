# Interpreting the results

Each finding has an ID, a default severity, a plain-English reason it matters, and a mapping to three common ways of describing good practice. Use this page to decide what to do with a finding, and how to talk about it with a manager, an auditor or a customer.

## How to read severity

Severity is a **triage default, not a risk score**. It reflects how much a gap usually matters if left open. Your own context can raise or lower it: an unused account in a tenant with no sensitive data is a different problem from the same account in a regulated business. The tool does not calculate an overall grade or percentage, because one would give a false impression of precision.

## About the framework mappings

The mappings below are plain-English paraphrases written to help a reader connect a technical finding to a familiar control. They are not quotations, they do not use the official numbering, and meeting them does not amount to certification.

- **Zero Trust** refers to three widely used principles: verify explicitly, use least-privilege access, and assume breach.
- **Cyber Essentials** refers to the UK scheme's five technical controls. These findings fall under *user access control* and *secure configuration*. Where the scheme expects multi-factor authentication for cloud services, the MFA findings are relevant. Check the current requirements document for the exact wording that applies to you.
- **CIS-style** refers to the identity and Conditional Access recommendations in the CIS Microsoft 365 Foundations Benchmark. Recommendation numbers change between versions, so they are not quoted here. Look up the current version when you need to cite one.

## MFA

| ID | Default severity | What it means | Why it matters | Zero Trust | Cyber Essentials | CIS-style |
| --- | --- | --- | --- | --- | --- | --- |
| `MFA-001` | High | One or more administrator accounts have no MFA method registered. | A stolen password is enough to take over an account that can change everything. | Verify explicitly: strongest proof for the highest-risk accounts. | User access control: MFA for administrative accounts. | Require MFA for administrative roles. |
| `MFA-002` | Medium | Enabled member users (not administrators) have no MFA method registered. | Registration is the step before enforcement. Users who have not registered will be blocked or enrolled at the moment you turn enforcement on. | Verify explicitly: a password alone is weak evidence. | User access control: MFA for all users of cloud services. | Ensure MFA is enabled for all users. |
| `MFA-003` | Low | Users whose only second factor is SMS or a voice call. | Better than nothing, but exposed to SIM-swap and social engineering. | Verify explicitly: prefer phishing-resistant factors. | User access control: a factor that is hard to intercept. | Prefer authenticator-app or phishing-resistant methods. |

Registration is not enforcement. A user can be registered and still never be asked for MFA if no Conditional Access policy requires it. Read the MFA results together with the Conditional Access checks.

## Stale accounts

| ID | Default severity | What it means | Why it matters | Zero Trust | Cyber Essentials | CIS-style |
| --- | --- | --- | --- | --- | --- | --- |
| `STALE-001` | Medium | Enabled members with no sign-in for more than the threshold (default 90 days). | Unused accounts are a quiet way in, and nobody notices when they are misused. They often still hold licences and group memberships. | Assume breach: reduce the number of identities an attacker can use. | User access control: remove accounts that are no longer needed. | Review and remove inactive accounts. |
| `STALE-002` | Low | Enabled members older than the threshold with no sign-in recorded. | Usually unused joiner accounts, shared mailboxes with sign-in left on, or service accounts. | Use least-privilege access: unused accounts should not be able to sign in. | User access control: only needed accounts should exist. | Review accounts with no recorded sign-in. |
| `STALE-003` | Low | Disabled accounts that still hold licences. | Cost, and a sign that the leaver process is incomplete. | Use least-privilege access: no entitlements on a switched-off identity. | User access control: leavers lose access completely. | Tidy leaver accounts, including licences. |

Caveats: emergency (break-glass) accounts are meant to be used rarely and will look stale. Pass them with `-ExcludeUserPrincipalName`. A last sign-in value can be empty for reasons other than "never signed in", so treat `STALE-002` as a prompt to check, not a conclusion.

## Privileged roles

| ID | Default severity | What it means | Why it matters | Zero Trust | Cyber Essentials | CIS-style |
| --- | --- | --- | --- | --- | --- | --- |
| `PRIV-001` | High | More permanent Global Administrators than the threshold (default: five or more), emergency accounts excluded. | Each one is a high-value target. Microsoft guidance suggests keeping the number small. | Use least-privilege access. | User access control: limit administrative rights. | Keep the number of Global Administrators small. |
| `PRIV-002` | Medium | Fewer than two Global Administrators. | A single lost or locked account could leave nobody able to manage the tenant. | Assume breach: plan for losing any one account. | User access control: administrative access is managed and recoverable. | Maintain emergency access accounts. |
| `PRIV-003` | Medium | Users with permanent assignments to high-privilege roles, where PIM is available. | Standing privilege is available to an attacker at all times. Just-in-time activation narrows the window and logs each use. | Use least-privilege access: just in time, not all the time. | User access control: time-limit administrative rights where practical. | Use just-in-time activation for privileged roles. |
| `PRIV-004` | Info | PIM data could not be read. | Permanent and eligible assignments cannot be told apart, so `PRIV-003` was not assessed. | Use least-privilege access by other means. | User access control: know who holds administrative rights. | Understand how privilege is granted. |
| `PRIV-005` | Low | Roles granted through groups. | Whoever can change the group's membership is effectively an administrator. | Use least-privilege access: indirect access is easy to forget. | User access control: review who can grant administrative access. | Protect and review role-assignable groups. |
| `PRIV-006` | Low | Applications (service principals) hold directory roles. | Non-human identities with administrative power need an owner and managed credentials. | Assume breach: protect non-human identities too. | User access control: every identity with admin rights has an owner. | Review application permissions and roles. |
| `PRIV-007` | High | Guest accounts hold a directory role. | External identities should rarely hold administrative power, and you do not control their home tenant. | Use least-privilege access. | User access control: strong justification for external administrators. | Restrict privileged roles for guests. |
| `PRIV-008` | Medium | Disabled accounts still hold role assignments. | Re-enabling the account, by mistake or by an attacker, restores the administrator access. | Use least-privilege access: no entitlements when switched off. | User access control: complete leaver removal. | Remove privileges when disabling accounts. |

Emergency accounts: pass their user principal names with `-EmergencyAccount`. They are shown in the table, flagged, and left out of the permanent-Global-Administrator and standing-privilege counts, because keeping them permanent is intended.

## Guest users

| ID | Default severity | What it means | Why it matters | Zero Trust | Cyber Essentials | CIS-style |
| --- | --- | --- | --- | --- | --- | --- |
| `GUEST-001` | Medium | Enabled guests with no sign-in for longer than the threshold, or none recorded. | Collaboration ends, but the access you granted does not. | Assume breach: unused external access is still access. | User access control: remove access for people who no longer need it, including external parties. | Review guest users regularly. |
| `GUEST-002` | Low | Invitations unaccepted for longer than the threshold (default 30 days). | Open offers of access linger, and an invitation can be redeemed later by the wrong person. | Use least-privilege access: do not leave open offers. | User access control: access that is not used should not stay available. | Clear stale guest invitations. |

A recurring access review in Entra (an Identity Governance feature) is the longer-term fix. This tool tells you where to start.

## Conditional Access

These are heuristic checks over policy settings. They do not simulate sign-ins. A policy is counted as covering a case only when it is **enforced** (not report-only), applies to **all cloud apps**, is not narrowed by platform, location, device filter or risk condition, and requires MFA on its own (not "MFA or compliant device"). Use the What If tool in the Entra admin centre to test real scenarios.

| ID | Default severity | What it means | Why it matters | Zero Trust | Cyber Essentials | CIS-style |
| --- | --- | --- | --- | --- | --- | --- |
| `CA-001` | High | No enforced policy requires MFA for administrators. | Without enforcement, registered MFA is optional for the most powerful accounts. | Verify explicitly. | User access control: MFA for admins, enforced by policy. | Require MFA for administrative roles. |
| `CA-002` | High | Legacy authentication is not blocked by an enforced policy. | Legacy protocols cannot perform MFA, so they bypass it. | Verify explicitly: close the doors that cannot ask for a second factor. | Secure configuration: switch off older, weaker services you do not need. | Block legacy authentication. |
| `CA-003` | High | No enforced policy requires MFA for all users. | Users are covered only by whatever narrower policies exist. | Verify explicitly: every sign-in. | User access control: MFA for all users, enforced by policy. | Require MFA for all users. |
| `CA-004` | Low | Policies in report-only or disabled state. | A policy only protects when it is on. Finish testing or remove it. | Verify explicitly. | Secure configuration: settings applied, not drafted. | Keep the enforced policy set current. |
| `CA-005` | Low | Enforced MFA or legacy-block policies with user, group or role exclusions. | Every excluded account is outside the control. | Verify explicitly: exceptions are few and reviewed. | User access control: controlled, recorded exceptions. | Minimise policy exclusions. |
| `CA-006` | Medium | No enforced MFA policy covers guests and external users. | External users are no more trustworthy than internal ones. | Verify explicitly. | User access control: MFA for external users of your cloud services. | Require MFA for guest users. |

If a tenant has no Conditional Access policies at all, Security defaults may be providing baseline MFA. The module cannot tell, so check in the Entra admin centre before treating `CA-001` to `CA-003` as open.

## What the tool cannot tell you

- Whether a person who is registered for MFA is actually prompted. That depends on policy and sign-in context.
- Whether an administrator account is used for daily work, or whether it has a mailbox. Separate admin accounts are good practice, but this tool does not test for them.
- Device compliance, application consent, mailbox forwarding rules, external sharing or Defender configuration. These are outside its scope.
- Anything that happened in the past. It reports configuration at the time it runs.
