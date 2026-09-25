## MODIFIED Requirements

### Requirement: HTTP Call Logging
The system SHALL create a log entry for every call `SendToApiInterface` makes to the SalesPrice export endpoint, whether the call succeeds or fails, recording the timestamp, the "Data Export Entry" that records this transmission, the endpoint URL, success/failure, the HTTP status code (if a response was received), and the full request and response bodies.

#### Scenario: Successful call is logged
- **WHEN** `SendToApiInterface` sends a request and receives a successful HTTP response
- **THEN** a log entry is created with `CXW Success` = true, the received HTTP status code, and the full request and response bodies stored

#### Scenario: Network failure is logged
- **WHEN** `SendToApiInterface` sends a request and `HttpClient.Send` returns `false` (no response received)
- **THEN** a log entry is created with `CXW Success` = false, an error message describing the failure, and the request body stored (the response is empty)

#### Scenario: Non-success HTTP status is logged
- **WHEN** `SendToApiInterface` sends a request and receives a response with a non-success HTTP status code
- **THEN** a log entry is created with `CXW Success` = false, the received HTTP status code, and both the request and response bodies stored

### Requirement: Log Entries Distinguishable by Source
Since the log table is shared between SellWatch, SalesPrice and the availability export, the system SHALL record which source table triggered each log entry, so entries from the features can be told apart and filtered independently.

#### Scenario: SalesPrice log entry records its source table
- **WHEN** `SendToApiInterface` creates a log entry
- **THEN** the entry's `"CXW Source Table No."` identifies `"Data Export Entry"` (50103) and `"CXW Source Entry No"` identifies the "Data Export Entry" created for that transmission

#### Scenario: Historical SalesPrice log entries remain navigable
- **WHEN** a user looks at a log entry created before this change, whose `"CXW Source Table No."` identifies `"CXW Sales Price Outbound File"`
- **THEN** the entry SHALL still show and relate to the original outbound file record

#### Scenario: Existing SellWatch behavior is unaffected
- **WHEN** SellWatch's `CreateEntryInexternalFile` creates a log entry (per `sellwatch-http-call-logging`)
- **THEN** the entry's `"CXW Source Table No."` identifies `"CXW Watch Online Approval"`, and all previously-specified SellWatch logging behavior continues unchanged
