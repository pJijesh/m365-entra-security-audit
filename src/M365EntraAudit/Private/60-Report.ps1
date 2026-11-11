function Get-AuditReportCss {
    @'
:root{--bg:#f5f6f8;--surface:#fff;--text:#1b2430;--muted:#5b6675;--line:#dfe3ea;--accent:#2b4c7e;--accent-soft:#e8eef7;
--high:#b3261e;--high-bg:#fdeceb;--med:#8a5a00;--med-bg:#fff3d6;--low:#1f5f99;--low-bg:#e3f0fb;--info:#4a5563;--info-bg:#eceff3;--ok:#1d6b3a;--ok-bg:#e2f4e8;--bar:#2b4c7e;--track:#e3e7ee}
@media (prefers-color-scheme:dark){:root{--bg:#10151c;--surface:#171e28;--text:#e6eaf0;--muted:#9aa6b6;--line:#2a3441;--accent:#8fb4ee;--accent-soft:#1e2b40;
--high:#ff9b94;--high-bg:#3a1c1b;--med:#f3c566;--med-bg:#37290d;--low:#8cc4f5;--low-bg:#162a3d;--info:#b4bfce;--info-bg:#232c39;--ok:#7fd7a0;--ok-bg:#16301f;--bar:#8fb4ee;--track:#2a3441}}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font:15px/1.55 system-ui,-apple-system,"Segoe UI",Roboto,Helvetica,Arial,sans-serif}
.wrap{max-width:1080px;margin:0 auto;padding:0 16px 48px}
header.top{background:var(--accent);color:#fff;padding:28px 0 24px;margin-bottom:24px}
header.top .wrap{padding-bottom:0}
header.top h1{margin:0 0 4px;font-size:1.6rem;font-weight:650;letter-spacing:-.01em}
header.top p{margin:0;opacity:.9}
.meta{display:flex;flex-wrap:wrap;gap:8px 20px;margin-top:14px;font-size:.85rem;opacity:.92}
.badge{display:inline-block;border-radius:999px;padding:2px 10px;font-size:.78rem;font-weight:600}
.badge.demo{background:#ffe08a;color:#4a3500}
.badge.live{background:#d3f0dc;color:#14502a}
h2{font-size:1.2rem;margin:36px 0 12px;padding-bottom:6px;border-bottom:2px solid var(--line)}
h3{font-size:1rem;margin:20px 0 8px}
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px}
.card{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:14px 16px}
.card .n{font-size:1.9rem;font-weight:700;line-height:1.1}
.card .l{color:var(--muted);font-size:.82rem;margin-top:4px}
.card.sev-High .n{color:var(--high)}.card.sev-Medium .n{color:var(--med)}.card.sev-Low .n{color:var(--low)}.card.sev-Info .n{color:var(--info)}
.note{background:var(--accent-soft);border-left:4px solid var(--accent);padding:10px 14px;border-radius:6px;margin:14px 0;font-size:.9rem}
.sev{display:inline-block;min-width:64px;text-align:center;border-radius:6px;padding:1px 8px;font-size:.76rem;font-weight:700;text-transform:uppercase;letter-spacing:.03em}
.sev.High{background:var(--high-bg);color:var(--high)}.sev.Medium{background:var(--med-bg);color:var(--med)}
.sev.Low{background:var(--low-bg);color:var(--low)}.sev.Info{background:var(--info-bg);color:var(--info)}
.pass{background:var(--ok-bg);color:var(--ok)}.fail{background:var(--high-bg);color:var(--high)}
.pill{display:inline-block;border-radius:6px;padding:1px 8px;font-size:.76rem;font-weight:700}
article.finding{background:var(--surface);border:1px solid var(--line);border-left-width:5px;border-radius:8px;padding:14px 16px;margin:12px 0}
article.finding.High{border-left-color:var(--high)}article.finding.Medium{border-left-color:var(--med)}
article.finding.Low{border-left-color:var(--low)}article.finding.Info{border-left-color:var(--info)}
article.finding h3{margin:6px 0 4px}
.fid{color:var(--muted);font-size:.8rem;margin-left:8px;font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace}
.cnt{color:var(--muted);font-size:.85rem;margin-left:8px}
.detail{margin:4px 0 8px}
.fix{margin:8px 0}
.fix b,.maps b{font-size:.8rem;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
details.maps{margin-top:8px;font-size:.88rem}
details.maps summary{cursor:pointer;color:var(--accent);font-weight:600}
details.maps dl{margin:8px 0 0;display:grid;grid-template-columns:150px 1fr;gap:6px 14px}
details.maps dt{font-weight:600;color:var(--muted)}details.maps dd{margin:0}
.tablewrap{overflow-x:auto;background:var(--surface);border:1px solid var(--line);border-radius:8px}
table{border-collapse:collapse;width:100%;font-size:.86rem}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid var(--line);vertical-align:top}
th{background:var(--accent-soft);font-weight:650;white-space:nowrap}
tr:last-child td{border-bottom:0}
td.num{text-align:right;font-variant-numeric:tabular-nums}
.bar{height:14px;background:var(--track);border-radius:7px;overflow:hidden;margin:6px 0}
.bar>span{display:block;height:100%;background:var(--bar)}
.kv{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:6px 24px;margin:10px 0}
.kv div{display:flex;justify-content:space-between;border-bottom:1px dotted var(--line);padding:3px 0}
.kv span:first-child{color:var(--muted)}
.small{font-size:.82rem;color:var(--muted)}
.nowrap{white-space:nowrap}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;font-size:.82rem}
footer{margin-top:40px;font-size:.82rem;color:var(--muted);border-top:1px solid var(--line);padding-top:14px}
@media (max-width:600px){details.maps dl{grid-template-columns:1fr}header.top h1{font-size:1.3rem}}
@media print{body{background:#fff}header.top{background:#fff;color:#000;border-bottom:2px solid #000}details.maps{display:block}.card,article.finding{break-inside:avoid}}
'@
}

function ConvertTo-HtmlTable {
    <#
    .SYNOPSIS
        Builds an HTML table from records. Every value is HTML-encoded.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Record,
        [Parameter(Mandatory)][hashtable[]]$Column,   # @{ Header=''; Property=''; Class=''; Format=scriptblock }
        [int]$MaxRows = 40
    )

    if (@($Record).Count -eq 0) { return '<p class="small">No records.</p>' }

    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('<div class="tablewrap"><table><thead><tr>')
    foreach ($c in $Column) { [void]$sb.Append("<th>$(ConvertTo-HtmlSafe $c.Header)</th>") }
    [void]$sb.Append('</tr></thead><tbody>')
    foreach ($r in @($Record | Select-Object -First $MaxRows)) {
        [void]$sb.Append('<tr>')
        foreach ($c in $Column) {
            $v = $r.($c.Property)
            if ($c.Format) { $v = & $c.Format $v $r }
            elseif ($v -is [datetime]) { $v = Format-AuditDate $v }
            elseif ($v -is [System.Collections.IEnumerable] -and $v -isnot [string]) { $v = (@($v) | ForEach-Object { [string]$_ }) -join ', ' }
            $cls = if ($c.Class) { " class=`"$($c.Class)`"" } else { '' }
            [void]$sb.Append("<td$cls>$(ConvertTo-HtmlSafe $v)</td>")
        }
        [void]$sb.Append('</tr>')
    }
    [void]$sb.Append('</tbody></table></div>')
    if (@($Record).Count -gt $MaxRows) {
        [void]$sb.Append("<p class=`"small`">Showing $MaxRows of $(@($Record).Count) rows. The CSV file has every row.</p>")
    }
    return $sb.ToString()
}

function New-AuditHtmlReport {
    <#
    .SYNOPSIS
        Renders audit results as one self-contained HTML file (inline CSS, no scripts, no external requests).
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Private helper that writes one report file to a path the caller chose.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Audit,
        [Parameter(Mandatory)][string]$Path,
        [int]$MaxRows = 40
    )

    $e = { param($v) ConvertTo-HtmlSafe $v }
    $sb = New-Object System.Text.StringBuilder
    $add = { param($s) [void]$sb.AppendLine($s) }

    $findings = @($Audit.Findings)
    $bySeverity = @{ High = 0; Medium = 0; Low = 0; Info = 0 }
    foreach ($f in $findings) { $bySeverity[$f.Severity]++ }

    $modeBadge = if ($Audit.DemoMode) { '<span class="badge demo">DEMO: synthetic data</span>' } else { '<span class="badge live">Live tenant data</span>' }
    $title = 'Microsoft 365 and Entra ID security audit'

    & $add '<!DOCTYPE html>'
    & $add '<html lang="en-GB"><head><meta charset="utf-8">'
    & $add '<meta name="viewport" content="width=device-width, initial-scale=1">'
    & $add "<title>$(& $e $title)</title>"
    & $add "<style>$(Get-AuditReportCss)</style></head><body>"
    & $add '<header class="top"><div class="wrap">'
    & $add "<h1>$(& $e $title)</h1>"
    & $add '<p>Read-only review of identity configuration: MFA, stale accounts, privileged roles, guests and Conditional Access.</p>'
    & $add "<div class=`"meta`"><span>$modeBadge</span><span>Tenant: $(& $e $Audit.Tenant)</span><span>Generated: $(& $e $Audit.GeneratedAt.ToString('yyyy-MM-dd HH:mm')) (UTC$(& $e $Audit.GeneratedAt.ToString('zzz')))</span><span>M365EntraAudit $(& $e $Audit.ToolVersion)</span></div>"
    & $add '</div></header><main class="wrap">'

    if ($Audit.DemoMode) {
        & $add '<div class="note"><b>Demo report.</b> Every user, domain and policy in this report is synthetic, generated for illustration around the fictional organisation Northwind Traders (northwind.example). It does not describe a real tenant.</div>'
    }

    # ---- Executive summary ----
    & $add '<h2>Summary</h2><div class="cards">'
    foreach ($sev in 'High', 'Medium', 'Low', 'Info') {
        & $add "<div class=`"card sev-$sev`"><div class=`"n`">$($bySeverity[$sev])</div><div class=`"l`">$sev findings</div></div>"
    }
    & $add '</div>'

    $mfa = $Audit.Areas['MFA']; $stale = $Audit.Areas['Stale accounts']; $priv = $Audit.Areas['Privileged roles']
    $guest = $Audit.Areas['Guest users']; $ca = $Audit.Areas['Conditional Access']
    & $add '<div class="cards" style="margin-top:12px">'
    if ($mfa) { & $add "<div class=`"card`"><div class=`"n`">$(& $e $mfa.Summary.MembersCoveragePercent)%</div><div class=`"l`">Members with an MFA method registered</div></div>" ; & $add "<div class=`"card`"><div class=`"n`">$(& $e $mfa.Summary.AdministratorsWithoutMfa)</div><div class=`"l`">Administrators without MFA</div></div>" }
    if ($stale) { & $add "<div class=`"card`"><div class=`"n`">$(& $e ($stale.Summary.NoRecentSignIn + $stale.Summary.NeverSignedIn))</div><div class=`"l`">Enabled members inactive or never used</div></div>" }
    if ($priv) { & $add "<div class=`"card`"><div class=`"n`">$(& $e $priv.Summary.GlobalAdministratorsPermanent)</div><div class=`"l`">Permanent Global Administrators (excl. emergency)</div></div>" }
    if ($guest) { & $add "<div class=`"card`"><div class=`"n`">$(& $e $guest.Summary.TotalGuests)</div><div class=`"l`">Guest accounts</div></div>" }
    if ($ca) { & $add "<div class=`"card`"><div class=`"n`">$(& $e $ca.Summary.ChecksPassed)/$(& $e $ca.Summary.ChecksTotal)</div><div class=`"l`">Conditional Access checks passed</div></div>" }
    & $add '</div>'

    if (@($Audit.Errors).Count -gt 0) {
        & $add '<div class="note"><b>Not fully assessed.</b><ul>'
        foreach ($err in $Audit.Errors) { & $add "<li>$(& $e $err.Area): $(& $e $err.Message)</li>" }
        & $add '</ul>The areas above were skipped or partial. Check the Graph scopes and licences listed in docs/permissions.md.</div>'
    }

    # ---- Findings ----
    & $add '<h2>Findings</h2>'
    & $add '<p class="small">Sorted by severity. Severity is a triage default, not a risk score. Adjust it to your own context.</p>'
    if ($findings.Count -eq 0) { & $add '<p>No findings were raised by these checks.</p>' }
    foreach ($f in $findings) {
        & $add "<article class=`"finding $(& $e $f.Severity)`">"
        & $add "<div><span class=`"sev $(& $e $f.Severity)`">$(& $e $f.Severity)</span><span class=`"fid`">$(& $e $f.Id)</span><span class=`"cnt`">$(& $e $f.Area)$(if ($f.AffectedCount -gt 0) { " &middot; $($f.AffectedCount) affected" })</span></div>"
        & $add "<h3>$(& $e $f.Title)</h3>"
        if ($f.Detail) { & $add "<p class=`"detail`">$(& $e $f.Detail)</p>" }
        & $add "<p class=`"fix`"><b>What to do</b><br>$(& $e $f.Remediation)</p>"
        & $add '<details class="maps"><summary>How this maps to common frameworks</summary><dl>'
        & $add "<dt>Zero Trust</dt><dd>$(& $e $f.ZeroTrust)</dd>"
        & $add "<dt>Cyber Essentials</dt><dd>$(& $e $f.CyberEssentials)</dd>"
        & $add "<dt>CIS-style control</dt><dd>$(& $e $f.CisStyle)</dd>"
        & $add '</dl></details></article>'
    }

    # ---- MFA ----
    if ($mfa) {
        $s = $mfa.Summary
        & $add '<h2>MFA coverage</h2>'
        & $add "<div class=`"bar`" role=`"img`" aria-label=`"$(& $e $s.MembersCoveragePercent) percent of members covered`"><span style=`"width:$([math]::Min(100,[double]$s.MembersCoveragePercent))%`"></span></div>"
        & $add "<p>$(& $e $s.MembersWithMfa) of $(& $e $s.Members) member users have at least one MFA method registered ($(& $e $s.MembersCoveragePercent)%).</p>"
        & $add "<div class=`"kv`"><div><span>Users in the report</span><span>$(& $e $s.UsersInReport)</span></div><div><span>Guests in the report</span><span>$(& $e $s.Guests)</span></div><div><span>Administrators</span><span>$(& $e $s.Administrators)</span></div><div><span>Administrators without MFA</span><span>$(& $e $s.AdministratorsWithoutMfa)</span></div><div><span>Members without MFA (non-admin)</span><span>$(& $e $s.MembersWithoutMfa)</span></div><div><span>Phone-only MFA</span><span>$(& $e $s.PhoneOnlyUsers)</span></div><div><span>Passwordless-capable</span><span>$(& $e $s.PasswordlessCapable)</span></div></div>"
        & $add '<h3>Users needing attention</h3>'
        $exposed = @($mfa.Records | Where-Object { $_.Status -ne 'Strong' } | Sort-Object @{ Expression = { -not $_.IsAdmin } }, Status, DisplayName)
        & $add (ConvertTo-HtmlTable -Record $exposed -MaxRows $MaxRows -Column @(
                @{ Header = 'Name'; Property = 'DisplayName' }, @{ Header = 'User principal name'; Property = 'UserPrincipalName'; Class = 'mono' },
                @{ Header = 'Type'; Property = 'UserType' }, @{ Header = 'Admin'; Property = 'IsAdmin'; Format = { param($v) if ($v) { 'Yes' } else { '' } } },
                @{ Header = 'Status'; Property = 'Status' }, @{ Header = 'Methods'; Property = 'MethodsRegistered' }))
        & $add '<p class="small">The Graph registration report does not include disabled users.</p>'
    }

    # ---- Stale accounts ----
    if ($stale) {
        $s = $stale.Summary
        & $add "<h2>Stale accounts</h2><p class=`"small`">Threshold: no sign-in for more than $(& $e $s.InactiveDaysThreshold) days. $(& $e $s.MembersChecked) member accounts checked.</p>"
        & $add "<div class=`"kv`"><div><span>No recent sign-in</span><span>$(& $e $s.NoRecentSignIn)</span></div><div><span>Never signed in</span><span>$(& $e $s.NeverSignedIn)</span></div><div><span>Disabled but licensed</span><span>$(& $e $s.DisabledButLicensed)</span></div><div><span>Flagged accounts holding a licence</span><span>$(& $e $s.InactiveAccountsHoldingLicences)</span></div></div>"
        & $add (ConvertTo-HtmlTable -Record @($stale.Records) -MaxRows $MaxRows -Column @(
                @{ Header = 'Name'; Property = 'DisplayName' }, @{ Header = 'User principal name'; Property = 'UserPrincipalName'; Class = 'mono' },
                @{ Header = 'Category'; Property = 'Category' }, @{ Header = 'Last sign-in'; Property = 'LastSignIn'; Format = { param($v) if ($v) { Format-AuditDate $v } else { 'None recorded' } } },
                @{ Header = 'Days'; Property = 'DaysSinceSignIn'; Class = 'num' }, @{ Header = 'Licences'; Property = 'Licences' }))
    }

    # ---- Privileged roles ----
    if ($priv) {
        $s = $priv.Summary
        & $add '<h2>Privileged role holders</h2>'
        & $add "<div class=`"kv`"><div><span>Global Administrators (distinct users)</span><span>$(& $e $s.GlobalAdministratorsTotal)</span></div><div><span>Permanent (excl. emergency accounts)</span><span>$(& $e $s.GlobalAdministratorsPermanent)</span></div><div><span>Eligible only through PIM</span><span>$(& $e $s.GlobalAdministratorsEligibleOnly)</span></div><div><span>Users with standing high privilege</span><span>$(& $e $s.UsersWithStandingHighPrivilege)</span></div><div><span>Groups holding roles</span><span>$(& $e $s.GroupsHoldingRoles)</span></div><div><span>Applications holding roles</span><span>$(& $e $s.ServicePrincipalsHoldingRoles)</span></div><div><span>PIM data available</span><span>$(if ($s.PimAvailable) { 'Yes' } else { 'No' })</span></div></div>"
        $shown = @($priv.Records | Where-Object { $_.IsHighPrivilege })
        & $add (ConvertTo-HtmlTable -Record $shown -MaxRows $MaxRows -Column @(
                @{ Header = 'Role'; Property = 'Role' }, @{ Header = 'Holder'; Property = 'DisplayName' },
                @{ Header = 'Type'; Property = 'PrincipalType'; Format = { param($v, $r) if ($r.IsGuest) { "$v (guest)" } else { $v } } },
                @{ Header = 'How held'; Property = 'AssignmentType' },
                @{ Header = 'Via group'; Property = 'ViaGroup' },
                @{ Header = 'Note'; Property = 'IsEmergencyAccount'; Format = { param($v, $r) $n = @(); if ($v) { $n += 'Emergency account' }; if ($r.AccountEnabled -eq $false) { $n += 'Disabled' }; $n -join ', ' } }))
        & $add '<p class="small">High-privilege roles only. The CSV lists every directory role assignment.</p>'
    }

    # ---- Guests ----
    if ($guest) {
        $s = $guest.Summary
        & $add "<h2>Guest users</h2><p class=`"small`">Stale after $(& $e $s.StaleDaysThreshold) days without sign-in; invitations overdue after $(& $e $s.PendingDaysThreshold) days.</p>"
        & $add "<div class=`"kv`"><div><span>Total guests</span><span>$(& $e $s.TotalGuests)</span></div><div><span>Active</span><span>$(& $e $s.Active)</span></div><div><span>Stale</span><span>$(& $e $s.Stale)</span></div><div><span>No sign-in recorded</span><span>$(& $e $s.NoSignInRecorded)</span></div><div><span>Pending invitations</span><span>$(& $e $s.PendingInvitations)</span></div><div><span>Overdue invitations</span><span>$(& $e $s.PendingOverdue)</span></div></div>"
        & $add "<p class=`"small`">Top source domains: $(& $e $s.TopSourceDomains)</p>"
        $attention = @($guest.Records | Where-Object { $_.Status -ne 'Active' } | Sort-Object Status, @{ Expression = { $_.AgeDays }; Descending = $true })
        & $add (ConvertTo-HtmlTable -Record $attention -MaxRows $MaxRows -Column @(
                @{ Header = 'Name'; Property = 'DisplayName' }, @{ Header = 'Mail'; Property = 'Mail'; Class = 'mono' },
                @{ Header = 'Status'; Property = 'Status' }, @{ Header = 'Invited'; Property = 'Created' },
                @{ Header = 'Age (days)'; Property = 'AgeDays'; Class = 'num' },
                @{ Header = 'Last sign-in'; Property = 'LastSignIn'; Format = { param($v) if ($v) { Format-AuditDate $v } else { 'None recorded' } } }))
    }

    # ---- Conditional Access ----
    if ($ca) {
        $s = $ca.Summary
        & $add '<h2>Conditional Access</h2>'
        & $add "<p>$(& $e $s.PolicyCount) policies: $(& $e $s.Enforced) enforced, $(& $e $s.ReportOnly) report-only, $(& $e $s.Disabled) disabled.</p>"
        & $add '<h3>Baseline checks</h3>'
        & $add (ConvertTo-HtmlTable -Record @($ca.Checks) -MaxRows 20 -Column @(
                @{ Header = 'Check'; Property = 'Id'; Class = 'mono nowrap' }, @{ Header = 'What is checked'; Property = 'Name' },
                @{ Header = 'Result'; Property = 'Passed'; Format = { param($v) if ($v) { 'Pass' } else { 'Gap' } } },
                @{ Header = 'Detail'; Property = 'Detail' }))
        & $add '<h3>Policies</h3>'
        & $add (ConvertTo-HtmlTable -Record @($ca.Records) -MaxRows $MaxRows -Column @(
                @{ Header = 'Policy'; Property = 'DisplayName' }, @{ Header = 'State'; Property = 'State' },
                @{ Header = 'Users'; Property = 'Users' }, @{ Header = 'Apps'; Property = 'Applications' },
                @{ Header = 'Grant'; Property = 'Grant' }, @{ Header = 'Exclusions'; Property = 'Exclusions'; Class = 'num' }))
        & $add '<p class="small">These checks read policy settings. They do not simulate sign-ins. Use the What If tool in Entra to test specific scenarios.</p>'
    }

    # ---- Footer ----
    & $add '<footer><p><b>Read-only.</b> This tool only reads from Microsoft Graph. It makes no changes to your tenant, and this file was created locally. Nothing was sent anywhere by the module.</p>'
    & $add "<p>Scopes requested: <span class=`"mono`">$(& $e (($script:RequiredScopes.Keys) -join ', '))</span></p>"
    & $add '<p>Limitations: signInActivity needs Entra ID P1 or P2 and can be empty for accounts with no recorded sign-in; the MFA registration report excludes disabled users; PIM data needs Entra ID P2 or Governance; Conditional Access checks are heuristics. See docs/interpreting-results.md.</p></footer>'
    & $add '</main></body></html>'

    Set-Content -LiteralPath $Path -Value $sb.ToString() -Encoding utf8
    return $Path
}
