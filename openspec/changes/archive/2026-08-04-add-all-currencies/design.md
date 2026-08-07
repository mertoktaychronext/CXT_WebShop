## Context

Page 51001 "SL Sales Price Checking List" has an action "Add All Countries" that, starting from the DE-based source line(s) (`"Country Code" = 'DE'`, `"DE Price Processed" = false`), loops over every `Country/Region` with `"Sales Price Activated" = true` (excluding DE itself) and inserts one new "SL Sales Price Checking" line per country, converting the price via that country's `"Sales Price Currency Code"` and the latest exchange rate (`Currency Exchange Rate.GetLastestExchangeRate`). Countries sharing a currency (e.g. several Eurozone countries) each get their own line with identical currency and converted price — the only difference is `"Country Code"`. This is confirmed by reading the current implementation in `src/Pages/Pag51001.SLSalesPriceCheckingList.al`.

`"SL Sales Price Checking"` (`src/Tables/Tab51001.SLSalesPriceChecking.al`) has primary key `(Item No., Variant Code, Currency Code, Country Code)`. `"Country Code"` has no `NotBlank` constraint, and its `OnValidate` trigger (which derives `"Currency Code"` from the country) is never invoked by the copy action today — both the current and the new implementation assign fields directly (`Rec.Field := Value`), bypassing `Validate()`.

The user confirmed (via clarifying question during proposal) that new currency-based lines should have `"Country Code" = ''` (blank), meaning the line applies to all countries sharing that currency rather than to one specific country. This requires no schema/key change: a blank `Code[10]` is a valid, distinct key value and cannot collide with the source DE line (which keeps `"Country Code" = 'DE'`).

## Goals / Non-Goals

**Goals:**
- Replace "Add All Countries" with "Add all Currencies": one new line per **distinct currency** among Sales-Price-activated countries (excluding the source line's own currency), not one per country.
- Reuse the exact same underlying logic/structure as "Add All Countries" wherever the behavior doesn't have to change: same guard order, same country loop (`Country/Region`, `SetRange("Sales Price Activated", true)`), same exchange-rate conversion (`GetLastestExchangeRate`), same field-copy block. The only deliberate deltas are: (a) skip a country whose currency was already used to create a line in this run, (b) leave `"Country Code"` blank instead of the country's code.
- Preserve all existing safeguards from "Add All Countries": setup validation (`"Minimum Margin %"`, `"Stock Price Threshold %"`), "Nothing to process" guards, and idempotency (the action can't silently duplicate lines if run twice for the same source line).
- Keep the same field-copy semantics (Reason Code, Comment, Starting/Ending Date/Time, Approved By, Accept New Setup, Validated := true) as the current action.
- "Add All Countries" is removed without replacement (ersatzlos gestrichen) — no toggle, no fallback, no dual-mode. There is exactly one action going forward: "Add all Currencies".

**Non-Goals:**
- Not generalizing the hardcoded `"Country Code" = 'DE'` source-line assumption — the new action still triggers from the DE-based source line(s), matching current scope. De-hardcoding "which country is the base line" is a separate, future change.
- Not changing Codeunit 51000/51001 or the (currently placeholder) "Upload Sales Price" action — how currency-only lines eventually map to the real `"Sales Price"` table (which still expects a `"Country/Region Code"`) is out of scope here and will be addressed when that placeholder is implemented.
- Not adding UI to show/hide blank-Country-Code lines differently in the repeater — the existing "Country Code" column will simply display blank for these rows.

## Decisions

**1. Blank `"Country Code"` for currency-based lines (per user decision).**
Alternative considered: pick a representative/"lead" country per currency. Rejected — the user explicitly called this out as fachlich irreführend (factually misleading), since the line would look country-specific when it isn't. Blank requires no schema change and is unambiguous once documented.

**2. Currency deduplication via a `Get()` existence check against the target table itself, not an in-memory List.**
The country loop stays exactly as in "Add All Countries" (`Country/Region`, `SetRange("Sales Price Activated", true)`, exclude the source's own country/currency). Before inserting, check `g_recSalesPriceCheck2.Get("Item No.", "Variant Code", <country's currency>, '')` — if a line for that currency already exists (inserted earlier in this same loop), skip; otherwise proceed with `Init()`/conversion/`Insert()` exactly as before, just with `"Country Code" := ''` instead of the country's code.
Alternative considered: a local `List of [Code[10]]` tracking already-used currencies. Rejected per explicit instruction to stay as close as possible to "Add All Countries" — the rest of this codebase (and the original action) always de-duplicates/looks up via `Record.Get`/`FindFirst` against real tables, never via an in-memory generic collection, so a `Get()` check is the smaller, more consistent delta from the existing logic.

**3. Idempotency field renamed from `"DE Price Processed"` to `"Currencies Processed"`.**
The old name was tied to the per-country/DE-specific mental model. Since the project has no production data yet (fresh AL app, idRanges 51000-51049), renaming is low-risk and keeps the field self-explanatory under the new currency-based model. The field keeps the same Boolean semantics and position in the workflow (checked/set on the source line after a successful run).

**4. Source line's own currency is excluded from the loop.**
Mirrors the original's `Code <> 'DE'` self-exclusion (don't recreate a line identical to the source). Concretely: skip any country whose `"Sales Price Currency Code"` equals the source line's `"Currency Code"` (typically blank/LCY for the DE line).

**5. `Enabled = not NonDEPrice` kept unchanged.**
The currency-copy action only makes sense starting from the DE-based (non-`NonDEPrice`) workflow, same as today.

## Risks / Trade-offs

- **[Risk] Blank `"Country Code"` may look like a data-entry mistake to reviewers in the Validate/Approve grid.** → Mitigation: none implemented in this change (Non-Goal); consider a future tooltip or a computed display label if this proves confusing in practice.
- **[Risk] Downstream consumers (e.g. a future real "Upload Sales Price" implementation, or reports) may assume `"Country Code"` is always populated.** → Mitigation: called out explicitly in proposal.md Impact section and here, so it's visible before that placeholder is built out.
- **[Trade-off] Fewer, "wider" lines are harder to filter by a specific country in the Sales Price Checking List.** → Accepted trade-off per the user's explicit request; the whole point of the change is to stop duplicating per country.

## Open Questions

- Should the repeater's "Country Code" column get a visual hint (e.g. placeholder text "All countries with this currency") for blank rows, or is a plain blank cell acceptable? Left as a follow-up, not blocking this change.
- When the "Upload Sales Price" placeholder action is eventually implemented, how should a currency-only checking line be expanded back into per-country `"Sales Price"` records? Explicitly deferred — out of scope for this change.
