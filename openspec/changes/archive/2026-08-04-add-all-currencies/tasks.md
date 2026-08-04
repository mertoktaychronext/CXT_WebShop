## 1. Table changes (Tab51001.SLSalesPriceChecking.al)

- [x] 1.1 Rename field "DE Price Processed" to "Currencies Processed" (keep the same field ID and Boolean type).
- [x] 1.2 Update the field's Caption/comment to reflect the new currency-based meaning.
- [x] 1.3 Add a short comment on the "Country Code" field documenting that a blank value means "applies to all countries sharing the line's currency".

## 2. Page changes (Pag51001.SLSalesPriceCheckingList.al)

- [x] 2.1 Remove the action "Add All Countries" entirely (including its OnAction logic) — no toggle, no fallback, no dual-mode; it is deleted without replacement (ersatzlos gestrichen).
- [x] 2.2 Add a new action "Add all Currencies" in the same `group(Import)`, reusing the exact same properties as the removed action (`Enabled = not NonDEPrice`, `Promoted = true`, `PromotedCategory = New`, `PromotedIsBig = true`, `Image = Add`).
- [x] 2.3 Reuse the same pre-condition guards as the old action, in the same order, only renaming references from "DE Price Processed" to "Currencies Processed" (setup fields set; at least one line exists; an unprocessed DE-based source line exists; no unvalidated/unaccepted lines).
- [x] 2.4 Keep the same outer loop structure as the old action: `Country/Region` with `SetRange("Sales Price Activated", true)`, excluding the source line's own country. Inside the loop, before building a new line, skip the country if its `"Sales Price Currency Code"` is blank, equals the source line's own `"Currency Code"`, or already has a corresponding line — checked via `g_recSalesPriceCheck2.Get("Item No.", "Variant Code", <country's currency>, '')` (existence check against the target table, not an in-memory list), matching how the rest of the codebase de-duplicates.
- [x] 2.5 For each currency that passes the checks in 2.4, insert one new "SL Sales Price Checking" line exactly as the old action did (`Init()`, convert "Stock Price" / "Recom. Retail Price" / "Strike Price" via `Currency Exchange Rate.GetLastestExchangeRate`, copy "Reason Code", Comment, "Starting Date", "Starting Time", "Ending Date", "Ending Time", "Approved By", "Accept New Setup", `Validated := true`, `Insert(true)`), with the sole differences being `"Country Code" := ''` (instead of the country's code) and `"Currency Code" := <the country's currency>`.
- [x] 2.6 After successful processing of a source line, set `"Currencies Processed" := true` on it (mirroring the old `"DE Price Processed"` update, same place in the flow).
- [x] 2.7 Update the page's header comment block to describe "Add all Currencies" instead of "Add All Countries".

## 3. Verification

- [x] 3.1 No leftover references to "Add All Countries" or "DE Price Processed" anywhere in `src/` (verified via repo-wide search; remaining hits are intentional historical comments naming the old identifiers for traceability). Note: no AL compiler is available in this environment, so this was verified by careful manual review + search, not an actual build — recommend a real compile in VS Code/AL:Go! before shipping.
- [x] 3.2 Manually traced through all scenarios in `specs/sales-price-currency-copy/spec.md` against the new implementation (multiple countries sharing a currency → one line; source currency excluded; blank currency skipped; exchange-rate conversion; idempotency on re-run; field copy semantics) — all match.
- [x] 3.3 Change status confirmed via `openspec status` (see below); ready for `/opsx:archive` once the user has reviewed/compiled.
