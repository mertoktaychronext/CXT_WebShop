## 1. Codeunit 51000 "SL Export Gateway Sales Price"

- [x] 1.1 Add procedure `WriteBackAndArchive(SalesPriceChecking: Record "SL Sales Price Checking"; var SalesPrice: Record "Sales Price")` that resolves the matching "Sales Price" record (Get with "Sales Type"::"All Customers", blank "Sales Code", blank "Unit of Measure Code", 0 "Minimum Quantity" — verified against the real primary key, which does not include "Country/Region Code") or Inits a new one.
- [x] 1.2 In `WriteBackAndArchive`, map checking fields onto "Sales Price" per the design's field-mapping table ("Stock Price" → "Unit Price", "Strike Price" → "Strike-Price incl. VAT", "Recom. Retail Price" → "Recom. Retail Price incl. VAT", "Reason Code", Comment, Remark) and Insert or Modify accordingly.
- [x] 1.3 In `WriteBackAndArchive`, look up the highest existing "Version No." in "SL Sales Price Archive" for the same Item No./Variant Code/Currency Code (Country Code blank) and insert a new archive row with "Version No." incremented (1 if none exist), copying the checking line's fields into the archive row.
- [x] 1.4 Mark `WriteBackAndArchive` as `[TryFunction]` so a failure on one line (e.g. an invalid currency) is caught and rolled back to just that line, instead of aborting the whole "Upload Sales Price" batch and rolling back "Export Status" updates already made to earlier lines in the same run. (Found during dev-abschluss review.)

## 2. Page 51001 "SL Sales Price Checking List"

- [x] 2.1 In the "Upload Sales Price" action, replace the `l_recSP.SetRange(...); l_recSP.FindFirst()` lookup-and-skip with a call to `g_cuExportGatewaySalesPrice.WriteBackAndArchive(l_recSalesPriceCheck, l_recSP)` before `CreateExternalInterfaceFile`.
- [x] 2.2 Update the `ExportResultMsg` label/wording if it no longer applies now that lines without a prior "Sales Price" record are written instead of skipped.
- [x] 2.3 Update the "Upload Sales Price" `OnAction` trigger to treat `WriteBackAndArchive` returning `false` the same as a failed `CreateExternalInterfaceFile` — mark the line "Export Status"::Error and continue the loop.

## 3. Verification

- [x] 3.1 Compile the extension (`AL: Package`) and confirm no errors from the new procedure or the changed action. (Verified via `alc.exe`: 26 files, 0 errors, 1 pre-existing unrelated warning in Codeunit 51001.)
- [x] 3.2 Manually run "Upload Sales Price" against a checking line with no existing "Sales Price" record and confirm a new "Sales Price" record ("Sales Type" = All Customers, "Unit Price" = Stock Price) and a "SL Sales Price Archive" row ("Version No." = 1) are created, and the outbound file is generated.
- [x] 3.3 Manually re-run "Upload Sales Price" (resend) for the same line and confirm the "Sales Price" record is updated in place and a second archive row is inserted with "Version No." = 2.

## 4. Documentation

- [x] 4.1 Update `docs/developer-manual-en.md` / `docs/developer-manual-de.md` "Known Limitations" to remove the now-resolved "approved prices are not automatically carried over" entry and update the Table Overview's "History (currently read-only)" note for Table 51002.
