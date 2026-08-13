## ADDED Requirements

### Requirement: Sales price export uses a configured API interface
The system SHALL allow a Key User to select exactly one API interface (from the generic API interface setup) on the general sales price setup, to be used whenever an approved sales price is sent to the external system.

#### Scenario: No interface configured
- **WHEN** the export gateway attempts to send a sales price and no API interface is selected on the general sales price setup
- **THEN** the system SHALL stop with a clear error instead of attempting to send

#### Scenario: Configured interface targets the wrong table
- **WHEN** the API interface selected on the general sales price setup declares a source table other than the sales price table
- **THEN** the system SHALL stop with a clear error instead of attempting to send

### Requirement: Approved sales prices are transmitted via HTTP
The system SHALL transmit the JSON representation of an approved sales price to the endpoint of the configured API interface using an HTTP request, applying the authentication configured on that interface.

#### Scenario: Successful transmission
- **WHEN** a sales price is exported and the external system responds with a successful HTTP status
- **THEN** the corresponding outbound file entry SHALL be marked as processed

#### Scenario: Failed transmission
- **WHEN** a sales price is exported and the HTTP request fails (network error or non-success HTTP status)
- **THEN** the corresponding outbound file entry SHALL be marked as an error, and the underlying sales price approval SHALL NOT be reverted

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
