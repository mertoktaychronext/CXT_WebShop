# sales-price-export-job Specification

## Purpose
TBD - created by archiving change sales-price-export-job-queue. Update Purpose after archive.
## Requirements
### Requirement: Released prices are stored per country in the sales price export table
When a checking line with a country is released, the system SHALL insert exactly one record into the table "CXW Sales Price Export" that holds the released price of that line's country: item number, country code, currency code, starting/ending date and time, unit price (from `"CXW Stock Price"`), unit price (LCY) calculated at release, non-stock price, strike price, recommended retail price, exchange rate amount and date, reason code, comment, remark, last modified user and date, the `SystemId` of the written "Sales Price" record, and the entry number of the "Data Export Entry" created for it. Records SHALL NOT be changed after the release, except for the entry number back-reference.

#### Scenario: One record per released country line
- **WHEN** approved lines for item A61087 for DE, AT and US are released
- **THEN** three "CXW Sales Price Export" records exist, one per country, each with its own prices and its own "Data Export Entry"

#### Scenario: Countries sharing a currency keep their own price
- **WHEN** DE is released with a price of 1000 and afterwards AT with a price of 1100, both with blank currency
- **THEN** the "CXW Sales Price Export" record for DE still holds 1000 and the record for AT holds 1100

#### Scenario: Unit price (LCY) is frozen at release
- **WHEN** a US line with `"CXW Exchange Rate Amount"` = 1.14 and a unit price of 2790 is released
- **THEN** the record holds `"CXW Unit Price (LCY)"` = 2790 / 1.14, and a later change of exchange rates does not change it

#### Scenario: Records are visible in a list
- **WHEN** a user opens "CXW Sales Price Export Entries"
- **THEN** all released prices are listed with their country and the current status of the related "Data Export Entry", and the user can drill down to that entry

### Requirement: The export entry only references the sales price export record
The "Data Export Entry" created on release SHALL carry no price data of its own. Its `"Source Record ID"` SHALL be the record ID of the "CXW Sales Price Export" record, which the job uses to determine what to export. The system SHALL NOT add fields to "Data Export Entry" via table extension.

#### Scenario: Job resolves the export record
- **WHEN** the job processes a pending `SALESPRICE` entry
- **THEN** it reads the price data from the "CXW Sales Price Export" record identified by the entry's `"Source Record ID"`

#### Scenario: Export record no longer exists
- **WHEN** the "CXW Sales Price Export" record referenced by the entry cannot be found and the payload has not been built yet
- **THEN** the entry is set to `Status` = Error with an explanatory `"Error Message"`, `"Attempt Count"` is increased by 1, and no HTTP request is sent

### Requirement: Sales price export runs as a job queue codeunit
The system SHALL provide a codeunit "CXW Export Sales Price Job" with `TableNo = "Job Queue Entry"` that a Key User can schedule as a recurring Job Queue Entry. Each run SHALL process every "Data Export Entry" with `Destination Code` = `SALESPRICE` that is eligible according to the selection rule, and transmit it via the API interface configured on the general sales price setup.

#### Scenario: Pending entries are exported
- **WHEN** the job runs and there are "Data Export Entry" records with `Destination Code` = `SALESPRICE` and `Status` = `CXW Pending`
- **THEN** each of these entries is transmitted and ends with `Status` = Processed or `Status` = Error

#### Scenario: Entries of other destinations are ignored
- **WHEN** the job runs and there are "Data Export Entry" records with a `Destination Code` other than `SALESPRICE`
- **THEN** those entries are neither selected nor modified

#### Scenario: Export deactivated
- **WHEN** the job runs and `"CXW Price Export Active"` is false or `"CXW API Interface Code"` is blank on the general sales price setup
- **THEN** the job ends without error, no entry is transmitted and all `CXW Pending` entries keep their status

### Requirement: Failed entries are retried up to a configurable maximum
The system SHALL retry a `SALESPRICE` "Data Export Entry" with `Status` = Error on each job run as long as its `"Attempt Count"` is less than `"CXW Max. Export Attempts"` on the general sales price setup (default 3; a value of 0 SHALL be treated as 3). Once `"Attempt Count"` has reached that maximum, the entry SHALL NOT be selected again until it is requeued manually.

#### Scenario: Retry below the maximum
- **WHEN** the job runs, `"CXW Max. Export Attempts"` = 3, and a `SALESPRICE` entry has `Status` = Error and `"Attempt Count"` = 2
- **THEN** the entry is transmitted again and its `"Attempt Count"` becomes 3

#### Scenario: Maximum reached
- **WHEN** the job runs, `"CXW Max. Export Attempts"` = 3, and a `SALESPRICE` entry has `Status` = Error and `"Attempt Count"` = 3
- **THEN** the entry is not selected and remains unchanged

#### Scenario: Retry sends the same payload
- **WHEN** an entry whose payload was already built in an earlier attempt is retried
- **THEN** the stored payload is transmitted unchanged and is not rebuilt

