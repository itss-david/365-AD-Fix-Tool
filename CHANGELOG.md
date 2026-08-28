# Changelog

Versioning: `major.minor.patch`, starting at `0.0.0`. Major = large leaps in
logic/flow, minor = smaller logic changes, patch = small fixes/renames/docs.

## 0.1.1

- Fix: `Invoke-ADFixCheck` no longer aborts the entire run (losing the
  already-computed AD-side results) when the Microsoft 365 comparison step
  fails - e.g. the Microsoft.Graph modules aren't installed, or sign-in is
  cancelled. The failure is now logged as a warning and the report is still
  written from whatever AD checks (and any cloud checks that did complete)
  succeeded. Reported after a real run surfaced this on a box without the
  Graph modules installed.

## 0.1.0

Initial build of the ADFixTool module.

- Data-driven rule catalog (`ADFixTool/Config/ADFixRules.psd1`) covering
  IdFix-parity checks: blank/invalid/duplicate/too-long `UserPrincipalName`
  and `mail`, `proxyAddresses` format/primary/duplicate checks, and
  name-attribute whitespace/length checks.
- `Get-ADFixDomainUser` for scoped AD user retrieval.
- `Get-ADFixSyncScope` for Entra Connect OU-filtering awareness (reads the
  `ADSync` module when run on the sync server, falls back to manual
  `-IncludedOU`/`-ExcludedOU`).
- `Invoke-ADFixRuleSet` rule engine running the catalog against AD users.
- `Connect-ADFix365Session`, `Get-ADFix365User`, `Compare-ADFix365Identity`
  for comparing synced users against Microsoft 365 via Microsoft Graph.
- `Export-ADFixReport` for CSV + HTML report output.
- `Invoke-ADFixCheck` end-to-end orchestrator and `Start-ADFixTool.ps1`
  convenience entry point.
