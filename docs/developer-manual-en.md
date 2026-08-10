# Developer Manual – SL Chronext Webshop

## Overview

This Business Central (AL) extension covers webshop sales price management: CSV import into a staging table, business validation (margin, price swings), approval by a staff member, optionally expanding an approved price to all activated foreign currencies, and uploading approved prices to an external system. The "Upload Sales Price" action writes each approved price into the standard "Sales Price" table and a versioned "CXW Sales Price Archive" entry before sending it to a configurable API interface. A second, independent component for file-based price import (not yet live) rounds out the project. The project is a migration from a legacy, long-grown Dynamics NAV system into modern, SaaS-capable AL.

> **Update 2026-08-10:** All 26 objects in this extension (previously IDs 51000–51007, "SL" prefix) were moved, as a pure rename/renumber, into the registered idRange block 60311–60336 ("CXW" prefix), as were all fields they define ("CXW "/"CXW" prefix). Business logic, behavior, and field captions are unchanged. Two identifiers additionally had to be shortened due to AL's 30-character limit: Table 60316 "CXW Price Import Protocol" (no "Sales" in the identifier) and the field "CXW Non Stock Price Thresh %" on Table 60311 (caption still "Non Stock Price Threshold %"). This manual has been updated accordingly.

As a second, functionally independent component, the extension includes **SellWatch**: purchase requests for used watches coming in from the SellWatch partner are automatically turned into a vendor and a purchase order (Codeunit 60305 "CXW SellWatch Mgt"); a read-only overview page (Page 60307 "CXW SellWatch-Overview") shows seller, watch, and order data. A separate mechanism checks over HTTP whether a watch is visible in the SellWatch online shop (Table 60301 "CXW Watch Online Approval"), and logs every call including failure telemetry (Table 60302 "CXW Http Call Log", Page 60309). SellWatch and sales price management are functionally separate but share the same interface master data table "CXW API Interface Setup" (Table 60317), and since the HTTP-logging update also the shared "CXW Http Call Log": the online check uses the hard-coded code `'WOA'` there.

> **Update 2026-08-10 (unified HTTP call logging):** Table 60302/Page 60309 were previously named `"CXW SW Http Call Log"` and hard-wired to `"CXW Watch Online Approval"`. Renamed to `"CXW Http Call Log"` (Caption `'Http Call Log'`) and given a new `"CXW Source Table No."` field (same pattern as `"CXW API Interface Setup"."CXW Source Table No."`), so `"CXW Source Entry No"` now points at either `"CXW Watch Online Approval"` (60301) or `"CXW Sales Price Outbound File"` (60314) depending on `"CXW Source Table No."`. `Codeunit "CXW Export Gateway Sales Price"`'s `SendToApiInterface` now logs every call (success, non-success HTTP status, network failure) into the same log SellWatch uses, redacting the `Authorization` header (mirroring the existing `X-API-KEY` redaction for SellWatch). Both permission sets (`CXWChronWSAll`, `CXW SWChronWSAll`) were updated accordingly.

> **Update 2026-08-10:** Also on 2026-08-10, the 11 SellWatch objects (previously IDs 51001–51010, inconsistent "SW"/"SellWatch"/no-prefix naming) were moved, as a pure rename/renumber, into the registered idRange block 60300–60310 and given a consistent "CXW " prefix, as were the roughly 70 fields they define. Field captions, enum values, and business logic are unchanged (see `openspec/changes/archive/2026-08-10-sellwatch-cxw-renumbering/`). IDs 60311–60349 were already reserved for/occupied by sales price management at that point; SellWatch has used 60300–60310 since, and the rest of 60300–60349 remains free for future objects.

## Technical Stack

| Component | Technology | Version |
|---|---|---|
| Extension type | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Object ID range | Customer range | 60300–60349 (used: 60300–60310 SellWatch, 60311–60336 sales price management); 51000–51049 remains registered but, since the 2026-08-10 rename, is no longer occupied by any object in this extension |
| Dependencies | – | none (`dependencies: []` in `app.json`) |
| Publisher | Salini Life | – |
| Extension ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Project Structure

