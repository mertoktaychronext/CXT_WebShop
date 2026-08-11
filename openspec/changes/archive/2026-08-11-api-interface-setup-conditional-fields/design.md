## Context

`"CXW API Interface Setup"` (Table 60317) currently has 11 fields, split into three groups by relevance:
- **Always relevant**: Code, Description, Endpoint URL, Auth Type, HTTP Method, SOAP Action, Source Table No., Active.
- **Relevant for `ApiKeyHeader` / `BasicAuth` / `AWSSigV4`** (optional for the last): `API Key` (masked, Isolated Storage via `SetApiKey`/`GetApiKey`) — for `AWSSigV4` it's optionally sent as an `X-API-Key` header alongside the SigV4 signature, discovered while live-debugging the sales-price-aws-sigv4-auth change against a real AWS API Gateway endpoint that layers an API-key usage plan on top of IAM authorization.
- **Relevant only for `AWSSigV4`**: AWS Access Key ID, AWS Region, AWS Service (plain fields), AWS Secret Access Key, AWS Session Token (masked, Isolated Storage).

Page 60324 is `PageType = List` with all 11 fields in one `repeater(Group)`, unconditionally visible regardless of the row's `"CXW Auth Type"`. Table 60317's own `"CXW Active"` activation guard already encodes which fields are required per auth type (see `OnValidate` of `"CXW Active"`), so the relevance rules exist in the codebase today — they're just not reflected in what the page shows.

**Key platform constraint**: in AL, a page field's `Visible` property on a `repeater` is evaluated for the column as a whole, not per displayed row — a grid column is inherently a page-wide construct shared by every record, not something that can differ row-by-row (there is no supported mechanism to show a column for row 1 and hide it for row 2 in the same repeater). Genuine per-record conditional field visibility is only possible on a page that has exactly one current record at a time, i.e. a Card page, where `Visible` can safely depend on `Rec."CXW Auth Type"` because there is no ambiguity about "which record."

## Goals / Non-Goals

**Goals:**
- When editing one interface, only the fields relevant to its selected `"CXW Auth Type"` are visible/enterable — changing Auth Type live-updates which fields show, without needing to save and reopen.
- Centralize "which fields are relevant for which auth type" in one place (Table 60317), so the page and the existing `"CXW Active"` activation guard both read from the same source instead of maintaining parallel logic that can drift when a future auth type is added.
- Preserve the existing list-based overview (browsing/comparing interfaces, seeing which are Active, at a glance) — this change is about the editing experience, not removing the ability to see multiple interfaces at once.

**Non-Goals:**
- No changes to `SendToApiInterface` (Codeunit 60329) or any signing/auth logic — this is purely an editing-surface change.
- No new auth types, no new fields beyond what already exists.
- No change to how secrets are stored (Isolated Storage via the existing `Set`/`Get` procedure pairs stays exactly as is).

## Decisions

### 1. Add a Card page for guided single-record editing; keep the List page as a trimmed-down overview
Page 60324 stays a List page but its repeater is trimmed to the fields useful for scanning multiple interfaces at once (Code, Description, Endpoint URL, Auth Type, Active) — the type-specific detail fields (API Key, all AWS fields, HTTP Method, SOAP Action) are removed from the repeater. A new Card page, `"CXW API Interface Setup Card"`, becomes the place those fields live, reached by drilling into a row from the list (standard `RunObject`/`PromotedActionCategories` drill-down pattern already used elsewhere in this app, e.g. Page 60322 → checking lines). On the Card page, `Rec."CXW Auth Type"` has exactly one value at a time, so `Visible` can correctly reflect it.

**Alternative considered**: keep everything on the List page and try to fake per-row visibility with `ShowAsCombobox`/conditional formatting tricks. Rejected — not supported by the platform for column visibility (see Context); would only produce inconsistent or misleading behavior across rows.

**Alternative considered**: convert Page 60324 itself from List to Card (single record focus, `ListPart` elsewhere for overview). Rejected as more invasive than necessary — this table has few rows (a handful of interfaces), the existing List page's `UsageCategory = Administration` entry point and row-browsing behavior are useful today and referenced by nothing that would need to change; adding a companion Card page is the smaller, standard, well-understood BC pattern (list-to-card drill-down, same as most BC setup areas).

