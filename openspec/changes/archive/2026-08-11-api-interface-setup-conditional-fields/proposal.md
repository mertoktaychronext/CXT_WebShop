## Why

`"CXW API Interface Setup"` (Table 60317, Page 60324) has grown to 11 configuration fields as auth types were added (`None`, `ApiKeyHeader`, `BasicAuth`, `AWSSigV4`), but every field is always shown regardless of the selected `"CXW Auth Type"`. Setting up the AWS SigV4 interface live (2026-08-11) surfaced this directly: it took several rounds of back-and-forth to work out which of API Key / AWS Access Key ID / AWS Region / AWS Service / AWS Secret Access Key / AWS Session Token were actually required for the chosen auth type, because the page gives no indication — every field looks equally relevant whether or not it does anything for the current selection. This is only going to get worse as more auth types or per-type fields are added.

## What Changes

- Page-level: only show/enable the fields that are actually relevant to the currently selected `"CXW Auth Type"` on the interface being edited — e.g. the AWS-specific fields (Access Key ID, Region, Service, Secret Access Key, Session Token) only appear for `AWSSigV4`; the generic `API Key` field only appears for `ApiKeyHeader`, `BasicAuth`, and `AWSSigV4` (where it optionally doubles as an `X-API-Key` header value, per the live SigV4 setup).
- Because `Visible` on a List/repeater page is a column-level property shared by every row (AL cannot vary a column's visibility per record in a repeater), achieving true per-record conditional fields requires a single-record editing surface — the design will settle whether that's a new Card page reachable from the existing list, or another mechanism; the List page's row-based overview stays unaffected either way.
- **BREAKING**: none intended — purely an editing-experience change; no fields, table structure, or auth logic are removed or renamed.

## Capabilities

### New Capabilities
- `api-interface-setup-conditional-fields`: guided, auth-type-aware data entry for `"CXW API Interface Setup"`, showing only the fields relevant to the selected `"CXW Auth Type"` when configuring one interface.

### Modified Capabilities
(none — no archived spec currently documents the API Interface Setup page's field layout; this is new spec territory, not a change to prior documented requirements)

## Impact

- `src/Pages/Pag60324.CXWAPIInterfaceSetup.al` — field visibility/layout changes, likely a new companion Card page.
- `src/Tables/Tab60317.CXWAPIInterfaceSetup.al` — no structural changes expected, but may gain a helper procedure or two for the page to query "which fields are relevant" per auth type, kept in one place rather than duplicated in page logic.
- No impact on `SendToApiInterface` (Codeunit 60329) or the signing/auth logic itself — this only changes what's shown while editing, not what's sent.
- No impact on SellWatch (`Table 60301`) — it doesn't use Page 60324 for its own interface record.
