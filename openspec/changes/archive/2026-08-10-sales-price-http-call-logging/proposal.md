## Why

`Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` sends the SalesPrice export HTTP call and only records a coarse outcome on the outbound file record itself (`"CXW Status"`, a 250-char `"CXW Response Message"`) — there is no per-call log, no stored request/response body, and no way to download what was actually sent or received. Meanwhile `Table "CXW SW Http Call Log"` already solves exactly this problem for SellWatch's online-check call (timestamped log, downloadable request/response, redacted secrets), but it's wired specifically to `"CXW Watch Online Approval"` and can't currently be reused. Generalizing that one table to accept log entries from any source, and pointing SalesPrice's HTTP call at it, gives both features the same diagnostic capability without maintaining two separate logging implementations.

## What Changes

- Generalize `Table "CXW SW Http Call Log"` so a log entry can originate from any source table, not just `"CXW Watch Online Approval"`: add a `"CXW Source Table No."` field (same `AllObjWithCaption` pattern already used by `"CXW API Interface Setup"."CXW Source Table No."`) and change `"CXW Source Entry No"`'s `TableRelation` to a conditional relation keyed off it, instead of a single hardcoded relation to `"CXW Watch Online Approval"`.
- **Rename** the table and its page from `"CXW SW Http Call Log"` to `"CXW Http Call Log"` (same object IDs, name only) — "SW" no longer describes its scope once a second, unrelated feature logs into it. Caption stays `'Http Call Log'` (drops the now-inaccurate "SW" from the user-facing label too).
- Wire `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` to write a log entry for every call it makes (success, non-success HTTP status, and network failure) — the same three scenarios `sellwatch-http-call-logging` already covers for SellWatch, sourced from `"CXW Sales Price Outbound File"`.
- **Redact the `Authorization` header** in SalesPrice's logged request text, the same way SellWatch redacts `X-API-KEY` — this is a new secret-leak risk introduced by adding logging here (`SendToApiInterface` currently sends real API keys / Base64-encoded Basic-auth credentials in that header) and must not be stored in the log.
- Add `"CXW Source Table No."` as a visible column on `Page "CXW Http Call Log"` so a shared list can be told apart by origin at a glance.
- Grant `PermissionSet CXWChronWSAll` (SalesPrice) read/insert/modify/delete on the log table and execute on the log page — it currently has neither, since the table was SellWatch-only until now.
- Not touching: the outbound file's own `"CXW Status"`/`"CXW Response Message"` fields stay as the quick-glance status; the new log is an additional, more detailed record, mirroring how SellWatch keeps both `Watch Online Approval.Remark` and the detailed HTTP log side by side. Also not touching: SellWatch's own logging behavior, `LogHttpCallFailureTelemetry` (telemetry) — the user's ask was specifically about the table; a SalesPrice telemetry event can be a fast follow if wanted, not bundled in here.

## Capabilities

### New Capabilities
- `sales-price-http-call-logging`: logging (shared table + downloadable request/response) for the SalesPrice export HTTP call, mirroring `sellwatch-http-call-logging`'s scope for the SalesPrice side.

### Modified Capabilities
- None. `sellwatch-http-call-logging`'s described behavior for SellWatch is unchanged — the table it logs into becomes shared, but no requirement in that spec names the table, and every field it does name (`CXW Success`, `CXW Watch Online Approval`, etc.) keeps its current identifier.

## Impact

- `src/Tables/Tab60302.CXWSWHttpCallLog.al` → renamed `Tab60302.CXWHttpCallLog.al`: object/Caption rename, new `"CXW Source Table No."` field, `"CXW Source Entry No"`'s `TableRelation` becomes conditional (Watch Online Approval + Sales Price Outbound File).
- `src/Pages/Pag60309.CXWSWHttpCallLog.al` → renamed `Pag60309.CXWHttpCallLog.al`: object/Caption rename, `SourceTable` updated, new `"CXW Source Table No."` column, tooltip on `"CXW Source Entry No"` generalized (no longer names Watch Online Approval specifically).
- `src/Tables/Tab60301.CXWWatchOnlineApproval.al`: `LogHttpCall`'s call site sets the new `"CXW Source Table No."` (to `Database::"CXW Watch Online Approval"`) alongside the existing `"CXW Source Entry No"` — otherwise unchanged.
- `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al`: `SendToApiInterface` gains a redacted-request-text builder (mirroring `Tab60301`'s `BuildRedactedRequestText`) and a call to insert a log entry in each of its three outcome branches (success, non-success status, network failure — the `SendOk = false` branch is currently a single combined path and needs splitting to log the two failure kinds distinctly, matching the existing three-scenario shape).
- `src/PermissionSets/CXWChronWSAll.permissionset.al` (SalesPrice): add `tabledata "CXW Http Call Log" = RIMD` and `page "CXW Http Call Log" = X`.
- `src/PermissionSets/CXWSWChronWSAll.permissionset.al` (SellWatch): update the two existing `"CXW SW Http Call Log"` references to the new name.
- `openspec/specs/sales-price-http-call-logging/spec.md` (new, this change).
- Documentation (funktionsregister, developer/user/key-user manuals): the renamed table/page and the new SalesPrice logging behavior need reflecting — scheduled as a dedicated task, same as prior changes this session.
