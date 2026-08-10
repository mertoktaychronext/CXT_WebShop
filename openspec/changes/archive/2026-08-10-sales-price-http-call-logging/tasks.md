## 1. Table: generalize and rename

- [x] 1.1 `git mv src/Tables/Tab60302.CXWSWHttpCallLog.al src/Tables/Tab60302.CXWHttpCallLog.al`. Change `table 60302 "CXW SW Http Call Log"` → `table 60302 "CXW Http Call Log"`; `Caption = 'SW Http Call Log'` → `Caption = 'Http Call Log'`.
- [x] 1.2 Add `field(10; "CXW Source Table No."; Integer)` with `TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));` (see design.md for exact snippet).
- [x] 1.3 Change `"CXW Source Entry No"`'s `TableRelation` from the single hardcoded `"CXW Watch Online Approval"."CXW Entry No"` to the conditional form keyed off `"CXW Source Table No."` (Watch Online Approval = 60301, Sales Price Outbound File = 60314 — see design.md for exact syntax).

## 2. Page: generalize and rename

- [x] 2.1 `git mv src/Pages/Pag60309.CXWSWHttpCallLog.al src/Pages/Pag60309.CXWHttpCallLog.al`. Change `page 60309 "CXW SW Http Call Log"` → `page 60309 "CXW Http Call Log"`; `Caption = 'SW Http Call Log'` → `Caption = 'Http Call Log'`; `SourceTable = "CXW SW Http Call Log"` → `SourceTable = "CXW Http Call Log"`.
- [x] 2.2 Add a `field("CXW Source Table No."; Rec."CXW Source Table No.")` column to the repeater, placed before `"CXW Source Entry No"`, with a tooltip explaining it identifies which feature made the call.
- [x] 2.3 Update `"CXW Source Entry No"`'s tooltip — currently "Specifies the Watch Online Approval entry that triggered this call." — to a source-agnostic wording (e.g. "Specifies the entry in the source table that triggered this call.").
- [x] 2.4 `DownloadRequest`/`DownloadResponse` actions and their `StrSubstNo('SWHttpCallLog_%1_...', ...)` filename prefixes: update the literal prefix from `SWHttpCallLog_` to `HttpCallLog_` for consistency with the rename (cosmetic, but avoid leaving a stale "SW" in generated filenames).

## 3. SellWatch call site: set the new source-table field

- [x] 3.1 In `src/Tables/Tab60301.CXWWatchOnlineApproval.al`, `LogHttpCall`: change `HttpCallLog: Record "CXW SW Http Call Log"` → `Record "CXW Http Call Log"`. Add `HttpCallLog."CXW Source Table No." := Database::"CXW Watch Online Approval";` alongside the existing `HttpCallLog."CXW Source Entry No" := pWOA."CXW Entry No";` line. No other logic changes — SellWatch's three call sites (`CreateEntryInexternalFile`'s success/non-success/network-failure branches) are otherwise untouched.

## 4. SalesPrice call site: add logging

