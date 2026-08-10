## ADDED Requirements

### Requirement: HTTP Call Logging
The system SHALL create a log entry for every call `SendToApiInterface` makes to the SalesPrice export endpoint, whether the call succeeds or fails, recording the timestamp, the triggering `"CXW Sales Price Outbound File"` entry, the endpoint URL, success/failure, the HTTP status code (if a response was received), and the full request and response bodies.

#### Scenario: Successful call is logged
- **WHEN** `SendToApiInterface` sends a request and receives a successful HTTP response
- **THEN** a log entry is created with `CXW Success` = true, the received HTTP status code, and the full request and response bodies stored

#### Scenario: Network failure is logged
- **WHEN** `SendToApiInterface` sends a request and `HttpClient.Send` returns `false` (no response received)
- **THEN** a log entry is created with `CXW Success` = false, an error message describing the failure, and the request body stored (the response is empty)

#### Scenario: Non-success HTTP status is logged
- **WHEN** `SendToApiInterface` sends a request and receives a response with a non-success HTTP status code
- **THEN** a log entry is created with `CXW Success` = false, the received HTTP status code, and both the request and response bodies stored

### Requirement: Authorization Header Redaction in Logged Requests
The system SHALL NOT persist the real value of the `Authorization` request header in any logged request. The logged request text SHALL show that the header was sent, with its value replaced by a fixed placeholder, regardless of whether the underlying authentication is an API key or Basic auth.

#### Scenario: API key auth is redacted in the log
- **WHEN** a log entry is created for a call sent with `Auth Type` = API Key Header
- **THEN** the stored request body contains the `Authorization` header name with a redacted placeholder value, and does not contain the real API key anywhere in the stored text

#### Scenario: Basic auth is redacted in the log
- **WHEN** a log entry is created for a call sent with `Auth Type` = Basic Authentication
- **THEN** the stored request body contains the `Authorization` header name with a redacted placeholder value, and does not contain the real (Base64-encoded) credentials anywhere in the stored text

### Requirement: Downloadable Request and Response
The system SHALL let a user download the stored request and the stored response of a logged SalesPrice call as separate `.txt` files, using the same shared log page SellWatch's calls already use.

#### Scenario: Downloading the request
- **WHEN** a user selects a SalesPrice log entry and chooses to download its request
- **THEN** the system offers the full logged request text as a `.txt` file download

#### Scenario: Downloading the response
- **WHEN** a user selects a SalesPrice log entry and chooses to download its response
- **THEN** the system offers the full logged response text as a `.txt` file download

### Requirement: Log Entries Distinguishable by Source
Since the log table is shared between SellWatch and SalesPrice, the system SHALL record which source table triggered each log entry, so entries from the two features can be told apart and filtered independently.

#### Scenario: SalesPrice log entry records its source table
- **WHEN** `SendToApiInterface` creates a log entry
- **THEN** the entry's `"CXW Source Table No."` identifies `"CXW Sales Price Outbound File"` and `"CXW Source Entry No"` identifies the specific outbound file record

#### Scenario: Existing SellWatch behavior is unaffected
- **WHEN** SellWatch's `CreateEntryInexternalFile` creates a log entry (per `sellwatch-http-call-logging`)
- **THEN** the entry's `"CXW Source Table No."` identifies `"CXW Watch Online Approval"`, and all previously-specified SellWatch logging behavior continues unchanged
