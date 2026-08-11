# sales-price-aws-sigv4-auth

AWS SigV4 request signing for the SalesPrice export HTTP call, including the new interface-setup credentials it depends on.

## Requirements

### Requirement: AWS SigV4 Auth Type
The system SHALL support `AWSSigV4` as a value of `"CXW API Auth Type"`, distinct from `None`, `ApiKeyHeader`, and `BasicAuth`.

#### Scenario: AWS SigV4 is selectable on an interface
- **WHEN** a user sets `"CXW Auth Type"` to `AWSSigV4` on a `"CXW API Interface Setup"` record
- **THEN** the system accepts the value, the same as any other `"CXW Auth Type"` option

### Requirement: AWS Credential Configuration
The system SHALL let a user configure, per `"CXW API Interface Setup"` record, an AWS Access Key ID, an AWS Region, an AWS Service, an AWS Secret Access Key, and an optional AWS Session Token — following the same storage pattern already used for the existing API key (Isolated Storage for secrets, plain fields for non-secret configuration).

#### Scenario: Non-secret AWS fields are stored as plain fields
- **WHEN** a user enters an AWS Access Key ID, Region, or Service on the interface setup page
- **THEN** the values are stored directly on the `"CXW API Interface Setup"` record, visible in the field the same way `"CXW Endpoint URL"` is

#### Scenario: AWS Secret Access Key is stored securely
- **WHEN** a user enters an AWS Secret Access Key on the interface setup page
- **THEN** the value is stored in Isolated Storage (module scope, keyed per interface code) rather than in a plain table field, and is not shown again once saved

#### Scenario: AWS Session Token is optional
- **WHEN** an interface's AWS Session Token has not been set
- **THEN** the system treats the credentials as a long-lived (non-temporary) IAM credential and omits any session-token-related header from signed requests for that interface

### Requirement: Interfaces cannot be activated without complete AWS SigV4 configuration
When `"CXW Auth Type" = AWSSigV4`, the system SHALL require the AWS Access Key ID, Region, Service, and Secret Access Key to be set before the interface can be marked `"CXW Active"`, mirroring the existing requirement that `ApiKeyHeader`/`BasicAuth` interfaces have an API key before activation.

#### Scenario: Activating an incomplete AWS SigV4 interface is blocked
- **WHEN** a user attempts to set `"CXW Active" = true` on an interface with `"CXW Auth Type" = AWSSigV4` while any of the AWS Access Key ID, Region, Service, or Secret Access Key is blank
- **THEN** the system raises an error and does not activate the interface

#### Scenario: Activating a complete AWS SigV4 interface succeeds
- **WHEN** a user sets `"CXW Active" = true` on an interface with `"CXW Auth Type" = AWSSigV4` and all of the AWS Access Key ID, Region, Service, and Secret Access Key are set
- **THEN** the system activates the interface

### Requirement: AWS SigV4 Request Signing
When sending a request through an interface with `"CXW Auth Type" = AWSSigV4`, the system SHALL sign the request per the AWS Signature Version 4 algorithm (`AWS4-HMAC-SHA256`), producing an `Authorization` header containing the derived `Credential`, `SignedHeaders`, and `Signature`, and an `X-Amz-Date` header, such that a correctly configured AWS SigV4-verifying endpoint accepts the request.

#### Scenario: Signed headers include host and the timestamp
- **WHEN** the system signs a request for an AWS SigV4 interface
- **THEN** the `SignedHeaders` list in the `Authorization` header includes at minimum `content-type`, `host`, and `x-amz-date`, matching the headers actually present on the sent request

#### Scenario: Session token is included when configured
- **WHEN** the system signs a request for an AWS SigV4 interface whose AWS Session Token is non-blank
- **THEN** the request includes an `X-Amz-Security-Token` header carrying that token, and `x-amz-security-token` is part of the signed headers list

#### Scenario: Session token is omitted when not configured
- **WHEN** the system signs a request for an AWS SigV4 interface whose AWS Session Token is blank
- **THEN** the request does not include an `X-Amz-Security-Token` header, and it is not part of the signed headers list

### Requirement: AWS Credentials Are Redacted in Logged Requests
The system SHALL NOT persist the real AWS Secret Access Key, Session Token, or the derived request signature's ability to be replayed in a way that exposes the secret, in any logged request text for an AWS SigV4 call. The logged request SHALL show that the request was authenticated, with the sensitive parts of the `Authorization` header redacted, consistent with how `ApiKeyHeader`/`BasicAuth` requests are already redacted before being logged.

#### Scenario: AWS SigV4 auth is redacted in the log
- **WHEN** a log entry is created for a call sent with `"CXW Auth Type" = AWSSigV4`
- **THEN** the stored request text does not contain the real AWS Secret Access Key or Session Token anywhere, and the `Authorization`/`X-Amz-Security-Token` header values are shown redacted rather than in full
