# Contributing

Thank you for taking an interest. Issues and pull requests are welcome.

## Ground rules

- **Keep it read-only.** Do not add a cmdlet or HTTP call that changes a tenant, and do not request a `ReadWrite` scope. The tests enforce this.
- **Keep Graph calls in one place.** New `Get-Mg*` calls belong in `src/M365EntraAudit/Private/30-GraphData.ps1`, and any new scope must be added to `docs/permissions.md` with a reason.
- **Use synthetic data only.** Test and demo data must use reserved example domains such as `northwind.example`. Never commit real tenant data, user names or organisation names. A hygiene test checks this.
- **Document new findings.** A finding needs an entry in the catalogue (`20-FindingCatalog.ps1`) and an explanation in `docs/interpreting-results.md`. The tests check both.
- **British English, plain tone, no dashes as punctuation.** Use commas, colons or full stops instead.

## Before you open a pull request

Use PowerShell 7 with Pester 5 and PSScriptAnalyzer installed:

```powershell
./tools/Invoke-Lint.ps1
Invoke-Pester -Path ./tests -Output Detailed
```

If you change the report, regenerate the sample with `./tools/New-SampleReport.ps1` (the screenshot step needs Python with Playwright; use `-SkipScreenshot` to skip it).

Please describe what you tested, and say plainly if you could not test against a live tenant.
