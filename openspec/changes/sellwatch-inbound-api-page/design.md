## Context

Page 60307 "CXW SellWatch-Overview" (`src/Pages/Pag60307.CXWSellWatchOverview.al`) is `PageType = List` over table 60300 "CXW SellWatch Vendor Info", with `Editable = false` and Insert/Modify/Delete all disallowed — it exists purely so staff can review incoming SellWatch offers and jump to the resulting Purchase Order. `Codeunit 60305 "CXW SellWatch Mgt"` separately reads rows where `"CXW Created" = false`, creates a Vendor + Vendor Bank Account, and raises a Purchase Order — it owns the processing state fields (`CXW Created`, `CXW PO Number`, `CXW VendorNo`).

In AL, `PageType` is a single, non-combinable property (`Card`, `List`, `API`, `Worksheet`, …). A page cannot be both a Web Client list and an OData API endpoint. There is also no existing `PageType = API` object anywhere in this repo or its sibling repos (`CHX.Base`, `SL Chronext Webshop`) to reuse conventions from — this change establishes the first one. The closest existing HTTP-integration pattern (`Table 60317 "CXW API Interface Setup"`, `Codeunit 60329 "CXW Export Gateway Sales Price"`, AWS SigV4 auth) is strictly outbound (BC calling out and signing its own requests) and does not apply to an inbound, BC-hosted endpoint.

## Goals / Non-Goals

**Goals:**
- Let an external system create/update SellWatch entries over HTTP without touching page 60307.
- Keep page 60307 as the single, unchanged display surface — new rows appear there automatically.
- Prevent inbound HTTP writes from corrupting the processing state that `Codeunit "CXW SellWatch Mgt"` depends on.
- Establish a minimal, standard-BC-auth API convention that later API pages in this app can follow.

**Non-Goals:**
- Building a generic multi-entity API framework — this change adds exactly one API page for SellWatch.
- Custom authentication (API keys stored in `CXW API Interface Setup`, AWS SigV4, etc.) — that pattern is for BC-initiated outbound calls; an inbound BC API page uses BC's own service authentication.
- Changing `Codeunit "CXW SellWatch Mgt"` processing logic, page 60307's UI, or table 60300's schema.
- Bulk/batch import — the API is record-at-a-time (standard OData behavior); file-based bulk import already exists via the Sales Price Inbound File pattern if ever needed for SellWatch.

## Decisions

### 1. New `PageType = API` page over the existing table, not a staging table
Table 60300 already has an explicit "unprocessed" marker (`CXW Created = false`) that `Codeunit "CXW SellWatch Mgt"` polls. Writing API inserts directly into table 60300 reuses that existing state machine with zero changes to the codeunit. A staging table (mirroring `CXW Sales Price Inbound File`) was considered but rejected: that pattern exists for file/blob payloads that need parsing before becoming structured rows, whereas the API page receives already-structured JSON matching table fields 1:1 — an extra staging hop would add a table and a copy-step for no benefit.

### 2. Field-level write contract: split writable vendor/watch/offer fields from system-owned processing fields
The API page exposes the same field groups as page 60307 (vendor master data, watch details, commercial/offer data) as insertable/modifiable, but the following remain **not editable through the API** (system-owned, set only by `Codeunit "CXW SellWatch Mgt"` or by the platform):
- `"CXW Entry No"` — primary key, AutoIncrement.
- `"CXW Created"` — always forced to `false` on insert via the page's `OnInsertRecord` trigger, regardless of payload, so a caller can never mark its own row as already processed.
- `"CXW PO Number"`, `"CXW VendorNo"` — populated only once the codeunit creates the Vendor/PO.
- `"CXW Tracking Number"` — FlowField, inherently read-only.

This mirrors how page 60307 already hides `"CXW Entry No"` and blocks all modification — the API page applies the same ownership boundary, just scoped per-field instead of for the whole record.

### 3. Authentication: standard BC API auth, not the custom outbound gateway pattern
The API page is secured the same way every BC API page is: a Web Service Access Key or Entra ID OAuth token on the calling side, enforced by the platform via the existing SellWatch permission set (`CXWSWChronWSAll`, permissionset 60310) extended to include the new page. No AL-level auth code is needed or written — `Table "CXW API Interface Setup"` / AWS SigV4 is for BC-as-client (outbound), not BC-as-server (inbound), so it's out of scope here.

### 4. API surface naming (new convention — first API page in this app)
No `APIPublisher`/`APIGroup`/`APIVersion` convention exists yet in this codebase. Propose:
- `APIPublisher = 'saliniLife'`
- `APIGroup = 'sellWatch'`
- `APIVersion = 'v2.0'`
- `EntityName = 'sellWatchVendorInfo'`, `EntitySetName = 'sellWatchVendorInfos'`
- Object ID: next free ID in the app's 60300-60349 range (used up to ~60336 at time of writing).

This is a **new** convention, not an existing one being followed — flagged as an open question in case the team already has an unwritten preference (e.g. matching a public-facing API naming scheme used elsewhere at Chronext).

### 5. Idempotency / de-duplication
Field `"CXW SRid"` already acts as an external reference ID (it's the only field page 60307's `OnOpenPage` filters non-blank on). The API page's `OnInsertRecord`/`OnModifyRecord` triggers check for another row with the same `"CXW SRid"` (excluding the record's own `"CXW Entry No"`) and reject with an error if one exists, since the primary key (`"CXW Entry No"`) is an internal auto-increment the external caller doesn't know. The check runs on insert unconditionally and on modify whenever `"CXW SRid"` changes, so a `PATCH` can't silently collide two rows onto the same external reference. Table 60300 gained a secondary key on `"CXW SRid"` so this lookup doesn't degrade into a full table scan as the table grows.

## Risks / Trade-offs

- **[Risk]** External caller sends a partial/invalid row (missing Brand/Model/offer price) that `Codeunit "CXW SellWatch Mgt"` doesn't expect. → **Mitigation**: add minimal required-field validation in the API page's `OnInsertRecord` trigger (reuse/extend existing field validation already implied by table 60300, don't duplicate business logic from the codeunit).
- **[Risk]** Duplicate submissions from the external system (retries) create duplicate SellWatch entries. → **Mitigation**: `"CXW SRid"` uniqueness check per Decision 5.
- **[Risk]** A caller attempts to overwrite processing-state fields to force premature Purchase Order creation or to mark a row falsely as already handled. → **Mitigation**: field-level non-editable contract per Decision 2, enforced in the page's field properties (not just documentation).
- **[Trade-off]** Establishing a brand-new API naming convention with no prior art means it may need revisiting once a second API page is built. Accepted since blocking on a company-wide API standard isn't warranted for one endpoint.

## Migration Plan

- Purely additive: new page object + permission set entry. No data migration, no changes to existing objects.
- Deploy via normal AL extension publish; no upgrade codeunit needed (no schema change).
- Rollback: remove the new page and its permission set entry; page 60307 and table 60300 are untouched throughout, so rollback carries no data risk.

## Open Questions

- Does Chronext already have a company-wide `APIPublisher`/`APIGroup` naming standard from another BC app (outside this repo) that this should align with, or is `saliniLife` / `sellWatch` an acceptable first convention?
- Should invalid/partial inbound payloads be rejected outright (HTTP 4xx) or accepted and flagged for manual review on page 60307? (Assumed: reject outright, consistent with the "read-only overview" role of page 60307.)
- Confirm which specific fields the external system will actually populate (full 45-field set vs. a subset) — affects which fields need `OnInsertRecord` validation in Decision 2.
