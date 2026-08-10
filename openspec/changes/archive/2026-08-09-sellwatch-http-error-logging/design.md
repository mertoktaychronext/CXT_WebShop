## Context

`Table 51009 "Watch Online Approval"`'s `CreateEntryInexternalFile` procedure calls a SellWatch HTTP endpoint (`GET <Endpoint URL>/<Item No>/<Variant Code>/check`, API key from `Table 51007 "SL API Interface Setup"`, Code `WOA`) to decide whether a purchased watch may go live. Today, three exit points (`HttpClientObj.Send` returning `false`, a non-success status code, or simply nothing in the response) all fall through silently — `WOA` is left unchanged and nothing is recorded anywhere. This was flagged as a known limitation during the SellWatch migration (see developer manual) and this change closes it.

There is a precedent in the codebase for logging outbound HTTP payloads: `Table 51004 "SL Sales Price Outbound File"` stores the JSON sent to the Sales Price export endpoint plus a `Response Message` text field and a status enum. That table is intentionally *not* reused here — it has no field for the raw response body, no link back to a source record, and mixing two unrelated domains (Sales Price export queue vs. SellWatch online-check log) into one table would violate the project's existing "keep SL and SW objects separate" pattern (see `docs/funktionsregister/*` "Auslagerungs-Kandidaten"). This change introduces a new, SellWatch-specific log table instead.

## Goals / Non-Goals

**Goals:**
- Every call `CreateEntryInexternalFile` makes is logged — both successful and failed — with enough detail to diagnose a failure after the fact.
- Failures additionally raise a telemetry event, so they're visible in Application Insights without anyone opening the log page.
- The stored request can never leak the real `X-API-KEY` value.
- A Key User (or developer) can download the exact request and response bodies as `.txt` files for a given log entry.

**Non-Goals:**
- No retry logic, no alerting/notification beyond telemetry, no automatic cleanup/retention policy for old log entries (can be a follow-up if the table grows large).
- No changes to the Sales Price export logging path (`Codeunit 51000`, `Table 51004`) — out of scope per the proposal's scope note.
- No change to `CreateEntryInexternalFile`'s existing behavior towards the `Watch Online Approval` record (it still just sets `"Check Online"`/`Remark` or leaves the record untouched); this change only adds observability around it, not new business logic.

## Decisions

- **New table `SW Http Call Log`, not a reuse of `Table 51004`**: separate domain, separate schema (needs a request Blob + a response Blob + a link to the `Watch Online Approval` entry that triggered the call), and keeps the existing SL/SW object separation intact. Proposed ID: **Table 51010** (next free ID in the registered `51000-51049` range; 51000-51009 are all taken).
- **New page `SW Http Call Log`** (Page 51006, next free page ID), a read-only list with two actions, `Download Request` and `Download Response`, each calling the global `DownloadFromStream` procedure against the corresponding Blob field's `InStream`.
- **Header redaction, not omission**: the logged request text includes the full request line and headers *except* the `X-API-KEY` value, which is replaced with a fixed placeholder (e.g. `X-API-KEY: ***redacted***`) rather than dropping the header entirely — so the log still shows *that* an API key was sent, without exposing it. This is a hard requirement, not a nice-to-have, given the API key was just moved out of source code specifically to stop it leaking in plaintext (see the earlier `sellwatch-table-extensions`-adjacent dev-abschluss finding).
- **Table fields**: `Entry No` (Integer, AutoIncrement, PK), `Call DateTime` (DateTime), `Source Entry No` (Integer, the triggering `Watch Online Approval."Entry No"`), `Endpoint URL` (Text[250]), `Success` (Boolean), `HTTP Status Code` (Integer), `Error Message` (Text[250]), `Request` (Blob), `Response` (Blob). No FlowField back-reference is added to `Watch Online Approval` — the log is looked up by filtering on `Source Entry No` from the log page/table itself, keeping `Table 51009` unchanged apart from the new logging calls.
- **Telemetry via `Session.LogMessage`**, following the project's `implementing-telemetry` skill conventions (Feature Telemetry pattern) rather than a bespoke mechanism: one event ID (e.g. `SW0001`) logged at `Verbosity::Error`, `DataClassification::SystemMetadata`, `TelemetryScope::ExtensionPublisher`, with custom dimensions for the endpoint, HTTP status (if any), and the `Watch Online Approval` entry number — no request/response body in the telemetry event itself (that stays in the Blob log table only, to avoid duplicating potentially sensitive payload data into Application Insights).
- **Logging happens inline in `CreateEntryInexternalFile`**, wrapping the existing `HttpClientObj.Send` call and its two early exits, rather than extracting a separate reusable "HTTP logging" codeunit. There is currently exactly one call site; a shared logging codeunit would be premature abstraction until a second call site (e.g. Sales Price export) actually needs the same behavior.
- **New Permission Set entries**: `tabledata`/`table`/`page` entries for the new table and page are added to `SWChronWSAll` (not a new permission set), since this log is part of the SellWatch domain.

## Risks / Trade-offs

- [Blob-based request/response storage on every call could grow the table unbounded] → Mitigation: explicitly out of scope (see Non-Goals); flagged as a follow-up if call volume turns out to be high enough to matter.
- [Redacting the API key by string-replace on the built request text is easy to get subtly wrong (e.g. if the key value happens to also appear elsewhere in the URL)] → Mitigation: build the redacted request text by omitting the key value at the point the header is constructed, not via after-the-fact find-and-replace on the final request string.
- [Telemetry event schema/verbosity conventions might not match whatever the `implementing-telemetry` skill's current guidance says by the time this is implemented] → Mitigation: re-check that skill during `/opsx:apply` rather than treating the event ID/dimensions named here as final.

## Open Questions

- Should successful calls also be prunable/short-retention while failed calls are kept longer? Deferred — no retention policy in this change (see Non-Goals).
- Exact telemetry event ID (`SW0001` used as a placeholder) — confirm there isn't already an event ID registry/convention elsewhere in the codebase before implementation (none was found during this change's research).
