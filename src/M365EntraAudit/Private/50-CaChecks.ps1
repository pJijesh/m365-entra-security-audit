# Heuristic checks over flattened Conditional Access policies (see ConvertFrom-AuditCaPolicy).
# They look at policy settings only. They do not evaluate sign-ins, device state or exclusions in context.

function Test-CaPolicyEnforced {
    param($Policy)
    return ($Policy.State -eq 'enabled')
}

function Test-CaPolicyRequiresMfa {
    param($Policy)
    if ($Policy.HasAuthenticationStrength) { return $true }
    $controls = @($Policy.BuiltInControls)
    if ($controls -notcontains 'mfa') { return $false }
    # With OR, other controls (for example a compliant device) can satisfy the policy instead of MFA.
    return ($controls.Count -eq 1 -or $Policy.GrantOperator -eq 'AND')
}

function Test-CaPolicyAllApps {
    param($Policy)
    return (@($Policy.IncludeApplications) -contains 'All')
}

function Test-CaPolicyUnconditional {
    # True when no platform, location, device, or risk condition narrows the policy.
    param($Policy)
    return (-not $Policy.Platforms -and -not $Policy.HasLocationCondition -and -not $Policy.HasDeviceFilter -and
        @($Policy.SignInRiskLevels).Count -eq 0 -and @($Policy.UserRiskLevels).Count -eq 0)
}

function Test-CaClientAppsCoverModern {
    param($Policy)
    $types = @($Policy.ClientAppTypes)
    return ($types -contains 'all') -or (($types -contains 'browser') -and ($types -contains 'mobileAppsAndDesktopClients'))
}

function Test-CaAdminMfaPolicy {
    param($Policy)
    if (-not (Test-CaPolicyEnforced $Policy)) { return $false }
    if (-not (Test-CaPolicyRequiresMfa $Policy) -or -not (Test-CaPolicyAllApps $Policy)) { return $false }
    if (-not (Test-CaPolicyUnconditional $Policy) -or -not (Test-CaClientAppsCoverModern $Policy)) { return $false }
    $ga = $script:GlobalAdministratorRoleId
    $includesGa = (@($Policy.IncludeRoles) -contains $ga) -or
    ((@($Policy.IncludeUsers) -contains 'All') -and (@($Policy.ExcludeRoles) -notcontains $ga))
    return $includesGa
}

function Test-CaAllUsersMfaPolicy {
    param($Policy)
    if (-not (Test-CaPolicyEnforced $Policy)) { return $false }
    return ((Test-CaPolicyRequiresMfa $Policy) -and (Test-CaPolicyAllApps $Policy) -and
        (Test-CaPolicyUnconditional $Policy) -and (Test-CaClientAppsCoverModern $Policy) -and
        (@($Policy.IncludeUsers) -contains 'All'))
}

function Test-CaGuestMfaPolicy {
    param($Policy)
    if (-not (Test-CaPolicyEnforced $Policy)) { return $false }
    return ((Test-CaPolicyRequiresMfa $Policy) -and (Test-CaPolicyAllApps $Policy) -and
        (Test-CaPolicyUnconditional $Policy) -and $Policy.IncludesGuests)
}

function Test-CaLegacyBlockPolicy {
    param($Policy)
    if (-not (Test-CaPolicyEnforced $Policy)) { return $false }
    $types = @($Policy.ClientAppTypes)
    return ((@($Policy.BuiltInControls) -contains 'block') -and (Test-CaPolicyAllApps $Policy) -and
        (@($Policy.IncludeUsers) -contains 'All') -and
        ($types -contains 'exchangeActiveSync') -and ($types -contains 'other'))
}
