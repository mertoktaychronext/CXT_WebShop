# workshop-line-api-purchase-data Specification

## Purpose
TBD - created by archiving change workshop-line-api-purchase-data. Update Purpose after archive.
## Requirements
### Requirement: Workshop lines API returns purchase data
The `workshopLines` API (page "CXW Workshop Line API") SHALL return, for every workshop line, the following read-only fields: `vendorOrderNo`, `vendorNo`, `vendorName`, `variantCode`, `description`, `quantity`, `unitPrice`, `seller_currency` and `usedGoods`. Their values SHALL be taken from the purchase order header and purchase order line of the workshop line at the time the line was sent to the workshop: `"Vendor Order No."`, `"Buy-from Vendor No."`, `"Buy-from Vendor Name"`, `"Currency Code"` (header) and `"Variant Code"`, `Description`, `Quantity`, `"Direct Unit Cost"`, `"Used Good"` (line). If the purchase order has no currency code, `seller_currency` SHALL contain the local currency code from the general ledger setup.

#### Scenario: Purchase data in the API response
- **WHEN** a purchase order line for vendor V0001 "Watch Seller GmbH" with vendor order no. "SR-4711", currency USD, variant V001, description "Rolex Submariner", quantity 1, direct unit cost 7500 and "Used Good" = true is sent to the workshop, and the workshop reads `workshopLines`
- **THEN** the returned line contains `"vendorNo": "V0001"`, `"vendorName": "Watch Seller GmbH"`, `"vendorOrderNo": "SR-4711"`, `"seller_currency": "USD"`, `"variantCode": "V001"`, `"description": "Rolex Submariner"`, `"quantity": 1`, `"unitPrice": 7500` and `"usedGoods": true`

#### Scenario: Purchase order in local currency
- **WHEN** a line of a purchase order with blank currency code is sent to the workshop and the local currency code is EUR
- **THEN** the API returns `"seller_currency": "EUR"`

#### Scenario: Values are a snapshot of the hand-over
- **WHEN** the description of the purchase order line is changed after the line was sent to the workshop
- **THEN** the API still returns the description at the time of sending

#### Scenario: Values survive cancellation of the order
- **WHEN** the purchase order is deleted after the workshop disproved authenticity
- **THEN** the workshop line still returns the purchase data it was created with

### Requirement: Workshop lines API returns watch data from the item attributes
The `workshopLines` API SHALL return the read-only fields `brand`, `model`, `subModel`, `ref`, `year`, `condition`, `box` and `certificate`. Their values SHALL be taken, at the time the line was sent to the workshop, from the item attribute values assigned to the item of the purchase order line ("Item Attribute Value Mapping" for table Item) with the item attribute IDs 1 (`brand`), 2 (`model`), 3 (`subModel`), 5 (`ref`), 8 (`year`), 10 (`condition`), 11 (`box`) and 13 (`certificate`). The text values SHALL be passed on unchanged. `year` SHALL be returned as a number; a value that is not an integer SHALL be returned as `0`. All eight fields SHALL always be included in the response, as `""` (or `0` for `year`) if no value is assigned. A missing attribute value SHALL NOT prevent sending the line to the workshop.

#### Scenario: Watch data available
- **WHEN** the item of a line has the attribute values 1 = "Rolex", 2 = "Submariner", 3 = "Date", 5 = "126610LN", 8 = "2021", 10 = "AA", 11 = "ja", 13 = "nein", and the line is sent to the workshop
- **THEN** the API returns `"brand": "Rolex"`, `"model": "Submariner"`, `"subModel": "Date"`, `"ref": "126610LN"`, `"year": 2021`, `"condition": "AA"`, `"box": "ja"` and `"certificate": "nein"`

#### Scenario: Optional values not maintained
- **WHEN** the item has no values for the attributes 3, 5 and 8
- **THEN** the API returns `"subModel": ""`, `"ref": ""` and `"year": 0`

#### Scenario: Year is not a number
- **WHEN** the value of attribute 8 is "2015-2018"
- **THEN** the API returns `"year": 0`

#### Scenario: No watch data maintained
- **WHEN** a line is sent to the workshop for an item without any of these attribute values
- **THEN** the workshop line is created, and the API returns empty values for the watch data fields and `0` for `year`

### Requirement: Workshop lines API returns the tenant
The `workshopLines` API SHALL return a read-only field `tenant` with the value of the setup field "Workshop Tenant" on the purchases & payables setup of the company. The value SHALL be read at runtime and SHALL NOT be stored on the workshop line.

#### Scenario: Tenant in the response
- **WHEN** "Workshop Tenant" is set to "GmbH" and the workshop reads `workshopLines`
- **THEN** every returned line contains `"tenant": "GmbH"`

#### Scenario: Tenant changed after sending
- **WHEN** "Workshop Tenant" is changed after lines were sent to the workshop
- **THEN** the API returns the new value for these lines as well

### Requirement: Additional fields cannot be changed through the API
The workshop SHALL NOT be able to change any of the additional fields through the API. A PATCH request that changes one of them SHALL be rejected with an error, and the workshop line SHALL remain unchanged. Writing the existing check result fields SHALL continue to work.

#### Scenario: Attempt to change the vendor
- **WHEN** the workshop sends a PATCH request that sets `vendorNo` to a different value
- **THEN** the request is rejected with an error and the workshop line keeps its original values

#### Scenario: Check result can still be written
- **WHEN** the workshop sends a PATCH request with `status`, `genuine` and attribute values only
- **THEN** the changes are saved as before

### Requirement: The workshop API user gets no access to purchase, vendor or item data
The permission set "CXW Workshop API" SHALL grant, besides the workshop line table, only read access to "Purchases & Payables Setup" (needed for `tenant`). Returning the purchase and watch data SHALL NOT require access to purchase documents, vendors, items or item attributes for the workshop API user.

#### Scenario: API user reads the additional fields
- **WHEN** a user with only the permission set "CXW Workshop API" reads `workshopLines`
- **THEN** all additional fields, including `tenant`, are returned without a permission error

#### Scenario: API user cannot read purchase orders
- **WHEN** a user with only the permission set "CXW Workshop API" tries to read a purchase order through any other API or page
- **THEN** access is denied

### Requirement: Existing open workshop lines are filled on upgrade
When the extension is upgraded, the system SHALL fill the additional fields once for existing workshop lines with status `New` or `WS checked` whose purchase order line still exists. Lines with status `Processed` or `Error` SHALL remain unchanged. The fill SHALL run only once per company.

#### Scenario: Open line is filled
- **WHEN** the extension is upgraded and a workshop line with status `New` exists whose purchase order line still exists
- **THEN** the line's purchase and watch data fields are filled from the purchase order and the item attributes

#### Scenario: Processed line is not changed
- **WHEN** the extension is upgraded and a workshop line with status `Processed` exists
- **THEN** its additional fields remain empty

#### Scenario: Second upgrade does not fill again
- **WHEN** the extension is upgraded a second time
- **THEN** the fill is not executed again

### Requirement: Additional fields are visible internally
The page "CXW Workshop Lines" SHALL show the additional purchase and watch data fields read-only, and the purchases & payables setup page SHALL show the field "Workshop Tenant".

#### Scenario: Internal user checks what the workshop received
- **WHEN** a user opens "CXW Workshop Lines"
- **THEN** vendor, vendor order no., description, quantity, unit price, currency, used goods and the watch data fields of each line are visible

