## MODIFIED Requirements

### Requirement: Sales Price write-back before export
Before queuing a "CXW Sales Price Checking" line for export, the system SHALL write that line's data into the standard "Sales Price" table, updating an existing matching record or inserting a new one if none exists. Source lines without a country SHALL NOT be written back.

#### Scenario: Source line is not written back
- **WHEN** "Release Sales Prices" is run and an approved source line has blank "CXW Country Code"
- **THEN** no "Sales Price" record is inserted or modified for that line, so the rounded price of the DE country line is not overwritten

#### Scenario: No matching Sales Price record exists yet
- **WHEN** the "Release Sales Prices" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Starting Date" combination that has no existing "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system inserts a new "Sales Price" record with the checking line's data before queuing the export, instead of skipping the line

#### Scenario: A matching Sales Price record already exists
- **WHEN** the "Release Sales Prices" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Starting Date" combination that already has a matching "Sales Price" record with "Sales Type" = All Customers
- **THEN** the system updates that existing "Sales Price" record with the checking line's current data before queuing the export

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
Before queuing a "CXW Sales Price Checking" line for export, the system SHALL insert a new row into "CXW Sales Price Archive" containing a snapshot of that checking line **only if** the line's "CXW Country Code" equals the `"CXW Archive Country Code"` of the general sales price setup (default `DE`). The new row's "CXW Version No." SHALL be incremented relative to any prior archive rows for the same "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination. Lines of all other countries, and source lines without a country, SHALL NOT be archived. If `"CXW Archive Country Code"` is blank, "Release Sales Prices" SHALL stop with an error before processing any line.

#### Scenario: Archive country line is archived
- **WHEN** "Release Sales Prices" processes a checking line with "CXW Country Code" = `DE` and the archive country is `DE`
- **THEN** the system inserts a new archive row for that line

#### Scenario: Other country line is not archived
- **WHEN** "Release Sales Prices" processes a checking line with "CXW Country Code" = `AT` and the archive country is `DE`
- **THEN** no archive row is inserted for that line, while its "Sales Price" write-back and its "CXW Sales Price Export" record are still created

#### Scenario: Source line without country is not archived
- **WHEN** "Release Sales Prices" is run and an approved checking line has blank "CXW Country Code"
- **THEN** no archive row is inserted for that line

#### Scenario: Archive country not configured
- **WHEN** "Release Sales Prices" is run and `"CXW Archive Country Code"` is blank
- **THEN** the action stops with an error and no line is processed

#### Scenario: First archive entry for a combination
- **WHEN** the "Release Sales Prices" action archives a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination that has no prior "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." = 1

#### Scenario: Subsequent archive entry for a combination
- **WHEN** the "Release Sales Prices" action archives a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination that already has one or more "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." set to one greater than the highest existing "CXW Version No." for that combination

#### Scenario: Archive row reflects checking line data
- **WHEN** the system inserts a new "CXW Sales Price Archive" row for a checking line
- **THEN** the archive row's fields (including "CXW Country Code", "CXW Stock Price", "CXW Non Stock Price", "CXW Strike Price", "CXW Recom. Retail Price", "CXW Starting Date", "CXW Starting Time", "CXW Ending Date", "CXW Ending Time", "CXW Old Stock Price", "CXW Exchange Rate Amount", "CXW Exchange Rate Date", "CXW Reason Code", CXW Comment, CXW Remark, CXW Validated, "CXW Accept New Setup") match the corresponding fields on the source checking line

### Requirement: Write-back and archiving occur for every export attempt
The system SHALL perform the "Sales Price" write-back, and for the archive country the "CXW Sales Price Archive" snapshot, for every "CXW Sales Price Checking" line that "Release Sales Prices" processes, including lines being released again after a previous successful release.

#### Scenario: Releasing an already-queued line again
- **WHEN** the operator confirms releasing checking lines whose "CXW Export Status" is already "Queued"
- **THEN** the system writes an updated "Sales Price" record, inserts a new, higher-versioned "CXW Sales Price Archive" row for lines of the archive country, and creates a new "CXW Sales Price Export" record and "Data Export Entry" for each of these lines

### Requirement: A write-back failure on one line does not abort the batch
If writing back, archiving or queuing a checking line fails (e.g. an invalid value prevents the "Sales Price" record from being saved), the system SHALL mark only that line as failed, roll back all changes made for that line, and continue processing the remaining lines in the same "Release Sales Prices" run, instead of aborting the run and losing the results already recorded for earlier lines.

#### Scenario: One line fails validation during write-back
- **WHEN** "Release Sales Prices" processes multiple approved lines and the write-back for one line fails
- **THEN** that line's "CXW Export Status" is set to "Error", neither a "CXW Sales Price Export" record nor a "Data Export Entry" is created for it, and the system continues processing the remaining lines instead of stopping the run

#### Scenario: Earlier successful lines are not rolled back by a later failure
- **WHEN** "Release Sales Prices" successfully writes back, archives, and queues one or more lines before encountering a line whose write-back fails
- **THEN** the "CXW Export Status", "Sales Price", "CXW Sales Price Archive", "CXW Sales Price Export" and "Data Export Entry" changes already made for the earlier, successful lines remain in effect
