# M365EntraAudit root module. Loads private helpers first, then public commands.
$privateFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File | Sort-Object Name
$publicFiles = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File | Sort-Object Name

foreach ($file in @($privateFiles) + @($publicFiles)) {
    . $file.FullName
}

# Keep the default console display of the audit result short.
Update-TypeData -TypeName 'M365EntraAudit.AuditResult' -DefaultDisplayPropertySet 'Tenant', 'DemoMode', 'GeneratedAt', 'FindingCounts', 'ReportPath' -Force

Export-ModuleMember -Function $publicFiles.BaseName
