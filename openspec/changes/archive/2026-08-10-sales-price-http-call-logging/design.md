## Context

`Table "CXW SW Http Call Log"` (60302) already does everything a shared HTTP-call log needs — per-call timestamp, endpoint, success flag, HTTP status, error message, and downloadable request/response blobs (`Page "CXW SW Http Call Log"`, 60309) — but its `"CXW Source Entry No"` field has a single hardcoded `TableRelation = "CXW Watch Online Approval"."CXW Entry No"`, and both the table and page are named after "SW" (SellWatch). SalesPrice's own HTTP call, in `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface`, currently logs nothing beyond a status flag and a 250-char message on the outbound file record — no request/response body, no per-attempt history (a re-sent line just overwrites the previous status).

This codebase already has a precedent for "this record can point at different source tables" — `Table "CXW API Interface Setup"."CXW Source Table No."` (Integer, `TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table))`), used so one interface-setup row can serve either `Sales Price` or (implicitly) other tables. This design reuses that exact pattern for the log table's source field.

## Goals / Non-Goals

**Goals:**
- One shared log table/page for both SellWatch's online-check call and SalesPrice's export call, distinguishable by source.
- SalesPrice gets the same three logged outcomes SellWatch already has (success, non-success HTTP status, network failure) with downloadable request/response.
- No secret (`Authorization` header) ever gets persisted in the new SalesPrice request logs — closing the same class of risk SellWatch already closed for `X-API-KEY`.
- SellWatch's existing behavior, spec (`sellwatch-http-call-logging`), and log entries already in the table are unaffected by the generalization.

**Non-Goals:**
- No SalesPrice telemetry event (SellWatch's `LogHttpCallFailureTelemetry` stays SellWatch-only for now) — the user's ask was the table; telemetry can follow separately if wanted.
- No change to `"CXW Sales Price Outbound File"."CXW Status"`/`"CXW Response Message"` — they stay as the quick-glance status column; the new log is additive detail, not a replacement.
- No generalization beyond these two sources. A third future caller can extend the same conditional `TableRelation` later; not designing an abstract "pluggable logger" interface now.

## Decisions

### Renaming `"CXW SW Http Call Log"` → `"CXW Http Call Log"`

Same object IDs (Table 60302, Page 60309), name and Caption only. "SW" stops being accurate the moment a second, unrelated feature logs into it — consistent with this session's established convention of not leaving a feature-specific prefix on something that's no longer feature-specific (mirrors why the earlier renumbering changes replaced ad-hoc prefixes rather than layering new ones on top). File names follow: `Tab60302.CXWSWHttpCallLog.al` → `Tab60302.CXWHttpCallLog.al`, `Pag60309.CXWSWHttpCallLog.al` → `Pag60309.CXWHttpCallLog.al`.

### Generalizing the source reference

Add a new field and change the existing one's relation, both on `Table "CXW Http Call Log"`:

```al
field(10; "CXW Source Table No."; Integer)
{
    Caption = 'Source Table No.';
    DataClassification = SystemMetadata;
    TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
}
field(3; "CXW Source Entry No"; Integer)
{
    Caption = 'Source Entry No';
    TableRelation = if ("CXW Source Table No." = const(60301)) "CXW Watch Online Approval"."CXW Entry No"
                     else
                     if ("CXW Source Table No." = const(60314)) "CXW Sales Price Outbound File"."CXW Entry No.";
    DataClassification = SystemMetadata;
}
```

(Field ID 10 for the new field — next free number after the existing 1–9.) Both existing and new callers set `"CXW Source Table No."` explicitly (`Database::"CXW Watch Online Approval"` / `Database::"CXW Sales Price Outbound File"`) rather than relying on any inference, so the conditional relation always resolves correctly regardless of call order.

**Alternative considered:** a generic `RecordID` field instead of separate table-no/entry-no fields. Rejected — `"CXW API Interface Setup"` already established the table-no + entry-no pair as this project's convention for polymorphic source references; matching it keeps the two "points at another table generically" mechanisms in the app identical instead of introducing a second style.

### Reusing the redaction pattern for SalesPrice

`SendToApiInterface` builds its `Authorization` header from either `ApiInterfaceSetup.GetApiKey()` directly (ApiKeyHeader auth) or a Base64-encoded credential (BasicAuth) — both are secrets that must not reach the log. Add a `BuildRedactedRequestText` local procedure to `Codeunit "CXW Export Gateway Sales Price"`, mirroring `Tab60301`'s: method + URL + `Content-Type` header + `Authorization: ***redacted***` + the JSON body (the body itself is business data already visible elsewhere via the outbound file's `TargetFile` blob, not a secret — logging it in the request text is fine and useful for diagnosing malformed payloads).

### Splitting `SendToApiInterface`'s failure path into two logged outcomes

Today, `SendOk = false` (network failure, no response) and `SendOk = true` + non-success status code are already handled as two separate `ResponseText` constructions in the existing code — they just aren't logged. The three logging call sites map directly onto the three existing branches already in the procedure (success, non-success status, network failure) — no new branching logic needed, just a `LogHttpCall(...)` call added into each of the three places that currently only set `vOutboundFile."CXW Status"`.

## Risks / Trade-offs

- [Renaming the table/page touches two permission sets and any documentation mentioning "SW Http Call Log"] → Mitigation: same mechanical rename process already used twice this session (git mv + compile-verify + doc regen pass), not a new technique.
- [Conditional `TableRelation` with `const(60301)`/`const(60314)` hardcodes object IDs into the field definition] → Accepted trade-off, matches how AL's own conditional-relation syntax works (it requires literal `const()` values, not indirection); if either object is ever renumbered again, this relation needs updating alongside every other reference to that ID.
- [SalesPrice's log volume could grow faster than SellWatch's if uploads run frequently] → Not a concern raised by the user; no retention/cleanup mechanism designed here, matching SellWatch's own log table which also has none.

## Migration Plan

Not applicable — pure additive change plus an object rename (name only, same IDs, so no data migration for existing SellWatch log rows: they keep their `"CXW Source Entry No"` values, and existing rows will simply have a blank `"CXW Source Table No."` until backfilled). One thing worth deciding at apply time: whether to backfill existing SellWatch log rows' new `"CXW Source Table No."` field (to `Database::"CXW Watch Online Approval"`) via an upgrade codeunit, or leave historical rows with a blank source-table (acceptable since the existing `"CXW Source Entry No"` values are unambiguous in practice — no SalesPrice rows exist yet to collide with). Recommend: leave blank, note it in tasks — this mirrors the "no upgrade codeunit, nothing deployed with real data yet" reasoning from the earlier renumbering changes, and the ambiguity is purely cosmetic (an already-filterable list column being blank for old rows).

## Open Questions

None outstanding — the two real judgment calls (rename the table, and how to structure the source reference) both had a strong precedent in this codebase to follow directly.
