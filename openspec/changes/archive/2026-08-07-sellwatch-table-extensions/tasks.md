## 1. Purchase Line table extension

- [x] 1.1 Create `src/TableExtensions/TabExt51003.SWPurchaseLine.al`: `tableextension 51003 "SW Purchase Line" extends "Purchase Line"` with field `51000; "Used good"; Boolean` (`Caption = 'Used Good'`, `DataClassification = ToBeClassified`).

## 2. Purchase Header table extension

- [x] 2.1 Create `src/TableExtensions/TabExt51004.SWPurchaseHeader.al`: `tableextension 51004 "SW Purchase Header" extends "Purchase Header"` with field `51000; "Tracking Number"; Text[30]` (`Caption = 'Tracking Number'`, `DataClassification = ToBeClassified`).

## 3. Re-enable SellWatch Mgt field assignment

- [x] 3.1 In `src/Codeunits/Codeunit51002.SellWatchMgt.al`, uncomment `PLRec."Used good" := true;` and remove the now-resolved TODO comment above it.
- [x] 3.2 Leave the `Vendor.Street`, `Vendor.SetPostingGroups()`, `Vendor.GetnewNoSeries()`, and `Vendor Bank Account."akq IBAN / SWIFT approved"` TODOs untouched (confirmed out of scope — not needed).

## 4. Verification

- [x] 4.1 Compile the AL project (or open in VS Code and build) and confirm no errors from the two new table extensions or from Codeunit 51002 — in particular that `PurchaseHeader."Tracking Number"` in `CreateSourceFilePurchaseRequest` and the `Tracking Number` FlowField `CalcFormula` on `Table 51008 "SellWatch Vendor Info"` now resolve.
- [x] 4.2 Confirm no field id collisions: `Used good` (Purchase Line) and `Tracking Number` (Purchase Header) each use field id 51000 on their own distinct base table.
- [x] 4.3 Confirm `app.json` idRanges still cover 51003 and 51004 (within the existing `51000-51049` range — no change needed).
