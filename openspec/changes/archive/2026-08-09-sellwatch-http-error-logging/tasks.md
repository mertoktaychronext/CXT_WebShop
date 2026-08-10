## 1. Log table

- [x] 1.1 Create `src/Tables/Tab51010.SWHttpCallLog.al`: `table 51010 "SW Http Call Log"` with fields `Entry No` (Integer, AutoIncrement, PK), `Call DateTime` (DateTime), `Source Entry No` (Integer, links to `Watch Online Approval."Entry No"`), `Endpoint URL` (Text[250]), `Success` (Boolean), `HTTP Status Code` (Integer), `Error Message` (Text[250]), `Request` (Blob), `Response` (Blob).
- [x] 1.2 Add a key on `Source Entry No` for lookup from a given `Watch Online Approval` entry.

## 2. Log page

- [x] 2.1 Create `src/Pages/Pag51006.SWHttpCallLog.al`: `page 51006 "SW Http Call Log"`, read-only list showing all fields except the two Blobs, with ToolTips on every field per project convention.
- [x] 2.2 Add action `Download Request` calling `DownloadFromStream` against the `Request` Blob's `InStream`, suggested filename `SWHttpCallLog_<Entry No>_Request.txt`.
- [x] 2.3 Add action `Download Response` calling `DownloadFromStream` against the `Response` Blob's `InStream`, suggested filename `SWHttpCallLog_<Entry No>_Response.txt`.

## 3. Instrument the HTTP call

- [x] 3.1 In `src/Tables/Tab51009.WatchOnlineApproval.al`, `CreateEntryInexternalFile`: build the logged request text (method, URL, headers) with the `X-API-KEY` header value replaced by a fixed placeholder at construction time (not via find-and-replace on the final request text — see design.md Risks).
- [x] 3.2 On `HttpClient.Send` returning `false`: insert a `SW Http Call Log` entry with `Success` = false, an error message, the redacted request text, and an empty response.
- [x] 3.3 On a non-success HTTP status: insert a `SW Http Call Log` entry with `Success` = false, the HTTP status code, the redacted request text, and the response body.
- [x] 3.4 On success: insert a `SW Http Call Log` entry with `Success` = true, the HTTP status code, the redacted request text, and the response body.
- [x] 3.5 Consult the `implementing-telemetry` skill for the current Feature Telemetry / `Session.LogMessage` conventions, then raise a telemetry event on every failure path (3.2 and 3.3) with the endpoint, HTTP status code (if any), and the `Watch Online Approval` entry number as custom dimensions — no request/response body in the telemetry event.

## 4. Permissions

- [x] 4.1 Add `tabledata "SW Http Call Log" = RIMD` and `table "SW Http Call Log" = X` to `src/PermissionSets/SWChronWSAll.permissionset.al`.
- [x] 4.2 Add `page "SW Http Call Log" = X` to `src/PermissionSets/SWChronWSAll.permissionset.al`.

## 5. Verification

- [x] 5.1 Compile the AL project and confirm no errors from the new table/page or from the modified `CreateEntryInexternalFile`.
- [x] 5.2 Confirm the redacted request text never contains the real API key value in any code path (success, network failure, non-success status).
- [x] 5.3 Confirm `app.json` idRanges still cover 51010/51006 (within the existing `51000-51049` range).
- [x] 5.4 Update the developer manual's "Known Limitations" entry for `CreateEntryInexternalFile` (currently states failures are silent/unlogged) to reflect the new logging and telemetry behavior.