- [x] 4.1 In `src/Codeunits/Codeunit60329.CXWExportGatewaySalesPrice.al`, add a `local procedure BuildRedactedRequestText(pMethod: Text; pUrl: Text; pJsonBody: Text): Text` mirroring `Tab60301`'s version — method + URL + `Content-Type: application/json` + `Authorization: ***redacted***` + the JSON body, using `Codeunit "Type Helper"`'s `LFSeparator()` between lines (same as the SellWatch version).
- [x] 4.2 Add a `local procedure LogHttpCall(pOutboundFile: Record "CXW Sales Price Outbound File"; pEndpointUrl: Text; pSuccess: Boolean; pHttpStatusCode: Integer; pErrorMessage: Text; pRequestText: Text; pResponseText: Text)` mirroring `Tab60301`'s `LogHttpCall` exactly, except: `HttpCallLog."CXW Source Table No." := Database::"CXW Sales Price Outbound File";` and `HttpCallLog."CXW Source Entry No" := pOutboundFile."CXW Entry No";`. **Deviation:** the correct field reference is `pOutboundFile."CXW Entry No."` (with trailing period — `"CXW Sales Price Outbound File"` uses a different naming convention than SellWatch's `"CXW Entry No"`). Initially written without the period, caught immediately by an IDE compile diagnostic and fixed.
- [x] 4.3 In `SendToApiInterface`, build the redacted request text once (via 4.1) right after `HttpContentObj`/headers are set up, before `HttpClientObj.Send`. Add three `LogHttpCall(...)` calls, one in each existing outcome branch:
  - the `if SendOk and HttpResponse.IsSuccessStatusCode()` branch (success: `pSuccess = true`, real `HttpStatusCode`, empty error, `ResponseText` read via `HttpResponse.Content().ReadAs(...)` — note `ResponseText` isn't currently read on the success path, only on failure; read it here specifically for the log)
  - the `if SendOk` (but non-success status) branch (`pSuccess = false`, real `HttpStatusCode`, the existing `ResponseText` formatted error)
  - the network-failure `else` branch (`pSuccess = false`, `HttpStatusCode = 0`, `'The request could not be sent (network error).'`, empty response)
- [x] 4.4 Do not change `vOutboundFile."CXW Status"`/`"CXW Response Message"` assignments — those stay exactly as they are today; the new logging is additive.

## 5. Permission Sets

- [x] 5.1 `src/PermissionSets/CXWChronWSAll.permissionset.al` (SalesPrice): add `tabledata "CXW Http Call Log" = RIMD,` and `page "CXW Http Call Log" = X,` to the `Permissions` list. **Deviation:** also added `table "CXW Http Call Log" = X,`, consistent with how every other table in this permission set already has a matching `table = X` entry alongside its `tabledata` entry.
- [x] 5.2 `src/PermissionSets/CXWSWChronWSAll.permissionset.al` (SellWatch): update its two existing `"CXW SW Http Call Log"` references (`tabledata` and `page`) to `"CXW Http Call Log"`. **Deviation:** there were three references, not two (`tabledata`, `table`, and `page`) — all three updated.

## 6. Build Verification

- [x] 6.1 Compile the app and resolve every error. There must be zero remaining references to `"CXW SW Http Call Log"` anywhere under `src/`. Compiled clean.
- [x] 6.2 Manually reason through (or test if a BC environment is available) that a SellWatch log entry and a SalesPrice log entry can coexist in the table without `TableRelation` errors, and that each resolves to the correct source record when looked up via the page. Reasoned through: `"CXW Source Entry No"`'s conditional `TableRelation` branches on `"CXW Source Table No."` (60301 vs 60314), so each row's relation resolves independently of what other rows exist — no BC environment was available to execute an actual insert/lookup.

## 7. Documentation

- [x] 7.1 Regenerate the funktionsregister and developer/user/key-user manuals to reflect: the table/page rename, the new `"CXW Source Table No."` field, and SalesPrice's new HTTP logging behavior (mirroring how the existing SellWatch logging is documented today). Updated: `developer-manual-de.md`, `developer-manual-en.md`, `funktionsregister-sl-chronext-webshop.md`, `gesamtuebersicht.md`, `key-user-manual-de.md`, `key-user-manual-en.md`. **Deviation (out of original task wording, but required):** also reconciled `Translations/CHX.Webshop.de-DE.xlf` against the regenerated `.g.xlf` — the table/page rename produced new trans-unit ID hashes, and the new `"CXW Source Table No."` field/column and the new `NetworkErrorTxt` label needed German translations. `user-manual-*.md` were not touched — no end-user-facing (non-key-user) behavior changed.

## 8. Final Check

- [x] 8.1 Full-text search for `"SW Http Call Log"` (with and without the `CXW ` prefix) and `SWHttpCallLog` across `src/`, `docs/`, and `Translations/`, confirming every remaining hit is either an intentional historical changelog note or something out of scope, not a missed rename. Result: zero hits in `src/` and `Translations/`; remaining `docs/` hits are all intentional "previously named X" changelog notes. Also diffed all trans-unit IDs between `.g.xlf` and `de-DE.xlf`: the only mismatches found are unrelated to this change (pre-existing, uncommitted `TableExtension`/`PageExtension` "Country Region" deletion already present in the working tree before this task started — out of scope here, previously flagged to the user).