### 2. Field relevance lives on Table 60317, exposed as boolean procedures, not duplicated in page logic
Add procedures to Table 60317 such as `IsApiKeyFieldRelevant(): Boolean` (true unless `"CXW Auth Type" = None`) and `IsAwsFieldsRelevant(): Boolean` (true only for `AWSSigV4`). The Card page calls these (via `Rec.IsApiKeyFieldRelevant()` etc.) to drive `Visible` properties, and the existing `"CXW Active"` `OnValidate` guard is refactored to call the same procedures instead of repeating the `"CXW Auth Type" <> "CXW Auth Type"::AWSSigV4`-style conditions inline. One source of truth: adding a 5th auth type later only requires updating these procedures once, and both the guard and the page stay correct automatically.

**Alternative considered**: put the relevance logic directly in the Card page's AL code (e.g. in `OnAfterGetCurrRecord`). Rejected — the activation guard on the table would still need its own copy of the same rules, and the two would inevitably drift the next time an auth type is added or changed, which is exactly the problem this change exists to avoid in miniature.

### 3. Visibility recalculated in both `OnAfterGetCurrRecord` and `"CXW Auth Type"`'s `OnValidate`
Card-page boolean variables (e.g. `ShowApiKeyField`, `ShowAwsFields`) are set in `trigger OnAfterGetCurrRecord()` (covers navigating between records) and re-set inside the `"CXW Auth Type"` field's own `OnValidate` trigger (covers changing the auth type on the record currently being edited, so the field set updates live without requiring a save/reopen round-trip).

### 4. List page keeps `"CXW Auth Type"` itself visible and editable
The auth type selector stays on the List page (alongside Code/Description/Endpoint URL/Active) even though it's the very field that drives detail-field relevance — users need to see/compare auth types across interfaces without opening each one, and changing it inline on the list is harmless (it just means the newly-relevant detail fields aren't visible until the user opens the Card). Only the *detail* fields specific to a type move to the Card.

## Risks / Trade-offs

- **[Risk]** Removing inline detail-field editing from the List page changes a workflow users may be used to (editing an AWS field directly in the list row) → **Mitigation**: this table realistically holds a small number of interfaces (currently SellWatch's `'WOA'` entry plus the sales-price export interface); drilling into a Card for detail editing is the standard BC pattern used almost everywhere else in Business Central, not a novel or heavier workflow.
- **[Risk]** Two places (Card page `Visible` bindings, Table 60317 relevance procedures) must stay conceptually in sync even though the logic itself is centralized in the table procedures → **Mitigation**: Decision 2 ensures the Card page never re-implements the rules, only calls the table procedures — there is exactly one place the actual per-auth-type conditions are written.
- **[Risk]** A field could be marked "not relevant" and hidden while still holding previously-entered data (e.g. a user fills in AWS fields, then switches Auth Type away from `AWSSigV4`) — the data isn't deleted, just hidden → **Mitigation**: this is existing, unchanged behavior (switching auth type today already leaves the other fields' stored values untouched; `SendToApiInterface` only reads the fields relevant to the currently-selected type), so no new data-hygiene issue is introduced; explicitly out of scope to add "clear irrelevant fields on auth type change" logic, since that risks silently discarding a value a user might switch back to.

## Migration Plan

No data migration — purely additive (new Card page) plus a field-visibility/layout change on an existing page. Existing interface records are unaffected; all currently-stored values (plain fields and Isolated Storage secrets) remain exactly as they are and remain reachable via the new Card page. Deploy via normal `AL: Publish`. Rollback is a normal code revert — the List page's full field set can be restored by reverting Page 60324, with no data-shape changes to undo.

## Open Questions

- Should drilling from the List page into the Card happen via a explicit "Edit" action, double-click/`Enter` on the row (standard BC drill-down), or both? Leaning towards standard drill-down (matches every other BC list-to-card pattern, no extra action needed) — can be finalized during implementation without further design input.
