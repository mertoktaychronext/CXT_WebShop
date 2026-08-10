# sellwatch-http-call-logging

Logging (table + downloadable request/response + telemetry on failure) for the SellWatch online-check HTTP call.

## Requirements

### Requirement: HTTP Call Logging
The system SHALL create a log entry for every call `CreateEntryInexternalFile` makes to the SellWatch online-check endpoint, whether the call succeeds or fails, recording the timestamp, the triggering `Watch Online Approval` entry, the endpoint URL, success/failure, the HTTP status code (if a response was received), and the full request and response bodies.

#### Scenario: Successful call is logged
- **WHEN** `CreateEntryInexternalFile` sends a request and receives a successful HTTP response
- **THEN** a log entry is created with `Success` = true, the received HTTP status code, and the full request and response bodies stored

#### Scenario: Network failure is logged
- **WHEN** `CreateEntryInexternalFile` sends a request and `HttpClient.Send` returns `false` (no response received)
- **THEN** a log entry is created with `Success` = false, an error message describing the failure, and the request body stored (the response is empty)

#### Scenario: Non-success HTTP status is logged
- **WHEN** `CreateEntryInexternalFile` sends a request and receives a response with a non-success HTTP status code
- **THEN** a log entry is created with `Success` = false, the received HTTP status code, and both the request and response bodies stored

### Requirement: API Key Redaction in Logged Requests
The system SHALL NOT persist the real value of the `X-API-KEY` request header in any logged request. The logged request text SHALL show that the header was sent, with its value replaced by a fixed placeholder.

#### Scenario: API key is redacted in the log
- **WHEN** a log entry is created for a call that included the `X-API-KEY` header
- **THEN** the stored request body contains the `X-API-KEY` header name with a redacted placeholder value, and does not contain the real API key value anywhere in the stored text

### Requirement: Failure Telemetry
The system SHALL raise a telemetry event for every failed call to the SellWatch online-check endpoint, in addition to the table log entry, so failures are visible without opening the log page.

#### Scenario: Telemetry event raised on failure
- **WHEN** a call to the SellWatch online-check endpoint fails (network failure or non-success HTTP status)
- **THEN** a telemetry event is logged recording the endpoint, the HTTP status code (if any), and the triggering `Watch Online Approval` entry number

#### Scenario: No telemetry event on success
- **WHEN** a call to the SellWatch online-check endpoint succeeds
- **THEN** no failure telemetry event is raised for that call

### Requirement: Downloadable Request and Response
The system SHALL let a user download the stored request and the stored response of a logged call as separate `.txt` files.

#### Scenario: Downloading the request
- **WHEN** a user selects a log entry and chooses to download its request
- **THEN** the system offers the full logged request text as a `.txt` file download

#### Scenario: Downloading the response
- **WHEN** a user selects a log entry and chooses to download its response
- **THEN** the system offers the full logged response text as a `.txt` file download
