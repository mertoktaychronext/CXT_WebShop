## Context

`Codeunit 51002 "SellWatch Mgt"` was migrated from a NAV export (see `src/Codeunits/Codeunit51002.SellWatchMgt.al`). Two of its field references target fields that don't exist on the standard `Purchase Line` and `Purchase Header` tables in this app — the NAV objects that originally added them were never exported:

- `PLRec."Used good"` (write) — commented out during migration with a `// TODO`.
- `PurchaseHeader."Tracking Number"` (read, in `CreateSourceFilePurchaseRequest`, and in the `Tracking Number` FlowField on `Table 51008 "SellWatch Vendor Info"`) — missed during the original migration since no AL compiler was available at the time to catch it.

Equivalent gaps also exist on `Vendor` (`Street`) and `Vendor Bank Account` (`akq IBAN / SWIFT approved`), surfaced during the same review. The user has confirmed those two are **not needed** — they stay out of scope, and the corresponding commented-out lines in `SellWatch Mgt` are left as-is.

The existing table extension pattern in this project (`src/TableExtensions/TabExt51000.SLCountryRegion.al` etc.) extends one base table per file, uses `Caption`/`DataClassification` on every field, and numbers extension objects and their fields sequentially within the registered `51000-51049` range.

## Goals / Non-Goals

**Goals:**
- Add the two fields SellWatch Mgt / SellWatch Vendor Info actually need: `Used good` (Purchase Line), `Tracking Number` (Purchase Header).
- Re-enable the one matching field assignment in SellWatch Mgt (`PLRec."Used good"`) so purchase order creation writes this value again.
- Keep field names and types faithful to what the original NAV code implies.

**Non-Goals:**
- `Vendor.Street` and `Vendor Bank Account."akq IBAN / SWIFT approved"` — confirmed not needed; no table extension for `Vendor` or `Vendor Bank Account` is created by this change.
- Reimplementing `Vendor.SetPostingGroups()` or `Vendor.GetnewNoSeries()`. No source for either procedure was ever delivered; inventing that business logic is out of scope. Their call sites stay commented with the existing TODO.
- Any data backfill for existing records — these are new, empty fields on tables that already contain data; no historical values exist to migrate.

## Decisions

- **Table extension, not a new table**: The fields must be reachable through the `Purchase Line` and `Purchase Header` record variables already used in `SellWatch Mgt`, so a table extension is the only fit (matches Teilaufgabe 1 of the NAV→BC migration rules: standard-table fields in the customer id range become table extensions, never edits to the base table).
- **One table extension per base table**: `TabExt51003.SWPurchaseLine.al` and `TabExt51004.SWPurchaseHeader.al` — mirrors the existing `SL ...` extensions (one file/object per extended base table).
- **Field types**:
  - `Used good` on Purchase Line: `Boolean`, matching its use as a flag (`:= TRUE`) in the original source, next to the existing standard `Differential Taxation` field it's used alongside.
  - `Tracking Number` on Purchase Header: `Text[30]`, matching the length of the `Tracking Number` FlowField already declared on `SellWatch Vendor Info` (`Table 51008`), whose `CalcFormula` looks this field up.
- **Field IDs**: 51000 within each new extension (scoped per base table, so no collision across the two new extensions or with the existing `SL ...` extensions on different base tables).
- **Naming kept 1:1 with the NAV source** (`Used good`, `Tracking Number`) rather than normalized to AL casing conventions, so that if the real originating NAV objects are ever recovered, this can be diffed/reconciled by name instead of guessed at again.

## Risks / Trade-offs

- [Field name casing doesn't match AL naming conventions ("Used good")] → Mitigation: intentional, documented above; flagged for a follow-up rename once (if ever) the original source object is recovered.
- [Guessed field length for `Tracking Number` may not match a future recovered source] → Mitigation: additive-only field with `ToBeClassified` data classification, chosen to match the already-existing FlowField length; widening a `Text` field length later is a non-breaking change.
- [`Vendor.Street` / `Vendor Bank Account."akq IBAN / SWIFT approved"` stay unresolved] → Not a risk for this change since explicitly out of scope; the corresponding `SellWatch Mgt` lines remain commented with their existing TODOs.

## Open Questions

- None outstanding for this change now that Vendor / Vendor Bank Account are confirmed out of scope. `Vendor.SetPostingGroups()` / `Vendor.GetnewNoSeries()` remain a known gap tracked via the existing TODOs in `SellWatch Mgt`, not by this change.
