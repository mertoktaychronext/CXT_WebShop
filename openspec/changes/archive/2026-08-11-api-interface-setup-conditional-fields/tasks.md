## 1. Table: centralize field relevance rules

- [x] 1.1 In `src/Tables/Tab60317.CXWAPIInterfaceSetup.al`, add `procedure IsApiKeyFieldRelevant(): Boolean` returning `"CXW Auth Type" <> "CXW Auth Type"::None`.
- [x] 1.2 Add `procedure IsAwsFieldsRelevant(): Boolean` returning `"CXW Auth Type" = "CXW Auth Type"::AWSSigV4`.
- [x] 1.3 Refactor the `"CXW Active"` field's `OnValidate` trigger to call `IsApiKeyFieldRelevant()`/`IsAwsFieldsRelevant()` instead of its inline `"CXW Auth Type" <> "CXW Auth Type"::...` conditions, preserving the exact same error behavior (`MissingApiKeyErr` / `MissingAwsCredentialsErr`).
  - Implemented as `IsApiKeyFieldRelevant() and not IsAwsFieldsRelevant()` for the API-key branch, which is exactly equivalent to the original `<> None and <> AWSSigV4` condition (verified: true only for `ApiKeyHeader`/`BasicAuth`).

## 2. New Card page for guided single-record editing

- [x] 2.1 Create `src/Pages/Pag60325.CXWAPIInterfaceSetupCard.al`, `page 60325 "CXW API Interface Setup Card"`, `PageType = Card`, `SourceTable = "CXW API Interface Setup"`, `ApplicationArea = All`.
- [x] 2.2 Move the type-specific fields from Page 60324's repeater onto this Card page: `ApiKey` (masked, `g_txtApiKey`/`SetApiKey`), `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"`, `AwsSecretAccessKey` (masked), `AwsSessionToken` (masked), plus `"CXW Http Method"` and `"CXW SOAP Action"` (always-relevant, not auth-type-gated) and `"CXW Source Table No."` and `"CXW Active"` — same field controls, triggers, and tooltips as they exist today on Page 60324, just relocated.
- [x] 2.3 Add page-level `var` booleans `ShowApiKeyField` and `ShowAwsFields`; set both in `trigger OnAfterGetCurrRecord()` from `Rec.IsApiKeyFieldRelevant()` / `Rec.IsAwsFieldsRelevant()`.
- [x] 2.4 Set `Visible = ShowApiKeyField` on the `ApiKey` field control; set `Visible = ShowAwsFields` on `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"`, `AwsSecretAccessKey`, `AwsSessionToken`.
- [x] 2.5 In `"CXW Auth Type"`'s `OnValidate` trigger on this Card page, re-set `ShowApiKeyField`/`ShowAwsFields` from the same two procedures so the field set updates immediately after changing the auth type, without needing to leave and reopen the record.

## 3. Trim the List page to an overview

- [x] 3.1 In `src/Pages/Pag60324.CXWAPIInterfaceSetup.al`, remove the fields moved to the Card page from the repeater: `ApiKey`, `"CXW AWS Access Key ID"`, `"CXW AWS Region"`, `"CXW AWS Service"`, `AwsSecretAccessKey`, `AwsSessionToken`, `"CXW Http Method"`, `"CXW SOAP Action"`, `"CXW Source Table No."`. Keep `"CXW Code"`, `"CXW Description"`, `"CXW Endpoint URL"`, `"CXW Auth Type"`, `"CXW Active"`.
- [x] 3.2 Remove the now-unused page variables `g_txtApiKey`, `g_txtAwsSecretAccessKey`, `g_txtAwsSessionToken` and their `OnValidate` triggers from Page 60324 (they move to Page 60325 per task 2.2).
- [x] 3.3 Wire drill-down from the List page to the Card page for a selected row (`RunObject = page "CXW API Interface Setup Card"` on the row action / drill-down field, per design.md Decision 1 and the Open Question's default — standard BC drill-down, no separate explicit action needed unless drill-down alone proves insufficient during manual testing).
  - `DrillDownPageId`/`LookupPageId` turned out invalid on a List page in this context (compiler AL0124) — used the actual supported mechanism instead: `trigger OnDrillDown()` on the `"CXW Code"` field calling `Page.Run(Page::"CXW API Interface Setup Card", Rec)`, plus an explicit "Edit Details" navigation action (`RunObject` + `RunPageOnRec = true`) for discoverability.

## 4. Build Verification

- [x] 4.1 Compile the app and resolve every error.
  - First pass caught the `DrillDownPageId`/`LookupPageId` issue (task 3.3 note above); second pass compiled clean (only the pre-existing, unrelated warning in `Codeunit60330.CXWImportSalesPrices.al`).
- [x] 4.2 Manually reason through every scenario in `specs/api-interface-setup-conditional-fields/spec.md`: field relevance per auth type (both procedures), Card page show/hide per auth type, live update on auth type change, List page column set, drill-down navigation, activation guard still blocking correctly.
  - All scenarios verified against the implementation; see reasoning captured during apply.
- [x] 4.3 Confirm `SendToApiInterface` (Codeunit 60329) is untouched and still compiles/behaves identically — this change only touches Table 60317's guard refactor (same behavior, different call path) and the two pages.
  - Confirmed via `git status`: Codeunit 60329 is unmodified by this change (its current diff predates this change, from the earlier live AWS SigV4 debugging session).

## 5. Documentation

- [x] 5.1 Update `docs/developer-manual-de.md` / `-en.md`: note the new Card page (60325) and that Page 60324 is now an overview-only list, mirroring how the AWS SigV4 addition was documented.
  - Also caught up the project-structure counts (Pages 7→8, Enums 6→7) that were left stale from the earlier live AWS SigV4 debugging session's Enum60336/HTTP-Method addition.
- [x] 5.2 New translatable strings (new Card page field captions/tooltips carried over from Page 60324, any new captions on Page 60324/60325 themselves) need German translations in `Translations/CHX.Webshop.de-DE.xlf` — follow the `managing-bc-translations` skill's sync procedure.
  - Removed 12 trans-units orphaned by trimming Page 60324 (their controls no longer exist there) and added 19 new ones for Page 60325 and the new "Edit Details" action — reusing the exact German text already established for fields that just relocated, translating only the genuinely new strings (page caption, FastTab captions, action caption/tooltip). Verified via script: 0 missing units, 0 placeholder mismatches, well-formed XML, full project compiles clean.
