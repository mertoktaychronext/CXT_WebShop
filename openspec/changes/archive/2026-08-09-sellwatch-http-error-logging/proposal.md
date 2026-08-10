## Why

`CreateEntryInexternalFile` on `Table 51009 "Watch Online Approval"` calls the SellWatch online-check API but currently aborts silently on any failure (network error, non-success HTTP status) — nothing is logged, so a stuck "Check Online" flag is undiagnosable today (already flagged as a known limitation in the developer manual). This change adds a durable, downloadable record of every call, plus telemetry for failures, so ops/support can actually find out what happened.

## What Changes

- New table logging every SellWatch online-check HTTP call (both successful and failed): timestamp, endpoint, related `Watch Online Approval` entry, outcome, HTTP status code, error message, and the full request and response bodies as Blobs.
- **Security requirement, not optional**: the logged request must never contain the raw `X-API-KEY` value — the header is redacted before it's persisted, so this log can't reintroduce the plaintext-secret problem the API key was just moved out of source code to avoid.
- New list page over the log table with two actions to download the stored request and response bodies as `.txt` files.
- Every failed call additionally raises a telemetry event (`Session.LogMessage` / Feature Telemetry, per the project's `implementing-telemetry` conventions) with the failure reason, so failures surface in Application Insights even if nobody opens the log page.
- `Table 51009`'s `CreateEntryInexternalFile` is modified to write a log entry (and telemetry on failure) around its existing `HttpClient.Send` call, instead of silently returning.

**Scope note (assumption, flag if wrong):** this covers only the SellWatch online-check call in `Table 51009`. The Sales Price export call in `Codeunit 51000` already has its own outbound-file/response-message logging (`Table 51004`) and is out of scope here — if that call should also gain telemetry and a downloadable request log, say so and this proposal will be extended.

## Capabilities

### New Capabilities
- `sellwatch-http-call-logging`: Logging (table + downloadable request/response + telemetry on failure) for the SellWatch online-check HTTP call.

### Modified Capabilities
<!-- none: no existing spec's requirements change; this only adds new logging around existing, unspecified behavior -->

## Impact

- New AL files under `src/Tables/` and `src/Pages/` (IDs from the registered `51000-51049` range): a log table and a list page with download actions.
- Modified: `src/Tables/Tab51009.WatchOnlineApproval.al` (`CreateEntryInexternalFile`) — writes a log entry and, on failure, a telemetry event; no change to its existing success/failure behavior towards the `Watch Online Approval` record itself.
- Possible new entry in `src/PermissionSets/SWChronWSAll.permissionset.al` for the new table/page.
- No changes to `Table 51007 "SL API Interface Setup"` or the Sales Price export path.
