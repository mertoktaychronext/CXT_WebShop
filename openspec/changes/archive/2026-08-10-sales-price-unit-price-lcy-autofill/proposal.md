## Why

Running the "Validate" action on Page 60322 "CXW Sales Price Checking List" crashes with `Attempted to divide by zero.` inside `fnValidate` whenever a checking line has a matching, previously-uploaded "Sales Price" record. Root cause: `fnValidate` divides by that previous record's `"CXW Unit Price (LCY)"` field, but nothing in the codebase ever writes to that field automatically — `Codeunit 60329 "CXW Export Gateway Sales Price"`.`WriteBackAndArchive` (the normal "Upload Sales Price" write-back path) and `Codeunit 60330 "CXW Import Sales Prices"` (the file-based import) both only write the standard `"Unit Price"` field. `"CXW Unit Price (LCY)"` is only ever set if a key user manually types a value into it on the standard "Sales Prices" page. In practice this means the very first "Validate" run against a second price update for any item/currency combination reliably crashes and aborts the entire batch (a `repeat...until` loop with no per-line error handling), for every line after the one that triggered the divide.

## What Changes

- `Codeunit 60329 "CXW Export Gateway Sales Price"` automatically populates `"CXW Unit Price (LCY)"` on the "Sales Price" record every time it writes `"Unit Price"` (both the insert and update branch of `WriteBackAndArchive`/`UpdateSalesPriceFields`):
  - If the "Sales Price" record's "Currency Code" is blank (already LCY), `"CXW Unit Price (LCY)"` is set equal to `"Unit Price"` directly.
  - If "Currency Code" is set, `"CXW Unit Price (LCY)"` is converted from `"Unit Price"` using an exchange rate — preferring the checking line's own captured `"CXW Exchange Rate Amount"` (set when the line was created via "Add all Currencies") when it is non-zero, and falling back to a live lookup via `Currency Exchange Rate.GetLastestExchangeRate` (the same pattern already used in Page 60322's "Add all Currencies" and `fnCalcNonStockPrice`) when it is not — covering checking lines imported directly via CSV with a foreign currency, which never go through "Add all Currencies" and so never get `"CXW Exchange Rate Amount"` populated.
- Page 60322's `fnValidate` no longer divides unconditionally by the previous record's `"CXW Unit Price (LCY)"`. When that value is `0` (still true for every "Sales Price" record written before this fix, until it is re-uploaded), the previous-price percentage comparison and its threshold warning are skipped for that line instead of crashing the batch. This is included alongside the write-back fix — without it, every "Sales Price" record already in the database keeps crashing "Validate" until each one happens to be re-sent through "Upload Sales Price" again.
- **BREAKING**: none — this only adds a previously-empty field's value and adds a guard around an existing crash path; no existing field, action, or interface signature changes.

## Capabilities

### New Capabilities
- `sales-price-checking-validation`: the "Validate" action's per-line comparison against the previous "Sales Price" (stock-price swing %, margin %, date-range checks) and its robustness when no reliable previous price exists.

### Modified Capabilities
- `sales-price-checking-writeback`: `WriteBackAndArchive` gains a requirement to populate `"CXW Unit Price (LCY)"` on the "Sales Price" record it writes, in addition to the existing `"Unit Price"` write.

## Impact

- `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al` — `UpdateSalesPriceFields` gains the LCY population logic; a new local procedure resolves the exchange rate (captured-on-checking-line vs. live lookup).
- `src/Pages/Pag60322.CXWSalesPriceCheckingList.al` — `fnValidate` guards its two divisions by `g_recSP."CXW Unit Price (LCY)"`.
- No table, permission set, or translation changes are anticipated (no new fields, captions, or tooltips) — `"CXW Unit Price (LCY)"` already exists (`TabExt60319`, field 60305).
- Every "Sales Price" record written or updated after this change gets a correct `"CXW Unit Price (LCY)"` going forward; records already in the database keep `"CXW Unit Price (LCY)" = 0` until the next time they're written back (this change does not include a data-repair/backfill routine for existing records — see design.md for why).
