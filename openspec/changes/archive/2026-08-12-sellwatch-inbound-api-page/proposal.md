## Why

External systems need to push SellWatch offer/vendor data into Business Central via HTTP, but page 60307 "CXW SellWatch-Overview" is a locked-down `PageType = List` page (Editable = false, Insert/Modify/Delete disallowed) used purely for human review. A BC page has a single, fixed `PageType`, so `List` and `API` cannot coexist on one object — the existing page cannot be repurposed to also accept inbound writes. A separate `PageType = API` page bound to the same table is required; page 60307 keeps its current role as the one available display page.

## What Changes

- Add a new `PageType = API` page (next free object ID in range 60300-60349) over table 60300 "CXW SellWatch Vendor Info", exposing an OData v4 entity that external systems can POST/PATCH via HTTP call, secured with standard BC API authentication (Web Service Access Key or Entra ID OAuth — no custom auth logic in AL).
- New API page is Insertable/Modifiable = true for the inbound field set (vendor, watch, and offer fields); internal processing fields (`CXW Created`, `CXW PO Number`, `CXW VendorNo`) are NOT editable through the API so inbound writes cannot short-circuit `Codeunit "CXW SellWatch Mgt"`'s own processing state.
- Page 60307 "CXW SellWatch-Overview" is left functionally unchanged — it remains the single read-only overview/display page for SellWatch entries, including already-flowing-through-the-API rows.
- Extend permission set `CXWSWChronWSAll` (permissionset 60310) to grant the new API page.
- Document the field-level write contract (which fields are externally writable vs. system-owned) so the HTTP caller and `Codeunit "CXW SellWatch Mgt"` don't race on the same record.

## Capabilities

### New Capabilities
- `sellwatch-inbound-api`: A `PageType = API` endpoint over `CXW SellWatch Vendor Info` that lets external systems create/update SellWatch entries via HTTP, alongside the existing read-only overview page.

### Modified Capabilities
- (none — page 60307 and table 60300 keep their existing requirements; this change is additive)

## Impact

- **New AL object**: one new API page file (e.g. `src/Pages/Pag603XX.CXWSellWatchAPI.al`), next free ID in the app's 60300-60349 range.
- **Permission sets**: `src/PermissionSets/CXWSWChronWSAll.permissionset.al` gains a `page "CXW SellWatch API" = X` entry.
- **No change** to `src/Pages/Pag60307.CXWSellWatchOverview.al` or `src/Tables/Tab60300.CXWSellWatchVendorInfo.al` schema.
- **No change** to `Codeunit 60305 "CXW SellWatch Mgt"` logic, but its assumption that `"CXW Created" = false` marks an unprocessed, vendor-master-complete row now depends on the API caller supplying a complete, valid row in one call (see design.md for validation approach).
- Downstream: rows inserted via the new API become visible immediately in page 60307 and are picked up by the existing `Codeunit "CXW SellWatch Mgt"` batch/job-queue processing — no changes needed there.
