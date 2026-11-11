function Get-AuditRequiredScope {
    <#
    .SYNOPSIS
        Returns the read-only Microsoft Graph scopes this module needs.
    .DESCRIPTION
        Pass the result straight to Connect-MgGraph. Use -Detailed to see why each scope is requested.
    .EXAMPLE
        Connect-MgGraph -Scopes (Get-AuditRequiredScope)
    .EXAMPLE
        Get-AuditRequiredScope -Detailed | Format-Table -AutoSize -Wrap
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param([switch]$Detailed)

    if ($Detailed) {
        foreach ($name in $script:RequiredScopes.Keys) {
            [pscustomobject]@{ Scope = $name; Purpose = $script:RequiredScopes[$name] }
        }
    }
    else {
        [string[]]$script:RequiredScopes.Keys
    }
}