```
app.json                          # Extension manifest, idRanges 51000-51049 + 60300-60349
src/
  Tables/                         # 10 tables (60300-60302 SellWatch; 60311-60313, 60314-60317 sales price management)
  TableExtensions/                # 5 extensions (Purchase Line, Purchase Header – SellWatch; Country/Region, Sales Price, Currency – sales price management)
  PageExtensions/                 # 3 extensions (Countries/Regions, Sales Prices, Currencies) – sales price management only
  Pages/                          # 7 pages + 1 xmlport (60307-60309 SellWatch; 60321-60324 + Xmlport 60328 sales price management)
  Codeunits/                      # 3 codeunits (SellWatch Mgt – SellWatch; Export Gateway Sales Price, Import Sales Prices – sales price management)
  Enums/                          # 6 enums (SW Order Status – SellWatch; 5 more – sales price management)
  PermissionSets/                 # 2 permission sets (CXW SWChronWSAll – SellWatch; CXWChronWSAll – sales price management)
Translations/                     # .g.xlf (generated) + de-DE.xlf (maintained)
openspec/
  specs/                          # durable capability specs (e.g. sales-price-currency-copy, sellwatch-http-call-logging, sellwatch-standard-table-extensions)
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
   │  (Item No./Currency Code — no country code          (Validate / Approve / Add all Currencies /
   │   and no variant code on this table)                Upload Sales Price)
   │
   │  Action "Upload Sales Price" → Codeunit 60329 "CXW Export Gateway Sales Price"
   │
   ├─► WriteBackAndArchive: writes/updates standard table "Sales Price"
   │      (Sales Type = All Customers) and inserts a new, incrementally
   │      versioned row into Table 60313 "CXW Sales Price Archive"
   │      (view via Page 60323, read-only)
   │
   └─► CreateExternalInterfaceFile: reflects the "Sales Price" record into
          JSON, stores it in Table 60314 "CXW Sales Price Outbound File",
          and POSTs it via HttpClient to the endpoint configured on
          Table 60317 "CXW API Interface Setup" (Page 60324), using the
          interface selected on Table 60311's "CXW API Interface Code" field.
          Since the HTTP-logging update, SendToApiInterface logs every call
          (success, non-success status, network failure) into Table 60302
          "CXW Http Call Log" ("CXW Source Table No." = 60314), with the
          Authorization header redacted — the same log SellWatch uses for
          its online check (see below).

Control data for "Add all Currencies":
Table Extension "CXWCurrency" (on standard table "Currency", field "CXW Sales Price Activated")
   ◄── Page Extension "CXWCurrencies" (on standard page "Currencies")

Country/Region now only supplies informational fields (taxation type, delivery time,
default foreign currency) via Table Extension "CXW Country Region" / Page Extension
"CXW Country Region Card" — no activation logic anymore.

Independent, not-yet-live component:
File (CSV) → Table 60315 "CXW Sales Price Inbound File"
           → Codeunit 60330 "CXW Import Sales Prices" (OnRun)
           → writes directly into standard table "Sales Price"
           → errors logged in Table 60316 "CXW Price Import Protocol"
```

### SellWatch

```
Table 60300 "CXW SellWatch Vendor Info" (rows created externally – no
xmlport/API page for it found in the project; access controlled via
permission set 60310 "CXW SWChronWSAll")
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
          the stored request text) into Table 60302 "CXW SW Http Call
          Log"; on failure, also raises telemetry (Session.LogMessage,
          event ID 'SW-0101')

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

## Object Interfaces (Public Procedures & Events)

Full list of all procedures, triggers, and events: see `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Key public interfaces:

| Object | Element | Purpose |
|---|---|---|
| Codeunit 60329 | `WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Writes/updates a "Sales Price" record from an approved checking line (Sales Type = All Customers) and archives a new version. `[TryFunction]` — a failure is caught and reported as `false` instead of aborting the caller's whole batch. |
| Codeunit 60329 | `CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"): Boolean` | Reflects a "Sales Price" record into JSON, stores it in Table 60314, sends it to the configured API interface, and logs the call in Table 60302 "CXW Http Call Log". |
| Page 60322 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Calculates the non-stock price for lines within a price range. Currently not called from any active code path. |
| Codeunit 60330 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Raised when the automated file import changes an existing sales price. Currently has no subscriber. |
| Table 60317 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Stores/reads the API key for an interface in Isolated Storage (module scope) rather than in a plain table field. |
| Codeunit 60305 | `OnRun` / `ValidateAndCreateVendor` (local) | Processes every Table 60300 row with "CXW Created" = false: finds or creates a vendor plus bank account, then creates and releases a purchase order. No caller of this `OnRun` found anywhere in the project (see Known Limitations). |
| Codeunit 60305 | `CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text` | Builds the JSON for a purchase-order acknowledgment (SRid, purchase_order, optional tracking_number). Currently not called from anywhere else in the code. |
| Codeunit 60305 | `CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text` | Builds the JSON for a status update to SellWatch (name, e-mail, watch data, link to the online approval, payout currency/amount from the archived purchase line). Currently not called from anywhere else in the code. |
| Table 60301 | `CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")` | Sends an HTTP GET to the SellWatch endpoint to check whether a watch should be online, updates the row accordingly, and logs the call in Table 60302 ("CXW Source Table No." = 60301). Currently not called from anywhere else in the code. |

