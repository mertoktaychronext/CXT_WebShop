## MODIFIED Requirements

### Requirement: Approved sales prices are transmitted via HTTP
The system SHALL transmit the JSON representation of an approved sales price to the endpoint of the configured API interface using an HTTP request, applying the authentication configured on that interface. The outcome of every transmission attempt SHALL be recorded as a "Data Export Entry" (ChronextBC table 50103) with `"Destination Code"` = `SALESPRICE`, `"Payload Format"` = JSON, the transmitted JSON stored as payload, the outbound file name in `FileName`, and the written-back "Sales Price" record in `"Source Record ID"`. The system SHALL NOT write to "CXW Sales Price Outbound File" anymore.

#### Scenario: Successful transmission
- **WHEN** a sales price is exported and the external system responds with a successful HTTP status
- **THEN** a "Data Export Entry" with `Destination Code` = `SALESPRICE` SHALL be created with `Status` = Processed, `Attempt Count` = 1, and `Processed At` and `Last Attempt At` set to the time of the call

#### Scenario: Failed transmission
- **WHEN** a sales price is exported and the HTTP request fails (network error or non-success HTTP status)
- **THEN** a "Data Export Entry" with `Destination Code` = `SALESPRICE` SHALL be created with `Status` = Error, `Attempt Count` = 1, `Last Attempt At` set, `Processed At` left empty and `Error Message` containing the HTTP status and response text (or the network error text), and the underlying sales price approval SHALL NOT be reverted

#### Scenario: Payload is visible in the ChronextBC export entries
- **WHEN** a user opens "Data Export Entries" (page 50108) and selects an entry with `Destination Code` = `SALESPRICE`
- **THEN** the JSON payload that was transmitted for that sales price SHALL be shown in the payload FactBox

#### Scenario: No legacy outbound file is written
- **WHEN** a sales price is exported, successfully or not
- **THEN** no new record SHALL be inserted into "CXW Sales Price Outbound File"

### Requirement: Exported sales price carries the country
The JSON transmitted for a "CXW Sales Price Checking" line SHALL contain, in addition to the fields of the written-back "Sales Price" record, a field `"CXW Country Code"` holding the checking line's `"CXW Country Code"` (empty for source lines without a country). The file name stored on the resulting "Data Export Entry" SHALL include the country code so that entries for different countries sharing a currency are distinguishable.

#### Scenario: Country line is exported
- **WHEN** "Upload Sales Price" exports a checking line with `"CXW Country Code"` = `AT` and `"CXW Currency Code"` blank
- **THEN** the transmitted JSON contains `"CXW Country Code": "AT"` and the `FileName` of the created "Data Export Entry" contains both the item number and `AT`

#### Scenario: Two countries with the same currency are exported separately
- **WHEN** "Upload Sales Price" exports approved lines for the same item for DE and AT, both with blank `"CXW Currency Code"`
- **THEN** two separate JSON payloads are transmitted, one with `"CXW Country Code": "DE"` and one with `"CXW Country Code": "AT"`, each recorded in its own "Data Export Entry"

#### Scenario: Source line without country is exported
- **WHEN** "Upload Sales Price" exports a source line with blank `"CXW Country Code"`
- **THEN** the transmitted JSON contains `"CXW Country Code": ""`

## ADDED Requirements

### Requirement: Sales price export entries are not resent by the ChronextBC export job
Because ChronextBC's "Data Export Mgt." (codeunit 50102) sends every "Data Export Entry" with `Status` = "Waiting to Process" through "Data Export API Sender", the system SHALL ensure that no "Data Export Entry" created by the sales price export remains in status "Waiting to Process" after the export of a line has finished. Retrying a failed sales price transmission SHALL happen only via the "Upload Sales Price" action.

#### Scenario: Entry status is final after export
- **WHEN** the sales price export of a line has finished (successfully or not)
- **THEN** the "Data Export Entry" created for it SHALL have `Status` = Processed or `Status` = Error, never "Waiting to Process"

#### Scenario: ChronextBC export job ignores sales price entries
- **WHEN** "Data Export Mgt." runs after sales prices were exported
- **THEN** none of the "Data Export Entry" records with `Destination Code` = `SALESPRICE` SHALL be selected or sent again
