function Get-MfaCoverage {
    <#
    .SYNOPSIS
        Reports which users have registered a multi-factor authentication method.
    .DESCRIPTION
        Reads the authentication methods registration report (userRegistrationDetails). Flags users with
        no MFA method registered, administrators without MFA, and users who rely only on phone-based MFA.
        Read-only. Disabled users do not appear in the underlying Graph report.
    .PARAMETER DemoMode
        Use synthetic data instead of connecting to a tenant.
    .EXAMPLE
        Get-MfaCoverage | Select-Object -ExpandProperty Summary
    .EXAMPLE
        (Get-MfaCoverage -DemoMode).Records | Where-Object Status -eq 'No MFA'
    .NOTES
        Required scope: AuditLog.Read.All (see docs/permissions.md).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param([switch]$DemoMode)

    # @(...) around the command itself keeps an empty result as an empty array rather than $null.
    $registrations = @(if ($DemoMode) { (Get-AuditDemoDataset).MfaRegistrations } else { Get-AuditMfaRegistration })

    $records = foreach ($r in $registrations) {
        $effective = @($r.MethodsRegistered | Where-Object { $_ -and $_ -notin $script:NonMfaMethods })
        $phoneOnly = $effective.Count -gt 0 -and @($effective | Where-Object { $_ -notin $script:PhoneMethods }).Count -eq 0
        $status = if (-not $r.IsMfaRegistered) { 'No MFA' } elseif ($phoneOnly) { 'Phone only' } else { 'Strong' }

        [pscustomobject]@{
            PSTypeName            = 'M365EntraAudit.MfaRecord'
            DisplayName           = $r.DisplayName
            UserPrincipalName     = $r.UserPrincipalName
            UserType              = $r.UserType
            IsAdmin               = [bool]$r.IsAdmin
            IsMfaRegistered       = [bool]$r.IsMfaRegistered
            IsPasswordlessCapable = [bool]$r.IsPasswordlessCapable
            MethodsRegistered     = [string[]]@($r.MethodsRegistered)
            Status                = $status
        }
    }
    $records = @($records)

    $members = @($records | Where-Object { $_.UserType -ne 'guest' })
    $guests = @($records | Where-Object { $_.UserType -eq 'guest' })
    $membersWithMfa = @($members | Where-Object { $_.IsMfaRegistered })
    $admins = @($records | Where-Object { $_.IsAdmin })
    $adminsNoMfa = @($admins | Where-Object { -not $_.IsMfaRegistered })
    $membersNoMfa = @($members | Where-Object { -not $_.IsMfaRegistered -and -not $_.IsAdmin })
    $phoneOnlyUsers = @($records | Where-Object { $_.Status -eq 'Phone only' })

    $coverage = if ($members.Count -gt 0) { [math]::Round(100 * $membersWithMfa.Count / $members.Count, 1) } else { 0 }

    $summary = [pscustomobject]@{
        UsersInReport          = $records.Count
        Members                = $members.Count
        Guests                 = $guests.Count
        MembersWithMfa         = $membersWithMfa.Count
        MembersCoveragePercent = $coverage
        GuestsWithoutMfa       = @($guests | Where-Object { -not $_.IsMfaRegistered }).Count
        Administrators         = $admins.Count
        AdministratorsWithoutMfa = $adminsNoMfa.Count
        MembersWithoutMfa      = $membersNoMfa.Count
        PhoneOnlyUsers         = $phoneOnlyUsers.Count
        PasswordlessCapable    = @($records | Where-Object { $_.IsPasswordlessCapable }).Count
    }

    $findings = New-Object System.Collections.Generic.List[object]
    if ($adminsNoMfa.Count -gt 0) {
        $names = ($adminsNoMfa | Select-Object -First 5 -ExpandProperty UserPrincipalName) -join ', '
        $findings.Add((New-AuditFinding -Id 'MFA-001' -AffectedCount $adminsNoMfa.Count -Detail "Administrators without MFA: $names$(if ($adminsNoMfa.Count -gt 5) { ', and others' })."))
    }
    if ($membersNoMfa.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'MFA-002' -AffectedCount $membersNoMfa.Count -Detail "$($membersNoMfa.Count) of $($members.Count) member users in the report ($coverage% covered overall)."))
    }
    if ($phoneOnlyUsers.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'MFA-003' -AffectedCount $phoneOnlyUsers.Count -Detail 'These users have only SMS or voice call registered as a second factor.'))
    }

    [pscustomobject]@{
        PSTypeName = 'M365EntraAudit.MfaCoverageResult'
        Area       = 'MFA'
        Summary    = $summary
        Findings   = $findings.ToArray()
        Records    = $records
    }
}
