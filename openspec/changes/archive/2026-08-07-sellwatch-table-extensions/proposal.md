## Why

`Codeunit51002.SellWatchMgt.al` (procedure `CreateSourceFilePurchaseRequest`) and the `Tracking Number` FlowField on `Table 51008 "SellWatch Vendor Info"` both read `PurchaseHeader."Tracking Number"` — a field that does not exist on the standard `Purchase Header` table. This was missed during the initial NAV→AL migration (no AL compiler was available at the time to catch it) and surfaced only now.

Separately, `CreatePurchaseOrder` in the same codeunit has a commented-out assignment to `PurchaseLine."Used good"`, a field that likewise doesn't exist on the standard `Purchase Line` table because the NAV field extension that originally added it was never delivered as part of the SellWatch export bundle.

(Note: equivalent gaps on `Vendor` — `Street` — and `Vendor Bank Account` — `akq IBAN / SWIFT approved` — were also found, but are explicitly **not needed** and stay out of scope for this change; their commented-out assignments in `SellWatch Mgt` remain untouched.)

## What Changes

- New table extension on `Purchase Line` adding field `Used good` (`Boolean`), used to flag SellWatch purchase lines as used-goods (relevant together with the existing `Differential Taxation` field).
- New table extension on `Purchase Header` adding field `Tracking Number` (`Text[30]`), read by `SellWatch Mgt`'s `CreateSourceFilePurchaseRequest` and by the `Tracking Number` FlowField on `SellWatch Vendor Info`.
- Re-enable the commented-out `PLRec."Used good" := true;` assignment in `src/Codeunits/Codeunit51002.SellWatchMgt.al`.
- Out of scope: `Vendor.Street`, `Vendor Bank Account."akq IBAN / SWIFT approved"`, and the procedures `SetPostingGroups()` / `GetnewNoSeries()` called on `Vendor` — not needed, their commented-out call sites stay as-is.

## Capabilities

### New Capabilities
- `sellwatch-standard-table-extensions`: Table extensions that add the SellWatch-specific fields (`Used good` on Purchase Line, `Tracking Number` on Purchase Header) required by the SellWatch purchase order creation flow.

### Modified Capabilities
<!-- none: this change only adds new fields consumed by already-existing SellWatch logic; no existing spec's requirements change -->

## Impact

- New AL files under `src/TableExtensions/` (IDs from the project's registered range 51000-51049):
  - `Purchase Line` table extension (`Used good` field)
  - `Purchase Header` table extension (`Tracking Number` field)
- Modified: `src/Codeunits/Codeunit51002.SellWatchMgt.al` — uncomment the `PLRec."Used good"` assignment now that the field exists (the `Tracking Number` read already compiles once that field is present; no further code change needed there).
- No changes to `app.json` (table extensions fit within the existing `51000-51049` id range).
