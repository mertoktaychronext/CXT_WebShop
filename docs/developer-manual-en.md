# Developer Manual – SL Chronext Webshop

## Overview

This Business Central (AL) extension covers webshop sales price management: CSV import into a staging table, business validation (margin, price swings), approval by a staff member, optionally expanding an approved price to all activated foreign currencies, and uploading approved prices to an external system. The "Upload Sales Price" action writes each approved price into the standard "Sales Price" table and a versioned "CXW Sales Price Archive" entry before sending it to a configurable API interface. A second, independent component for file-based price import (not yet live) rounds out the project. The project is a migration from a legacy, long-grown Dynamics NAV system into modern, SaaS-capable AL.

> **Update 2026-08-10:** All 26 objects in this extension (previously IDs 51000–51007, "SL" prefix) were moved, as a pure rename/renumber, into the registered idRange block 60311–60336 ("CXW" prefix), as were all fields they define ("CXW "/"CXW" prefix). Business logic, behavior, and field captions are unchanged. Two identifiers additionally had to be shortened due to AL's 30-character limit: Table 60316 "CXW Price Import Protocol" (no "Sales" in the identifier) and the field "CXW Non Stock Price Thresh %" on Table 60311 (caption still "Non Stock Price Threshold %"). This manual has been updated accordingly.

As a second, functionally independent component, the extension includes **SellWatch**: purchase requests for used watches coming in from the SellWatch partner are automatically turned into a vendor and a purchase order (Codeunit 60305 "CXW SellWatch Mgt"); a read-only overview page (Page 60307 "CXW SellWatch-Overview") shows seller, watch, and order data. A separate mechanism checks over HTTP whether a watch is visible in the SellWatch online shop (Table 60301 "CXW Watch Online Approval"), and logs every call including failure telemetry (Table 60302 "CXW Http Call Log", Page 60309). SellWatch and sales price management are functionally separate but share the same interface master data table "CXW API Interface Setup" (Table 60317), and since the HTTP-logging update also the shared "CXW Http Call Log": the online check uses the hard-coded code `'WOA'` there.

As a third, likewise functionally independent component, the extension includes the **Workshop authenticity check** (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60340, Codeunit 60331, PermissionSets 60301/60302): once a purchased watch has arrived, it is handed over to an external workshop via the "Send to Workshop" action on the purchase order page (capturing the manufacturer serial number), and the workshop reports back authenticity and item attributes through a bidirectional custom API (Page 60339, OAuth2-S2S authenticated). A job-queue-driven codeunit (60331) processes checked lines: if authenticity is confirmed, only the goods receipt is posted and the reported attributes are written as standard item attributes; if authenticity is disproved, the purchase order is cancelled. See the "Workshop Authenticity Check" section below for details.

As a fourth, new component, the extension includes **Consignment Sales** (Enum 60343, Table 60341, Codeunit 60344/60345, Page 60342): when a sales invoice is posted with a line for an item whose `"CXB Consignment Sales"` = true (a field supplied by the CHX.Base dependency), an event subscriber on `Codeunit "Sales-Post"` creates a consignment posting entry and automatically resolves the matching, received-but-not-yet-invoiced purchase order. A job-queue-driven codeunit posts due entries (due date = sales invoice posting date + a configurable delay in days) automatically as a purchase invoice. See the "Consignment Sales" section below for details.

> **Update 2026-09-24 (sales price export logs to "Data Export Entry"):** Codeunit 60329 no longer writes each transmission to Table 60314 "CXW Sales Price Outbound File"; like the availability export (Codeunit 60347) it now writes to ChronextBC table 50103 "Data Export Entry" (Destination Code `SALESPRICE`, payload, file name, status Processed/Error, error message). The entry is only created **after** the HTTP call, directly with its final status (`CreateDataExportEntry`), because ChronextBC's "Data Export Mgt." (50102) would resend every entry in status "Waiting to Process" through "Data Export API Sender". `SALESPRICE` is reserved and must **not** be created as a "Data Export API Setup" code — otherwise "Export Data" on Page 50108 would send without AWS SigV4. "CXW Http Call Log" now points to the "Data Export Entry" ("CXW Source Table No." = 50103). Table 60314 is `ObsoleteState = Pending` (tag 27.0.0.3). Configuration and authentication ("CXW API Interface Setup") are unchanged. Details: `openspec/changes/sales-price-export-data-export-entry/`.

> **Update 2026-09-23 (Add all Countries):** Action "Add all Currencies" replaced by "Add all Countries" – activation and sales price currency now per country (table/page extension 60346/60347 on "Country/Region"), table/page extension 60320/60327 on "Currency" removed, new key field "CXW Country Code" on Table 60312/60313, country code in the export JSON. Details: `openspec/changes/add-all-countries-sales-price/`.

> **Update 2026-09-02 (Full re-verification):** All 57 AL objects were reconciled line by line against the current code (branch `03-FEAT/Workshop`). Corrected: the architecture sketch still referred to a "Country/Region" table/page extension that does not (any longer) exist in this extension — activation for "Add all Currencies" lives exclusively on "Currency". Clarified: `CreateSellWatchItem` reads the item template from `Purchases & Payables Setup."CXW SW Item Template Code"`. No code changes.

> **Update 2026-08-14 (Consignment Sales added):** New objects 60341/60342/60343/60344/60345, new setup field `"CXW SW Consignment Invoice Delay (Days)"` on `TableExtension 60322 "CXW SW Purchases Setup"`. This also restored the SellWatch item-template configuration that a previous version of this manual documented as "lost before commit" (see Known Limitations, prior wording) — it is now present in production code, and the note below has been corrected. Also corrected the previously wrong "no dependencies" claim: `app.json` has depended on **CHX.Base** since the item-template configuration was added.

