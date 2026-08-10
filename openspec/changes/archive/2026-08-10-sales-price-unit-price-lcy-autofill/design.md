## Context

`"CXW Unit Price (LCY)"` (`TabExt60319`, field 60305, plain `Decimal`, no default, no `OnValidate`) has exactly one writer in the entire codebase today: manual entry on the standard "Sales Prices" page via `PageExt60326`. Every automated write of a "Sales Price" record — `Codeunit 60329`'s `WriteBackAndArchive` (the live "Upload Sales Price" path) and `Codeunit 60330`'s file import (not yet wired live) — only writes `"Unit Price"`. `fnValidate` on Page 60322 divides by the *previous* "Sales Price" record's `"CXW Unit Price (LCY)"` twice, to compute the % swing between the new checking line's price and the last uploaded price for the same item/currency. Since that field is structurally always `0` on automated rows, the second "Validate" run against any item/currency that already has an uploaded price divides by zero and aborts the whole batch loop (`repeat...until`, no per-line error handling — see `Codeunit60329`'s existing per-line `[TryFunction]` pattern for `WriteBackAndArchive` itself, which `fnValidate` does not have).

Separately, `"CXW Sales Price Checking"` already carries `"CXW Exchange Rate Amount"` and `"CXW Exchange Rate Date"` (fields 17–18), populated only by the "Add all Currencies" action (Page 60322) when it derives a foreign-currency checking line from the LCY "master" line. Checking lines imported directly via CSV with a non-blank `"CXW Currency Code"` (`XmlPort 60328`) never go through "Add all Currencies" and so never get these two fields populated — they stay `0`/blank on those rows.

The exchange-rate convention already in production (Page 60322, "Add all Currencies" and `fnCalcNonStockPrice`) is:
```
FCY_Price := LCY_Price * (1 / rate)      // rate returned by Currency Exchange Rate.GetLastestExchangeRate
"CXW Exchange Rate Amount" := 1 / rate   // i.e. FCY units per 1 LCY unit
```
which inverts to:
```
LCY_Price := FCY_Price / "CXW Exchange Rate Amount"
```
This design reuses that exact convention rather than introducing a second, independent notion of "exchange rate" into the codebase.

## Goals / Non-Goals

**Goals:**
- Every "Sales Price" record written by `WriteBackAndArchive` going forward has a correct, non-zero (where a price exists) `"CXW Unit Price (LCY)"`, for both LCY and foreign-currency records, including ones whose checking line came from direct CSV import rather than "Add all Currencies".
- `fnValidate` no longer crashes the entire "Validate" batch when it encounters a previous "Sales Price" record whose `"CXW Unit Price (LCY)"` is still `0` (i.e. every record written before this fix, until it's re-uploaded).

**Non-Goals:**
- No backfill/data-repair routine for `"CXW Unit Price (LCY)"` on "Sales Price" records already in the database. These stay `0` until the next time `WriteBackAndArchive` writes them (i.e. the next price update for that item/currency going through the normal "Upload Sales Price" flow) — at which point the new logic kicks in and self-heals them. A one-time repair job is a separate, optional follow-up if the business wants existing records fixed immediately rather than opportunistically; not included here to keep this change scoped to the crash fix.
- `"CXW Unit Price (LCY) incl. VAT"` (`TabExt60319` field 60306) is out of scope — it is not read by any division and has no observed writer either, but fixing it is a separate, unrelated data-quality question the user did not ask about.
- No change to `Codeunit 60330` (file-based import, not wired live) — it writes "Sales Price" directly via its own `WriteSalesPrices`, bypassing `Codeunit 60329` entirely. Out of scope for this change; flagged as a residual gap below.
- No change to the exchange-rate *lookup* mechanism itself — this reuses `Currency Exchange Rate.GetLastestExchangeRate`, already used elsewhere in this codebase, rather than introducing a new conversion helper.

## Decisions

### 1. Where to compute the LCY value: inside `UpdateSalesPriceFields`
`UpdateSalesPriceFields` is the single place both the insert and update branch of `WriteBackAndArchive` already funnel through to set price fields on the "Sales Price" record (`Codeunit60329.al` lines 29–38). Adding the LCY population there, rather than duplicating it in both branches of `WriteBackAndArchive`, keeps the two call sites in sync automatically — matching how every other price-derived field on that record is already handled.

### 2. Exchange rate source: prefer the checking line's captured rate, fall back to a live lookup
`UpdateSalesPriceFields` already receives `pSalesPriceChecking: Record "CXW Sales Price Checking"` as a parameter, so `"CXW Exchange Rate Amount"` is available without an extra lookup for any line that went through "Add all Currencies". For lines where it's `0` (blank currency master lines, and CSV-imported foreign-currency lines that skipped "Add all Currencies"), the new local procedure falls back to `Currency Exchange Rate.GetLastestExchangeRate(pSalesPriceChecking."CXW Currency Code", ExchangeRateDate, ExchangeRateAmt)` — the same procedure and calling convention already used in Page 60322 — and applies the same `1/rate` inversion so the result is directly comparable to (and interchangeable with) the "Add all Currencies"-captured value.

**Alternative considered:** always do a live lookup, ignore the checking line's captured rate entirely. Rejected — it would silently use a different (possibly later, possibly different) exchange rate than the one the user actually saw and approved the price against during "Validate"/"Approve", which is a worse inconsistency than what this change is trying to fix.

### 3. Blank Currency Code is not converted, ever
When `"Currency Code"` on the "Sales Price" record is blank, the record is already in LCY by definition (this mirrors how "Add all Currencies" treats the blank-currency line as the LCY "master" it converts every other currency from). `"CXW Unit Price (LCY)" := "Unit Price"` directly, no exchange-rate lookup attempted, so this path can never itself introduce a new divide-by-zero.

### 4. `fnValidate` guard: skip the comparison, don't error and don't silently fabricate a percentage
When `g_recSP."CXW Unit Price (LCY)" = 0`, both dependent calculations (`TXT001`/`TXT007` remark generation and `g_decStockPricePercentFromPrev`) are skipped for that line, leaving `"CXW Remark"` and the swing check exactly as if no previous "Sales Price" record existed at all (i.e. `g_recSP.FindFirst()` had failed). This reuses the same "no previous price to compare against" semantics already implemented in the code path directly below it (the `if g_recSP.FindFirst() then` guard itself), rather than inventing a new state or error message.

**Alternative considered:** fall back to comparing against the previous record's standard `"Unit Price"` field instead of skipping. Rejected for this change — `"Unit Price"` is in the "Sales Price" record's own transaction currency, not LCY, so comparing a checking line's price (already resolved to the checking line's currency) against a *different* previous record's `"Unit Price"` would only be valid if both are in the same currency, which isn't guaranteed to hold across price updates (e.g. an item's price gets re-priced in a different currency later). Once this change ships, `"CXW Unit Price (LCY)"` will be reliably populated for every future record anyway, making the zero case a transient condition affecting only not-yet-re-uploaded legacy records, not a steady-state one worth a more complex fallback.

## Risks / Trade-offs

- **[Risk]** Existing "Sales Price" records keep `"CXW Unit Price (LCY)" = 0` until next write → **Mitigation**: covered by the `fnValidate` guard (Decision 4) so it degrades to "no comparison" instead of crashing; self-heals the next time each record is written back through the normal flow.
- **[Risk]** `Codeunit 60330`'s file-based import writes "Sales Price" directly, bypassing this fix entirely, so records created that way would still get `"CXW Unit Price (LCY)" = 0` → **Mitigation**: none in this change (see Non-Goals) — `Codeunit 60330` is not wired into any live process today (documented Known Limitation), so this is a latent gap rather than an active one; worth revisiting if/when that import is ever connected to a job queue.
- **[Risk]** A live `GetLastestExchangeRate` fallback lookup could fail (no exchange rate defined for that currency/date) → **Mitigation**: mirror the existing behavior of the same call in Page 60322 — if no rate is found, the resulting `"CXW Unit Price (LCY)"` stays `0` for that record (same as today, not worse), and `fnValidate`'s guard (Decision 4) already tolerates that.

## Migration Plan

No data migration. This is a forward-only behavior change to two existing procedures; no schema change (the field being populated already exists), no permission changes, no new translatable strings. Deploy via the normal `AL: Publish` flow. Rollback is a normal code revert — no data is deleted or restructured, so reverting does not orphan or corrupt any existing "Sales Price" or "CXW Sales Price Checking" data (it would simply resume leaving new records at `"CXW Unit Price (LCY)" = 0`, i.e. today's status quo).

## Open Questions

- Should a one-time backfill/repair codeunit for existing "Sales Price" records be a separate, immediate follow-up change, or left opportunistic (self-heals on next price update)? Left as opportunistic for this change; flag to the business owner if a large backlog of stale records is expected to sit un-re-uploaded for a long time.
- Is `Codeunit 60330` (file-based import) expected to ever go live? If so, it should get the same `"CXW Unit Price (LCY)"` population logic before it's wired up — out of scope here since it isn't live today.
