function Get-GuestUsers {
    <#
    .SYNOPSIS
        Reviews guest (external) accounts: age, last sign-in and pending invitations.
    .DESCRIPTION
        Read-only. A guest is reported as stale when it is enabled, has been invited for longer than
        StaleDays, and has no sign-in within StaleDays (or none recorded). Pending invitations are
        reported when they have waited longer than PendingInvitationDays.
    .PARAMETER StaleDays
        Days without a sign-in after which an accepted guest is reported. Default 90.
    .PARAMETER PendingInvitationDays
        Days after which an unaccepted invitation is reported. Default 30.
    .PARAMETER AsOf
        Date used for the calculation. Defaults to now.
    .PARAMETER DemoMode
        Use synthetic data instead of connecting to a tenant.
    .NOTES
        Required scopes: User.Read.All, AuditLog.Read.All (see docs/permissions.md).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateRange(1, 3650)][int]$StaleDays = 90,
        [ValidateRange(1, 3650)][int]$PendingInvitationDays = 30,
        [datetime]$AsOf = (Get-Date),
        [switch]$DemoMode
    )

    $users = @(if ($DemoMode) { (Get-AuditDemoDataset -AsOf $AsOf).Users } else { Get-AuditUser })
    $guests = @($users | Where-Object { $_.UserType -eq 'Guest' })

    $records = foreach ($g in $guests) {
        $age = Get-DaysSince -Date $g.CreatedDateTime -AsOf $AsOf
        $daysSince = Get-DaysSince -Date $g.LastSignInDateTime -AsOf $AsOf
        $pending = $g.ExternalUserState -eq 'PendingAcceptance'
        $pendingRef = if ($g.ExternalUserStateChangeDateTime) { $g.ExternalUserStateChangeDateTime } else { $g.CreatedDateTime }
        $pendingDays = Get-DaysSince -Date $pendingRef -AsOf $AsOf

        $domain = ''
        if ($g.Mail -match '@(?<d>[^@]+)$') { $domain = $Matches['d'] }
        elseif ($g.UserPrincipalName -match '_(?<d>[^_#]+)#EXT#') { $domain = $Matches['d'] }

        $status = if (-not $g.AccountEnabled) { 'Disabled' }
        elseif ($pending -and $pendingDays -gt $PendingInvitationDays) { 'Pending invitation (overdue)' }
        elseif ($pending) { 'Pending invitation' }
        elseif ($null -eq $daysSince -and $age -gt $StaleDays) { 'No sign-in recorded' }
        elseif ($null -ne $daysSince -and $daysSince -gt $StaleDays) { 'Stale' }
        else { 'Active' }

        [pscustomobject]@{
            PSTypeName        = 'M365EntraAudit.GuestRecord'
            DisplayName       = $g.DisplayName
            Mail              = $g.Mail
            SourceDomain      = $domain
            Status            = $status
            InvitationState   = $g.ExternalUserState
            Created           = $g.CreatedDateTime
            AgeDays           = $age
            LastSignIn        = $g.LastSignInDateTime
            DaysSinceSignIn   = $daysSince
            IsLicensed        = @($g.LicenceSkuIds).Count -gt 0
        }
    }
    $records = @($records)

    $stale = @($records | Where-Object { $_.Status -in 'Stale', 'No sign-in recorded' })
    $overdue = @($records | Where-Object { $_.Status -eq 'Pending invitation (overdue)' })
    $pendingAll = @($records | Where-Object { $_.Status -like 'Pending invitation*' })

    $topDomains = @($records | Group-Object SourceDomain | Sort-Object Count -Descending | Select-Object -First 5 |
            ForEach-Object { "$($_.Name) ($($_.Count))" })

    $summary = [pscustomobject]@{
        StaleDaysThreshold    = $StaleDays
        PendingDaysThreshold  = $PendingInvitationDays
        TotalGuests           = $records.Count
        Active                = @($records | Where-Object Status -eq 'Active').Count
        Stale                 = @($records | Where-Object Status -eq 'Stale').Count
        NoSignInRecorded      = @($records | Where-Object Status -eq 'No sign-in recorded').Count
        PendingInvitations    = $pendingAll.Count
        PendingOverdue        = $overdue.Count
        OldestGuestAgeDays    = $(if ($records.Count) { ($records | Measure-Object AgeDays -Maximum).Maximum } else { 0 })
        TopSourceDomains      = $topDomains -join ', '
    }

    $findings = New-Object System.Collections.Generic.List[object]
    if ($stale.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'GUEST-001' -AffectedCount $stale.Count -Detail "Enabled guests with no sign-in for more than $StaleDays days, or none recorded."))
    }
    if ($overdue.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'GUEST-002' -AffectedCount $overdue.Count -Detail "Invitations unaccepted for more than $PendingInvitationDays days."))
    }

    [pscustomobject]@{
        PSTypeName = 'M365EntraAudit.GuestResult'
        Area       = 'Guest users'
        Summary    = $summary
        Findings   = $findings.ToArray()
        Records    = $records
    }
}
