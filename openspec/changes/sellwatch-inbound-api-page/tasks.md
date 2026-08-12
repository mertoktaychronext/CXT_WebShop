## 1. Confirm open questions before coding

- [x] 1.1 Confirm with stakeholders whether an existing company-wide `APIPublisher`/`APIGroup` naming convention exists (design.md Decision 4); if not, proceed with `saliniLife` / `sellWatch` / `v1.0`. **Confirmed: no existing convention, proceed with proposed values (APIVersion later bumped to `v2.0`).**
- [x] 1.2 Confirm the exact set of fields the external system will populate (full field set vs. subset) so the API page's insertable/modifiable field list and required-field validation match reality. **Confirmed: all non-system fields writable.**
- [x] 1.3 Confirm invalid/partial payloads should be rejected outright (HTTP 4xx) rather than accepted and flagged for manual review. **Confirmed: reject outright.**

## 2. New API page

- [x] 2.1 Create `src/Pages/Pag60337.CXWSellWatchAPI.al` with `PageType = API`, `SourceTable = "CXW SellWatch Vendor Info"`, `APIPublisher = 'saliniLife'`, `APIGroup = 'sellWatch'`, `APIVersion = 'v1.0'`, `EntityName = 'sellWatchVendorInfo'`, `EntitySetName = 'sellWatchVendorInfos'`, `DelayedInsert = true`.
- [x] 2.2 Add fields for vendor master data, watch details, and commercial/offer data as insertable/modifiable, matching the field groups shown on page 60307.
- [x] 2.3 Mark `"CXW Entry No"` as the key field (not editable); mark `"CXW Created"`, `"CXW PO Number"`, `"CXW VendorNo"` as `Editable = false` on the page so they cannot be set via HTTP payload.
- [x] 2.4 Implement `OnInsertRecord` trigger: force `"CXW Created" := false`, run minimal required-field validation (per task 1.2), and reject insert if a record with the same `"CXW SRid"` already exists.
- [x] 2.5 Implement `OnModifyRecord` trigger (if updates are needed) applying the same field-ownership restrictions as insert. **Also re-checks `"CXW SRid"` uniqueness when it changes (dev-abschluss finding), and Table 60300 gained a secondary key on `"CXW SRid"` so the duplicate check doesn't full-scan.**

## 3. Permissions

- [x] 3.1 Add `page "CXW SellWatch API" = X` entry to `src/PermissionSets/CXWSWChronWSAll.permissionset.al` (permissionset 60310).
- [x] 3.2 Verify no other permission set needs the new page (check for a dedicated "API" permission set pattern, e.g. how `CXWChronWSAll` covers the outbound Sales Price API objects). **Confirmed: `CXWChronWSAll` (60336) only covers unrelated Sales Price/API Interface Setup objects — no addition needed there.**

## 4. Validation

- [x] 4.1 Compile the extension and resolve any AL errors/warnings for the new page. **Compiles cleanly (fixed `OnModifyRecord` signature); the one remaining compiler warning is pre-existing and unrelated to this change.**
- [ ] 4.2 Manually test: POST a new SellWatch entry via HTTP (e.g. Postman with BC Web Service Access Key) and confirm it appears on page 60307 unmodified in behavior.
- [ ] 4.3 Manually test: attempt to POST with `"CXW Created": true` and confirm the inserted record has `"CXW Created" = false`.
- [ ] 4.4 Manually test: POST a duplicate `"CXW SRid"` and confirm it is rejected.
- [ ] 4.5 Confirm `Codeunit "CXW SellWatch Mgt"` picks up and processes an API-inserted row exactly as it would a manually-entered one (Vendor + Purchase Order creation).
- [ ] 4.6 Confirm an unauthenticated / unauthorized HTTP call to the new endpoint is rejected.

## 5. Documentation

- [x] 5.1 Update `Funktionsregister` (per repo convention, see `al-funktionsregister` skill) to include the new API page and its purpose. **Updated `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md` and `docs/funktionsregister/gesamtuebersicht.md`.**
- [x] 5.2 Document the API endpoint URL pattern, required auth, and writable field list for the external system's integrators. **Added to `docs/developer-manual-de.md` and `docs/developer-manual-en.md` (SellWatch architecture section).**
