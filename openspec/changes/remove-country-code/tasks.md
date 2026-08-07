## 1. Table 51002 "SL Sales Price Archive"

- [x] 1.1 Remove field 14 `"Country Code"` (and its `TableRelation`), change primary key to `"Item No.", "Currency Code", "Version No."`.

## 2. Table Extension 51001 "SL Sales Price" (extends standard "Sales Price")

- [x] 2.1 Remove field 51005 `"Country/Region Code"` entirely — this field is owned by this extension, not a base-app field.

## 3. Pages

- [x] 3.1 `Pag51002.SLSalesPriceArchive.al`: remove the `"Country Code"` repeater column.
- [x] 3.2 `PagExt51001.SLSalesPrices.al`: remove the `"Country/Region Code"` field display.

## 4. Codeunit 51000 "SL Export Gateway Sales Price"

- [x] 4.1 `UpdateSalesPriceFields`: remove the `vSalesPrice.Validate("Country/Region Code", '')` line.
- [x] 4.2 `ArchiveCheckingLine`: remove the `SetRange("Country Code", '')` filter and the `l_recSalesPriceArchive."Country Code" := ''` assignment.

## 5. Codeunit 51001 "SL Import Sales Prices" (not yet live)

- [x] 5.1 `ProcessLine`: remove the `Country/Region Code` case and renumber the remaining `case` indices down by one.
- [x] 5.2 `EvaluateHeaderRow`: remove `'Country_Region Code'` from `ExpectedValues` (column count and order must match the renumbered `ProcessLine`).
- [x] 5.3 `WriteSalesPrices`: remove `vSalesPriceTemp."Country/Region Code"` from the `SalesPrice.Get(...)` call and remove the `SalesPrice.Validate("Country/Region Code", vSalesPriceTemp."Country/Region Code")` line. Refined beyond the original plan: rather than leaving the `Get(...)` call at a shorter argument count (which empirically still compiled — AL's generated `Get()` accepts a positional prefix of the primary key, confirmed during this task), the call now passes all 8 real primary-key segments explicitly, with `''` for "Variant Code", so the fix doesn't rely on that under-documented compiler behavior.

## 6. Documentation

- [x] 6.1 `docs/developer-manual-de.md` / `-en.md`: updated the Table Overview entry for Table 51002 (dropped "+ Country Code" from the key description) and resolved the two "Known Limitations" entries this change fixes (the `SalesPrice.Get` key mismatch in Codeunit 51001, and Table 51002 "still carries its own country code").

## 7. Verification

- [x] 7.1 Compile the extension (`AL: Package`) and confirm no errors from the removed field/key changes across all affected objects. (Verified via `alc.exe`: 26 files, 0 errors, 1 pre-existing unrelated warning in Codeunit 51001.)
- [x] 7.2 Re-sync `Translations/SL Chronext Webshop.de-DE.xlf` against the regenerated `.g.xlf` (removed 3 trans-units orphaned by the removed field captions/columns; re-verified 205/205 units match with 0 missing/orphaned/mismatched).
- [x] 7.3 Manually run the full workflow (Import CSV → Validate → Approve → Add all Currencies → Upload Sales Price) and confirm no step references or requires a country code, and that the exported "Sales Price" JSON no longer contains a "Country/Region Code" field.
- [x] 7.4 If publishing to an environment with existing `"SL Sales Price Archive"` data, confirm the schema sync succeeds; if it fails on a primary-key collision, resolve per the mitigation in `design.md` before retrying.
