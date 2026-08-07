## Why

Item variants will no longer be used going forward — sales prices are now managed per item and currency only, never per variant. Carrying "Variant Code" through the checking table, the archive, the CSV import formats, and every lookup keyed on it is dead weight that adds a key segment, a TableRelation, and matching logic that no longer reflects how the business works. Removing it simplifies the data model (one checking/archive row per item+currency instead of per item+variant+currency) and removes a source of accidental complexity from every action that touches these tables.

## What Changes

- Remove the `"Variant Code"` field from `"SL Sales Price Checking"` (Table 51001) and `"SL Sales Price Archive"` (Table 51002), including their `TableRelation` to `"Item Variant"`.
- **BREAKING**: Primary key of `"SL Sales Price Checking"` changes from `Item No., Variant Code, Currency Code` to `Item No., Currency Code`. Primary key of `"SL Sales Price Archive"` changes from `Item No., Variant Code, Currency Code, Country Code, Version No.` to `Item No., Currency Code, Country Code, Version No.`.
- Remove the `"Variant Code"` column from `Page 51001 "SL Sales Price Checking List"` and `Page 51002 "SL Sales Price Archive"`.
- Remove all `"Variant Code"`-keyed lookups and comparisons in `Page 51001`'s actions ("Add all Currencies", "Validate", price comparison against `"Item Ledger Entry"`) and in `Codeunit 51000 "SL Export Gateway Sales Price"` (`WriteBackAndArchive`, `ArchiveCheckingLine`).
- **BREAKING**: Remove the `VarCode` column from the `"SL Import Sales Price"` XMLport's CSV format (Xmlport 51000) and from `Codeunit 51001 "SL Import Sales Prices"`'s file-based CSV format — both formats lose a column and all following columns shift position by one.
- Standard table `"Sales Price"` itself keeps its own `"Variant Code"` field (it's a Microsoft base-app field, not owned by this extension) — this extension simply stops populating it, always writing/matching it blank, meaning every price this extension manages applies to the item as a whole.
- Update the CSV column documentation in the user manual to match the new, shorter column layout.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `sales-price-checking-writeback`: the "Sales Price write-back" and "Sales Price Archive snapshot" requirements currently describe matching/versioning by "Item No./Variant Code/Currency Code" combination — this changes to "Item No./Currency Code" now that variant is no longer part of the model.

## Impact

- `src/Tables/Tab51001.SLSalesPriceChecking.al`, `src/Tables/Tab51002.SLSalesPriceArchive.al`: field removal, primary key change.
- `src/Pages/Pag51001.SLSalesPriceCheckingList.al`, `src/Pages/Pag51002.SLSalesPriceArchive.al`: remove the "Variant Code" column.
- `src/Pages/XmlPort51000.SLImportSalesPrice.al`: remove the `VarCode` field element and drop it from `SourceTableView` sorting; CSV format changes (breaking for any already-prepared import files).
- `src/Codeunits/Codeunit51000.SLExportGatewaySalesPrice.al`: `WriteBackAndArchive` and `ArchiveCheckingLine` no longer read/pass "Variant Code" — the standard `"Sales Price"` record they write is always saved with a blank `"Variant Code"`.
- `src/Codeunits/Codeunit51001.SLImportSalesPrices.al` (not yet wired into any live process): drop the `Variant Code` CSV column from `ProcessLine`/`EvaluateHeaderRow`, renumber remaining columns; `WriteSalesPrices` always resolves/writes a blank `"Variant Code"` on `"Sales Price"`.
- `docs/user-manual-de.md` / `-en.md`: CSV column list needs updating (loses the variant column, remaining columns renumber).
- `docs/developer-manual-de.md` / `-en.md`, `docs/funktionsregister/*`, `docs/SCHWACHSTELLEN.md` (mentions of "Variantencode" in findings N4/W4): become stale and should be revisited, though not part of this change's core scope.
- No data migration is planned for existing rows in `"SL Sales Price Archive"` that may have distinct `"Variant Code"` values under what will become a colliding key (Item No./Currency Code/Country Code/Version No.) — accepted risk per stakeholder decision; see design.md.
