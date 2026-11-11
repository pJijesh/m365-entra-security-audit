BeforeAll {
    . (Join-Path $PSScriptRoot 'TestSupport.ps1')
    Import-AuditModuleForTest
    $script:AsOf = [datetime]'2026-06-01'
}

Describe 'Get-StaleAccounts' {
    BeforeAll {
        Mock -ModuleName M365EntraAudit Get-AuditUser { $global:AuditTestData.TestUsers }
        Mock -ModuleName M365EntraAudit Get-AuditSubscribedSku { @([pscustomobject]@{ SkuId = 'sku-e3'; SkuPartNumber = 'SPE_E3' }) }
        $users = @(
            (New-TestUser -Name 'Active' -Upn 'active@northwind.example' -LastSignIn $script:AsOf.AddDays(-3) -Skus 'sku-e3')
            (New-TestUser -Name 'Stale' -Upn 'stale@northwind.example' -LastSignIn $script:AsOf.AddDays(-200) -Skus 'sku-e3')
            (New-TestUser -Name 'Boundary' -Upn 'boundary@northwind.example' -LastSignIn $script:AsOf.AddDays(-90))
            (New-TestUser -Name 'Never' -Upn 'never@northwind.example' -Created $script:AsOf.AddDays(-300) -LastSignIn $null)
            (New-TestUser -Name 'NewJoiner' -Upn 'new@northwind.example' -Created $script:AsOf.AddDays(-5) -LastSignIn $null)
            (New-TestUser -Name 'Leaver' -Upn 'leaver@northwind.example' -Enabled $false -LastSignIn $script:AsOf.AddDays(-400) -Skus 'sku-e3')
            (New-TestUser -Name 'DisabledNoLicence' -Upn 'dnl@northwind.example' -Enabled $false -LastSignIn $script:AsOf.AddDays(-400))
            (New-TestUser -Name 'Emergency' -Upn 'emergency@northwind.example' -LastSignIn $script:AsOf.AddDays(-500))
            (New-TestUser -Name 'Guest' -Upn 'guest_fabrikam.example#EXT#@northwind.example' -UserType 'Guest' -LastSignIn $script:AsOf.AddDays(-500))
        )
        Set-AuditTestData -Name TestUsers -Value $users
    }

    It 'reports enabled members with no sign-in beyond the threshold' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf -ExcludeUserPrincipalName 'emergency@northwind.example'
        ($r.Records | Where-Object Category -eq 'No recent sign-in').UserPrincipalName | Should -Be 'stale@northwind.example'
    }
    It 'does not report an account exactly on the threshold' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf
        $r.Records.UserPrincipalName | Should -Not -Contain 'boundary@northwind.example'
    }
    It 'reports never-signed-in accounts only once they are older than the threshold' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf
        ($r.Records | Where-Object Category -eq 'Never signed in').UserPrincipalName | Should -Be 'never@northwind.example'
    }
    It 'reports disabled accounts only when they still hold a licence' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf
        ($r.Records | Where-Object Category -eq 'Disabled but licensed').UserPrincipalName | Should -Be 'leaver@northwind.example'
    }
    It 'translates licence ids into product names' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf
        ($r.Records | Where-Object UserPrincipalName -eq 'stale@northwind.example').Licences | Should -Contain 'SPE_E3'
    }
    It 'leaves guests to Get-GuestUsers' {
        (Get-StaleAccounts -AsOf $script:AsOf).Records.UserPrincipalName | Should -Not -Contain 'guest_fabrikam.example#EXT#@northwind.example'
    }
    It 'honours the exclusion list' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf -ExcludeUserPrincipalName 'emergency@northwind.example'
        $r.Records.UserPrincipalName | Should -Not -Contain 'emergency@northwind.example'
    }
    It 'raises one finding per category' {
        $r = Get-StaleAccounts -InactiveDays 90 -AsOf $script:AsOf -ExcludeUserPrincipalName 'emergency@northwind.example'
        $r.Findings.Id | Should -Be 'STALE-001', 'STALE-002', 'STALE-003'
    }
    It 'changes results when the threshold changes' {
        $r = Get-StaleAccounts -InactiveDays 300 -AsOf $script:AsOf
        ($r.Records | Where-Object Category -eq 'No recent sign-in').UserPrincipalName | Should -Be 'emergency@northwind.example'
    }
    It 'still works when licence names cannot be read' {
        Mock -ModuleName M365EntraAudit Get-AuditSubscribedSku { throw 'Insufficient privileges' }
        $r = Get-StaleAccounts -AsOf $script:AsOf 3>$null
        ($r.Records | Where-Object UserPrincipalName -eq 'stale@northwind.example').Licences | Should -Contain 'sku-e3'
    }
}
