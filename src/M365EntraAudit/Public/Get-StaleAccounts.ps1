function Get-StaleAccounts {
    <#
    .SYNOPSIS
        Finds member accounts that are inactive, never used, or disabled but still licensed.
    .DESCRIPTION
        Uses the signInActivity property (needs AuditLog.Read.All and an Entra ID P1 or P2 licence).
        Guest accounts are covered by Get-GuestUsers. Read-only.
    .PARAMETER InactiveDays
        Number of days without a sign-in after which an enabled account is reported. Default 90.
    .PARAMETER ExcludeUserPrincipalName
        Accounts to leave out, for example emergency access accounts that are meant to be used rarely.
    .PARAMETER AsOf
        Date used for the calculation. Defaults to now; set it to make results reproducible.
    .PARAMETER DemoMode
        Use synthetic data instead of connecting to a tenant.
    .EXAMPLE
        Get-StaleAccounts -InactiveDays 60 -ExcludeUserPrincipalName 'breakglass1@contoso.example'
    .NOTES
        Required scopes: User.Read.All, AuditLog.Read.All, LicenseAssignment.Read.All (see docs/permissions.md).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [ValidateRange(1, 3650)][int]$InactiveDays = 90,
        [string[]]$ExcludeUserPrincipalName = @(),
        [datetime]$AsOf = (Get-Date),
        [switch]$DemoMode
    )

    if ($DemoMode) {
        $demo = Get-AuditDemoDataset -AsOf $AsOf
        $users = $demo.Users
        $skus = $demo.SubscribedSkus
    }
    else {
        $users = @(Get-AuditUser)
        $skus = try { @(Get-AuditSubscribedSku) } catch { Write-Warning "Licence names unavailable: $($_.Exception.Message)"; @() }
    }

    $skuName = @{}
    foreach ($s in @($skus)) { $skuName[$s.SkuId] = $s.SkuPartNumber }

    $members = @($users | Where-Object { $_.UserType -ne 'Guest' -and $_.UserPrincipalName -notin $ExcludeUserPrincipalName })

    $records = foreach ($u in $members) {
        $licensed = @($u.LicenceSkuIds).Count -gt 0
        $daysSince = Get-DaysSince -Date $u.LastSignInDateTime -AsOf $AsOf
        $age = Get-DaysSince -Date $u.CreatedDateTime -AsOf $AsOf

        $category = $null
        if ($u.AccountEnabled) {
            if ($null -ne $daysSince -and $daysSince -gt $InactiveDays) { $category = 'No recent sign-in' }
            elseif ($null -eq $daysSince -and $null -ne $age -and $age -gt $InactiveDays) { $category = 'Never signed in' }
        }
        elseif ($licensed) { $category = 'Disabled but licensed' }

        if ($category) {
            [pscustomobject]@{
                PSTypeName          = 'M365EntraAudit.StaleAccountRecord'
                DisplayName         = $u.DisplayName
                UserPrincipalName   = $u.UserPrincipalName
                Category            = $category
                AccountEnabled      = [bool]$u.AccountEnabled
                LastSignIn          = $u.LastSignInDateTime
                DaysSinceSignIn     = $daysSince
                Created             = $u.CreatedDateTime
                Licences            = [string[]]@($u.LicenceSkuIds | ForEach-Object { if ($skuName.ContainsKey($_)) { $skuName[$_] } else { $_ } })
                IsLicensed          = $licensed
            }
        }
    }
    $records = @($records | Sort-Object Category, @{ Expression = { $_.DaysSinceSignIn }; Descending = $true })

    $noRecent = @($records | Where-Object Category -eq 'No recent sign-in')
    $never = @($records | Where-Object Category -eq 'Never signed in')
    $disabledLicensed = @($records | Where-Object Category -eq 'Disabled but licensed')

    $summary = [pscustomobject]@{
        InactiveDaysThreshold = $InactiveDays
        MembersChecked        = $members.Count
        EnabledMembers        = @($members | Where-Object AccountEnabled).Count
        NoRecentSignIn        = $noRecent.Count
        NeverSignedIn         = $never.Count
        DisabledButLicensed   = $disabledLicensed.Count
        InactiveAccountsHoldingLicences = @($records | Where-Object IsLicensed).Count
    }

    $findings = New-Object System.Collections.Generic.List[object]
    if ($noRecent.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'STALE-001' -AffectedCount $noRecent.Count -Detail "No sign-in for more than $InactiveDays days. $(@($noRecent | Where-Object IsLicensed).Count) of these hold a licence."))
    }
    if ($never.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'STALE-002' -AffectedCount $never.Count -Detail "Created more than $InactiveDays days ago with no sign-in recorded."))
    }
    if ($disabledLicensed.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'STALE-003' -AffectedCount $disabledLicensed.Count -Detail 'Accounts are disabled but still have one or more licences assigned.'))
    }

    [pscustomobject]@{
        PSTypeName = 'M365EntraAudit.StaleAccountResult'
        Area       = 'Stale accounts'
        Summary    = $summary
        Findings   = $findings.ToArray()
        Records    = $records
    }
}
