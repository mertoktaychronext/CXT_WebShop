# workshop-line-attribute-prefill Specification

## Purpose
Prefill of the workshop line check attributes from the item attributes on "Send to Workshop" and write-back on processing, both via one fixed mapping of workshop fields to item attribute IDs (placeholders without an ID are neither prefilled nor written back; no item attributes are created).
## Requirements
### Requirement: Workshop attribute fields are prefilled from the item attributes
When a purchase order line is sent to the workshop ("Send to Workshop"), the system SHALL fill the workshop line attribute fields with the value that is assigned to the item of the purchase order line for the item attribute with the following fixed item attribute ID: `"CXW Dial Color"` → 22 "Zifferblatt Farbe 1", `"CXW Case Diameter"` → 18 "Gehäuse Größe", `"CXW Bracelet Material"` → 23 "Armband Material", `"CXW Case Material"` → 16 "Gehäuse Material", `"CXW Movement"` → 15 "Werk", `"CXW Gender"` → 24 "Geschlecht", `"CXW Crystal"` → 20 "Glas". The fields `"CXW Features"`, `"CXW Attribute 9"` and `"CXW Attribute 10"` are placeholders without an assigned item attribute; they SHALL NOT be prefilled and SHALL remain empty until an attribute ID is assigned to them. If the item has no value for the mapped attribute, the field SHALL remain empty. The attributes SHALL be identified by ID only, not by name; there is no fallback attribute. A missing value SHALL NOT prevent sending the line to the workshop.

#### Scenario: Attribute values maintained
- **WHEN** the item of a purchase order line has the attribute values 22 "Zifferblatt Farbe 1" = "black", 18 "Gehäuse Größe" = 41 and 16 "Gehäuse Material" = "steel", and the line is sent to the workshop
- **THEN** the workshop line has `"CXW Dial Color"` = "black", `"CXW Case Diameter"` = "41" and `"CXW Case Material"` = "steel", and the API returns `"dialColor": "black"`, `"caseDiameter": "41"` and `"caseMaterial": "steel"`

#### Scenario: Gender comes from Geschlecht
- **WHEN** the item has attribute 24 "Geschlecht" = "Herren" and the line is sent to the workshop
- **THEN** `"CXW Gender"` = "Herren" and the API returns `"gender": "Herren"`

#### Scenario: Attribute not maintained
- **WHEN** the item has no value for attribute 15 "Werk"
- **THEN** the workshop line is created and `movement` is returned as `""`

#### Scenario: Placeholders stay empty
- **WHEN** any line is sent to the workshop
- **THEN** `features`, `attribute9` and `attribute10` are returned as `""`

#### Scenario: Prefilled values are a snapshot
- **WHEN** an attribute value of the item is changed after the line was sent to the workshop
- **THEN** the workshop line keeps the value at the time of sending

### Requirement: Workshop can correct prefilled values
The prefilled attribute fields SHALL remain writable for the workshop through the `workshopLines` API as before, including the placeholders `features`, `attribute9` and `attribute10`. On processing a genuine line, every non-empty value of a field with an assigned attribute ID SHALL be written to that item attribute of the item. A value that does not yet exist for the attribute SHALL be created as a new attribute value; no new item attribute SHALL ever be created. Values of placeholder fields without an assigned attribute ID SHALL NOT be written back. An invalid value for a numeric attribute (e.g. a non-numeric value for 18 "Gehäuse Größe") SHALL make the processing of the line fail with the existing error handling (status `Error`, error text on the line).

#### Scenario: Workshop corrects a value
- **WHEN** a line was prefilled with `"CXW Dial Color"` = "black", the workshop sends a PATCH with `"dialColor": "blue"`, `"status": "WS checked"` and `"genuine": true`, and the line is processed
- **THEN** attribute 22 "Zifferblatt Farbe 1" of the item has the value "blue"

#### Scenario: Workshop confirms a value unchanged
- **WHEN** a prefilled line is set to `WS checked` and genuine without changing the attribute fields, and the line is processed
- **THEN** the item attributes keep their values and no additional item attribute or attribute value is created

#### Scenario: Workshop reports a new value
- **WHEN** the workshop reports `"crystal": "sapphire-ar"` and this value does not exist for attribute 20 "Glas", and the line is processed
- **THEN** the value "sapphire-ar" is created for attribute 20 and assigned to the item

#### Scenario: Case diameter as number
- **WHEN** the workshop reports `"caseDiameter": "41"` and the line is processed
- **THEN** attribute 18 "Gehäuse Größe" of the item has the value 41

#### Scenario: No English attributes are created
- **WHEN** a genuine line with values in all attribute fields is processed
- **THEN** no item attribute named "Dial Color", "Case Diameter", "Bracelet Material", "Case Material", "Movement", "Gender", "Crystal", "Features", "Attribut 9" or "Attribut 10" exists afterwards

#### Scenario: Placeholder values are not written back
- **WHEN** the workshop reports `"features": "chronograph"` and `"attribute9": "x"`, and the line is processed
- **THEN** the values remain on the workshop line, no item attribute or attribute value is created for them, and the line is processed successfully

### Requirement: Prefill and write-back use the same attribute mapping
The mapping between the workshop line fields and the item attribute IDs SHALL be defined in exactly one place and used both for prefilling and for writing back on processing. Assigning an attribute ID to a placeholder field in this one place SHALL enable both prefilling and writing back for it.

#### Scenario: Round trip hits the same attribute
- **WHEN** a line is prefilled from attribute 16 for `"CXW Case Material"` and later processed
- **THEN** the value is written back to attribute 16

### Requirement: Open workshop lines are prefilled on upgrade
On upgrading to the version that contains this change, the system SHALL prefill, once, the empty attribute fields of all workshop lines with status `New`. Fields that already have a value SHALL NOT be overwritten. Lines with status `WS checked`, `Processed` or `Error` SHALL remain unchanged.

#### Scenario: New line is prefilled
- **WHEN** the extension is upgraded and a workshop line with status `New` has empty attribute fields and its item has attribute values
- **THEN** the empty fields are filled with the item attribute values

#### Scenario: Existing values and checked lines stay unchanged
- **WHEN** the extension is upgraded and a workshop line has status `WS checked`, or a `New` line already has `"CXW Dial Color"` = "Blue"
- **THEN** the `WS checked` line is not changed and `"CXW Dial Color"` stays "Blue"

