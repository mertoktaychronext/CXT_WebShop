## ADDED Requirements

### Requirement: Sales header has a hold order flag
The table "Sales Header" SHALL have a Boolean field "CXW Hold Order" with the caption "Hold Order" (de-DE "Auftrag halten"). Its default value SHALL be `false`. The field SHALL be set and cleared only manually by the user; no code in this extension SHALL set or clear it automatically.

#### Scenario: New sales order
- **WHEN** a user creates a new sales order
- **THEN** "Hold Order" is `false`

#### Scenario: User holds an order
- **WHEN** a user sets "Hold Order" on sales order 101001 and closes the page
- **THEN** sales order 101001 is saved with "Hold Order" = `true`

#### Scenario: User releases the hold
- **WHEN** a user clears "Hold Order" on a held sales order
- **THEN** the order is saved with "Hold Order" = `false`

### Requirement: Hold order flag is visible on the sales order
The page "Sales Order" SHALL show "Hold Order" in the General section, with a tooltip that explains the flag is informational only. The field SHALL be editable only while the order has status Open.

#### Scenario: Field on an open sales order
- **WHEN** a user opens a sales order with status Open
- **THEN** the General section shows the editable field "Hold Order"

#### Scenario: Field on a released sales order
- **WHEN** a user opens a sales order with status Released
- **THEN** the General section shows "Hold Order" read-only with its current value

### Requirement: Hold order flag can only be changed on open orders
"Hold Order" SHALL only be changeable while the sales header has status Open. Changing it on a sales header with any other status (Released, Pending Approval, Pending Prepayment) SHALL fail with the standard status error, regardless of whether the change comes from a page or from code. The value set before release SHALL be kept unchanged while the order is not open.

#### Scenario: Change on a released order is rejected
- **WHEN** code or a user validates "Hold Order" on sales order 101001 with status Released
- **THEN** an error states that Status must be equal to Open, and "Hold Order" keeps its previous value

#### Scenario: Change after reopening
- **WHEN** a user reopens released sales order 101001 and sets "Hold Order"
- **THEN** the change is saved

#### Scenario: Value is kept on release
- **WHEN** a user releases a sales order with "Hold Order" = `true`
- **THEN** the released order still shows "Hold Order" = `true`

### Requirement: Hold order flag is visible and filterable in the sales order list
The page "Sales Order List" SHALL show "Hold Order" as a column, so that users can filter and sort sales orders by it.

#### Scenario: Filter held orders
- **WHEN** a user filters the sales order list on "Hold Order" = Yes
- **THEN** only sales orders with "Hold Order" = `true` are shown

### Requirement: Hold order flag does not block any process
Apart from its own change restriction, "Hold Order" SHALL be informational only. Releasing, posting (shipment and invoice), creating warehouse documents and all other standard or extension processes SHALL behave exactly as if the field did not exist.

#### Scenario: Release a held order
- **WHEN** a user releases a sales order with "Hold Order" = `true`
- **THEN** the order is released without error or warning

#### Scenario: Post a held order
- **WHEN** a user posts shipment and invoice for a sales order with "Hold Order" = `true`
- **THEN** posting succeeds as for any other order
