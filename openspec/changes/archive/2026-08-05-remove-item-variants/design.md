## Context

"Variant Code" currently appears in seven files, in two distinct roles:

1. **Owned fields** on `Table 51001 "SL Sales Price Checking"` and `Table 51002 "SL Sales Price Archive"` — part of each table's primary key, with a `TableRelation` to `"Item Variant"`.
2. **Pass-through references** to the standard `Table 7002 "Sales Price"`'s own `"Variant Code"` field (which this extension cannot remove — it's a Microsoft base-app field), in `Codeunit 51000 "SL Export Gateway Sales Price"` and `Codeunit 51001 "SL Import Sales Prices"`.

`Table 51001` is fully transient in practice — `Page 51001`'s `OnOpenPage` trigger calls `Rec.DeleteAll()` on every open, so it never holds data across sessions. `Table 51002` is the opposite: since `sales-price-checking-writeback` (previous change), every "Upload Sales Price" run inserts a permanent, versioned row into it. This asymmetry matters for the primary-key change below.

## Goals / Non-Goals

**Goals:**
- Remove `"Variant Code"` as an owned field from `Table 51001` and `Table 51002`, including their `TableRelation` and primary-key membership.
- Remove every UI column, lookup, and comparison in this extension's own code that is keyed on that field.
- Reduce the primary keys accordingly: `Table 51001` → `Item No., Currency Code`; `Table 51002` → `Item No., Currency Code, Country Code, Version No.`.
- Keep the CSV import formats (`Xmlport 51000`, and the not-yet-live `Codeunit 51001` file format) consistent with the new, variant-less checking model — drop the variant column from both, not just one.

**Non-Goals:**
- Removing `"Variant Code"` from the standard `"Sales Price"` table itself — not possible (base-app field) and not required; this extension simply always writes/matches it blank going forward, meaning every price applies to the item as a whole rather than to a specific variant.
- Data migration or an upgrade codeunit for existing `"SL Sales Price Archive"` rows — explicitly out of scope per stakeholder decision (see Risks).
- Any change to `sales-price-currency-copy` ("Add all Currencies") — its spec text describes behavior in terms of currency/country only and never names "Variant Code", so no spec-level change is needed there even though the implementation currently threads the field through its per-line uniqueness check.

## Decisions

### Field removal, not just hiding
Delete the `"Variant Code"` field block outright from `Tab51001` and `Tab51002` (not `ObsoleteState`/`Enabled = false`) — this is a PTE with no AppSource compatibility constraint, and the field is genuinely unused going forward, not being phased out gradually.

**Alternative considered**: mark obsolete instead of deleting, per the AppSource-safe pattern (`managing-appsource-compliance`). Rejected — that pattern exists to avoid breaking installed dependents of a *published* app; this extension has no dependents and no AppSource requirement, so the simpler, cleaner deletion is preferred over carrying dead `ObsoleteReason` fields indefinitely.

### Primary key reduction
`Table 51001` key becomes `Item No., Currency Code`. `Table 51002` key becomes `Item No., Currency Code, Country Code, Version No.`. Every `Get()`/`SetRange()` call currently including `"Variant Code"` drops that argument/filter:
- `Page 51001`, action `"Add all Currencies"`: `g_recSalesPriceCheck2.Get(Item No., Variant Code, Currency Code)` → `Get(Item No., Currency Code)`; the assignment `g_recSalesPriceCheck2."Variant Code" := ...` is deleted.
- `Page 51001`, action `"Upload Sales Price"` support code and `fnValidate`: `g_recSP.SetRange("Variant Code", ...)` and `g_recILE.SetRange("Variant Code", ...)` are deleted — the margin/price comparison now matches on Item No. (+ Currency Code / Starting Date where already filtered) alone.
- `Page 51001`, `UpdateSalesPriceCheck.Get(Item No., Variant Code, Currency Code)` → `Get(Item No., Currency Code)`.
- `Codeunit 51000`, `WriteBackAndArchive`: the `SalesPrice.Get(...)` call and the `Init` branch drop the `"Variant Code"` argument/assignment entirely — since the standard `"Sales Price"` table's own key still has a `"Variant Code"` segment, the call passes `''` explicitly for that slot (not sourced from `SalesPriceChecking` anymore, since the field no longer exists there).
- `Codeunit 51000`, `ArchiveCheckingLine`: drops `l_recSalesPriceArchive.SetRange("Variant Code", ...)` from the version-lookup filter.