### Requirement: Every attempt updates the export entry
For every transmission attempt the job SHALL increment `"Attempt Count"` by 1 and set `"Last Attempt At"` on the "Data Export Entry". On success it SHALL set `Status` = Processed and `"Processed At"`. On failure (network error, non-success HTTP status, or a runtime error while building the payload) it SHALL set `Status` = Error and `"Error Message"` to the HTTP status and response text, the network error text, or the runtime error text, truncated to the field length.

#### Scenario: Successful attempt
- **WHEN** the endpoint responds with a successful HTTP status
- **THEN** the entry has `Status` = Processed, `"Processed At"` and `"Last Attempt At"` set, and `"Attempt Count"` increased by 1

#### Scenario: HTTP failure
- **WHEN** the endpoint responds with HTTP 500 and body `boom`
- **THEN** the entry has `Status` = Error, `"Error Message"` containing `HTTP 500: boom`, and `"Attempt Count"` increased by 1

### Requirement: One failing entry does not abort the job run
The job SHALL process each entry in isolation and commit its result before continuing with the next entry. A failure on one entry SHALL NOT roll back or prevent the processing of other entries, and the job run itself SHALL NOT end with an error because individual entries failed.

#### Scenario: Mixed results in one run
- **WHEN** the job processes three pending entries and the second one fails
- **THEN** the first and third entries end as Processed, the second ends as Error, and the Job Queue Entry finishes successfully

### Requirement: Sales price payload format
The payload built for a `SALESPRICE` entry SHALL be a JSON object containing exactly the following keys, in this order: `itemNo`, `variantCode`, `salesType`, `salesCode`, `startingDate`, `currencyCode`, `countryRegionCode`, `unitOfMeasureCode`, `minimumQuantity`, `unitPrice`, `priceIncludesVat`, `allowInvoiceDisc`, `vatBusPostingGrPrice`, `endingDate`, `allowLineDisc`, `id`, `remark`, `nonStockPrice`, `lastModifiedUserID`, `lastModifiedDate`, `reasonCode`, `comment`, `strikePriceInclVat`, `recomRetailPriceInclVat`, `unitPriceLcy`, `startingTime`, `endingTime`, `profit`, `unitCost`, `vatProdPostingGroup`. The keys `promotionMediumNo`, `promMedTarGrpNo`, `setNo`, `sizeCodeDiva`, `colorCodeDiva`, `colorDescriptionDiva`, `sizeDescriptionDiva`, `systemValueSizeCodes`, `systemValueColorCodes`, `sizeToEnterCode`, `priceGroupId`, `fallBackPrice`, `documentUnitPrice`, `deliveryCostLimitCode` and `priceChangeSuggWriteOff` SHALL NOT be included.

#### Scenario: Complete key set
- **WHEN** the job builds the payload for any entry
- **THEN** the JSON contains all 30 listed keys, in the listed order, and none of the excluded keys

#### Scenario: Value types
- **WHEN** the job builds the payload
- **THEN** `minimumQuantity`, `unitPrice`, `nonStockPrice`, `strikePriceInclVat`, `recomRetailPriceInclVat`, `unitPriceLcy`, `profit` and `unitCost` are JSON numbers, `priceIncludesVat`, `allowInvoiceDisc` and `allowLineDisc` are JSON booleans, and all other keys are JSON strings

#### Scenario: Empty date and time values
- **WHEN** the export record has no starting date, ending date, starting time, ending time or last modified date
- **THEN** the corresponding keys contain the empty string `""`

#### Scenario: Sales type and id formatting
- **WHEN** the payload is built for a "Sales Price" with "Sales Type" = All Customers
- **THEN** `salesType` is `"2"` and `id` is the "Sales Price" `SystemId` in the form `{XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX}` in upper case

### Requirement: Payload values are taken from the export record, the sales price and the item
The payload SHALL take `currencyCode`, `countryRegionCode`, `startingDate`, `endingDate`, `startingTime`, `endingTime`, `unitPrice`, `unitPriceLcy`, `nonStockPrice`, `strikePriceInclVat`, `recomRetailPriceInclVat`, `remark`, `comment`, `reasonCode`, `lastModifiedUserID`, `lastModifiedDate` and `id` from the "CXW Sales Price Export" record. The keys `salesType`, `salesCode`, `unitOfMeasureCode`, `minimumQuantity`, `priceIncludesVat`, `allowInvoiceDisc`, `vatBusPostingGrPrice` and `allowLineDisc` SHALL come from the "Sales Price" record identified by the stored `SystemId`. `vatProdPostingGroup` and `unitCost` (`"Unit Cost"`) SHALL come from the item. `itemNo` and `variantCode` SHALL be derived from the item as described in "Item number and variant code use the old NAV numbers".

#### Scenario: Two countries sharing a currency
- **WHEN** DE is released with a price of 1000 and afterwards AT with a price of 1100, both with blank currency, and the job then exports both entries
- **THEN** the payload for DE contains `"countryRegionCode": "DE"` and `"unitPrice": 1000`, and the payload for AT contains `"countryRegionCode": "AT"` and `"unitPrice": 1100`

