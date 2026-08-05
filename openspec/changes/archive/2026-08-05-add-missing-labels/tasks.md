## 1. Page 51001 "SL Sales Price Checking List"

- [x] 1.1 Add `NothingToProcessErr: Label 'Nothing to process';` and replace all 9 `Error('Nothing to process')` call sites (Validate ×2, Approve ×3, Add all Currencies ×3, Upload Sales Price ×1) with `Error(NothingToProcessErr)`.
- [x] 1.2 Add `ValidateDoneMsg: Label 'validate data is done';` and replace `Message('validate data is done')` with `Message(ValidateDoneMsg)`.
- [x] 1.3 Add `AcceptNewPriceSetupQst: Label 'Are you sure want to Accept New Price Setup?';` and replace `Confirm('Are you sure want to Accept New Price Setup?', false)` with `Confirm(AcceptNewPriceSetupQst, false)`.
- [x] 1.4 Add `DoneMsg: Label 'done';` and replace the 2 `Message('done')` call sites (Approve, Add all Currencies) with `Message(DoneMsg)`.
- [x] 1.5 Add `ModifyNotAllowedErr: Label 'not possible';` and replace `Error('not possible')` in `OnModifyRecord` with `Error(ModifyNotAllowedErr)`.
- [x] 1.6 Add `ValidatingProgressMsg: Label 'Validating Sales Price @1@@@@@@@@@@@@@@@';` and replace `ProgressWindow.Open('Validating Sales Price @1@@@@@@@@@@@@@@@')` with `ProgressWindow.Open(ValidatingProgressMsg)`.

## 2. XMLport 51000 "SL Import Sales Price"

- [x] 2.1 Add `ImportDoneMsg: Label 'done';` and replace `Message('done')` in `OnPostXmlPort` with `Message(ImportDoneMsg)`.

## 3. Table 51001 "SL Sales Price Checking"

- [x] 3.1 Add `PleaseValidateErr: Label 'Please click Validate button.';` and replace `Error('Please click Validate button.')` in the `"Accept New Setup"` `OnValidate` trigger with `Error(PleaseValidateErr)`.

## 4. Verification

- [x] 4.1 Compile the extension (`AL: Package`) and confirm no errors. (Verified via `alc.exe`: 26 files, 0 errors, 1 pre-existing unrelated warning in Codeunit 51001.)
- [x] 4.2 Confirm the 2 `StrSubstNo` calls building internal identifiers (outbound JSON filename in `Codeunit 51000`, Isolated Storage key in `Table 51007`) were left untouched. (Verified via grep: all 3 `StrSubstNo` literal calls in `src/` unchanged — filename, HTTP diagnostic text, and storage key; 0 remaining literal `Error(`/`Message(`/`Confirm(` calls anywhere in `src/`.)
- [x] 4.3 Re-sync `Translations/SL Chronext Webshop.de-DE.xlf` against the regenerated `.g.xlf`: added German translations for all 8 new trans-units (9 call sites map to 8 distinct texts, since Page 51001's `DoneMsg` and Xmlport 51000's `ImportDoneMsg` are separate per-object trans-units despite identical English text), verified the `@1@...@` progress-bar placeholder preserved character-for-character in `ValidatingProgressMsg`'s translation, and confirmed 213/213 trans-units match with 0 missing/orphaned/mismatched.
- [ ] 4.4 Manually spot-check at least one converted message in the running app (e.g. trigger "Nothing to process" via Validate with an empty list) to confirm the displayed text is unchanged from before this change.
