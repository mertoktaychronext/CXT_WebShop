## Context

`Page 51001 "SL Sales Price Checking List"`, action `"Upload Sales Price"`, currently:

1. Finds "SL Sales Price Checking" lines with `"Accept New Setup" = true`.
2. For each, does `l_recSP.SetRange("Item No."/"Variant Code"/"Currency Code")` on the standard `"Sales Price"` table and `FindFirst()`.
3. If found, calls `Codeunit 51000 "SL Export Gateway Sales Price".CreateExternalInterfaceFile(l_recSP)`, which reflects over every field of the given `"Sales Price"` record, builds a JSON object, stores it in `"SL Sales Price Outbound File"`, and POSTs it via the API interface configured on `"SL General Sales Price Setup"`.
4. Sets `"Export Status"` to `Sent`/`Error` on the checking line.

`"Sales Price"` is never written by this flow, and `"SL Sales Price Archive"` (Table 51002) is never written by anything — both are documented gaps (`docs/developer-manual-en.md`, "Known Limitations"). A separate, not-live CSV import path (`Codeunit 51001 "SL Import Sales Prices"`) does write `"Sales Price"` using the standard `"Unit Price"` field and an insert-or-modify pattern keyed on `Item No. / Sales Type / Sales Code / Starting Date / Currency Code / Country/Region Code / Variant Code / Unit of Measure Code / Minimum Quantity` — that pattern is reused here for consistency.

The extension adds these fields to `"Sales Price"` via `TabExt51001.SLSalesPrice.al`: `"Reason Code"`, `Comment`, `Remark`, `"Recom. Retail Price incl. VAT"`, `"Strike-Price incl. VAT"`, `"Country/Region Code"`, `"Unit Price (LCY)"`, `"Unit Price (LCY) incl. VAT"`.

## Goals / Non-Goals

**Goals:**
- Every "SL Sales Price Checking" line that the "Upload Sales Price" action attempts to export first gets written into `"Sales Price"` (insert or update), so the export is no longer dependent on a pre-existing record.
- Every such line also gets a new, versioned snapshot row in `"SL Sales Price Archive"`.
- `"Sales Type"` on the written `"Sales Price"` record is always `All Customers`.
- `"Stock Price"` is written to the standard `"Unit Price"` field (per stakeholder decision — keeps this flow aligned with the CSV import path rather than the page-local `"Unit Price (LCY)"` field).
- `"Country/Region Code"` is left blank (per stakeholder decision — a price with `"Sales Type" = All Customers` and no currency-specific country applies to every country using that currency, consistent with the `sales-price-currency-copy` capability).

**Non-Goals:**
- No change to `"Add all Currencies"`, `"Validate"`, or `"Approve"` actions.
- No change to the CSV-based import path (`Codeunit 51001`, not live).
- `"Non Stock Price"` has no equivalent field on `"Sales Price"` and is out of scope — it is not written back or archived beyond what `"SL Sales Price Archive"` already stores as a snapshot field.
- No change to the outbound JSON shape produced by `CreateExternalInterfaceFile` — it still reflects over whatever fields exist on the `"Sales Price"` record passed in.
- No retroactive backfill of `"Sales Price"` or archive rows for lines uploaded before this change.

## Decisions

### Where the write-back logic lives
New public procedure `WriteBackAndArchive` on `Codeunit 51000 "SL Export Gateway Sales Price"`, taking the `"SL Sales Price Checking"` line and returning the `"Sales Price"` record to export:

```al
procedure WriteBackAndArchive(SalesPriceChecking: Record "SL Sales Price Checking"; var SalesPrice: Record "Sales Price")
```

Called from the `"Upload Sales Price"` action's loop, immediately before `CreateExternalInterfaceFile`, replacing the current `l_recSP.SetRange(...); l_recSP.FindFirst()` lookup-and-skip.

**Alternative considered**: inline the logic in the page action. Rejected — the codeunit already owns "turn a checking-adjacent record into an exported Sales Price", keeping the page thin and the logic reachable for a future test codeunit.

### Sales Price key resolution (insert vs. update)
The standard "Sales Price" table's primary key (verified against the downloaded symbols in `.alpackages/Microsoft_Base Application_*.app`, table 7002) is `Item No., Sales Type, Sales Code, Starting Date, Currency Code, Variant Code, Unit of Measure Code, Minimum Quantity` — it does **not** include `"Country/Region Code"` (that field, added by `TabExt51001.SLSalesPrice.al`, is a plain non-key field). `Codeunit 51001 "SL Import Sales Prices"` calls `SalesPrice.Get(...)` with `"Country/Region Code"` as an extra argument, which does not match this key; that pre-existing mismatch is out of scope here (see Non-Goals) and is not reused.

`WriteBackAndArchive` therefore calls `SalesPrice.Get(Item No., "Sales Type"::"All Customers", '', Starting Date, Currency Code, Variant Code, '', 0)` — `Sales Code`, `"Unit of Measure Code"` blank, `"Minimum Quantity"` 0 — with `"Sales Type"` fixed to `All Customers`. `"Country/Region Code"` is set to blank as a regular field assignment after Get/Init, not as part of the key lookup. If `Get` fails, `Init` + populate + `Insert`; otherwise populate + `Modify`.

