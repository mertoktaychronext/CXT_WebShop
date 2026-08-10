## Why

Country-level differentiation of sales prices will no longer be used going forward, mirroring the just-completed removal of item variants. Both country-related fields this extension carries — `"Country Code"` on `"SL Sales Price Archive"` and the custom `"Country/Region Code"` field this extension adds to the standard `"Sales Price"` table — are already written blank by every live code path (`Codeunit 51000`'s `WriteBackAndArchive` always sets `"Country/Region Code"` and `"Country Code"` to `''`). They are dead weight: a key segment, a `TableRelation`, UI columns, and CSV-format columns that no longer reflect how prices are managed. Removing them simplifies the data model further and, as a side effect, fixes a pre-existing key mismatch in the not-yet-live CSV import path (see Impact).

## What Changes

- Remove the `"Country Code"` field from `"SL Sales Price Archive"` (Table 51002), including its `TableRelation` to `"Country/Region"`.
- **BREAKING**: Primary key of `"SL Sales Price Archive"` changes from `Item No., Currency Code, Country Code, Version No.` to `Item No., Currency Code, Version No.`.
- Remove the custom `"Country/Region Code"` field (ID 51005) that `TableExtension 51001 "SL Sales Price"` adds to the standard `"Sales Price"` table — this field is owned entirely by this extension (not a Microsoft base-app field), so it can be deleted outright rather than just left blank.
- Remove the `"Country Code"` column from `Page 51002 "SL Sales Price Archive"` and the `"Country/Region Code"` column from `Page Extension 51001 "SL Sales Prices"`.
- Remove the now-pointless `"Country Code"`/`"Country/Region Code"` blanking logic in `Codeunit 51000 "SL Export Gateway Sales Price"` (`WriteBackAndArchive`, `ArchiveCheckingLine`) — there is nothing left to blank once the fields don't exist.
- **BREAKING**: Remove the `"Country/Region Code"` column from `Codeunit 51001 "SL Import Sales Prices"`'s not-yet-live CSV format (`ProcessLine`, `EvaluateHeaderRow`), renumbering the remaining columns. As a side effect, this removes the extra, non-key-matching `"Country/Region Code"` argument that `WriteSalesPrices`'s `SalesPrice.Get(...)` call currently passes — a pre-existing mismatch against the standard table's real primary key, already flagged in the developer manual's "Known Limitations" — so this call becomes correct as part of this change rather than needing a separate fix.
- `TableExtension 51000 "SL Country Region"` (adds `"Taxation Type"`, `"Delivery Time"`, `"Sales Price Currency Code"` to `Country/Region`) is **out of scope** — those are informational country/region attributes unrelated to the `"Country Code"`/`"Country/Region Code"` fields being removed here, and stay untouched.
- Update the CSV column documentation in the developer manual's "Known Limitations" (the SalesPrice.Get mismatch note becomes resolved) and Table Overview.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `sales-price-checking-writeback`: the "Sales Price write-back before export" requirement's "Country/Region Code is left blank" scenario is removed (nothing to blank once the field doesn't exist); the "Sales Price Archive snapshot before export" requirement's "Archive row reflects checking line data" scenario drops the "'Country Code' is blank" clause for the same reason.

## Impact

- `src/Tables/Tab51002.SLSalesPriceArchive.al`: field removal, primary key change (second PK reduction on this table after `remove-item-variants`).
- `src/Pages/Pag51002.SLSalesPriceArchive.al`: remove the "Country Code" column.
- `src/TableExtensions/TabExt51001.SLSalesPrice.al`: remove the `"Country/Region Code"` field entirely (this extension owns it).
- `src/PageExtensions/PagExt51001.SLSalesPrices.al`: remove the "Country/Region Code" column.
- `src/Codeunits/Codeunit51000.SLExportGatewaySalesPrice.al`: `WriteBackAndArchive`/`UpdateSalesPriceFields`/`ArchiveCheckingLine` no longer reference either field.
- `src/Codeunits/Codeunit51001.SLImportSalesPrices.al` (not yet wired into any live process): drop the `Country/Region Code` CSV column from `ProcessLine`/`EvaluateHeaderRow`, renumber remaining columns; `WriteSalesPrices`'s `SalesPrice.Get(...)` call loses its extra, previously-mismatched argument.
- `docs/developer-manual-de.md` / `-en.md`: update the Table Overview (Table 51002's key) and resolve two "Known Limitations" entries (the `SalesPrice.Get` key mismatch, and Table 51002's "still carries its own country code" note) that this change fixes outright.
- No data migration is planned for existing rows in `"SL Sales Price Archive"` — same accepted-risk policy as `remove-item-variants` (that change's stakeholder answer was "unsure/not relevant, just remove it"); since `"Country Code"` has been written blank by every row inserted since `Codeunit 51000` went live, a collision on the reduced key is very unlikely in practice, more so than the variant case.
