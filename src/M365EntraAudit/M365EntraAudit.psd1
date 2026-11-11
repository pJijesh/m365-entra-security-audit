@{
    RootModule            = 'M365EntraAudit.psm1'
    ModuleVersion         = '0.1.0'
    GUID                  = '6f0a7c1e-3d52-4b8e-9a41-2c7d5e8b1f30'
    Author                = 'Puliyappottammal Jijesh'
    Copyright             = '(c) 2026 Puliyappottammal Jijesh. Released under the MIT licence.'
    Description           = 'Read-only security audit for Microsoft 365 and Microsoft Entra ID using the Microsoft Graph PowerShell SDK. Reports MFA coverage, stale accounts, privileged role holders, guest users and Conditional Access gaps as an HTML report and CSV files.'
    PowerShellVersion     = '7.2'
    CompatiblePSEditions  = @('Core')
    FunctionsToExport     = @(
        'Export-ConditionalAccessPolicies'
        'Get-AuditRequiredScope'
        'Get-GuestUsers'
        'Get-MfaCoverage'
        'Get-PrivilegedRoleHolders'
        'Get-StaleAccounts'
        'Invoke-SecurityAudit'
    )
    CmdletsToExport       = @()
    VariablesToExport     = @()
    AliasesToExport       = @()
    PrivateData           = @{
        PSData = @{
            Tags         = @('Microsoft365', 'EntraID', 'Security', 'Audit', 'MicrosoftGraph', 'ConditionalAccess', 'MFA', 'PIM', 'ReadOnly')
            LicenseUri   = 'https://github.com/pJijesh/m365-entra-security-audit/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/pJijesh/m365-entra-security-audit'
            ReleaseNotes = 'Initial release.'
        }
    }
}
