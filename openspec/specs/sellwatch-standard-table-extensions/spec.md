# sellwatch-standard-table-extensions

## Purpose

Table extensions that add the SellWatch-specific fields (`Used good` on `Purchase Line`, `Tracking Number` on `Purchase Header`) required by the SellWatch purchase order creation flow.

## Requirements

### Requirement: Purchase Line Used Good Flag
The system SHALL provide a `Used good` boolean field, added via table extension to the standard `Purchase Line` table, so that purchase lines created from SellWatch offers can be flagged as used goods.

#### Scenario: SellWatch creates a purchase line
- **WHEN** `Codeunit "SellWatch Mgt"` inserts a new `Purchase Line` for a purchase order created from a `SellWatch Vendor Info` entry
- **THEN** the new `Purchase Line` record's `Used good` field SHALL be set to `true`

### Requirement: Purchase Header Tracking Number Field
The system SHALL provide a `Tracking Number` text field, added via table extension to the standard `Purchase Header` table, so that tracking numbers recorded on a SellWatch purchase order can be read back into the SellWatch source-file JSON and into the `SellWatch Vendor Info` overview.

#### Scenario: Purchase request JSON includes a tracking number
- **WHEN** `Codeunit "SellWatch Mgt"`'s `CreateSourceFilePurchaseRequest` builds the JSON payload for a `Purchase Header` whose `Tracking Number` field is not blank
- **THEN** the JSON payload SHALL include a `tracking_number` property with that value

#### Scenario: SellWatch Vendor Info shows the tracking number
- **WHEN** the `Tracking Number` FlowField on a `SellWatch Vendor Info` record is calculated for an entry whose `PO Number` matches an Order-type `Purchase Header`
- **THEN** the FlowField SHALL return that `Purchase Header` record's `Tracking Number` value