> **Update 2026-08-13 (Workshop authenticity check documented):** The Workshop authenticity check has existed since an earlier extension update but wasn't documented in any of the three manuals. This update adds it to all three manuals (DE/EN) and to `docs/README.md`; it also corrects the outdated claim about hard-coded SellWatch variant codes (see Known Limitations) — no code changes.

> **Update 2026-08-10 (unified HTTP call logging):** Table 60302/Page 60309 were previously named `"CXW SW Http Call Log"` and hard-wired to `"CXW Watch Online Approval"`. Renamed to `"CXW Http Call Log"` (Caption `'Http Call Log'`) and given a new `"CXW Source Table No."` field (same pattern as `"CXW API Interface Setup"."CXW Source Table No."`), so `"CXW Source Entry No"` now points at either `"CXW Watch Online Approval"` (60301) or `"CXW Sales Price Outbound File"` (60314) depending on `"CXW Source Table No."`. `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` now logs every call (success, non-success HTTP status, network failure) into the same log SellWatch uses, redacting the `Authorization` header (mirroring the existing `X-API-KEY` redaction for SellWatch). Both permission sets (`CXWChronWSAll`, `CXW SWChronWSAll`) were updated accordingly.

> **Update 2026-08-10:** Also on 2026-08-10, the 11 SellWatch objects (previously IDs 51001–51010, inconsistent "SW"/"SellWatch"/no-prefix naming) were moved, as a pure rename/renumber, into the registered idRange block 60300–60310 and given a consistent "CXW " prefix, as were the roughly 70 fields they define. Field captions, enum values, and business logic are unchanged (see `openspec/changes/archive/2026-08-10-sellwatch-cxw-renumbering/`). IDs 60311–60349 were already reserved for/occupied by sales price management at that point; SellWatch has used 60300–60310 since, and the rest of 60300–60349 remains free for future objects.

## Technical Stack

| Component | Technology | Version |
|---|---|---|
| Extension type | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Object ID range | Customer range | 60300–60349 (used: 60300–60310 SellWatch, 60311–60336 sales price management, 60318–60345 Workshop authenticity check + Consignment Sales — object types overlap since each object type has its own ID namespace; only 4 IDs remain free after Consignment Sales, 60346–60349); 51000–51049 remains registered but, since the 2026-08-10 rename, is no longer occupied by any object in this extension |
| Dependencies | CHX.Base | 27.0.1.1 (provides, among other things, the `"CXB Consignment Sales"` item field that Consignment Sales relies on) |
| Publisher | Salini Life | – |
| Extension ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Project Structure

```
app.json                          # Extension manifest, idRanges 51000-51049 + 60300-60349, CHX.Base dependency
src/
  Tables/                         # 12 tables (60300-60302 SellWatch; 60311-60317 sales price management; 60318 Workshop; 60341 Consignment Sales)
  TableExtensions/                # 6 extensions (Purchase Line, Purchase Header, Purchases & Payables Setup – SellWatch/Consignment; Sales Price, Country/Region – sales price management; Purchase Line – Workshop)
  PageExtensions/                 # 5 extensions (Sales Prices, Countries/Regions – sales price management; Purchase Order, Purchase Order Subform – Workshop; Purchases & Payables Setup – SellWatch/Consignment)
  Pages/                          # 13 pages + 1 xmlport (60307-60309 + 60337 SellWatch; 60321-60325 + Xmlport 60328 sales price management; 60338-60340 Workshop; 60342 Consignment Sales)
  Codeunits/                      # 6 codeunits (SellWatch Mgt – SellWatch; Export Gateway Sales Price, Import Sales Prices – sales price management; Process Workshop Lines – Workshop; Consignment Sale Detection, Post Consignment Purchases – Consignment Sales)
  Enums/                          # 9 enums (SW Order Status – SellWatch; 6 more – sales price management; Workshop Line Status – Workshop; Consignment Posting Status – Consignment Sales)
  PermissionSets/                 # 5 permission sets (CXW SWChronWSAll, CXW Sell Watch API – SellWatch; CXWChronWSAll – sales price management; CXW Workshop All [also covers Consignment Sales since this update], CXW Workshop API – Workshop)
Translations/                     # .g.xlf (generated) + de-DE.xlf (maintained)
openspec/
  specs/                          # durable capability specs (e.g. sales-price-country-copy, sellwatch-http-call-logging, sellwatch-standard-table-extensions)
  changes/                        # in-progress and archived change proposals
docs/                             # this manual + function register
```

**File naming convention:** `Tab<ID>.<PascalCaseName>.al`, `Pag<ID>.<Name>.al`, `TabExt<ID>.<Name>.al`, `PagExt<ID>.<Name>.al`, `Enum<ID>.<Name>.al`, `Codeunit<ID>.<Name>.al`, `XmlPort<ID>.<Name>.al`.

## Setting Up a Local Development Environment

### Prerequisites

