## MODIFIED Requirements

### Requirement: Sales Price Archive snapshot before export
Before generating the outbound interface file for a "CXW Sales Price Checking" line, the system SHALL insert a new row into "CXW Sales Price Archive" containing a snapshot of that checking line, with "CXW Version No." incremented relative to any prior archive rows for the same "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination.

#### Scenario: First archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination that has no prior "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." = 1

#### Scenario: Subsequent archive entry for a combination
- **WHEN** the "Upload Sales Price" action processes a checking line for a "CXW Item No."/"CXW Currency Code"/"CXW Country Code" combination that already has one or more "CXW Sales Price Archive" rows
- **THEN** the system inserts a new archive row with "CXW Version No." set to one greater than the highest existing "CXW Version No." for that combination

#### Scenario: Countries sharing a currency are versioned independently
- **WHEN** the "Upload Sales Price" action processes checking lines for the same "CXW Item No." and "CXW Currency Code" but different "CXW Country Code" values (e.g. DE and AT)
- **THEN** each country's archive rows are versioned independently and no key conflict occurs

#### Scenario: Archive row reflects checking line data
- **WHEN** the system inserts a new "CXW Sales Price Archive" row for a checking line
- **THEN** the archive row's fields (including "CXW Country Code", "CXW Stock Price", "CXW Non Stock Price", "CXW Strike Price", "CXW Recom. Retail Price", "CXW Starting Date", "CXW Starting Time", "CXW Ending Date", "CXW Ending Time", "CXW Old Stock Price", "CXW Exchange Rate Amount", "CXW Exchange Rate Date", "CXW Reason Code", CXW Comment, CXW Remark, CXW Validated, "CXW Accept New Setup") match the corresponding fields on the source checking line
