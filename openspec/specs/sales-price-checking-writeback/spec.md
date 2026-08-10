# sales-price-checking-writeback

Writing approved "CXW Sales Price Checking" lines into "Sales Price" and archiving them into "CXW Sales Price Archive" (with incrementing version number) as part of the "Upload Sales Price" export step.

## Requirements

### Requirement: Sales Price write-back before export
Before generating the outbound interface file for a "CXW Sales Price Checking" line, the system SHALL write that line's data into the standard "Sales Price" table, updating an existing matching record or inserting a new one if none exists.

#### Scenario: No matching Sales Price record exists yet
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Starting Date" combination that has no existing "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system inserts a new "Sales Price" record with the checking line's data before generating the outbound file, instead of skipping the line

#### Scenario: A matching Sales Price record already exists
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Starting Date" combination that already has a matching "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system updates that existing "Sales Price" record with the checking line's current data before generating the outbound file

#### Scenario: Sales Type is always All Customers
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the "Sales Type" field on that record is set to "All Customers" and "Sales Code" is blank, regardless of any other value

#### Scenario: Country/Region Code is left blank
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the "Country/Region Code" field on that record is set to blank

#### Scenario: Stock Price maps to the standard Unit Price field
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the checking line's "CXW Stock Price" value is written to the standard "Unit Price" field on "Sales Price"

### Requirement: Sales Price Archive snapshot before export
Before generating the outbound interface file for a "CXW Sales Price Checking" line, the system SHALL insert a new row into "CXW Sales Price Archive" containing a snapshot of that checking line, with "CXW Version No." incremented relative to any prior archive rows for the same "CXW Item No."/"CXW Currency Code" combination.

#### Scenario: First archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code" combination that has no prior "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." = 1

#### Scenario: Subsequent archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code" combination that already has one or more "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." set to one greater than the highest existing "CXW Version No." for that combination

#### Scenario: Archive row reflects checking line data
- **WHEN** the system inserts a new "CXW Sales Price Archive" row for a checking line
- **THEN** the archive row's fields (including "CXW Stock Price", "CXW Non Stock Price", "CXW Strike Price", "CXW Recom. Retail Price", "CXW Starting Date", "CXW Starting Time", "CXW Ending Date", "CXW Ending Time", "CXW Old Stock Price", "CXW Exchange Rate Amount", "CXW Exchange Rate Date", "CXW Reason Code", CXW Comment, CXW Remark, CXW Validated, "CXW Accept New Setup") match the corresponding fields on the source checking line

> Note: earlier versions of this spec also asserted a "Country Code is blank" clause here. Neither "CXW Sales Price Archive" nor "CXW Sales Price Checking" has such a field in the current code — stale text left over from the (still open, not yet archived) `remove-country-code` change on this branch. Dropped as inapplicable; reconciling it properly is that other change's job.

### Requirement: Write-back and archiving occur for every export attempt
The system SHALL perform the "Sales Price" write-back and "CXW Sales Price Archive" snapshot for every "CXW Sales Price Checking" line that "Upload Sales Price" attempts to export, including lines being re-sent after a previous successful export.

#### Scenario: Resending an already-sent line
- **WHEN** the operator confirms resending checking lines whose "CXW Export Status" is already "Sent"
- **THEN** the system writes an updated "Sales Price" record and inserts a new, higher-versioned "CXW Sales Price Archive" row for each resent line before generating its outbound file

### Requirement: A write-back failure on one line does not abort the batch
If writing back or archiving a checking line fails (e.g. an invalid value prevents the "Sales Price" record from being saved), the system SHALL mark only that line as failed and continue processing the remaining lines in the same "Upload Sales Price" run, instead of aborting the run and losing the results already recorded for earlier lines.

#### Scenario: One line fails validation during write-back
- **WHEN** "Upload Sales Price" processes multiple approved lines and the write-back for one line fails
- **THEN** that line's "CXW Export Status" is set to "Error", no outbound file is generated for it, and the system continues processing the remaining lines instead of stopping the run

#### Scenario: Earlier successful lines are not rolled back by a later failure
- **WHEN** "Upload Sales Price" successfully writes back, archives, and exports one or more lines before encountering a line whose write-back fails
- **THEN** the "CXW Export Status", "Sales Price", and "CXW Sales Price Archive" changes already made for the earlier, successful lines remain in effect

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
