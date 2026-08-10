## Why

This branch (`02-DEV/SalesPrice`) still carries all 26 Sales-Price objects at their original `51000-51049` IDs with the `SL` company prefix (e.g. `Table 51001 "SL Sales Price Checking"`, `PermissionSet SLChronWSAll`). A sibling branch (`03-FEAT/Sellwatch`, not yet merged) has already moved its own objects into a newly registered `60300-60349` range and adopted a single `CXW` prefix, replacing the inconsistent old naming. Both branches diverge from the same unmerged commit on `01-Master/master`, so bringing this branch's objects into the same convention now — before either branch merges — avoids a second, much more disruptive renumbering after the fact, and gives the whole app one consistent object/field prefix instead of two different company abbreviations (`SL` here, `CXW` there).

## What Changes

- Renumber all 26 Sales-Price objects (7 tables, 3 table extensions, 4 pages, 3 page extensions, 1 XMLport, 2 codeunits, 5 enums, 1 permission set) from `51000-51049` into `60311-60336` — the block immediately following the 11 objects `03-FEAT/Sellwatch` already claimed at `60300-60310` within the shared `60300-60349` range, so the two branches stay collision-free without either one needing rework later.
- Replace the `SL` prefix with `CXW` on every one of those 26 object names (e.g. `"SL Sales Price Checking"` → `"CXW Sales Price Checking"`, `SLChronWSAll` → `CXWChronWSAll`) — unlike the SellWatch rename (where `CXW` was prepended in front of a business term), `SL` and `CXW` play the same role here (company/app prefix), so replacing avoids a redundant double prefix like `"CXW SL Sales Price Checking"`.
- Prefix every field defined by those 26 objects with `CXW ` (all fields on the 7 tables and 2 of the 3 table extensions' custom fields, plus the 1-field `CXWCurrency` extension) — Captions stay unchanged, only the AL identifier changes.
- Renumber the 3 table extensions' custom field IDs from the `51000s` (with one legacy gap at `51005`) to a contiguous `60300+` block within each extension's own field-ID space, mirroring the `SellWatch` change's pattern.
- Update every internal reference across all 26 files and their consumers: `TableRelation`s, the CSV `XMLport`'s field mappings, both codeunits' business logic, all 7 pages' and 3 page extensions' field/action bindings, and the permission set's object list.
- **Not renamed:** the Isolated Storage key format string `'SLAPIInterfaceSetup_ApiKey_%1'` in `Table "SL/CXW API Interface Setup"` stays exactly as-is — it is stored *data* (the lookup key for an already-possibly-stored encrypted API key), not an AL identifier; renaming it would orphan any API key already saved under the old key format in any environment this has been deployed to.
- **Not touched:** the two stray `namespace SL...`/`namespace SLChronextWebshop.SLChronextWebshop` declarations (in `PermissionSets/SLChronWSAll.permissionset.al` and the `Currency`/`Currencies` extension pair) are an unrelated, pre-existing inconsistency (only 2 of 26 files use AL namespaces at all) — left untouched since namespaces are a module-organization concept, not the object/field naming this change targets.
- `app.json`'s `idRanges` gains a `60300-60349` entry alongside the existing `51000-51049` one (mirroring the `SellWatch` branch's `app.json`), since the compiler requires every object ID to fall inside a registered range and the old `51000-51049` entry alone would no longer cover the renumbered objects.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `sales-price-checking-writeback`: every identifier in the requirements (`"SL Sales Price Checking"`, `"SL Sales Price Archive"`, and the listed field names) is renamed; described behavior is unchanged.
- `sales-price-currency-copy`: every identifier in the requirements (`"SL Sales Price Checking"`, the listed field names, the `"Add all Currencies"` action's page) is renamed; described behavior is unchanged.

## Impact

- `src/Tables/Tab51000*.al` … `Tab51007*.al` (7 files): renumbered/renamed, all fields renamed, files renamed to match.
- `src/TableExtensions/TabExt51000*.al`, `TabExt51001*.al`, `TabExt51002*.al` (3 files): renumbered/renamed, custom fields renumbered/renamed.
- `src/Pages/Pag51000*.al` … `Pag51003*.al`, `XmlPort51000*.al` (5 files): renumbered/renamed, every field/action binding referencing a renamed field or `RunObject` referencing a renamed page updated.
- `src/PageExtensions/PagExt51000*.al` … `PagExt51002*.al` (3 files): renumbered/renamed, field bindings updated.
- `src/Codeunits/Codeunit51000*.al`, `Codeunit51001*.al` (2 files): renumbered/renamed; both contain extensive business logic referencing nearly every field on the 7 tables — every reference updated.
- `src/Enums/Enum51000*.al` … `Enum51004*.al` (5 files): renumbered/renamed; enum values untouched. Every table field typed as one of these enums needs its `Enum "..."` type reference updated to the new enum name.
- `src/PermissionSets/SLChronWSAll.permissionset.al`: renumbered/renamed, every `tabledata`/`table`/`page`/`codeunit`/`xmlport` entry updated.
- `app.json`: add the `60300-60349` idRange entry.
- `openspec/specs/sales-price-checking-writeback/spec.md`, `openspec/specs/sales-price-currency-copy/spec.md`: identifier references updated (delta specs in this change).
- Documentation (funktionsregister, developer/user/key-user manuals) and both translation files were out of scope for this proposal's file-by-file cataloguing given the size of this change (26 objects vs. 11 for SellWatch) — `tasks.md` schedules them as a dedicated regeneration/reconciliation pass at the end, the same way the `SellWatch` change handled them.
- No data migration/upgrade codeunit: per `app.json`'s version (`1.0.0.1`) and this branch's isolated dev status, treated the same as the `SellWatch` precedent — confirm with the user before implementing if any environment already has real data under the current `51000s` IDs (see design.md Open Questions).
