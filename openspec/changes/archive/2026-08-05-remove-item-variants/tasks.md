## 1. Tables

- [x] 1.1 `Tab51001.SLSalesPriceChecking.al`: remove field 2 `"Variant Code"` (and its `TableRelation`), change primary key to `"Item No.", "Currency Code"`.
- [x] 1.2 `Tab51002.SLSalesPriceArchive.al`: remove field 2 `"Variant Code"` (and its `TableRelation`), change primary key to `"Item No.", "Currency Code", "Country Code", "Version No."`.

## 2. Pages

- [x] 2.1 `Pag51001.SLSalesPriceCheckingList.al`: remove the `"Variant Code"` repeater column.
- [x] 2.2 `Pag51002.SLSalesPriceArchive.al`: remove the `"Variant Code"` repeater column.
- [x] 2.3 `Pag51001.SLSalesPriceCheckingList.al`, action `"Add all Currencies"`: drop `"Variant Code"` from the `Get`/`SetRange`/`SetFilter` calls used for duplicate detection (`g_recSalesPriceCheck2.Get(...)`) and remove the `"Variant Code"` assignment when building a new currency line.
- [x] 2.4 `Pag51001.SLSalesPriceCheckingList.al`, `fnValidate` and the "Upload Sales Price" action: drop `"Variant Code"` from `g_recSP.SetRange(...)` and `g_recILE.SetRange(...)` calls used for price/margin comparison.
- [x] 2.5 `Pag51001.SLSalesPriceCheckingList.al`: drop `"Variant Code"` from the `UpdateSalesPriceCheck.Get(...)` call in `"Add all Currencies"`.
- [x] 2.6 `Pag51001.SLSalesPriceCheckingList.al`: removed the unused `MissingCountryCodeErr` label — dead code (no callers) whose text referenced "variant" (found while doing 2.1-2.5).

## 3. Codeunit 51000 "SL Export Gateway Sales Price"

- [x] 3.1 `WriteBackAndArchive`: remove `"Variant Code"` from the `SalesPrice.Get(...)` call and the `Init` branch's field assignments — pass/assign `''` for that key segment on the standard `"Sales Price"` record instead of reading it from `SalesPriceChecking`.
- [x] 3.2 `ArchiveCheckingLine`: remove the `SetRange("Variant Code", ...)` filter from the version-number lookup.

## 4. XMLport 51000 "SL Import Sales Price"

- [x] 4.1 Remove the `fieldelement(VarCode; SalesPriceChecking."Variant Code")` block.
- [x] 4.2 Remove `"Variant Code"` from `SourceTableView`'s `sorting(...)` clause.

## 5. Codeunit 51001 "SL Import Sales Prices" (not yet live)

- [x] 5.1 `ProcessLine`: remove `case 2` (Variant Code) and renumber the remaining `case` indices down by one (3→2 through 10→9).
- [x] 5.2 `EvaluateHeaderRow`: remove `'Variant Code'` from `ExpectedValues` (column count and order must match the renumbered `ProcessLine`).
- [x] 5.3 `WriteSalesPrices`: remove `"Variant Code"` from the `SalesPrice.Get(...)` call and remove the `SalesPrice."Variant Code" := vSalesPriceTemp."Variant Code"` assignment.

## 6. Documentation

- [x] 6.1 `docs/user-manual-de.md` / `-en.md`: update the CSV column list under "CSV-Datei importieren" / "Import a CSV file" to drop the variant column and reflect the new column order.
- [x] 6.2 `docs/developer-manual-de.md` / `-en.md`: update references to the checking/archive table primary keys and the architecture diagram.
- [x] 6.3 `Translations/SL Chronext Webshop.de-DE.xlf`: removed the 3 trans-units orphaned by the field/label removals (2× "Variant Code" caption, 1× `MissingCountryCodeErr`); re-verified 208/208 units match `.g.xlf` with 0 missing/orphaned/mismatched. (Found while verifying — not explicitly listed above but a direct consequence of 1.1/1.2/2.6.)

## 7. Verification

- [x] 7.1 Compile the extension (`AL: Package`) and confirm no errors from the removed field/key changes across all affected objects. (Verified via `alc.exe`: 26 files, 0 errors, 1 pre-existing unrelated warning in Codeunit 51001.)
- [ ] 7.2 Manually run the full workflow (Import CSV → Validate → Approve → Add all Currencies → Upload Sales Price) against the new, variant-less CSV format and confirm no step references or requires a variant column.
- [ ] 7.3 If publishing to an environment with existing `"SL Sales Price Archive"` data, confirm the schema sync succeeds; if it fails on a primary-key collision, resolve per the mitigation in `design.md` (clear conflicting rows or write a one-off upgrade step) before retrying.
