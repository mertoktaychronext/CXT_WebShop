## ADDED Requirements

### Requirement: Validate compares against the previous Sales Price when one exists
When the "Validate" action processes a "CXW Sales Price Checking" line, and a "Sales Price" record already exists for the same item/currency/starting date, the system SHALL compare the checking line's "CXW Stock Price" against that previous record's LCY price and flag large swings or decreases in "CXW Remark", as long as the previous record has a reliable LCY price to compare against.

#### Scenario: Previous price is lower — remark set
- **WHEN** "Validate" processes a checking line whose "CXW Stock Price" is lower than the matching previous "Sales Price" record's "CXW Unit Price (LCY)" (which is non-zero)
- **THEN** the system sets "CXW Remark" to describe the percentage decrease

#### Scenario: Previous price increase exceeds the configured threshold — remark set
- **WHEN** "Validate" processes a checking line whose "CXW Stock Price" is higher than the matching previous "Sales Price" record's "CXW Unit Price (LCY)" (which is non-zero) by more than the "CXW Stock Price Threshold %" configured on the general setup
- **THEN** the system sets "CXW Remark" to describe the percentage increase

### Requirement: A previous price with no reliable LCY value does not abort Validate
If the matching previous "Sales Price" record's `"CXW Unit Price (LCY)"` is `0` (for example because that record was written before LCY population existed, and has not yet been re-uploaded), the system SHALL treat the line as if no previous price were available for the swing comparison, instead of dividing by zero and aborting the batch.

#### Scenario: Previous price has a zero LCY value
- **WHEN** "Validate" processes a checking line whose matching previous "Sales Price" record has `"CXW Unit Price (LCY)" = 0`
- **THEN** the system skips the percentage-swing comparison and threshold check for that line, leaves any other remark logic (margin check, date-range check) unaffected, and continues processing the remaining lines in the batch

#### Scenario: One line's comparison being skipped does not affect other lines
- **WHEN** "Validate" processes a batch containing both a line whose previous price has a zero LCY value and lines whose previous prices have a reliable LCY value
- **THEN** every line in the batch is validated and marked "CXW Validated" = true, with only the affected line's swing-comparison remark skipped
