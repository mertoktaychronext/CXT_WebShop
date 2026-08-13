## ADDED Requirements

### Requirement: Generic API interface can be configured
The system SHALL provide a generic, reusable setup table where a Key User can define outbound API interfaces, each identified by a unique code and holding an endpoint URL, an authentication type, an active flag, and a reference to the object (table) this interface is used for.

#### Scenario: Key User creates a new API interface
- **WHEN** a Key User creates a new entry with a unique code, an endpoint URL, and selects a source table
- **THEN** the system saves the entry and makes it selectable from other setup areas that reference API interfaces

#### Scenario: Endpoint URL is required
- **WHEN** a Key User tries to activate an API interface entry without an endpoint URL
- **THEN** the system SHALL block activation with an error indicating the endpoint URL is missing

### Requirement: API interface can be deactivated without deletion
The system SHALL allow a Key User to deactivate an API interface entry so it can no longer be selected or used for sending data, without deleting its configuration.

#### Scenario: Deactivated interface is not usable
- **WHEN** an API interface entry has its active flag set to false
- **THEN** any feature attempting to use it for sending data SHALL fail with a clear error instead of silently sending

### Requirement: Authentication credentials are stored securely
The system SHALL store any API key or token required for authentication in Isolated Storage rather than as plain, readable table data, and SHALL never display the stored secret value in the user interface once saved.

#### Scenario: Secret is not visible after saving
- **WHEN** a Key User enters an API key for an interface and saves it
- **THEN** reopening the interface card SHALL NOT display the previously entered API key in plain text

#### Scenario: Secret is scoped to the extension
- **WHEN** the API key is stored
- **THEN** it SHALL be stored using an isolated storage scope that is only accessible to this extension

### Requirement: Interface declares its expected source table
The system SHALL require each API interface entry to declare which table's data it is intended to transmit, so that other features can validate they are using a correctly configured interface.

#### Scenario: Source table mismatch is rejected
- **WHEN** a feature attempts to use an API interface entry whose declared source table does not match the table it wants to send
- **THEN** the system SHALL block the operation with an error naming the mismatch
