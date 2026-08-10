## MODIFIED Requirements

### Requirement: Purchase Line Used Good Flag
The system SHALL provide a `CXW Used good` boolean field, added via table extension to the standard `Purchase Line` table, so that purchase lines created from SellWatch offers can be flagged as used goods.

#### Scenario: SellWatch creates a purchase line
- **WHEN** `Codeunit "CXW SellWatch Mgt"` inserts a new `Purchase Line` for a purchase order created from a `CXW SellWatch Vendor Info` entry
- **THEN** the new `Purchase Line` record's `CXW Used good` field SHALL be set to `true`

### Requirement: Purchase Header Tracking Number Field
The system SHALL provide a `CXW Tracking Number` text field, added via table extension to the standard `Purchase Header` table, so that tracking numbers recorded on a SellWatch purchase order can be read back into the SellWatch source-file JSON and into the `CXW SellWatch Vendor Info` overview.

#### Scenario: Purchase request JSON includes a tracking number
- **WHEN** `Codeunit "CXW SellWatch Mgt"`'s `CreateSourceFilePurchaseRequest` builds the JSON payload for a `Purchase Header` whose `CXW Tracking Number` field is not blank
- **THEN** the JSON payload SHALL include a `tracking_number` property with that value

#### Scenario: SellWatch Vendor Info shows the tracking number
- **WHEN** the `CXW Tracking Number` FlowField on a `CXW SellWatch Vendor Info` record is calculated for an entry whose `CXW PO Number` matches an Order-type `Purchase Header`
- **THEN** the FlowField SHALL return that `Purchase Header` record's `CXW Tracking Number` value
