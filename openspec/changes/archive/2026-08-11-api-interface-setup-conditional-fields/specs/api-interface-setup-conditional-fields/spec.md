## ADDED Requirements

### Requirement: Field Relevance Rules Centralized on the Interface Setup Table
The system SHALL expose, on `"CXW API Interface Setup"` (Table 60317), procedures that determine whether the API Key field and the AWS-specific fields (Access Key ID, Region, Service, Secret Access Key, Session Token) are relevant for the record's current `"CXW Auth Type"`, so that no other object needs to duplicate these conditions.

#### Scenario: API Key field is relevant for key-based and AWS SigV4 auth types
- **WHEN** `"CXW Auth Type"` is `ApiKeyHeader`, `BasicAuth`, or `AWSSigV4`
- **THEN** the system reports the API Key field as relevant

#### Scenario: API Key field is not relevant when no authentication is used
- **WHEN** `"CXW Auth Type"` is `None`
- **THEN** the system reports the API Key field as not relevant

#### Scenario: AWS-specific fields are relevant only for AWS Signature V4
- **WHEN** `"CXW Auth Type"` is `AWSSigV4`
- **THEN** the system reports the AWS-specific fields as relevant

#### Scenario: AWS-specific fields are not relevant for other auth types
- **WHEN** `"CXW Auth Type"` is `None`, `ApiKeyHeader`, or `BasicAuth`
- **THEN** the system reports the AWS-specific fields as not relevant

### Requirement: Detail Editing Page Shows Only Relevant Fields
The system SHALL provide a single-record editing page for `"CXW API Interface Setup"` on which the API Key field and the AWS-specific fields are shown or hidden according to the record's current `"CXW Auth Type"`, using the relevance rules from Table 60317.

#### Scenario: No auth type selected
- **WHEN** a user opens the detail editing page for an interface with `"CXW Auth Type"` = `None`
- **THEN** the API Key field and all AWS-specific fields are hidden

#### Scenario: Key-based auth type selected
- **WHEN** a user opens the detail editing page for an interface with `"CXW Auth Type"` = `ApiKeyHeader` or `BasicAuth`
- **THEN** the API Key field is shown and the AWS-specific fields are hidden

#### Scenario: AWS Signature V4 selected
- **WHEN** a user opens the detail editing page for an interface with `"CXW Auth Type"` = `AWSSigV4`
- **THEN** the API Key field and all AWS-specific fields are shown

### Requirement: Field Visibility Updates Live on Auth Type Change
When a user changes `"CXW Auth Type"` while editing an interface on the detail editing page, the system SHALL immediately update which detail fields are shown, without requiring the record to be saved and reopened.

#### Scenario: Switching away from AWS Signature V4
- **WHEN** a user changes `"CXW Auth Type"` from `AWSSigV4` to `BasicAuth` on the detail editing page
- **THEN** the AWS-specific fields become hidden immediately and the API Key field remains shown

#### Scenario: Switching to AWS Signature V4
- **WHEN** a user changes `"CXW Auth Type"` from `None` to `AWSSigV4` on the detail editing page
- **THEN** the API Key field and the AWS-specific fields become shown immediately

### Requirement: List Page Stays a Trimmed Overview
The list page for `"CXW API Interface Setup"` SHALL continue to show Code, Description, Endpoint URL, Auth Type, and Active for browsing and comparing interfaces, and SHALL NOT show the type-specific detail fields (API Key, AWS-specific fields, HTTP Method, SOAP Action) inline.

#### Scenario: Browsing interfaces
- **WHEN** a user opens the list page for API interfaces
- **THEN** the visible columns are Code, Description, Endpoint URL, Auth Type, and Active, and none of the type-specific detail fields are shown as columns

### Requirement: Navigating to Detail Editing
The system SHALL let a user open the detail editing page for a specific interface directly from the list page.

#### Scenario: Drilling into an interface
- **WHEN** a user drills down on a row in the list page
- **THEN** the detail editing page opens for that interface, showing its fields subject to the relevance rules

### Requirement: Activation Guard Uses the Shared Relevance Rules
The existing activation guard on `"CXW Active"` SHALL use the same relevance procedures as the detail editing page, rather than separately duplicated conditions, so the two cannot drift out of sync.

#### Scenario: Activation still blocked for incomplete AWS Signature V4 configuration
- **WHEN** a user attempts to set `"CXW Active" = true` on an interface with `"CXW Auth Type" = AWSSigV4` while any AWS-specific field required for relevance is blank
- **THEN** the system raises an error and does not activate the interface, using the same relevance determination the detail editing page uses to decide field visibility
