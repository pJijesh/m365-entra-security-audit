BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
    $script:RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
}

Describe 'Module manifest' {
    It 'is valid' {
        { Test-ModuleManifest -Path (Join-Path $script:RepoRoot 'src' 'M365EntraAudit' 'M365EntraAudit.psd1') -ErrorAction Stop } | Should -Not -Throw
    }
    It 'exports exactly the documented commands' {
        $expected = 'Export-ConditionalAccessPolicies', 'Get-AuditRequiredScope', 'Get-GuestUsers', 'Get-MfaCoverage', 'Get-PrivilegedRoleHolders', 'Get-StaleAccounts', 'Invoke-SecurityAudit'
        (Get-Command -Module M365EntraAudit).Name | Sort-Object | Should -Be ($expected | Sort-Object)
    }
    It 'requires PowerShell 7 or later' {
        [version](Import-PowerShellDataFile (Join-Path $script:RepoRoot 'src' 'M365EntraAudit' 'M365EntraAudit.psd1')).PowerShellVersion | Should -BeGreaterOrEqual ([version]'7.0')
    }
}

Describe 'Read-only guarantee' {
    BeforeAll {
        $script:SourceFiles = Get-ChildItem (Join-Path $script:RepoRoot 'src') -Recurse -Filter '*.ps1'
    }
    It 'never calls a Microsoft Graph SDK cmdlet that writes' {
        $pattern = '\b(New|Set|Update|Remove|Add|Grant|Revoke|Restore|Clear|Send|Import|Invoke)-Mg(?!Graph\b)\w*'
        $hits = $script:SourceFiles | Select-String -Pattern $pattern
        $hits | Should -BeNullOrEmpty
    }
    It 'never calls Invoke-MgGraphRequest or uses a write HTTP method' {
        ($script:SourceFiles | Select-String -Pattern 'Invoke-MgGraphRequest|-Method\s+(POST|PATCH|PUT|DELETE)') | Should -BeNullOrEmpty
    }
    It 'keeps Get-Mg cmdlets inside the data-access layer (apart from reading the connection state)' {
        $others = $script:SourceFiles | Where-Object Name -ne '30-GraphData.ps1'
        ($others | Select-String -Pattern '\bGet-Mg(?!Context\b)\w+') | Should -BeNullOrEmpty
    }
    It 'requests only read scopes' {
        $scopes = Get-AuditRequiredScope
        $scopes.Count | Should -BeGreaterThan 0
        foreach ($s in $scopes) {
            $s | Should -Match '\.Read\.(All|Directory)$'
            $s | Should -Not -Match 'ReadWrite'
        }
    }
    It 'documents a purpose for every scope' {
        foreach ($row in (Get-AuditRequiredScope -Detailed)) { $row.Purpose | Should -Not -BeNullOrEmpty }
    }
    It 'lists every requested scope in docs/permissions.md' {
        $doc = Get-Content (Join-Path $script:RepoRoot 'docs' 'permissions.md') -Raw
        foreach ($s in (Get-AuditRequiredScope)) { $doc | Should -Match ([regex]::Escape($s)) }
    }
}

Describe 'Finding catalogue' {
    It 'is complete for every finding' {
        InModuleScope M365EntraAudit {
            foreach ($id in (Get-AuditFindingCatalog)) {
                $f = New-AuditFinding -Id $id
                foreach ($p in 'Title', 'Area', 'Severity', 'Remediation', 'ZeroTrust', 'CyberEssentials', 'CisStyle') {
                    $f.$p | Should -Not -BeNullOrEmpty -Because "$id needs $p"
                }
                $f.Severity | Should -BeIn 'High', 'Medium', 'Low', 'Info'
            }
        }
    }
    It 'has every finding id explained in docs/interpreting-results.md' {
        $doc = Get-Content (Join-Path $script:RepoRoot 'docs' 'interpreting-results.md') -Raw
        $ids = InModuleScope M365EntraAudit { Get-AuditFindingCatalog }
        foreach ($id in $ids) { $doc | Should -Match ([regex]::Escape($id)) -Because "$id must be documented" }
    }
    It 'throws for an unknown id' {
        InModuleScope M365EntraAudit { { New-AuditFinding -Id 'NOPE-999' } | Should -Throw }
    }
}
