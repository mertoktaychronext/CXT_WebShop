# workshop-line-attribute-prefill Specification

## Purpose
TBD - created by archiving change workshop-line-prefill-attributes. Update Purpose after archive.
## Requirements
### Requirement: Workshop attribute fields are prefilled from the item attributes
When a purchase order line is sent to the workshop ("Send to Workshop"), the system SHALL fill the workshop line fields `"CXW Dial Color"`, `"CXW Case Diameter"`, `"CXW Bracelet Material"`, `"CXW Case Material"`, `"CXW Movement"`, `"CXW Gender"`, `"CXW Crystal"`, `"CXW Features"`, `"CXW Attribute 9"` and `"CXW Attribute 10"` with the value that is assigned to the item of the purchase order line for the item attribute of the same mapping that is used to write these fields back to the item on processing (attribute names "Dial Color", "Case Diameter", "Bracelet Material", "Case Material", "Movement", "Gender", "Crystal", "Features", "Attribut 9", "Attribut 10"). If the item has no value for that attribute, or the attribute does not exist, the system SHALL use the value of the item's ChronextBC attribute with the following item attribute ID as fallback: Dial Color → 22 "Zifferblatt Farbe 1", Case Diameter → 18 "Gehäuse Größe", Bracelet Material → 23 "Armband Material", Case Material → 16 "Gehäuse Material", Movement → 15 "Werk", Gender → 24 "Geschlecht", Crystal → 20 "Glas". Features, Attribut 9 and Attribut 10 have no fallback. If neither value exists, the field SHALL remain empty. The fallback SHALL only be used for prefilling; writing back SHALL still use the attribute names above. A missing value SHALL NOT prevent sending the line to the workshop.

#### Scenario: Attribute values maintained
- **WHEN** the item of a purchase order line has the attribute values "Dial Color" = "Black", "Case Diameter" = "41 mm" and "Case Material" = "Steel", and the line is sent to the workshop
- **THEN** the workshop line has `"CXW Dial Color"` = "Black", `"CXW Case Diameter"` = "41 mm" and `"CXW Case Material"` = "Steel", and the API returns `"dialColor": "Black"`, `"caseDiameter": "41 mm"` and `"caseMaterial": "Steel"`

#### Scenario: Fallback to the ChronextBC attribute
- **WHEN** the item has no value for "Dial Color" (or the attribute "Dial Color" does not exist) but attribute 22 "Zifferblatt Farbe 1" = "Schwarz", and the line is sent to the workshop
- **THEN** `"CXW Dial Color"` = "Schwarz" and the API returns `"dialColor": "Schwarz"`

#### Scenario: English attribute takes precedence
- **WHEN** the item has "Dial Color" = "Black" and attribute 22 "Zifferblatt Farbe 1" = "Schwarz"
- **THEN** `"CXW Dial Color"` = "Black"

#### Scenario: Attribute not maintained
- **WHEN** the item has neither a value for "Movement" nor for attribute 15 "Werk", and no item attribute "Attribut 9" exists
- **THEN** the workshop line is created and `movement` and `attribute9` are returned as `""`

#### Scenario: Unchanged fallback value is not written back
- **WHEN** a line was prefilled via fallback from attribute 22 = "Schwarz" (the item has no value for "Dial Color"), the workshop leaves `dialColor` = "Schwarz" unchanged and the line is processed
- **THEN** no value is written to "Dial Color", no item attribute "Dial Color" is created, and attribute 22 is unchanged

#### Scenario: Corrected fallback value is written to the named attribute
- **WHEN** a line was prefilled via fallback from attribute 22, the workshop corrects `dialColor` and the line is processed
- **THEN** the corrected value is written to the item attribute "Dial Color"; attribute 22 is unchanged

#### Scenario: Prefilled values are a snapshot
- **WHEN** an attribute value of the item is changed after the line was sent to the workshop
- **THEN** the workshop line keeps the value at the time of sending

### Requirement: Workshop can correct prefilled values
The prefilled attribute fields SHALL remain writable for the workshop through the `workshopLines` API as before. On processing a genuine line, the values currently on the workshop line (prefilled or corrected) SHALL be written to the named item attributes as before, except a value that is unchanged from the ChronextBC fallback: if the item has no value for the named attribute and the field value equals the value of the fallback attribute, the field SHALL NOT be written back.

#### Scenario: Workshop corrects a value
- **WHEN** a line was prefilled with "Dial Color" = "Black", the workshop sends a PATCH with `"dialColor": "Anthracite"` and `"status": "WS checked"` and `"genuine": true`, and the line is processed
- **THEN** the item attribute "Dial Color" of the item has the value "Anthracite"

#### Scenario: Workshop confirms a value unchanged
- **WHEN** a prefilled line is set to `WS checked` and genuine without changing the attribute fields, and the line is processed
- **THEN** the item attributes keep their values and no additional item attribute or attribute value is created

### Requirement: Prefill and write-back use the same attribute mapping
The mapping between the ten workshop line fields and the item attribute names SHALL be defined in exactly one place and used both for prefilling and for writing back on processing.

#### Scenario: Round trip hits the same attribute
- **WHEN** a line is prefilled from the named item attribute for `"CXW Case Material"` (not via fallback) and later processed
- **THEN** the value is written back to the same item attribute it was read from

### Requirement: Open workshop lines are prefilled on upgrade
On upgrading to the version that contains this change, the system SHALL prefill, once, the empty attribute fields of all workshop lines with status `New`. Fields that already have a value SHALL NOT be overwritten. Lines with status `WS checked`, `Processed` or `Error` SHALL remain unchanged.

#### Scenario: New line is prefilled
- **WHEN** the extension is upgraded and a workshop line with status `New` has empty attribute fields and its item has attribute values
- **THEN** the empty fields are filled with the item attribute values

#### Scenario: Existing values and checked lines stay unchanged
- **WHEN** the extension is upgraded and a workshop line has status `WS checked`, or a `New` line already has `"CXW Dial Color"` = "Blue"
- **THEN** the `WS checked` line is not changed and `"CXW Dial Color"` stays "Blue"

