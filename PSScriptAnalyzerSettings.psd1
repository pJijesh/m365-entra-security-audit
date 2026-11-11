@{
    Severity     = @('Error', 'Warning')
    ExcludeRules = @(
        # The command names Get-StaleAccounts, Get-GuestUsers, Get-PrivilegedRoleHolders and
        # Export-ConditionalAccessPolicies are plural on purpose: they return collections of results.
        'PSUseSingularNouns'
    )
}