### CSV format changes (both import paths)
- `Xmlport 51000 "SL Import Sales Price"`: remove the `fieldelement(VarCode; SalesPriceChecking."Variant Code")` block entirely and drop `"Variant Code"` from `SourceTableView`'s `sorting(...)` clause. The CSV column order becomes: Item No., Stock Price, Strike Price, Recom. Retail Price, Currency Code, Reason Code, Comment (was: Item No., **Variant Code**, Stock Price, ...).
- `Codeunit 51001 "SL Import Sales Prices"` (file-based, not live): remove case `2` (`Variant Code`) from `ProcessLine`, remove `'Variant Code'` from `EvaluateHeaderRow`'s `ExpectedValues`, and renumber every subsequent `case` index down by one (Sales Type 3→2, Sales Code 4→3, Currency Code 5→4, Country/Region Code 6→5, Unit Price 7→6, Price Includes VAT 8→7, Strike-Price 9→8, Recom. Retail Price 10→9). In `WriteSalesPrices`, the `SalesPrice.Get(...)` call and the `SalesPrice."Variant Code" := vSalesPriceTemp."Variant Code"` assignment are removed — `vSalesPriceTemp."Variant Code"` is never populated after this change, so passing/assigning it was already reducible to a blank literal; removing it outright avoids leaving a dead reference to a concept this extension no longer models.

**Alternative considered**: keep the CSV column position but leave it unread (skip index 2, don't map it to anything). Rejected — the proposal says "remove all fields and corresponding references," and a column nobody reads is exactly the kind of leftover complexity this change is meant to eliminate; an empty/ignored column would also permanently confuse anyone maintaining the CSV template later.

### Spec delta on `sales-price-checking-writeback`
Two requirements from the previous change describe matching/versioning by "Item No./Variant Code/Currency Code" combination. Both get a `MODIFIED Requirements` delta replacing that phrase with "Item No./Currency Code" throughout (see `specs/sales-price-checking-writeback/spec.md` in this change). No other capability needs a delta.

## Risks / Trade-offs

- **[Risk]** `Table 51002 "SL Sales Price Archive"` already holds real historical rows (populated automatically since the previous change shipped). If any existing rows share the same Item No./Currency Code/Country Code/Version No. but differ only by the now-removed `"Variant Code"`, the schema sync will fail on publish with a duplicate-primary-key error, or (if BC allows the sync but two rows silently collapse) historical data could be silently lost → **Mitigation**: none implemented — explicitly accepted per stakeholder decision (asked directly: "is there existing archive data with distinct variants that could collide" → answered "unsure/not relevant, just remove it"). If publish fails in practice, the concrete fix at that point is either clearing `"SL Sales Price Archive"` before publishing, or writing a short upgrade codeunit to deduplicate colliding rows first (`generating-bc-upgrade-codeunits` skill covers the pattern) — deferred rather than built speculatively.
- **[Risk]** The CSV column layout change is breaking for any already-prepared import file (manual CSV via `Xmlport 51000`, or files already staged for the not-yet-live `Codeunit 51001` path) → **Mitigation**: `docs/user-manual-*.md` gets its column list updated as part of this change so the next prepared file matches; no in-flight files are known to exist since Table 51001 is wiped on every page open.
- **[Trade-off]** Standard `"Sales Price"` records written by this extension are always variant-blank now, even though the base table still supports per-variant pricing. If a future requirement needs per-variant prices again, that capability has to be rebuilt from scratch (schema and all) rather than re-enabled — accepted, since the proposal states variants are not coming back ("zukünftig keine Varianten mehr gebraucht").

## Migration Plan

Code-only change plus a primary-key reduction on two extension-owned tables. No upgrade codeunit is included (see Risk above — deferred). Deploy via normal AL publish; if publish is rejected due to a data conflict on `Table 51002`, resolve per the mitigation above before retrying. Rollback is a straight revert of the affected files — since no upgrade codeunit runs, there's no forward-only data transformation to undo.

## Open Questions

None outstanding — the archive-data-collision question was resolved directly with the stakeholder before writing this design (risk accepted, no migration built).
