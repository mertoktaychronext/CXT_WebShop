## ADDED Requirements

### Requirement: Sales Price write-back before export
Before generating the outbound interface file for an "SL Sales Price Checking" line, the system SHALL write that line's data into the standard "Sales Price" table, updating an existing matching record or inserting a new one if none exists.

#### Scenario: No matching Sales Price record exists yet
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Variant Code/Currency Code/Starting Date combination that has no existing "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system inserts a new "Sales Price" record with the checking line's data before generating the outbound file, instead of skipping the line

#### Scenario: A matching Sales Price record already exists
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Variant Code/Currency Code/Starting Date combination that already has a matching "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system updates that existing "Sales Price" record with the checking line's current data before generating the outbound file

#### Scenario: Sales Type is always All Customers
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the "Sales Type" field on that record is set to "All Customers" and "Sales Code" is blank, regardless of any other value

#### Scenario: Country/Region Code is left blank
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the "Country/Region Code" field on that record is set to blank

#### Scenario: Stock Price maps to the standard Unit Price field
- **WHEN** the system writes or updates a "Sales Price" record from a checking line
- **THEN** the checking line's "Stock Price" value is written to the standard "Unit Price" field on "Sales Price"

### Requirement: Sales Price Archive snapshot before export
Before generating the outbound interface file for an "SL Sales Price Checking" line, the system SHALL insert a new row into "SL Sales Price Archive" containing a snapshot of that checking line, with "Version No." incremented relative to any prior archive rows for the same Item No./Variant Code/Currency Code combination.

#### Scenario: First archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Variant Code/Currency Code combination that has no prior "SL Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "Version No." = 1

#### Scenario: Subsequent archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Variant Code/Currency Code combination that already has one or more "SL Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "Version No." set to one greater than the highest existing "Version No." for that combination

#### Scenario: Archive row reflects checking line data
- **WHEN** the system inserts a new "SL Sales Price Archive" row for a checking line
- **THEN** the archive row's fields (including "Stock Price", "Non Stock Price", "Strike Price", "Recom. Retail Price", "Starting Date", "Starting Time", "Ending Date", "Ending Time", "Old Stock Price", "Exchange Rate Amount", "Exchange Rate Date", "Reason Code", Comment, Remark, Validated, "Accept New Setup") match the corresponding fields on the source checking line, and "Country Code" is blank

### Requirement: Write-back and archiving occur for every export attempt
The system SHALL perform the "Sales Price" write-back and "SL Sales Price Archive" snapshot for every "SL Sales Price Checking" line that "Upload Sales Price" attempts to export, including lines being re-sent after a previous successful export.

#### Scenario: Resending an already-sent line
- **WHEN** the operator confirms resending checking lines whose "Export Status" is already "Sent"
- **THEN** the system writes an updated "Sales Price" record and inserts a new, higher-versioned "SL Sales Price Archive" row for each resent line before generating its outbound file

### Requirement: A write-back failure on one line does not abort the batch
If writing back or archiving a checking line fails (e.g. an invalid value prevents the "Sales Price" record from being saved), the system SHALL mark only that line as failed and continue processing the remaining lines in the same "Upload Sales Price" run, instead of aborting the run and losing the results already recorded for earlier lines.

#### Scenario: One line fails validation during write-back
- **WHEN** "Upload Sales Price" processes multiple approved lines and the write-back for one line fails
- **THEN** that line's "Export Status" is set to "Error", no outbound file is generated for it, and the system continues processing the remaining lines instead of stopping the run

#### Scenario: Earlier successful lines are not rolled back by a later failure
- **WHEN** "Upload Sales Price" successfully writes back, archives, and exports one or more lines before encountering a line whose write-back fails
- **THEN** the "Export Status", "Sales Price", and "SL Sales Price Archive" changes already made for the earlier, successful lines remain in effect
