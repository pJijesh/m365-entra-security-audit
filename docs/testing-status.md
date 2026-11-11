# Testing status

This page states exactly what has been run, what was found, and what has not been verified. It describes version 0.1.0.

## What was run

Environment: Linux, PowerShell 7.4.6 (Core).

| Check | Command | Result |
| --- | --- | --- |
| Unit and integration tests | `Invoke-Pester -Configuration $config` with `Run.Path = ./tests`, Pester 5.7.1 | 85 tests, 85 passed, 0 failed, 0 skipped |
| Static analysis | `./tools/Invoke-Lint.ps1` (PSScriptAnalyzer 1.25.0, `Error` and `Warning` severities, settings in `PSScriptAnalyzerSettings.psd1`) | No findings |
| Tests without the Graph SDK | Same Pester run with only Pester and PSScriptAnalyzer on the module path | 85 passed. The tests do not need Microsoft.Graph installed, which matches the CI job. |
| Demo report | `Invoke-SecurityAudit -DemoMode` | Completed. 17 findings (4 High, 5 Medium, 8 Low), HTML report, CSV files and Conditional Access JSON written. |
| Sample report | `./tools/New-SampleReport.ps1` | `docs/sample-report.html` and `docs/sample-report.png` regenerated. The screenshot was viewed and renders correctly. |
| Graph SDK surface | Microsoft.Graph 2.41.2 installed from the PowerShell Gallery. Every `Get-Mg*` cmdlet and parameter the module uses was confirmed with `Get-Command`, and the model properties it reads (`SignInActivity`, `UserRegistrationDetails`, role schedule instances) were confirmed by reflection. | All present |
| Text hygiene | `tests/Hygiene.Tests.ps1`, part of the Pester run | Passed. It also failed as expected when a probe file with a forbidden term, a dash and a non-example address was added, then the probe was removed. |

The tests cover: read-only guarantees (no write cmdlets, no write HTTP methods, no `ReadWrite` scope), the finding catalogue and its documentation, MFA, stale account, guest, privileged role and Conditional Access logic, CSV formula-injection protection, report HTML encoding, and the full `Invoke-SecurityAudit` flow in demo mode and against mocked Graph data.

The linter excludes two rules for the `tests` folder only (`PSAvoidGlobalVars` and `PSUseShouldProcessForStateChangingFunctions`), because the tests share fixtures with mock bodies through one global variable and use `New-` helper names. The module and tools are checked with every rule.

## What was not run

- **No live tenant.** Nothing has been executed against a real Microsoft 365 tenant or the real Microsoft Graph service. Real response shapes, paging, throttling, large-tenant performance and licence-dependent behaviour are unverified. In particular, the mapping of real Conditional Access policy objects (via `ToJsonString()`) has only been exercised with hand-built policy JSON.
- **The GitHub Actions workflow has not been executed.** The workflow file parses as valid YAML and runs the same two commands as above, but it has not run on GitHub. The CI badge will show a result only after the first push.
- **Other platforms and versions.** Only PowerShell 7.4.6 on Linux was used. The manifest declares 7.2 as the minimum, which has not been tested. Windows and macOS were not tested.
- **Pester 6.** Pester 6.2.0 was present on the build machine but was not used. CI pins Pester 5.
- **Microsoft Learn permissions.** The mapping of endpoint to least-privileged permission in `docs/permissions.md` was not re-checked against Microsoft Learn in the final pass. Confirm it before relying on it.
- **App-only authentication.** Not tested.
- **Screenshot tooling on other machines.** `tools/capture_screenshot.py` was run with Playwright and Chromium on Linux only.
