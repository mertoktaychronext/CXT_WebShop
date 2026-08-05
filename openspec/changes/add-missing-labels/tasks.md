## 1. Page 51001 "SL Sales Price Checking List"

- [ ] 1.1 Add `NothingToProcessErr: Label 'Nothing to process';` and replace all 9 `Error('Nothing to process')` call sites (Validate ×2, Approve ×3, Add all Currencies ×3, Upload Sales Price ×1) with `Error(NothingToProcessErr)`.
- [ ] 1.2 Add `ValidateDoneMsg: Label 'validate data is done';` and replace `Message('validate data is done')` with `Message(ValidateDoneMsg)`.
- [ ] 1.3 Add `AcceptNewPriceSetupQst: Label 'Are you sure want to Accept New Price Setup?';` and replace `Confirm('Are you sure want to Accept New Price Setup?', false)` with `Confirm(AcceptNewPriceSetupQst, false)`.
- [ ] 1.4 Add `DoneMsg: Label 'done';` and replace the 2 `Message('done')` call sites (Approve, Add all Currencies) with `Message(DoneMsg)`.
- [ ] 1.5 Add `ModifyNotAllowedErr: Label 'not possible';` and replace `Error('not possible')` in `OnModifyRecord` with `Error(ModifyNotAllowedErr)`.
- [ ] 1.6 Add `ValidatingProgressMsg: Label 'Validating Sales Price @1@@@@@@@@@@@@@@@';` and replace `ProgressWindow.Open('Validating Sales Price @1@@@@@@@@@@@@@@@')` with `ProgressWindow.Open(ValidatingProgressMsg)`.

## 2. XMLport 51000 "SL Import Sales Price"

- [ ] 2.1 Add `ImportDoneMsg: Label 'done';` and replace `Message('done')` in `OnPostXmlPort` with `Message(ImportDoneMsg)`.

## 3. Table 51001 "SL Sales Price Checking"

- [ ] 3.1 Add `PleaseValidateErr: Label 'Please click Validate button.';` and replace `Error('Please click Validate button.')` in the `"Accept New Setup"` `OnValidate` trigger with `Error(PleaseValidateErr)`.

## 4. Verification

- [ ] 4.1 Compile the extension (`AL: Package`) and confirm no errors.
- [ ] 4.2 Confirm the 2 `StrSubstNo` calls building internal identifiers (outbound JSON filename in `Codeunit 51000`, Isolated Storage key in `Table 51007`) were left untouched.
- [ ] 4.3 Re-sync `Translations/SL Chronext Webshop.de-DE.xlf` against the regenerated `.g.xlf`: add German translations for all 9 new trans-units, verify placeholder/progress-bar syntax preserved in `ValidatingProgressMsg`'s translation, and confirm trans-unit counts match with 0 missing/orphaned/mismatched.
- [ ] 4.4 Manually spot-check at least one converted message in the running app (e.g. trigger "Nothing to process" via Validate with an empty list) to confirm the displayed text is unchanged from before this change.