#### Scenario: Sales Price record missing
- **WHEN** no "Sales Price" record exists for the stored `SystemId`
- **THEN** the entry is set to `Status` = Error and no HTTP request is sent

### Requirement: Item number and variant code use the old NAV numbers
`itemNo` SHALL contain the item's "Old Item No." if it is not blank, otherwise the item number. `variantCode` SHALL contain the item's "Old Variant Code" if it is not blank; otherwise the "Variant Code" of the "Sales Price" record, and if that is blank as well, the item number (the same rule as the availability export).

#### Scenario: Old numbers maintained
- **WHEN** item 1000123 has "Old Item No." A61087 and "Old Variant Code" A61087-01
- **THEN** the payload contains `"itemNo": "A61087"` and `"variantCode": "A61087-01"`

#### Scenario: No old numbers maintained
- **WHEN** item 1000123 has neither "Old Item No." nor "Old Variant Code" and the "Sales Price" record has no variant code
- **THEN** the payload contains `"itemNo": "1000123"` and `"variantCode": "1000123"`

#### Scenario: Only the old item number maintained
- **WHEN** item 1000123 has "Old Item No." A61087 but no "Old Variant Code", and the "Sales Price" record has no variant code
- **THEN** the payload contains `"itemNo": "A61087"` and `"variantCode": "1000123"`

### Requirement: Reason code is never empty
The `reasonCode` key SHALL contain the (untranslated) name of the "CXW Sales Price Reason Code" value of the export record, i.e. `CatMan`, `Purchasing` or `Marketing`, and SHALL never be an empty string.

#### Scenario: Default reason code
- **WHEN** the export record has the default reason code
- **THEN** the payload contains `"reasonCode": "CatMan"`

#### Scenario: Independent of the session language
- **WHEN** the job runs in a session with language German and the export record has reason code Marketing
- **THEN** the payload contains `"reasonCode": "Marketing"`

### Requirement: Unit cost and profit are calculated
`unitCost` SHALL be the item's `"Unit Cost"`. `profit` SHALL be the margin in percent: `Round((net − unitCost) / net × 100, 0.01)`, where `net` is the export record's unit price (LCY) reduced by the `"VAT %"` of the "VAT Posting Setup" for the sales price's `"VAT Bus. Posting Gr. (Price)"` and the item's `"VAT Prod. Posting Group"` (0 % if no such setup exists). If `net` is 0, `profit` SHALL be 0.

#### Scenario: Profit with VAT
- **WHEN** the unit price (LCY) is 1190, the matching VAT posting setup has `"VAT %"` = 19 and the item's `"Unit Cost"` = 800
- **THEN** the payload contains `"unitCost": 800` and `"profit": 20`

#### Scenario: Profit without VAT setup
- **WHEN** the unit price (LCY) is 1000, no matching VAT posting setup exists and the item's `"Unit Cost"` = 750
- **THEN** the payload contains `"profit": 25`

#### Scenario: Zero price
- **WHEN** the unit price (LCY) is 0
- **THEN** the payload contains `"profit": 0` and no division error occurs

### Requirement: Export settings are configurable
The general sales price setup SHALL provide the fields `"CXW Max. Export Attempts"` (Integer, initial value 3, minimum value 1) and `"CXW Archive Country Code"` (Code[10], related to "Country/Region", initial value `DE`), shown on the "CXW General Sales Price Setup" page next to the other export fields.

#### Scenario: New setup record
- **WHEN** a new general sales price setup record is created
- **THEN** `"CXW Max. Export Attempts"` is 3 and `"CXW Archive Country Code"` is `DE`

#### Scenario: Invalid attempts value
- **WHEN** a user enters 0 in `"CXW Max. Export Attempts"`
- **THEN** the system rejects the value

### Requirement: Failed entries can be requeued manually
The "Data Export Entries" page (ChronextBC page 50108) SHALL offer an action "Requeue Sales Price" that, for the selected entries with `Destination Code` = `SALESPRICE` and `Status` = Error, sets `Status` = `CXW Pending`, `"Attempt Count"` = 0 and clears `"Error Message"`, keeping the stored payload. Selected entries of other destinations or with another status SHALL remain unchanged.

#### Scenario: Requeue after maximum reached
- **WHEN** a user selects a `SALESPRICE` entry with `Status` = Error and `"Attempt Count"` = 3 and runs "Requeue Sales Price"
- **THEN** the entry has `Status` = `CXW Pending`, `"Attempt Count"` = 0 and an empty `"Error Message"`, and it is transmitted on the next job run

#### Scenario: Other entries in the selection
- **WHEN** the selection additionally contains a processed `SALESPRICE` entry and an erroneous entry of another destination
- **THEN** only the erroneous `SALESPRICE` entry is changed, and the user is informed how many entries were requeued

