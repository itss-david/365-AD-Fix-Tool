# Changelog

Versioning: `major.minor.patch`, starting at `0.0.0`. Major = large leaps in
logic/flow, minor = smaller logic changes, patch = small fixes/renames/docs.

## 0.1.2

- Fix: `Compare-ADFix365Identity` threw a parameter-binding error on every real
  run (`Cannot convert ... System.Guid ... to ... System.Byte[]`).
  `Get-ADUser`'s `ObjectGUID` property is a `[System.Guid]`, not a raw
  `byte[]`; `Convert-ADFixImmutableId` now accepts either type.
- Fix: that same function used `switch ($SourceAnchor) { { $_ -is [byte[]] } ... }`
  to branch on the anchor's type, but PowerShell's `switch` iterates over
  array *elements* when given an array subject, so the byte-array branch
  never matched its own type check. Replaced with a plain `if`/`elseif`.
- Fix: `New-ADFixIssueRecord`'s mandatory `SamAccountName`/`DistinguishedName`
  parameters rejected an empty string, which broke the
  `Sync-OrphanedCloudUser` case (a synced 365 user with no matching AD
  object, so there's no on-prem DN to report). Both now allow empty/null.
- All three were caught running the real comparison path against a live
  tenant/domain rather than only synthetic unit-style objects.

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
