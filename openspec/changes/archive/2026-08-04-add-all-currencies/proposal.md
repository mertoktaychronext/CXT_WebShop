## Why

The current "Add All Countries" action in Page 51001 "SL Sales Price Checking List" creates one new "SL Sales Price Checking" line per activated country ("Sales Price Activated" = true), converting the price using that country's assigned currency. Since several countries can share the same currency (e.g. multiple Eurozone countries), this produces redundant duplicate lines with identical currency and converted price, differing only in "Country Code". These duplicates add noise to the Validate/Approve review workflow and do extra, unnecessary currency-conversion and record-insert work. The actual driver of the price is the currency, not the country, so the copy operation should be keyed on currency instead.

## What Changes

- Remove the action "Add All Countries" from Page 51001 "SL Sales Price Checking List".
- Add a new action "Add all Currencies" that, starting from the source "SL Sales Price Checking" line (the existing DE-based line), creates exactly one additional line per **distinct currency** used by activated countries (instead of one line per country).
- The new lines are created with `"Country Code" = ''` (blank) — a currency-based line applies to all countries sharing that currency, not to one specific country. **BREAKING** in the sense that "Country Code" changes meaning for these generated rows: it no longer identifies a specific country but signals "applies by currency, not tied to a country." No table schema/key change is required (blank is a valid `Code[10]` value and does not collide with the country-keyed source row).
- Preserve the existing safeguards from "Add All Countries" (setup validation, "Nothing to process" guards, idempotency tracking so the action can't be run twice for the same source line) adapted to the currency-based flow.

## Capabilities

### New Capabilities
- `sales-price-currency-copy`: Copying a validated "SL Sales Price Checking" line to all currencies used by Sales-Price-activated countries, with currency-converted prices, as an alternative to the previous per-country copy.

### Modified Capabilities
- (none — no existing OpenSpec capability specs exist yet for this behavior; the previous "Add All Countries" behavior was implemented directly in AL and is being superseded, not evolved from a documented spec)

## Impact

- **Page 51001** "SL Sales Price Checking List" (`src/Pages/Pag51001.SLSalesPriceCheckingList.al`): action removed and replaced; `NonDEPrice`-based `Enabled` condition and idempotency flag need re-evaluation for the new flow.
- **Table 51001** "SL Sales Price Checking" (`src/Tables/Tab51001.SLSalesPriceChecking.al`): no schema change required, but the meaning of a blank "Country Code" needs to be documented on the field/table.
- No impact on Codeunit 51000 "SL Export Gateway Sales Price" or Codeunit 51001 "SL Import Sales Prices" (both currently placeholder/independent of this action).
- No impact on Table 51000 "SL General Sales Price Setup", Table Extension 51000/51001, or the Xmlport.
