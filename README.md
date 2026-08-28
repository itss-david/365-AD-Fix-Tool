# 365-AD-Fix-Tool

A PowerShell tool that checks on-prem Active Directory users for attribute
errors that would block or corrupt sync to Microsoft 365 (Entra ID), and
verifies already-synced users' data against 365. Built as a replacement for
Microsoft's deprecated [IdFix tool](https://github.com/microsoft/idfix).

## Why

IdFix is deprecated and no longer maintained. This tool covers the same
core need — find AD objects that will fail directory sync, before they fail —
using the modern [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/powershell/microsoftgraph)
instead of the retired MSOnline/AzureAD modules, and is built so the rule
set is easy to extend without touching the engine code.

## Requirements

- Windows PowerShell 5.1+ (or PowerShell 7+)
- RSAT: Active Directory module (`ActiveDirectory`), run from a domain-joined
  machine with rights to read user objects
- For the 365 comparison (skip with `-SkipCloudCheck`):
  `Microsoft.Graph.Authentication` and `Microsoft.Graph.Users` modules, and
  an account with at least `Directory.Read.All` / `User.Read.All` (Global
  Reader is enough)
- Optional: run from the Entra Connect (Azure AD Connect) server itself,
  with the `ADSync` module present, so sync-scope OU filtering is detected
  automatically (see below)

```powershell
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser
Install-Module Microsoft.Graph.Users -Scope CurrentUser
```

## Quick start

```powershell
# Full run: AD attribute checks + comparison against synced 365 users
.\Start-ADFixTool.ps1

# AD checks only, scoped to one OU, no Graph sign-in required
.\Start-ADFixTool.ps1 -SkipCloudCheck -IncludedOU 'OU=Staff,DC=contoso,DC=com'
```

This writes a CSV and an HTML report to `.\Reports` and prints a
color-coded summary to the console. Nothing in Active Directory is ever
modified — this tool only reports.

## What it checks

Rules are defined declaratively in [`ADFixTool/Config/ADFixRules.psd1`](ADFixTool/Config/ADFixRules.psd1) —
no engine code needs to change to add, remove, or tune a check. Out of the
box:

| Attribute | Checks |
|---|---|
| `UserPrincipalName` | blank, unsupported characters, over Entra ID's length limit, duplicate across users |
| `mail` | not a valid SMTP address, too long, duplicate across users |
| `proxyAddresses` | bad `TYPE:` prefix, missing primary (`SMTP:`), more than one primary, value duplicated on another user |
| `DisplayName` / `GivenName` / `Surname` | too long, leading/trailing whitespace |

Plus, when the 365 comparison runs (`Compare-ADFix365Identity`):

- AD users with no matching synced 365 user (not yet synced, or blocked by
  another error)
- Synced 365 users with no matching AD user (stale/orphaned)
- `mail`, `proxyAddresses`, and enabled-state mismatches between AD and 365

### Sync-scope awareness

Errors on a user AD Connect isn't even configured to sync are noise, not
action items. `Get-ADFixSyncScope` tries to read the real OU
include/exclude list straight from Entra Connect's `ADSync` module (only
possible when run on the sync server); otherwise it falls back to
`-IncludedOU`/`-ExcludedOU` you supply. Every issue in the report carries an
`InSyncScope` column so you can filter to what actually matters.

## Extending it

- **Add/remove a check**: edit the `Rules` array in
  `ADFixTool/Config/ADFixRules.psd1`. Each entry names a `Check` function;
  point it at an existing one (`Test-ADFixBlankAttribute`,
  `Test-ADFixAttributeLength`, `Test-ADFixDuplicateValue`, etc.) or write a
  new `Test-ADFix*` function under `ADFixTool/Private/` with the signature
  `param($User, $Context, $Rule)` returning `$true` when the rule is
  violated.
- **Use your own rule catalog**: pass `-RulesConfigPath` to
  `Invoke-ADFixCheck` / `Start-ADFixTool.ps1` instead of editing the
  built-in file.
- **Script around it**: import the module directly
  (`Import-Module .\ADFixTool\ADFixTool.psd1`) and call its functions
  (`Get-ADFixDomainUser`, `Invoke-ADFixRuleSet`, `Compare-ADFix365Identity`,
  `Export-ADFixReport`, …) individually instead of the all-in-one
  `Invoke-ADFixCheck`.

## Layout

```
Start-ADFixTool.ps1          Convenience entry point
ADFixTool/
  ADFixTool.psd1/.psm1       Module manifest + loader
  Config/ADFixRules.psd1     Declarative rule catalog (edit this to change checks)
  Public/                    Get-ADFixDomainUser, Invoke-ADFixRuleSet, Get-ADFixSyncScope,
                              Connect-ADFix365Session, Get-ADFix365User,
                              Compare-ADFix365Identity, Export-ADFixReport, Invoke-ADFixCheck
  Private/                   Individual Test-ADFix* rule checks + shared helpers
```

## Versioning

Semantic versioning (`major.minor.patch`), tracked in
`ADFixTool/ADFixTool.psd1` (`ModuleVersion`) and `CHANGELOG.md`, starting
from `0.0.0`:

- **major** — large leaps in logic or flow
- **minor** — smaller logic changes (new checks, new behavior)
- **patch** — small fixes, renames, documentation

## Roadmap ideas

- Optional `-Fix` mode for safe, unambiguous corrections (trim whitespace,
  strip invalid characters) with `-WhatIf`/`-Confirm` support
- Soft-match/hard-match conflict detection against 365
- License/mailbox comparison post-sync
