## MODIFIED Requirements

### Requirement: Sales Price write-back before export
Before generating the outbound interface file for an "SL Sales Price Checking" line, the system SHALL write that line's data into the standard "Sales Price" table, updating an existing matching record or inserting a new one if none exists.

#### Scenario: No matching Sales Price record exists yet
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Currency Code/Starting Date combination that has no existing "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system inserts a new "Sales Price" record with the checking line's data before generating the outbound file, instead of skipping the line

#### Scenario: A matching Sales Price record already exists
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Currency Code/Starting Date combination that already has a matching "Sales Price" record with "Sales Type" = All Customers
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
Before generating the outbound interface file for an "SL Sales Price Checking" line, the system SHALL insert a new row into "SL Sales Price Archive" containing a snapshot of that checking line, with "Version No." incremented relative to any prior archive rows for the same Item No./Currency Code combination.

#### Scenario: First archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Currency Code combination that has no prior "SL Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "Version No." = 1

#### Scenario: Subsequent archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for an Item No./Currency Code combination that already has one or more "SL Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "Version No." set to one greater than the highest existing "Version No." for that combination

#### Scenario: Archive row reflects checking line data
- **WHEN** the system inserts a new "SL Sales Price Archive" row for a checking line
- **THEN** the archive row's fields (including "Stock Price", "Non Stock Price", "Strike Price", "Recom. Retail Price", "Starting Date", "Starting Time", "Ending Date", "Ending Time", "Old Stock Price", "Exchange Rate Amount", "Exchange Rate Date", "Reason Code", Comment, Remark, Validated, "Accept New Setup") match the corresponding fields on the source checking line, and "Country Code" is blank