### Field mapping, "SL Sales Price Checking" → "Sales Price"
| Checking field | Sales Price field |
|---|---|
| `"Item No."` | `"Item No."` |
| `"Variant Code"` | `"Variant Code"` |
| `"Currency Code"` | `"Currency Code"` |
| `"Starting Date"` | `"Starting Date"` |
| `"Stock Price"` | `"Unit Price"` (standard field) |
| `"Strike Price"` | `"Strike-Price incl. VAT"` |
| `"Recom. Retail Price"` | `"Recom. Retail Price incl. VAT"` |
| `"Reason Code"` | `"Reason Code"` |
| `Comment` | `Comment` |
| `Remark` | `Remark` |
| — (fixed) | `"Sales Type"` = `All Customers`, `"Sales Code"` = `''`, `"Country/Region Code"` = `''` |

`"Non Stock Price"`, `"Starting Time"`, `"Ending Time"`, `"Old Stock Price"`, `"Exchange Rate Amount"/"Date"`, `"Accept New Setup"`, `Validated`, `"Approved By"` have no target field on `"Sales Price"` and are not written there (they remain visible via the archive snapshot instead, see below). Note: the standard table does have an `"Ending Date"` field, but it is intentionally left unmapped here to keep this change scoped to what was requested — only the fields listed in the table above are written.

### Archive versioning
Before inserting the archive row, look up the highest existing `"Version No."` in `"SL Sales Price Archive"` for the same `Item No. / Variant Code / Currency Code` (with `"Country Code" = ''`, consistent with the blank country decision above), and insert the new row with `"Version No." + 1` (starting at `1` if none exist). The archive row is a direct field-for-field copy of the `"SL Sales Price Checking"` line (all fields that exist on both tables), not of the `"Sales Price"` record — this preserves checking-only context (`"Old Stock Price"`, `"Exchange Rate Amount"/"Date"`, `Validated`, `"Accept New Setup"`, `Remark`) in the history that `"Sales Price"` itself doesn't carry.

**Alternative considered**: key the version counter on `Item No. / Variant Code / Currency Code / Country Code` using whatever `"Country Code"` ends up being (always blank here). Equivalent in practice today since `"Country Code"` is always blank from this flow, but the lookup still filters on it explicitly so a future change that populates `"Country Code"` differently doesn't silently share version counters across countries.

### Processing order per line
For each checking line reaching the export step (`"Accept New Setup" = true`, and either not yet `Sent` or the user confirmed resend): `WriteBackAndArchive` → `CreateExternalInterfaceFile(SalesPrice)` → set `"Export Status"`. This means a resend of an already-`Sent` line still produces a new `"Sales Price"` update and a new archive version — treated as intentional, since a resend implies the operator wants the current checking data live again.

### Per-line error isolation
`WriteBackAndArchive` is marked `[TryFunction]`. Without this, an error inside it (e.g. an invalid currency) would propagate out of the page action's `OnAction` trigger and abort the whole "Upload Sales Price" run — since BC page actions execute in an implicit transaction, this would roll back the `"Export Status"` updates already made to earlier, successfully-processed lines in the same run, silently losing that work. As a `TryFunction`, a failure inside `WriteBackAndArchive` instead rolls back only that call's own changes and returns `false`; the call site (`Page 51001`) treats that the same as a failed `CreateExternalInterfaceFile` — the line is marked `"Export Status"::Error` and the loop continues with the next line.

## Risks / Trade-offs

- **[Risk]** Removing the `FindFirst`-then-skip lookup means every approved line now writes to the live `"Sales Price"` table, including lines that previously had no counterpart and were silently ignored → **Mitigation**: this is the explicit intent of the change (see proposal, marked **BREAKING**); the existing pre-conditions (`"Accept New Setup" = true`, `Validated` enforced earlier in the workflow) already gate which lines reach this point.
- **[Risk]** `"Unit Price"` (standard field) diverges from `"Unit Price (LCY)"` (custom field already used by the page's own `fnValidate` comparison logic), since this change only writes the former → **Mitigation**: `fnValidate` reads whichever `"Sales Price"` record it already finds via its own separate lookup; it is unaffected by this change's field choice, but this divergence should be called out to the business owner as a follow-up (`"Unit Price (LCY)"` may become stale once this feature ships) — logged here rather than silently left inconsistent.
- **[Risk]** No `LockTable` around the read-then-write on `"Sales Price"` / `"SL Sales Price Archive"` → **Mitigation**: matches the existing style of this worksheet-driven, single-operator action (no locking elsewhere in `Page 51001`); not introducing new concurrency handling beyond what the surrounding code already does.
- **[Risk]** (caught during dev-abschluss review, now fixed) An unhandled error inside `WriteBackAndArchive` for one line would abort the whole "Upload Sales Price" batch and roll back `"Export Status"` updates already made to earlier lines in the same run → **Mitigation**: `WriteBackAndArchive` is a `[TryFunction]`; a failure is caught, the line is marked `"Export Status"::Error`, and the batch continues (see "Per-line error isolation" above).

## Migration Plan

Code-only change, no data migration. Deploy via normal AL publish. Rollback is a straight revert of the modified action/codeunit — no schema change, so no rollback data concerns. Existing `"Sales Price"` and `"SL Sales Price Archive"` rows are unaffected until the next "Upload Sales Price" run touches them.

## Open Questions

None outstanding — the two field-mapping ambiguities (price field, country code) were resolved with the business owner before this design was written.
