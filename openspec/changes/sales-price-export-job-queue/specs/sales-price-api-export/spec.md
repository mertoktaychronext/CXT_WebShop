## MODIFIED Requirements

### Requirement: Approved sales prices are transmitted via HTTP
The system SHALL transmit the JSON representation of an approved sales price to the endpoint of the configured API interface using an HTTP request, applying the authentication configured on that interface. Transmission SHALL NOT happen synchronously in a page action; instead, releasing an approved line SHALL create a "Data Export Entry" (ChronextBC table 50103) with `"Destination Code"` = `SALESPRICE`, `"Payload Format"` = JSON, `Status` = `CXW Pending`, the outbound file name in `FileName`, and the "CXW Sales Price Export" record created by the release in `"Source Record ID"`. The entry itself SHALL carry no price data. The job "CXW Export Sales Price Job" (see `sales-price-export-job`) SHALL build the JSON, store it as payload of that entry, and transmit it. The system SHALL NOT write to "CXW Sales Price Outbound File" anymore.

#### Scenario: Release creates a pending entry
- **WHEN** a user releases an approved checking line via "Release Sales Prices"
- **THEN** a "Data Export Entry" with `Destination Code` = `SALESPRICE`, `Status` = `CXW Pending`, `"Attempt Count"` = 0 and `"Source Record ID"` pointing to the new "CXW Sales Price Export" record exists, and no HTTP request is sent during the release

#### Scenario: Successful transmission
- **WHEN** the job transmits a pending entry and the external system responds with a successful HTTP status
- **THEN** the entry has `Status` = Processed, `"Attempt Count"` increased by 1, and `"Processed At"` and `"Last Attempt At"` set to the time of the call

#### Scenario: Failed transmission
- **WHEN** the job transmits a pending entry and the HTTP request fails (network error or non-success HTTP status)
- **THEN** the entry has `Status` = Error, `"Attempt Count"` increased by 1, `"Last Attempt At"` set, `"Processed At"` left empty and `"Error Message"` containing the HTTP status and response text (or the network error text), and the underlying sales price release SHALL NOT be reverted

#### Scenario: Payload is visible in the ChronextBC export entries
- **WHEN** a user opens "Data Export Entries" (page 50108) and selects a `SALESPRICE` entry for which the job has already made at least one attempt
- **THEN** the JSON payload that was transmitted for that sales price SHALL be shown in the payload FactBox

#### Scenario: No legacy outbound file is written
- **WHEN** a sales price is released or transmitted, successfully or not
- **THEN** no new record SHALL be inserted into "CXW Sales Price Outbound File"

### Requirement: Export failure is visible to the user
The system SHALL make transmission failures visible to the user, rather than only recording them silently in the background. Because transmission runs in the job queue, failures SHALL be visible on the `SALESPRICE` entries in "Data Export Entries" (`Status`, `"Error Message"`, `"Attempt Count"`) and in the HTTP call log. Failures of the write-back during release SHALL be reported to the user who runs "Release Sales Prices".

#### Scenario: Transmission failure is visible on the export entry
- **WHEN** the job fails to transmit a `SALESPRICE` entry
- **THEN** the entry shows `Status` = Error and an `"Error Message"` on page 50108, and a corresponding HTTP call log entry exists (unless no request was sent)

#### Scenario: Release reports write-back failures
- **WHEN** "Release Sales Prices" cannot write back at least one line
- **THEN** the closing message to the user SHALL indicate how many of the processed lines were queued for transmission

### Requirement: Each sales price line tracks its own export status
The system SHALL track, per sales price checking line, whether it has not been released for export, has been queued for export, or failed during release, using a distinct status value rather than a single yes/no flag. The value `Queued` SHALL be set when a "Data Export Entry" was created for the line; `Error` SHALL be set when the write-back or archiving failed. The value `Sent` SHALL no longer be set.

#### Scenario: New line starts as not sent
- **WHEN** a sales price checking line is created
- **THEN** its export status SHALL be "Not Sent" until a release is attempted