- Visual Studio Code with the official **AL Language** extension.
- Access to a Business Central environment (sandbox or on-premises) on version 26.0 or compatible.
- Symbols for the target environment (`.alpackages/`, generated via the AL extension's "Download Symbols", excluded from version control via `.gitignore`).

### Installation

```bash
# Download symbols for the target environment (VS Code Command Palette):
AL: Download Symbols

# Compile the project (VS Code Command Palette):
AL: Package

# Publish to the connected environment:
AL: Publish
```

No build/test script (`Makefile`, `npm` scripts, etc.) exists in this project — the build runs exclusively through the AL extension or an AL-Go pipeline, if one is set up separately.

### Configuration

No environment variables in the classic sense. Relevant configuration lives in `app.json` (`idRanges`, `features: ["NoImplicitWith","TranslationFile"]`) and, at runtime, in the **"CXW General Sales Price Setup"** table (see Key User Manual).

## Architecture

```
CSV file
   │  Action "Import CSV"
   ▼
Xmlport 60328 "CXW Import Sales Price"
   │  writes lines into
   ▼
Table 60312 "CXW Sales Price Checking"  ◄── Page 60322 "CXW Sales Price Checking List"
   │  (Item No./Currency Code/Country Code — blank       (Validate / Approve / Add all Countries /
   │   country = imported source line; no variant code)  Upload Sales Price)
   │
   │  Action "Upload Sales Price" → Codeunit 60329 "CXW Export Gateway Sales Price"
   │
   ├─► WriteBackAndArchive: writes/updates standard table "Sales Price"
   │      (Sales Type = All Customers) and inserts a new, incrementally
   │      versioned row into Table 60313 "CXW Sales Price Archive"
   │      (view via Page 60323, read-only)
   │
   └─► CreateExternalInterfaceFile: reflects the "Sales Price" record into
          JSON and POSTs it via HttpClient to the endpoint configured on
          Table 60317 "CXW API Interface Setup" (overview: Page 60324; per-interface
          detail setup incl. HTTP method/SOAPAction/authentication: Page 60325
          "CXW API Interface Setup Card", reachable via drilldown on the code or
          the "Edit Details" action on Page 60324), using the
          interface selected on Table 60311's "CXW API Interface Code" field.
          Since the HTTP-logging update, SendToApiInterface logs every call
          (success, non-success status, network failure) into Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 50103), with the
          Authorization header redacted — the same log SellWatch uses for
          its online check (see below). Since the AWS SigV4 update, "CXW Auth
          Type" (Enum 60335) also supports AWSSigV4 alongside None/ApiKeyHeader/
          BasicAuth: SendToApiInterface signs the request itself using AWS
          Signature Version 4 (Authorization and X-Amz-Date headers, plus
          X-Amz-Security-Token for temporary/STS credentials) — see the
          table overview below for the extra fields this needs on Table 60317;
          for signing-algorithm details see
          `openspec/changes/sales-price-aws-sigv4-auth/design.md`. Since the
          conditional-fields update, Page 60325 "CXW API Interface Setup Card"
          shows or hides the authentication-specific fields (API Key, all AWS
          fields) based on the selected "CXW Auth Type", driven by the new
          Table 60317 procedures `IsApiKeyFieldRelevant()` /
          `IsAwsFieldsRelevant()` — the same procedures the `"CXW Active"`
          activation guard uses, so the two can't drift apart. Page 60324
          itself now only shows overview columns (Code, Description, Endpoint
          URL, Auth Type, Active); see
          `openspec/changes/api-interface-setup-conditional-fields/design.md`
          for details.

Control data for "Add all Countries":
Table Extension 60346 "CXW Country/Region" (on standard table "Country/Region",
   fields "CXW Sales Price Activated", "CXW Sales Price Currency Code" – blank = LCY)
   ◄── Page Extension 60347 "CXW Countries/Regions" (on standard page "Countries/Regions")

"Add all Countries" (Page 60322, local procedures fnAddAllCountries/CreateCountryLine)
expands every source line ("CXW Country Code" blank, "CXW Countries Processed" = false)
into one line per activated country in that country's sales price currency. Same currency
as the source line → prices copied 1:1, otherwise converted via GetLastestExchangeRate.
The former per-currency activation (table/page extension 60320/60327 on "Currency",
action "Add all Currencies") was removed (change `add-all-countries-sales-price`). Enums 60331 "CXW Taxation Type" /
60332 "CXW Sales Price Reason Code" exist, but 60331 is currently not referenced by any
object in this extension (Table 60300 stores the taxation as a free-text "CXW Taxation").

Independent, not-yet-live component:
File (CSV) → Table 60315 "CXW Sales Price Inbound File"
           → Codeunit 60330 "CXW Import Sales Prices" (OnRun)
           → writes directly into standard table "Sales Price"
           → errors logged in Table 60316 "CXW Price Import Protocol"
```

### SellWatch

```
Table 60300 "CXW SellWatch Vendor Info" (rows created externally – via
Page 60337 "CXW SellWatch API" (PageType = API, see below) or directly
in the table; access controlled via permission set 60310
"CXW SWChronWSAll")
   │
   │  Codeunit 60305 "CXW SellWatch Mgt".OnRun → ValidateAndCreateVendor
   │  (the trigger itself is not wired in the AL code — no install
   │   codeunit, no job queue entry, no event subscriber found in the
   │   project; see Known Limitations)
   ▼
Rows with "CXW Created" = false:
   ├─► looks up an existing "Vendor" by Name/Address/Phone No./E-Mail;
   │      otherwise creates a new "Vendor" + "Vendor Bank Account"
   │      (bank account code = last 4 digits of the IBAN + currency code)
   │
   └─► CreatePurchaseOrder: creates a "Purchase Header" (Document Type =
          Order) and one "Purchase Line" — item no./variant code depend on
          "CXW Offer Type" (C2C-SW / CPST-SW / TI-SW), quantity 1, Amount
          and "Direct Unit Cost" = "CXW Final Offer Price", "CXW Used good"
          = true (table extension 60303 on "Purchase Line") — releases the
          order via codeunit "Release Purchase Document"
          (PerformManualRelease) and marks the vendor info row as
          "CXW Created" = true, with "CXW PO Number"/"CXW VendorNo" filled

Independently, per item/variant:
Table 60301 "CXW Watch Online Approval"
   │  CreateEntryInexternalFile (currently not called from anywhere
   │  else in the code)
   ▼
HTTP GET to <Endpoint URL>/<Item No>/<Variant Code>/check, header
"X-API-KEY" — endpoint/key come from Table 60317 "CXW API Interface
Setup", hard-coded to code 'WOA' (the same table sales price management
uses, see Codeunit 60329)
   │  Response field "shouldBeOnline" = 'TRUE' → sets "CXW Check Online" +
   │  "CXW First Online Date" if not yet set; otherwise "CXW Remark" =
   │  'Watch is offline'
   └─► logs every call (success and failure alike, API key redacted in
          the stored request text) into Table 60302 "CXW Http Call
          Log" ("CXW Source Table No." = 60301); on failure, also raises
          telemetry (Session.LogMessage, event ID 'SW-0101')

View (read-only, no insert/modify/delete via the pages):
Page 60307 "CXW SellWatch-Overview" (list, SourceTable Table 60300,
   filtered to "CXW SRid" <> '', "Show Document" action opens the
   purchase order)
Page 60308 "CXW SellWatch info" (CardPart on Table 60300 — watch detail data)
Page 60309 "CXW Http Call Log" (list, SourceTable Table 60302 – now a
   shared log for both SellWatch AND sales price management, "CXW Source
   Table No." column distinguishes the source; "Download Request"/"Download
   Response" actions download the blob as .txt)

JSON builders with no current caller in the project (presumably intended
for outbound status updates to SellWatch, see Known Limitations):
Codeunit 60305: CreateSourceFilePurchaseRequest(Purchase Header): Text
Codeunit 60305: CreateSourceFileOrderStatusSE(SellWatch Vendor Info; Enum
   "CXW SW Order Status"): Text
```

#### Page 60337 "CXW SellWatch API" – write access for external systems

Adds a `PageType = API` endpoint alongside the read-only page 60307, letting external systems create or update SellWatch entries over HTTP. Both pages sit on the same table 60300 but are separate objects — a page cannot be both `List` and `API` at once.

- **Endpoint pattern:** `.../api/saliniLife/sellWatch/v2.0/companies({companyId})/sellWatchVendorInfos` (standard BC OData v4 pattern from `APIPublisher`/`APIGroup`/`APIVersion`/`EntitySetName`); a single record via `.../sellWatchVendorInfos({id})`.
- **Methods:** `POST` to create, `PATCH` to update; `DELETE` is not allowed (`DeleteAllowed = false`).
- **Authentication:** standard BC API authentication (Web Service Access Key or Entra ID OAuth) — no custom auth logic in AL. Access additionally requires permission set 60310 "CXW SWChronWSAll" (`page "CXW SellWatch API" = X` entry).
- **Writable fields:** all vendor/watch/offer fields (e.g. Vendor Name, address, IBAN/BIC, Email, Brand/Model/Reference/SKU, Watch Condition, Offer Type, Final Offer Price, Currency Code, SRid).
- **Not writable (system-owned):** `CXW Entry No` (primary key), `CXW Created`, `CXW PO Number`, `CXW VendorNo` (set only by Codeunit 60305), and the FlowField `CXW Tracking Number`. Payload values for these fields are ignored or reset on insert/modify.
- **Validation:** `OnInsertRecord`/`OnModifyRecord` require `CXW SRid`, `CXW Brand`, `CXW Model`, and `CXW Final Offer Price`, and reject a duplicate `CXW SRid` with an error (HTTP 4xx) rather than creating an incomplete or duplicate row.
- Rows created/updated this way appear on page 60307 unchanged and are processed by Codeunit 60305 exactly like manually entered rows.

### Workshop Authenticity Check

```
Purchase Order (staff member)
   │  Action "Send to Workshop" (PageExtension 60328 "CXW Workshop
   │  Purchase Order", on Page "Purchase Order")
   ▼
For each open line (Type = Item, Quantity <> 0, Sent to Workshop = false):
   ├─► Confirm "Is item {No.} {Description} really arrived?"
   │     No  → "CXW Not Arrived" := true, line skipped (no abort)
   │     Yes → Page 60340 "CXW Serial No. Input" (StandardDialog, modal)
   │              mandatory manufacturer serial number field; blank/cancel
   │              → error collected for this line, continues with the
   │              next line
   ▼
On valid input:
   "CXW Manufacturer Serial No." + "CXW Sent to Workshop" := true on the
   Purchase Line (TableExtension 60321 "CXW Workshop Purchase Line")
   ▼
Table 60318 "CXW Workshop Line" created (PK: Document Type/No./Line No.),
Status = New, Item No. copied from the purchase line
   │
   │  PageExtension 60329 "CXW Workshop Purch Order Subf" locks the
   │  standard line fields (Editable = false) once "Sent to Workshop" = true
   ▼
External workshop reads/writes via
Page 60339 "CXW Workshop Line API" (PageType = API, OAuth2-S2S,
   endpoint pattern .../api/saliniLife/workshop/v1.0/companies({companyId})/
   workshopLines; Insert/Delete blocked, status regressions blocked)
   │  workshop sets: isAuthentic, Attribute 1-10, Status = "WS checked"
   ▼
Codeunit 60331 "CXW Process Workshop Lines" (job-queue driven, OnRun
   → ProcessCheckedLines, SetRange Status = "WS checked")
   │  per line: ProcessLineWithErrorHandling wraps TryProcessLine
   │  ([TryFunction]) – a failure doesn't block the remaining lines
   │
   ├─► Genuine = true → ProcessGenuineLine:
   │      "Qty. to Receive" = order quantity, Codeunit "Purch.-Post"
   │      (Receive = true, Invoice = false), then GetAttributeMapping
   │      transfers attributes 1-8 (business-named: Dial Color, Case
   │      Diameter, Bracelet Material, Case Material, Movement, Gender,
   │      Crystal, Features; 9-10 still placeholders) as standard item
   │      attributes (Item Attribute/Item Attribute Value/Item Attribute
   │      Value Mapping, missing entries created automatically as type
   │      Text) → Status = "Processed", "CXW Last Error" := ''
   │
   ├─► Genuine = false → ProcessNonGenuineLine:
   │      Status = "Processed" (deliberately set BEFORE deleting the PO,
   │      so the cascade-delete guard in TabExt60321 applies), then the
   │      purchase order is reopened if needed and deleted
   │
   └─► Failure (anywhere in the processing path) → Status = Error (only
          allowed from "WS checked", otherwise an OnModify error),
          "CXW Last Error" = GetLastErrorText(); Commit() after each line
          preserves already-successful lines regardless of the next
          line's outcome

View (read-only): Page 60338 "CXW Workshop Lines" (list, all fields incl.
   status, attributes, last error)

Delete behavior (TableExtension 60321, OnDelete of the Purchase Line):
   Workshop Line with status New/WS checked → deleted along with the line
   Workshop Line with status Processed → remains as an audit record
```

#### Page 60339 "CXW Workshop Line API" – bidirectional access for the workshop

Unlike Page 60337 (SellWatch, pure insert/update intake), this API allows the same external party to both read (open lines) and write (check result).

- **Endpoint pattern:** `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`.
- **Methods:** `GET` to fetch, `PATCH` to write back; `POST`/`DELETE` are blocked (`InsertAllowed = false`, `DeleteAllowed = false`) — lines are only ever created from within BC via "Send to Workshop".
- **Writable fields:** `dialColor`, `caseDiameter`, `braceletMaterial`, `caseMaterial`, `movement`, `gender`, `crystal`, `features` (business-named, correspond to AL fields 1–8), `attribute9`, `attribute10` (still generic, no business name assigned yet), `genuine`, `status`. Key, item, and serial number fields are locked (`OnModifyRecord` rejects change attempts with an error).
- **Update 2026-08-13 (Breaking Change):** The OData property names `attribute1`–`attribute8` were switched to their business names (e.g. `attribute1` → `dialColor`). Unlike the earlier internal AL field-identifier rename, this **is a breaking change to the external API contract** — the external workshop service must update its integration accordingly. `attribute9`/`attribute10` are unchanged, since they still have no assigned business name.
- **Status regressions blocked:** enforced in the table's own `OnModify` trigger (fires regardless of whether the change comes via the API or internally) — `WS checked` → `New` and any move away from `Processed` are rejected; a direct move to `Error` is only allowed from `WS checked`.
- **Authorization:** Permission Set 60302 "CXW Workshop API" — only `tabledata "CXW Workshop Line" = RM`, no access to Purchase Line, Item, or any other table.

### Consignment Sales

```
Purchase Order (staff member/Workshop process) – goods receipt already
posted, NOT yet invoiced
   │
Sales Order/Sales Invoice – line for an item with "CXB Consignment Sales" = true
   │  posted with Invoice (Ship & Invoice OR a separate invoice)
   ▼
Codeunit "Sales-Post".OnAfterPostSalesDoc (standard BC event)
   │  [EventSubscriber] Codeunit 60344 "CXW Consignment Sale Detection"
   │  .OnAfterPostSalesDocCreateConsignmentEntries
   │  aborts (no entry) if PreviewMode = true or SalesInvHdrNo = ''
   ▼
For each "Sales Invoice Line" with Type = Item and Item."CXB Consignment
Sales" = true:
   TryCreateConsignmentEntry ([TryFunction], catches every error — the
   sales posting itself must never fail because of this)
   │
   ├─► SetPurchaseOrder (public, reused by Codeunit 60345):
   │      Purchase Line filtered on Document Type = Order, Type = Item,
   │      No. = Item No., Quantity Received > 0, Qty. to Invoice > 0
   │      1 match    → "CXW Purchase Order No." set, Status = Open
   │      0/>1 match → Status = Error, descriptive error text, no abort
   │
   └─► "CXW Due Date" = Sales Invoice Posting Date + Purchases & Payables
          Setup."CXW SW Consignment Invoice Delay (Days)"
   ▼
Table 60341 "CXW Consignment Posting Entry" (PK: Entry No, AutoIncrement)
   │  View: Page 60342 "CXW Cons. Posting Entries" (list, read-only except
   │  for the "Retry" action: resets selected Error rows back to Open)
   ▼
Codeunit 60345 "CXW Post Consignment Purchases" (job-queue driven, OnRun
   → ProcessDueEntries, SetRange Status = Open, SetFilter Due Date <= Today)
   │  per entry: ProcessEntryWithErrorHandling wraps TryProcessEntry
   │  ([TryFunction]) — a failure doesn't block the other due entries,
   │  Commit() after each entry
   │
   │  If "CXW Purchase Order No." is blank (entry came from a 0/>1-match
   │  detection error), SetPurchaseOrder is retried — otherwise "Retry" on
   │  Page 60342 would have no effect
   ▼
Purchase Header read via Get(Order, ...); "Vendor Invoice No." set to
"CXW Sales Invoice No." + "-CONS" if blank; Purchase Line."Qty. to Invoice"
set to Quantity Received - Quantity Invoiced (raises a descriptive error
instead of a generic Purch.-Post message if <= 0); Receive = false,
Invoice = true, Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader)
   │
   ├─► Success  → Status = Posted, "CXW Error Text" cleared
   └─► Failure  → Status = Error, "CXW Error Text" = GetLastErrorText()
```

## Object Interfaces (Public Procedures & Events)

Full list of all procedures, triggers, and events: see `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Key public interfaces:

| Object | Element | Purpose |
|---|---|---|
| Codeunit 60329 | `WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Writes/updates a "Sales Price" record from an approved checking line (Sales Type = All Customers) and archives a new version. `[TryFunction]` — a failure is caught and reported as `false` instead of aborting the caller's whole batch. |
| Codeunit 60329 | `CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"; pCountryCode: Code[10]): Boolean` | Reflects a "Sales Price" record into JSON, adds the checking line's `"CXW Country Code"` (file name `SalesPrice_<Item>_<Currency>_<Country>.json`), sends it to the configured API interface, records the result via `CreateDataExportEntry` as a ChronextBC "Data Export Entry" (Destination Code `SALESPRICE`), and logs the call in Table 60302 "CXW Http Call Log". |
| Page 60322 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Calculates the non-stock price for lines within a price range. Currently not called from any active code path. |
| Codeunit 60330 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Raised when the automated file import changes an existing sales price. Currently has no subscriber. |
| Table 60317 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Stores/reads the API key for an interface in Isolated Storage (module scope) rather than in a plain table field. |
| Codeunit 60305 | `OnRun` / `ValidateAndCreateVendor` (local) | Processes every Table 60300 row with "CXW Created" = false: finds or creates a vendor plus bank account, then creates and releases a purchase order. No caller of this `OnRun` found anywhere in the project (see Known Limitations). |
| Codeunit 60305 | `CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text` | Builds the JSON for a purchase-order acknowledgment (SRid, purchase_order, optional tracking_number). Currently not called from anywhere else in the code. |
| Codeunit 60305 | `CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text` | Builds the JSON for a status update to SellWatch (name, e-mail, watch data, link to the online approval, payout currency/amount from the archived purchase line). Currently not called from anywhere else in the code. |
| Table 60301 | `CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")` | Sends an HTTP GET to the SellWatch endpoint to check whether a watch should be online, updates the row accordingly, and logs the call in Table 60302 ("CXW Source Table No." = 60301). Currently not called from anywhere else in the code. |
| Codeunit 60331 | `OnRun` / `ProcessCheckedLines` (local) | Job queue entry point; processes every Table 60318 row with status "WS checked" individually via `ProcessLineWithErrorHandling`. |
| Codeunit 60331 | `ProcessLineWithErrorHandling` / `TryProcessLine` (both local) | Wraps processing of a single line as a `[TryFunction]`; on failure, sets status to `Error` and writes `GetLastErrorText()` into "CXW Last Error", without blocking processing of the remaining lines (`Commit()` after each line). |
| Codeunit 60331 | `GetAttributeMapping(AttributeIndex: Integer): Text[250]` (local) | Central, swappable mapping from attribute index to standard item attribute name; index 1–8 returns the business names (Dial Color, Case Diameter, …), index 9–10 still returns placeholders "Attribut 9"/"Attribut 10". |
| Codeunit 60344 | `SetPurchaseOrder(var ConsignmentPostingEntry: Record "CXW Consignment Posting Entry"; ItemNo: Code[20])` | Resolves the open, received-but-not-yet-invoiced purchase order for an item and sets status/error text on the given entry accordingly. Made public deliberately so Codeunit 60345 can reuse it for the "Retry" action instead of duplicating the logic. |
| Codeunit 60345 | `OnRun` / `ProcessDueEntries` (local) | Job queue entry point; processes every Table 60341 entry with status "Open" and a reached "CXW Due Date" individually via `ProcessEntryWithErrorHandling`. |

Full list of all objects and their function counts: see `docs/funktionsregister/gesamtuebersicht.md`.

## Table Overview (Quick Reference)

| Table | Primary Key | Purpose |
|---|---|---|
| 60300 CXW SellWatch Vendor Info | Entry No | Incoming SellWatch purchase request: seller, bank, watch, and offer data; "CXW Created" flags whether the vendor/order have already been created automatically; FlowField "CXW Tracking Number" reads from table extension 60304 on "Purchase Header" |
| 60301 CXW Watch Online Approval | Entry No | Result of the online-visibility check per item/variant ("CXW Check Online", "CXW First Online Date", "CXW Remark"); FlowField "CXW SRid" reads the "Vendor Order No." of the related purchase order |
| 60302 CXW Http Call Log | Entry No | Shared log of every HTTP call made by `CreateEntryInexternalFile` (SellWatch) AND `SendToApiInterface` (sales price export) – success/failure, status code, redacted request, response as a blob; "CXW Source Table No." (60301, 50103 "Data Export Entry", or 60314 for legacy entries) + "CXW Source Entry No" identify the triggering record |
| 60311 CXW General Sales Price Setup | Primary Key (singleton) | Base settings, incl. export toggle and selected API interface |
| 60312 CXW Sales Price Checking | Item No., Currency Code, Country Code | Staging area for import/validation/approval |
| 60313 CXW Sales Price Archive | + Version No. | History; populated automatically by "Upload Sales Price" (Page 60322) via Codeunit 60329, "Version No." incremented per Item No./Currency Code/Country Code |
| 60314 CXW Sales Price Outbound File | Entry No. | **Obsolete Pending since 27.0.0.3** — no longer written (replaced by ChronextBC "Data Export Entry", Destination Code `SALESPRICE`); only holds legacy data up to 27.0.0.2 |
| 60315 CXW Sales Price Inbound File | Entry No. | For automated file import (not wired live) |
| 60316 CXW Price Import Protocol | Entry No. | Error log for the automated import (still the sales price import protocol table; "Sales" dropped from the identifier due to AL's 30-character limit) |
| 60317 CXW API Interface Setup | Code | Endpoint URL, auth type, and (isolated-storage) API key per external interface; when "CXW Auth Type" = AWSSigV4, also AWS Access Key ID/Region/Service (plain fields) and AWS Secret Access Key/Session Token (isolated storage) |
| 60318 CXW Workshop Line | Document Type, Document No., Line No. | One record per purchase line handed over to the workshop: Item No., Manufacturer Serial No., Status (Enum 60337: New/WS checked/Processed/Error), isAuthentic (authenticity flag), eight business-named attribute fields (Dial Color … Features) + two placeholders (Attribut 9/10), Created At, Checked At, Last Error |
| 60341 CXW Consignment Posting Entry | Entry No (AutoIncrement) | One record per posted sales invoice line for a consignment item: Item No., Purchase Order No. (blank on a detection failure), Sales Invoice No., Sales Posting Date, Due Date, Status (Enum 60343: Open/Posted/Error), Error Text |

## Permission Set

The **`CXWChronWSAll`** permission set (ID 60336, `src/PermissionSets/CXWChronWSAll.permissionset.al`) covers read/write access to all seven sales price management tables plus — since the HTTP-logging update — the shared Table 60302 "CXW Http Call Log", along with execute rights for both codeunits, Xmlport 60328, and the five pages (the four sales-price-management pages plus Page 60309 "CXW Http Call Log"). Table and page extensions don't need their own entries, since they're covered by the base object's permissions (e.g. standard access to "Currency"); the standard "Sales Price" table that Codeunit 60329 writes to is likewise covered by base app permissions, not by this set. Since 27.0.0.3 the set also grants `RIM` on the ChronextBC table "Data Export Entry" that the price export writes to. The set still needs to be actively assigned to a user group.

For SellWatch, the separate **`CXW SWChronWSAll`** permission set (ID 60310, `src/PermissionSets/CXWSWChronWSAll.permissionset.al`) covers RIMD access to the two SellWatch-only tables (60300–60301) plus the shared Table 60302 "CXW Http Call Log", along with execute rights for Codeunit 60305 and the three SellWatch pages (60307–60309, where Page 60309 "CXW Http Call Log" is likewise shared). Table extensions 60303/60304 on "Purchase Line"/"Purchase Header" don't need their own entries either, for the same reason as sales price management's extensions — they're covered by the base table's standard permissions. This set also still needs to be actively assigned to a user group.

For the Workshop authenticity check, there are two separate permission sets: **`CXW Workshop All`** (ID 60301, `src/PermissionSets/CXWWorkshopAll.permissionset.al`) for full internal access to Table 60318, all Workshop pages, and Codeunit 60331 — including the standard tables needed for goods receipt, cancellation, and item attributes (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping), so the job queue codeunit can run standalone — and **`CXW Workshop API`** (ID 60302, `src/PermissionSets/CXWWorkshopAPI.permissionset.al`) as a lean counterpart exclusively for the external workshop user: only `tabledata "CXW Workshop Line" = RM`, no insert/delete, no access to Purchase Line or Item. Both sets still need to be actively assigned (`CXW Workshop All` to internal staff / the job queue execution user, `CXW Workshop API` exclusively to the workshop's dedicated OAuth2-S2S user).

**`CXW Workshop All`** now also covers Table 60341, Codeunit 60344/60345, and Page 60342 since the Consignment Sales update, including read access to the standard tables `Sales Invoice Header`/`Sales Invoice Line` (for the event subscriber) and `Purchases & Payables Setup` (for the new delay field) — the job queue execution user for Codeunit 60345 therefore needs the same permission set as for Workshop processing.

## Running Tests

There are currently **no** AL test codeunits in this project. The specification `openspec/specs/sales-price-country-copy/spec.md` (scenarios for the country setup and the "Add all Countries" action) is a good basis for future tests. For SellWatch, `openspec/specs/sellwatch-http-call-logging/spec.md` (scenarios for success/failure logging, API key redaction, and telemetry from `CreateEntryInexternalFile`) and `openspec/specs/sellwatch-standard-table-extensions/spec.md` (scenarios for "CXW Used good" and "CXW Tracking Number") offer a comparable starting point. For the Workshop authenticity check, scenarios are still spread across several, partly unarchived OpenSpec changes (`openspec/changes/purchase-workshop-integration/specs/` plus the deltas built on top of it in `openspec/changes/archive/2026-08-13-workshop-line-error-handling/` and `openspec/changes/archive/2026-08-13-workshop-attribute-*`) — before writing tests, these should be consolidated into a canonical spec under `openspec/specs/workshop-line-processing/` (see Known Limitations).

## Deployment

No CI/CD setup (e.g. an AL-Go workflow) was found in the project. Deployment is currently manual via "AL: Publish" from VS Code into the target environment.

## Contributing / Conventions

- All new objects get IDs in the registered **60300–60349** range (see `app.json`, `idRanges`; the older 51000–51049 range remains registered but, since the 2026-08-10 rename, is no longer occupied), counted independently per object type.
- The code deliberately contains **no comments** (removed at the customer's explicit request) — business context and design decisions are documented here and in the function register instead. Please keep this style when making changes, and add context here rather than in the code.
- Completed, functional changes are documented as an OpenSpec change (`openspec/changes/`, archived under `openspec/changes/archive/` once finished) and captured as a durable spec under `openspec/specs/`.
- Translations: `.g.xlf` is generated by the compiler and must **not** be edited manually; maintain translations only in `Translations/CHX.Webshop.de-DE.xlf`.

## Known Limitations

- **"Add all Countries" only converts correctly from a source line in local currency.** The conversion (`price * (1 / rate)` via `GetLastestExchangeRate`) assumes the imported source line is in LCY. A source line in a foreign currency (e.g. CHF) would be converted incorrectly for countries with a different currency. Countries sharing the source line's currency receive the price unchanged.
- **"Sales Price" has no country.** For several countries sharing a currency, the same "Sales Price" record (key without country) is written several times with identical values; the country is kept only in the archive (Table 60313) and in the transmitted JSON (`"CXW Country Code"`).
- **"Approve" itself does not carry prices into the standard "Sales Price" table or into "CXW Sales Price Archive".** The action only sets the approval flags on Table 60312. The carry-over happens in the downstream "Upload Sales Price" step (Page 60322, Codeunit 60329), which writes both "Sales Price" (Sales Type = All Customers) and "CXW Sales Price Archive" (with an incremented "Version No.") before the outbound file is generated.
- **(Fixed 2026-08-10) `"CXW Unit Price (LCY)"` was never populated automatically** — `WriteBackAndArchive` used to write only the standard `"Unit Price"` field, while Page 60322's `fnValidate` divided by `"CXW Unit Price (LCY)"` when comparing against the previous price. Since that field stayed `0` on every automated write, every second "Validate" run against an item/currency that already had an uploaded price reliably crashed with `Attempted to divide by zero.` and aborted the whole batch. `Codeunit 60329`'s new `ResolveUnitPriceLCY` now populates the field on every write (converting via the exchange rate already captured on the checking line, or a fallback lookup); `fnValidate` also now skips the comparison instead of dividing when the previous record's value is still `0`. "Sales Price" records written before this fix stay at `0` until the next time they're written back through "Upload Sales Price" — no retroactive backfill (see `openspec/changes/archive/2026-08-10-sales-price-unit-price-lcy-autofill/design.md`).
- **`Reason Code` as an enum with no true blank value**: the enum always has a default value (`CatMan`) — there is no "no reason given" state.
- **The file-based import component (Codeunit 60330, Tables 60315–60316)** is fully implemented but not wired into any live process or scheduled anywhere (no job queue entry). `WriteSalesPrices`'s `SalesPrice.Get(...)` call now passes exactly the standard "Sales Price" table's 8 real primary-key segments (verified against the symbols in `.alpackages/Microsoft_Base Application_*.app`), with `''` for "Variant Code" — the previously-documented key mismatch here is resolved.
- **No automated tests** exist.
- **The actual trigger for Codeunit 60305 "CXW SellWatch Mgt".OnRun is not part of the AL source code.** The project has no install/upgrade codeunit, no event subscriber, and no API page that calls `OnRun` or inserts rows into Table 60300. In practice, execution must happen via a job queue entry created at runtime, a manual invocation, or an integration outside this codebase — that doesn't contradict the automated processing described in the User Manual, but it isn't traceable in the code itself.
- **`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE` (Codeunit 60305), and `CreateEntryInexternalFile` (Table 60301, for the actual online check) are currently not called from anywhere else in the project.** The two JSON builders in particular look like prepared but not-yet-wired status updates back to SellWatch.
- **`CreatePurchaseOrderinBV` and `CreatePurchaseOrderinGmBH` (Codeunit 60305, both local)** are likewise never called — leftovers of the GMBH/BV branching that, per a code comment, was already disabled in the source system. `ReadJSONFile` (Table 60301, local) is an empty stub with no function.
- **(Fixed) SellWatch item creation now uses a configurable item template instead of hard-coded variant codes.** Item/variant codes for SellWatch purchase lines used to be hard-coded (`C2C-SW`, `CPST-SW`, `TI-SW`); that was replaced with dynamic item creation via an item template (`CreateSellWatchItem`, Codeunit 60305, `Item.TransferFields(ItemTemplate, true)`). Unlike an earlier version of this manual documented, the template used is now actually configurable: `TableExtension 60322 "CXW SW Purchases Setup"` (field `"CXW SW Item Template Code"`) plus `PageExtension 60330` are present in production code (`CreateSellWatchItem` reads `PurchSetup."CXW SW Item Template Code"` and aborts with a descriptive error if it's blank or points at a template that no longer exists) — see `openspec/specs/sellwatch-item-template-setup/spec.md`.
- **Consignment Sales assumes "1 item = 1 open purchase order = 1 purchase line"** (the same assumption used by the Workshop authenticity check). If that assumption breaks (e.g. more than one open order for the same item), `SetPurchaseOrder` (Codeunit 60344) deliberately produces an `Error` entry instead of a more precise resolution.
- **`"Vendor Invoice No."` is populated with `"CXW Sales Invoice No." + "-CONS"` when posting automatically (Codeunit 60345), if blank on the purchase order.** This is a placeholder pattern for the actual vendor invoice reference, which isn't otherwise available in the automated flow — confirm with the business if needed.
- **No job queue entry for Codeunit 60345 "CXW Post Consignment Purchases" is pre-configured.** Must be set up manually after deployment (recommended: daily) — see Key User Manual.
- **The online check (`CreateEntryInexternalFile`) uses a hard-coded interface code `'WOA'`** on Table 60317 "CXW API Interface Setup" — the same table sales price management uses for its price export (there, via the configurable "CXW API Interface Code" field). For SellWatch, the code is not configurable; it must be exactly `'WOA'`.
- **The Workshop authenticity check only covers the standard case "one purchase order = one purchase line".** Mixed orders (multiple lines, some genuine, some not) are not implemented — on non-authenticity, `ProcessNonGenuineLine` (Codeunit 60331) currently cancels the *entire* purchase order even if only one of several lines were affected (marked `// TODO:` in the code).
- **Two of the ten Workshop attribute fields (Attribut 9/10) still have no business name assigned** (placeholder captions), unlike attributes 1–8, which are already named (Dial Color … Features).
- **The base spec for the Workshop authenticity check isn't cleanly archived.** The original `purchase-workshop-integration` change (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60340, Codeunit 60331, PermissionSets 60301/60302) sits misplaced under `openspec/changes/archive/2026-08-13-workshop-line-error-handling/purchase-workshop-integration/` instead of a proper, dated archive location, and is invisible to `openspec list`/`openspec status` (as of writing: 30/34 tasks). Several later changes (`workshop-line-error-handling`, `workshop-attribute-names`, `workshop-attribute-field-names`) ship delta specs against the `workshop-line-processing`/`workshop-line-api` capabilities that were consequently never consolidated into a canonical spec under `openspec/specs/`. This should be cleaned up before further changes to Workshop processing.
