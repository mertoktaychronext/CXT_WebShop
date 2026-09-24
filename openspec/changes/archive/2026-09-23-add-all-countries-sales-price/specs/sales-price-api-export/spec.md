## ADDED Requirements

### Requirement: Exported sales price carries the country
The JSON transmitted for a "CXW Sales Price Checking" line SHALL contain, in addition to the fields of the written-back "Sales Price" record, a field `"CXW Country Code"` holding the checking line's `"CXW Country Code"` (empty for source lines without a country). The outbound file name SHALL include the country code so that files for different countries sharing a currency are distinguishable.

#### Scenario: Country line is exported
- **WHEN** "Upload Sales Price" exports a checking line with `"CXW Country Code"` = `AT` and `"CXW Currency Code"` blank
- **THEN** the transmitted JSON contains `"CXW Country Code": "AT"` and the outbound file name contains both the item number and `AT`

#### Scenario: Two countries with the same currency are exported separately
- **WHEN** "Upload Sales Price" exports approved lines for the same item for DE and AT, both with blank `"CXW Currency Code"`
- **THEN** two separate JSON payloads are transmitted, one with `"CXW Country Code": "DE"` and one with `"CXW Country Code": "AT"`

#### Scenario: Source line without country is exported
- **WHEN** "Upload Sales Price" exports a source line with blank `"CXW Country Code"`
- **THEN** the transmitted JSON contains `"CXW Country Code": ""`