Full list of all objects and their function counts: see `docs/funktionsregister/gesamtuebersicht.md`.

## Table Overview (Quick Reference)

| Table | Primary Key | Purpose |
|---|---|---|
| 60300 CXW SellWatch Vendor Info | Entry No | Incoming SellWatch purchase request: seller, bank, watch, and offer data; "CXW Created" flags whether the vendor/order have already been created automatically; FlowField "CXW Tracking Number" reads from table extension 60304 on "Purchase Header" |
| 60301 CXW Watch Online Approval | Entry No | Result of the online-visibility check per item/variant ("CXW Check Online", "CXW First Online Date", "CXW Remark"); FlowField "CXW SRid" reads the "Vendor Order No." of the related purchase order |
| 60302 CXW Http Call Log | Entry No | Shared log of every HTTP call made by `CreateEntryInexternalFile` (SellWatch) AND `SendToApiInterface` (sales price export) – success/failure, status code, redacted request, response as a blob; "CXW Source Table No." (60301 or 60314) + "CXW Source Entry No" identify the triggering record |
| 60311 CXW General Sales Price Setup | Primary Key (singleton) | Base settings, incl. export toggle and selected API interface |
| 60312 CXW Sales Price Checking | Item No., Currency Code | Staging area for import/validation/approval |
| 60313 CXW Sales Price Archive | + Version No. | History; populated automatically by "Upload Sales Price" (Page 60322) via Codeunit 60329, "Version No." incremented per Item No./Currency Code |
| 60314 CXW Sales Price Outbound File | Entry No. | Sent JSON payloads with delivery status and response message, for troubleshooting failed transmissions |
| 60315 CXW Sales Price Inbound File | Entry No. | For automated file import (not wired live) |
| 60316 CXW Price Import Protocol | Entry No. | Error log for the automated import (still the sales price import protocol table; "Sales" dropped from the identifier due to AL's 30-character limit) |
| 60317 CXW API Interface Setup | Code | Endpoint URL, auth type, and (isolated-storage) API key per external interface |

## Permission Set

The **`CXWChronWSAll`** permission set (ID 60336, `src/PermissionSets/CXWChronWSAll.permissionset.al`) covers read/write access to all seven sales price management tables plus — since the HTTP-logging update — the shared Table 60302 "CXW Http Call Log", along with execute rights for both codeunits, Xmlport 60328, and the five pages (the four sales-price-management pages plus Page 60309 "CXW Http Call Log"). Table and page extensions don't need their own entries, since they're covered by the base object's permissions (e.g. standard access to "Currency"/"Country/Region"); the standard "Sales Price" table that Codeunit 60329 writes to is likewise covered by base app permissions, not by this set. The set still needs to be actively assigned to a user group.

For SellWatch, the separate **`CXW SWChronWSAll`** permission set (ID 60310, `src/PermissionSets/CXWSWChronWSAll.permissionset.al`) covers RIMD access to the two SellWatch-only tables (60300–60301) plus the shared Table 60302 "CXW Http Call Log", along with execute rights for Codeunit 60305 and the three SellWatch pages (60307–60309, where Page 60309 "CXW Http Call Log" is likewise shared). Table extensions 60303/60304 on "Purchase Line"/"Purchase Header" don't need their own entries either, for the same reason as sales price management's extensions — they're covered by the base table's standard permissions. This set also still needs to be actively assigned to a user group.

## Running Tests

There are currently **no** AL test codeunits in this project. The specification `openspec/specs/sales-price-currency-copy/spec.md` (10 scenarios for the "Add all Currencies" action) is a good basis for future tests — note that this spec predates the switch from country-based to currency-based activation and should be reviewed against the current behavior before writing tests from it. For SellWatch, `openspec/specs/sellwatch-http-call-logging/spec.md` (scenarios for success/failure logging, API key redaction, and telemetry from `CreateEntryInexternalFile`) and `openspec/specs/sellwatch-standard-table-extensions/spec.md` (scenarios for "CXW Used good" and "CXW Tracking Number") offer a comparable starting point.

## Deployment

No CI/CD setup (e.g. an AL-Go workflow) was found in the project. Deployment is currently manual via "AL: Publish" from VS Code into the target environment.

## Contributing / Conventions

- All new objects get IDs in the registered **60300–60349** range (see `app.json`, `idRanges`; the older 51000–51049 range remains registered but, since the 2026-08-10 rename, is no longer occupied), counted independently per object type.
- The code deliberately contains **no comments** (removed at the customer's explicit request) — business context and design decisions are documented here and in the function register instead. Please keep this style when making changes, and add context here rather than in the code.
- Completed, functional changes are documented as an OpenSpec change (`openspec/changes/`, archived under `openspec/changes/archive/` once finished) and captured as a durable spec under `openspec/specs/`.
- Translations: `.g.xlf` is generated by the compiler and must **not** be edited manually; maintain translations only in `Translations/SL Chronext Webshop.de-DE.xlf`.

## Known Limitations

- **"Approve" itself does not carry prices into the standard "Sales Price" table or into "CXW Sales Price Archive".** The action only sets the approval flags on Table 60312. The carry-over happens in the downstream "Upload Sales Price" step (Page 60322, Codeunit 60329), which writes both "Sales Price" (Sales Type = All Customers) and "CXW Sales Price Archive" (with an incremented "Version No.") before the outbound file is generated.
- **(Fixed 2026-08-10) `"CXW Unit Price (LCY)"` was never populated automatically** — `WriteBackAndArchive` used to write only the standard `"Unit Price"` field, while Page 60322's `fnValidate` divided by `"CXW Unit Price (LCY)"` when comparing against the previous price. Since that field stayed `0` on every automated write, every second "Validate" run against an item/currency that already had an uploaded price reliably crashed with `Attempted to divide by zero.` and aborted the whole batch. `Codeunit 60329`'s new `ResolveUnitPriceLCY` now populates the field on every write (converting via the exchange rate already captured on the checking line, or a fallback lookup); `fnValidate` also now skips the comparison instead of dividing when the previous record's value is still `0`. "Sales Price" records written before this fix stay at `0` until the next time they're written back through "Upload Sales Price" — no retroactive backfill (see `openspec/changes/archive/2026-08-10-sales-price-unit-price-lcy-autofill/design.md`).
- **`Reason Code` as an enum with no true blank value**: the enum always has a default value (`CatMan`) — there is no "no reason given" state.
- **The file-based import component (Codeunit 60330, Tables 60315–60316)** is fully implemented but not wired into any live process or scheduled anywhere (no job queue entry). `WriteSalesPrices`'s `SalesPrice.Get(...)` call now passes exactly the standard "Sales Price" table's 8 real primary-key segments (verified against the symbols in `.alpackages/Microsoft_Base Application_*.app`), with `''` for "Variant Code" — the previously-documented key mismatch here is resolved.
- **No automated tests** exist.
- **The actual trigger for Codeunit 60305 "CXW SellWatch Mgt".OnRun is not part of the AL source code.** The project has no install/upgrade codeunit, no event subscriber, and no API page that calls `OnRun` or inserts rows into Table 60300. In practice, execution must happen via a job queue entry created at runtime, a manual invocation, or an integration outside this codebase — that doesn't contradict the automated processing described in the User Manual, but it isn't traceable in the code itself.
- **`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE` (Codeunit 60305), and `CreateEntryInexternalFile` (Table 60301, for the actual online check) are currently not called from anywhere else in the project.** The two JSON builders in particular look like prepared but not-yet-wired status updates back to SellWatch.
- **`CreatePurchaseOrderinBV` and `CreatePurchaseOrderinGmBH` (Codeunit 60305, both local)** are likewise never called — leftovers of the GMBH/BV branching that, per a code comment, was already disabled in the source system. `ReadJSONFile` (Table 60301, local) is an empty stub with no function.
- **Item/variant codes for SellWatch purchase lines are hard-coded** (`C2C-SW`, `CPST-SW`, `TI-SW`, depending on "CXW Offer Type"). If the corresponding item/variant doesn't exist in the item master, `PLRec.Validate("No.", ...)` in `CreatePurchaseOrder` fails; there is no configuration page for this mapping.
- **The online check (`CreateEntryInexternalFile`) uses a hard-coded interface code `'WOA'`** on Table 60317 "CXW API Interface Setup" — the same table sales price management uses for its price export (there, via the configurable "CXW API Interface Code" field). For SellWatch, the code is not configurable; it must be exactly `'WOA'`.
