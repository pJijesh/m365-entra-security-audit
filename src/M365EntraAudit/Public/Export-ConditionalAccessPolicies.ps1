function Export-ConditionalAccessPolicies {
    <#
    .SYNOPSIS
        Exports Conditional Access policies to JSON and summarises common gaps.
    .DESCRIPTION
        Writes conditional-access-policies.json (Graph wire format, one array of policies) to OutputPath
        and returns the results of four checks: MFA for administrators, legacy authentication blocked,
        MFA for all users, and MFA for guests. The checks are heuristics over policy settings. They do not
        simulate sign-ins, so review the findings against your own design. Read-only. The JSON contains
        object IDs from your tenant, so treat the file as sensitive.
    .PARAMETER OutputPath
        Folder for the JSON file. Created if missing. Use -NoExport to analyse without writing a file.
    .PARAMETER NoExport
        Skip writing the JSON file.
    .PARAMETER DemoMode
        Use synthetic policies instead of connecting to a tenant.
    .EXAMPLE
        Export-ConditionalAccessPolicies -OutputPath .\audit-output | Select-Object -ExpandProperty Checks
    .NOTES
        Required scope: Policy.Read.All (see docs/permissions.md).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [string]$OutputPath = (Join-Path (Get-Location) 'audit-output'),
        [switch]$NoExport,
        [switch]$DemoMode
    )

    $policies = @(if ($DemoMode) { (Get-AuditDemoDataset).ConditionalAccess } else { Get-AuditConditionalAccessPolicy })

    $jsonPath = $null
    if (-not $NoExport) {
        if (-not (Test-Path -LiteralPath $OutputPath)) { New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null }
        $jsonPath = Join-Path (Resolve-Path -LiteralPath $OutputPath).Path 'conditional-access-policies.json'
        ConvertTo-Json -InputObject @($policies | ForEach-Object { $_.Raw }) -Depth 20 | Set-Content -LiteralPath $jsonPath -Encoding utf8
    }

    $enabled = @($policies | Where-Object { Test-CaPolicyEnforced $_ })
    $notEnforcing = @($policies | Where-Object { -not (Test-CaPolicyEnforced $_) })

    $adminMfa = @($enabled | Where-Object { Test-CaAdminMfaPolicy $_ })
    $legacy = @($enabled | Where-Object { Test-CaLegacyBlockPolicy $_ })
    $allMfa = @($enabled | Where-Object { Test-CaAllUsersMfaPolicy $_ })
    $guestMfa = @($enabled | Where-Object { (Test-CaAllUsersMfaPolicy $_) -or (Test-CaGuestMfaPolicy $_) })

    $names = { param($p) if (@($p).Count) { (@($p) | ForEach-Object { $_.DisplayName }) -join '; ' } else { '' } }
    $reportOnlyNames = {
        param($test)
        # A near miss is a policy that would satisfy the check if its state were 'enabled'.
        $near = @($notEnforcing | Where-Object { $copy = $_.PSObject.Copy(); $copy.State = 'enabled'; & $test $copy })
        if ($near.Count) { " Present but not enforcing: $((@($near) | ForEach-Object { '{0} ({1})' -f $_.DisplayName, $_.State }) -join '; ')." } else { '' }
    }
    $noPolicyNote = if ($policies.Count -eq 0) { ' No Conditional Access policies were found. If Security defaults are enabled they may provide baseline MFA; confirm in the Entra admin centre.' } else { '' }

    $checks = @(
        [pscustomobject]@{ Id = 'CA-001'; Name = 'MFA required for administrator roles'; Passed = ($adminMfa.Count -gt 0)
            Detail = $(if ($adminMfa.Count) { "Covered by: $(& $names $adminMfa)" } else { "No enforced policy found.$(& $reportOnlyNames ${function:Test-CaAdminMfaPolicy})$noPolicyNote" }) }
        [pscustomobject]@{ Id = 'CA-002'; Name = 'Legacy authentication blocked'; Passed = ($legacy.Count -gt 0)
            Detail = $(if ($legacy.Count) { "Covered by: $(& $names $legacy)" } else { "No enforced policy found.$(& $reportOnlyNames ${function:Test-CaLegacyBlockPolicy})$noPolicyNote" }) }
        [pscustomobject]@{ Id = 'CA-003'; Name = 'MFA required for all users'; Passed = ($allMfa.Count -gt 0)
            Detail = $(if ($allMfa.Count) { "Covered by: $(& $names $allMfa)" } else { "No enforced policy found.$(& $reportOnlyNames ${function:Test-CaAllUsersMfaPolicy})$noPolicyNote" }) }
        [pscustomobject]@{ Id = 'CA-006'; Name = 'MFA required for guests and external users'; Passed = ($guestMfa.Count -gt 0)
            Detail = $(if ($guestMfa.Count) { "Covered by: $(& $names $guestMfa)" } else { "No enforced policy found.$(& $reportOnlyNames ${function:Test-CaGuestMfaPolicy})$noPolicyNote" }) }
    )

    $findings = New-Object System.Collections.Generic.List[object]
    foreach ($c in $checks) {
        if (-not $c.Passed) { $findings.Add((New-AuditFinding -Id $c.Id -AffectedCount 1 -Detail $c.Detail)) }
    }

    if ($notEnforcing.Count -gt 0) {
        $list = ($notEnforcing | ForEach-Object { '{0} ({1})' -f $_.DisplayName, $_.State }) -join '; '
        $findings.Add((New-AuditFinding -Id 'CA-004' -AffectedCount $notEnforcing.Count -Detail $list))
    }

    $withExclusions = @($enabled | Where-Object {
            ((Test-CaPolicyRequiresMfa $_) -or (Test-CaLegacyBlockPolicy $_)) -and
            (@($_.ExcludeUsers).Count + @($_.ExcludeGroups).Count + @($_.ExcludeRoles).Count) -gt 0
        })
    if ($withExclusions.Count -gt 0) {
        $findings.Add((New-AuditFinding -Id 'CA-005' -AffectedCount $withExclusions.Count -Detail "Policies with user, group or role exclusions: $(& $names $withExclusions)."))
    }

    $summary = [pscustomobject]@{
        PolicyCount        = $policies.Count
        Enforced           = $enabled.Count
        ReportOnly         = @($policies | Where-Object { $_.State -eq 'enabledForReportingButNotEnforced' }).Count
        Disabled           = @($policies | Where-Object { $_.State -eq 'disabled' }).Count
        ChecksPassed       = @($checks | Where-Object Passed).Count
        ChecksTotal        = $checks.Count
        JsonPath           = $jsonPath
    }

    $policyRecords = @($policies | ForEach-Object {
            [pscustomobject]@{
                PSTypeName      = 'M365EntraAudit.CaPolicyRecord'
                DisplayName     = $_.DisplayName
                State           = $_.State
                Users           = $(if ($_.IncludeUsers -contains 'All') { 'All users' }
                    elseif ($_.IncludeRoles.Count) { "$($_.IncludeRoles.Count) admin roles" }
                    elseif ($_.IncludesGuests) { 'Guests and external users' }
                    else { 'Selected users or groups' })
                Applications    = $(if ($_.IncludeApplications -contains 'All') { 'All cloud apps' } else { ($_.IncludeApplications -join ', ') })
                Grant           = $(if ($_.HasAuthenticationStrength) { "Authentication strength: $($_.AuthenticationStrength)" } else { ($_.BuiltInControls -join " $($_.GrantOperator) ") })
                Exclusions      = @($_.ExcludeUsers).Count + @($_.ExcludeGroups).Count + @($_.ExcludeRoles).Count
                Modified        = $_.ModifiedDateTime
            }
        })

    [pscustomobject]@{
        PSTypeName = 'M365EntraAudit.ConditionalAccessResult'
        Area       = 'Conditional Access'
        Summary    = $summary
        Findings   = $findings.ToArray()
        Checks     = $checks
        Records    = $policyRecords
    }
}
