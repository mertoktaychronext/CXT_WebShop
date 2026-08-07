## Why

The "Upload Sales Price" action on Page 51001 "SL Sales Price Checking List" only looks up an already-existing "Sales Price" record to export — it never writes the approved checking data into "Sales Price" itself, and "SL Sales Price Archive" is currently never populated at all. Approved price changes therefore have no reliable path into the live "Sales Price" table, and lines without a pre-existing matching record are silently skipped during export ("without a matching sales price"). This closes that gap so an approved, uploaded price is guaranteed to exist in "Sales Price" and to have a versioned history entry in the archive.

## What Changes

- Before the outbound file/JSON is generated for a line, the "Upload Sales Price" action writes the corresponding "SL Sales Price Checking" line into the standard "Sales Price" table (insert if no record exists for the key, otherwise update the existing one).
- The "Sales Type" on the written/updated "Sales Price" record is always set to `All Customers`; "Sales Code" is left blank accordingly.
- "Stock Price" is written to the standard "Unit Price" field on "Sales Price".
- "Country/Region Code" on the written "Sales Price" record is left blank, since "SL Sales Price Checking" no longer carries a country code after the currency migration.
- Immediately after writing "Sales Price", the same checking line is archived into "SL Sales Price Archive" as a new row, with "Version No." incremented (per Item No./Variant Code/Currency Code combination) rather than left at its current, unused default.
- This write-back happens for every checking line that reaches the export step (i.e. every line actually attempted in "Upload Sales Price"), so a re-upload of an already-sent line also produces a new archive version.
- **BREAKING**: Lines that previously had no matching "Sales Price" record and were silently skipped during export are now written to "Sales Price" and included in the export instead of being skipped.

## Capabilities

### New Capabilities
- `sales-price-checking-writeback`: Writing approved "SL Sales Price Checking" lines into "Sales Price" and archiving them into "SL Sales Price Archive" (with incrementing version number) as part of the "Upload Sales Price" export step.

### Modified Capabilities
- None. `sales-price-currency-copy` (the "Add all Currencies" action) is unaffected.

## Impact

- `src/Pages/Pag51001.SLSalesPriceCheckingList.al`: "Upload Sales Price" action gains the write-to-"Sales Price"/archive step before calling `CreateExternalInterfaceFile`; the existing `FindFirst`-then-skip lookup is replaced by an insert-or-update.
- `src/Codeunits/Codeunit51000.SLExportGatewaySalesPrice.al` (or a new procedure alongside it): candidate home for the write-back logic so it stays reusable and testable outside the page.
- `src/Tables/Tab51002.SLSalesPriceArchive.al`: becomes an actively written table; no schema change expected, but its "currently read-only" status (per `docs/developer-manual-*.md`) needs updating.
- Standard table "Sales Price" (via `src/TableExtensions/TabExt51001.SLSalesPrice.al`): more records will be inserted/updated than before, including ones with no prior matching entry.
- `docs/developer-manual-en.md` / `docs/developer-manual-de.md`: the "Known Limitations" entry stating approved prices aren't carried over automatically becomes outdated and should be revisited once implemented.
