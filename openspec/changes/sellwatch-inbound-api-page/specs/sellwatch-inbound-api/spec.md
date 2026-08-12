## ADDED Requirements

### Requirement: SellWatch Inbound API Page
The system SHALL provide a `PageType = API` page over table 60300 "CXW SellWatch Vendor Info" that allows an authenticated external system to create and update SellWatch entries via HTTP call, separate from and without modifying `Page 60307 "CXW SellWatch-Overview"`.

#### Scenario: External system creates a SellWatch entry via HTTP POST
- **WHEN** an authenticated external system sends an HTTP POST with a JSON body containing vendor, watch, and offer fields to the SellWatch API endpoint
- **THEN** the system SHALL insert a new "CXW SellWatch Vendor Info" record with those field values

#### Scenario: New entry is immediately visible on the overview page
- **WHEN** a "CXW SellWatch Vendor Info" record is inserted via the API
- **THEN** the record SHALL appear on `Page 60307 "CXW SellWatch-Overview"` without any change to that page's definition

### Requirement: System-Owned Fields Are Not Externally Writable
The API page SHALL prevent external callers from setting or overwriting the processing-state fields owned by `Codeunit "CXW SellWatch Mgt"` (`"CXW Created"`, `"CXW PO Number"`, `"CXW VendorNo"`) and the system-managed `"CXW Entry No"` primary key.

#### Scenario: Caller attempts to submit CXW Created = true
- **WHEN** an external system's HTTP request body includes `"CXW Created": true` on insert
- **THEN** the system SHALL ignore that value and set `"CXW Created" = false` on the inserted record

#### Scenario: Caller attempts to set the PO Number or Vendor No directly
- **WHEN** an external system's HTTP request includes values for `"CXW PO Number"` or `"CXW VendorNo"`
- **THEN** the system SHALL reject or ignore those field values, leaving them to be populated only by `Codeunit "CXW SellWatch Mgt"`

### Requirement: Duplicate Submission Protection via External Reference
The system SHALL use the `"CXW SRid"` field as the external caller's reference identifier to detect duplicate submissions, since the internal `"CXW Entry No"` primary key is not known to external callers.

#### Scenario: Duplicate SRid submitted
- **WHEN** an external system submits an insert with a `"CXW SRid"` value that already exists on another "CXW SellWatch Vendor Info" record
- **THEN** the system SHALL reject the insert as a duplicate instead of creating a second entry with the same `"CXW SRid"`

### Requirement: API Access Restricted to Authorized Users
The system SHALL restrict access to the SellWatch inbound API page to callers authenticated via standard Business Central API authentication (Web Service Access Key or OAuth) and authorized through the SellWatch permission set.

#### Scenario: Unauthenticated request is rejected
- **WHEN** an HTTP call to the SellWatch API endpoint is made without valid BC API credentials
- **THEN** the system SHALL reject the request per standard Business Central API authentication behavior

#### Scenario: Authenticated user without SellWatch permissions is rejected
- **WHEN** an authenticated caller's user account lacks the permission set entry for the SellWatch API page
- **THEN** the system SHALL deny access to the API endpoint
