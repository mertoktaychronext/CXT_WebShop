## Why

`app.json`'s registered `idRanges` entry was already changed on this branch from `51000-51049` to `60300-60349`, but the eleven AL objects the SellWatch feature added on this branch (3 tables, 2 table extensions, 1 codeunit, 1 enum, 3 pages, 1 permission set) still use IDs in the old `51000-51049` block and mix two different informal name prefixes (`SW`, `SellWatch`, or none at all — e.g. `Codeunit 51002 "SellWatch Mgt"`, `Table 51010 "SW Http Call Log"`, `Table 51009 "Watch Online Approval"`). None of this has shipped yet (the branch isn't merged and carries no production data under these IDs), so this is the last point where renumbering and renaming is free of any upgrade-codeunit or data-migration cost. Fixing it now — before merge — avoids doing it later against live data and gives the feature a single, consistent `CXW` object/field prefix instead of the current ad-hoc mix.

## What Changes

- Renumber all 11 new SellWatch objects from the `51000s` into the registered `60300-60349` idRange (60300-60310 used, see design.md for the full old-ID → new-ID table).
- Rename every one of those 11 object identifiers to start with `CXW ` (e.g. `"SellWatch Mgt"` → `"CXW SellWatch Mgt"`, `"SW Http Call Log"` → `"CXW SW Http Call Log"`).
- Rename every field identifier introduced by those objects — all fields on the 3 new tables (`CXW SellWatch Vendor Info`, `CXW Watch Online Approval`, `CXW SW Http Call Log`) and the 2 fields added via table extension (`CXW Used good` on `Purchase Line`, `CXW Tracking Number` on `Purchase Header`) — to start with `CXW `. Field `Caption`s (the user-facing labels) are left unchanged; only the AL identifier changes.
- Renumber the 2 table-extension fields from field ID `51000` to `60300` (each field ID is scoped to its own extension's field-ID space, so both extensions independently reuse `60300`), mirroring the new base idRange the way the original `51000` mirrored the old one.
- Update every internal reference to the renamed objects/fields: `CalcFormula`, `TableRelation`, permission set entries, page field bindings, and every field/record reference inside `Codeunit "CXW SellWatch Mgt"` and `Table "CXW Watch Online Approval"`.
- Regenerate the funktionsregister, developer/user/key-user manuals (DE/EN), and `docs/README.md` so they reflect the new IDs and names, and regenerate the translation files (`.g.xlf`, then reconcile `de-DE.xlf`) so translation units point at the renamed objects/fields.
- No upgrade codeunit, no data migration: these objects don't exist in any deployed environment yet.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `sellwatch-standard-table-extensions`: the identifiers named in the requirements (`Codeunit "SellWatch Mgt"`, `Used good`, `Tracking Number`, `SellWatch Vendor Info`) are renamed; the described behavior is unchanged.
- `sellwatch-http-call-logging`: the identifiers named in the requirements (`Watch Online Approval`) are renamed; the described behavior is unchanged.

## Impact

- `app.json`: idRange already updated (no further change needed).
- `src/Tables/Tab51008.SellWatchVendorInfo.al`, `Tab51009.WatchOnlineApproval.al`, `Tab51010.SWHttpCallLog.al`: renumbered + renamed, all fields renamed. Files will be renamed to match new IDs/names.
- `src/TableExtensions/TabExt51003.SWPurchaseLine.al`, `TabExt51004.SWPurchaseHeader.al`: renumbered + renamed, extension field renumbered/renamed.
- `src/Codeunits/Codeunit51002.SellWatchMgt.al`: renumbered + renamed; every reference to the renamed tables/fields updated.
- `src/Enums/Enum51006.SWOrderStatus.al`: renumbered + renamed (enum values untouched).
- `src/Pages/Pag51004.SellWatchOverview.al`, `Pag51005.SellWatchInfo.al`, `Pag51006.SWHttpCallLog.al`: renumbered + renamed; every field binding updated to the new field names.
- `src/PermissionSets/SWChronWSAll.permissionset.al`: renumbered + renamed; every `tabledata`/`table`/`codeunit`/`page` entry updated to the new object names.
- `docs/developer-manual-de.md`, `-en.md`, `docs/key-user-manual-de.md`, `-en.md`, `docs/user-manual-de.md`, `-en.md`, `docs/README.md`, `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`, `docs/funktionsregister/gesamtuebersicht.md`: object/field names and IDs updated.
- `Translations/CHX.Webshop.g.xlf`, `Translations/CHX.Webshop.de-DE.xlf`: regenerated/reconciled against the renamed objects and fields.
- `openspec/specs/sellwatch-standard-table-extensions/spec.md`, `openspec/specs/sellwatch-http-call-logging/spec.md`: identifier references updated (delta specs in this change).
