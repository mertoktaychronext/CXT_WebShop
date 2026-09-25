# sales-price-api-export

## Purpose

Verwendet eine über `api-interface-setup` konfigurierte Schnittstelle, um das erzeugte Verkaufspreis-JSON tatsächlich per HTTP an ein externes System zu senden, statt es nur lokal abzulegen.
## Requirements
### Requirement: Sales price export uses a configured API interface
The system SHALL allow a Key User to select exactly one API interface (from the generic API interface setup) on the general sales price setup, to be used whenever an approved sales price is sent to the external system.

#### Scenario: No interface configured
- **WHEN** the export gateway attempts to send a sales price and no API interface is selected on the general sales price setup
- **THEN** the system SHALL stop with a clear error instead of attempting to send

#### Scenario: Configured interface targets the wrong table
- **WHEN** the API interface selected on the general sales price setup declares a source table other than the sales price table
- **THEN** the system SHALL stop with a clear error instead of attempting to send

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

### Requirement: Export failure is visible to the user
The system SHALL make transmission failures visible to the user triggering the export, rather than only recording them silently in the background.

#### Scenario: User sees a failure indication
- **WHEN** the "Upload Sales Price" action triggers a transmission that fails
- **THEN** the resulting message to the user SHALL indicate that at least one line could not be transmitted

### Requirement: Each sales price line tracks its own export status
The system SHALL track, per sales price checking line, whether it has not been sent, was sent successfully, or failed to send, using a distinct status value rather than a single yes/no flag.

#### Scenario: New line starts as not sent
- **WHEN** a sales price checking line is created
- **THEN** its export status SHALL be "Not Sent" until an export attempt is made

#### Scenario: Failed lines remain eligible for automatic retry
- **WHEN** the "Upload Sales Price" action is run again and a line's export status is "Not Sent" or "Error"
- **THEN** the system SHALL attempt to export that line again without asking for confirmation

### Requirement: Resending an already-sent line requires confirmation
The system SHALL NOT silently resend a sales price line whose export status is already "Sent"; it SHALL ask the user for confirmation before doing so.

#### Scenario: User declines to resend
- **WHEN** the "Upload Sales Price" action is run and at least one eligible line has export status "Sent", and the user declines the confirmation prompt
- **THEN** those already-sent lines SHALL be skipped for this run while lines with status "Not Sent" or "Error" are still processed

#### Scenario: User confirms resend
- **WHEN** the "Upload Sales Price" action is run and the user confirms the prompt to resend already-sent lines
- **THEN** those lines SHALL be exported again and their export status SHALL remain or return to "Sent" on success

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

### Requirement: Sales price export entries are not resent by the ChronextBC export job
Because ChronextBC's "Data Export Mgt." (codeunit 50102) sends every "Data Export Entry" with `Status` = "Waiting to Process" through "Data Export API Sender", the system SHALL ensure that no "Data Export Entry" created by the sales price export remains in status "Waiting to Process" after the export of a line has finished. Retrying a failed sales price transmission SHALL happen only via the "Upload Sales Price" action.

#### Scenario: Entry status is final after export
- **WHEN** the sales price export of a line has finished (successfully or not)
- **THEN** the "Data Export Entry" created for it SHALL have `Status` = Processed or `Status` = Error, never "Waiting to Process"

#### Scenario: ChronextBC export job ignores sales price entries
- **WHEN** "Data Export Mgt." runs after sales prices were exported
- **THEN** none of the "Data Export Entry" records with `Destination Code` = `SALESPRICE` SHALL be selected or sent again
