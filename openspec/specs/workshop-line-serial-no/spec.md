# workshop-line-serial-no Specification

## Purpose
TBD - created by archiving change workshop-line-serial-no. Update Purpose after archive.
## Requirements
### Requirement: Workshop line stores the BC serial number
The workshop line (table "CXW Workshop Line") SHALL have a field "Serial No." that holds the Business Central serial number of the watch. When a purchase line is sent to the workshop, the system SHALL set this field to the serial number determined for the purchase line during "Send to Workshop" (the serial number already assigned in the item tracking of the purchase line, or the number drawn from the item's serial no. series). The value SHALL be a snapshot of the hand-over and SHALL NOT be changed afterwards when the item tracking of the purchase line changes. The field SHALL NOT be editable by users.

#### Scenario: Existing item tracking serial number is taken over
- **WHEN** a purchase line whose item tracking already contains serial number "SN-000123" is sent to the workshop
- **THEN** the created workshop line has "Serial No." = "SN-000123"

#### Scenario: Newly drawn serial number is taken over
- **WHEN** a purchase line without item tracking is sent to the workshop and the next number of the item's serial no. series is "SN-000124"
- **THEN** the created workshop line has "Serial No." = "SN-000124"

#### Scenario: Serial number is a snapshot
- **WHEN** the item tracking of the purchase line is changed to a different serial number after the line was sent to the workshop
- **THEN** the workshop line keeps the serial number it was created with

#### Scenario: Line not sent
- **WHEN** a purchase line is not sent to the workshop (e.g. manufacturer serial number left empty)
- **THEN** no workshop line is created, and the serial number stays assigned to the purchase line for the next attempt

### Requirement: Serial number is visible on the workshop lines page
The page "CXW Workshop Lines" SHALL show the field "Serial No." read-only next to the manufacturer serial number.

#### Scenario: Internal user sees the serial number
- **WHEN** a user opens "CXW Workshop Lines"
- **THEN** each line shows its BC serial number next to the manufacturer serial number, and the value cannot be edited

### Requirement: Workshop lines API returns the serial number
The `workshopLines` API (page "CXW Workshop Line API") SHALL return the read-only field `serialNo` with the value of "Serial No." of the workshop line. The field SHALL always be included in the response, as `""` if no serial number is stored. A PATCH request that changes `serialNo` SHALL be rejected with an error, and the workshop line SHALL remain unchanged. Writing the existing check result fields SHALL continue to work. Reading `serialNo` SHALL NOT require any permission beyond the permission set "CXW Workshop API".

#### Scenario: Serial number in the API response
- **WHEN** a workshop line with "Serial No." = "SN-000123" and manufacturer serial no. "M12345" exists and the workshop reads `workshopLines`
- **THEN** the returned line contains `"serialNo": "SN-000123"` and `"manufacturerSerialNo": "M12345"`

#### Scenario: Line without serial number
- **WHEN** a workshop line has no serial number stored
- **THEN** the API returns `"serialNo": ""`

#### Scenario: Attempt to change the serial number
- **WHEN** the workshop sends a PATCH request that sets `serialNo` to a different value
- **THEN** the request is rejected with an error and the workshop line keeps its original values

#### Scenario: Check result can still be written
- **WHEN** the workshop sends a PATCH request with `status`, `genuine` and attribute values only
- **THEN** the changes are saved as before

#### Scenario: API user reads the serial number
- **WHEN** a user with only the permission set "CXW Workshop API" reads `workshopLines`
- **THEN** `serialNo` is returned without a permission error

### Requirement: Existing open workshop lines get the serial number on upgrade
When the extension is upgraded, the system SHALL fill "Serial No." once for existing workshop lines with status `New` or `WS checked` whose "Serial No." is empty and whose purchase line still exists, using the serial number from the item tracking of that purchase line. Lines with status `Processed` or `Error`, and lines whose purchase line has no serial number in its item tracking, SHALL remain unchanged. The fill SHALL run only once per company.

#### Scenario: Open line is filled
- **WHEN** the extension is upgraded and a workshop line with status `New` exists whose purchase line has serial number "SN-000100" in its item tracking
- **THEN** the workshop line gets "Serial No." = "SN-000100"

#### Scenario: Processed line is not changed
- **WHEN** the extension is upgraded and a workshop line with status `Processed` exists
- **THEN** its "Serial No." remains empty

#### Scenario: Purchase line without item tracking
- **WHEN** the extension is upgraded and the purchase line of an open workshop line has no serial number in its item tracking
- **THEN** the workshop line remains unchanged and the upgrade does not fail

#### Scenario: Second upgrade does not fill again
- **WHEN** the extension is upgraded a second time
- **THEN** the fill is not executed again

