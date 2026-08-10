## ADDED Requirements

### Requirement: Unit Price (LCY) is populated on write-back
Whenever the system writes or updates a "Sales Price" record from a "CXW Sales Price Checking" line, it SHALL also populate `"CXW Unit Price (LCY)"` on that record, in addition to the existing `"Unit Price"` write.

#### Scenario: Blank Currency Code — direct copy
- **WHEN** the system writes or updates a "Sales Price" record whose "Currency Code" is blank
- **THEN** `"CXW Unit Price (LCY)"` is set equal to `"Unit Price"`, with no exchange-rate conversion attempted

#### Scenario: Foreign currency line with a captured exchange rate
- **WHEN** the system writes or updates a "Sales Price" record for a checking line whose "Currency Code" is not blank and whose "CXW Exchange Rate Amount" is non-zero
- **THEN** `"CXW Unit Price (LCY)"` is computed by converting `"Unit Price"` to LCY using that checking line's own `"CXW Exchange Rate Amount"`, without performing a new exchange-rate lookup

#### Scenario: Foreign currency line without a captured exchange rate
- **WHEN** the system writes or updates a "Sales Price" record for a checking line whose "Currency Code" is not blank and whose "CXW Exchange Rate Amount" is zero (e.g. the checking line was imported directly via CSV rather than created through "Add all Currencies")
- **THEN** the system looks up the latest exchange rate for that currency via `Currency Exchange Rate.GetLastestExchangeRate` and uses it to compute `"CXW Unit Price (LCY)"` from `"Unit Price"`

#### Scenario: No exchange rate can be found
- **WHEN** the system attempts the fallback exchange-rate lookup for a foreign-currency line and no exchange rate exists for that currency
- **THEN** `"CXW Unit Price (LCY)"` is left at `0` on that record, and no error is raised that would abort the write-back