#### Scenario: Successful release
- **WHEN** "Release Sales Prices" writes back, archives and queues a line
- **THEN** its export status SHALL be "Queued"

#### Scenario: Failed lines remain eligible for automatic retry
- **WHEN** the "Release Sales Prices" action is run again and a line's export status is "Not Sent" or "Error"
- **THEN** the system SHALL attempt to release that line again without asking for confirmation

### Requirement: Resending an already-sent line requires confirmation
The system SHALL NOT silently release a sales price line again whose export status is already "Queued" (or the legacy value "Sent"); it SHALL ask the user for confirmation before doing so.

#### Scenario: User declines to resend
- **WHEN** the "Release Sales Prices" action is run and at least one eligible line has export status "Queued" or "Sent", and the user declines the confirmation prompt
- **THEN** those lines SHALL be skipped for this run while lines with status "Not Sent" or "Error" are still processed

#### Scenario: User confirms resend
- **WHEN** the "Release Sales Prices" action is run and the user confirms the prompt to release already queued lines again
- **THEN** those lines SHALL be written back and queued again with a new "CXW Sales Price Export" record and a new "Data Export Entry", and their export status SHALL be "Queued"

### Requirement: Exported sales price carries the country
Only checking lines with a country SHALL be exported. The JSON transmitted for a released line SHALL contain the key `countryRegionCode` holding the `"CXW Country Code"` of the referenced "CXW Sales Price Export" record, which is never empty. Source lines without a country SHALL NOT be written back, queued or transmitted. The file name stored on the "Data Export Entry" SHALL be `SalesPrice_<Item No.>_<Currency Code>_<Country Code>.json` so that entries for different countries sharing a currency are distinguishable.

#### Scenario: Country line is exported
- **WHEN** a line with `"CXW Country Code"` = `AT` and blank `"CXW Currency Code"` is released and transmitted
- **THEN** the transmitted JSON contains `"countryRegionCode": "AT"` and the `FileName` of the "Data Export Entry" contains both the item number and `AT`

#### Scenario: Two countries with the same currency are exported separately
- **WHEN** approved lines for the same item for DE and AT, both with blank `"CXW Currency Code"`, are released and transmitted
- **THEN** two separate JSON payloads are transmitted, one with `"countryRegionCode": "DE"` and one with `"countryRegionCode": "AT"`, each recorded in its own "Data Export Entry"

#### Scenario: Source line without country is not exported
- **WHEN** "Release Sales Prices" is run and an approved source line has blank `"CXW Country Code"`
- **THEN** no "Sales Price" write-back, no "CXW Sales Price Export" record and no "Data Export Entry" is created for it, its export status remains unchanged, and it is not counted in the closing message

#### Scenario: Only source lines are approved
- **WHEN** "Release Sales Prices" is run and all approved lines are source lines without a country
- **THEN** the action stops with an error asking the user to run "Add all Countries" first

### Requirement: Sales price export entries are not resent by the ChronextBC export job
Because ChronextBC's "Data Export Mgt." (codeunit 50102) sends every "Data Export Entry" with `Status` = "Waiting to Process" through "Data Export API Sender", the system SHALL ensure that no `SALESPRICE` "Data Export Entry" is ever committed with `Status` = "Waiting to Process". Pending entries SHALL use the status `CXW Pending`, added to the enum "Data Export Statuses" by an enum extension, and SHALL be set within the same transaction as the insert. Transmission and retry of `SALESPRICE` entries SHALL happen only via "CXW Export Sales Price Job".

#### Scenario: Entry is never committed as Waiting to Process
- **WHEN** "Release Sales Prices" creates a `SALESPRICE` entry
- **THEN** the committed entry has `Status` = `CXW Pending`, never "Waiting to Process"

#### Scenario: ChronextBC export job ignores sales price entries
- **WHEN** "Data Export Mgt." runs while `SALESPRICE` entries are `CXW Pending`, Processed or Error
- **THEN** none of these entries SHALL be selected, modified or sent
