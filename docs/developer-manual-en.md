# Developer Manual – SL Chronext Webshop

## Overview

This Business Central (AL) extension covers webshop sales price management: CSV import into a staging table, business validation (margin, price swings), approval by a staff member, optionally expanding an approved price to all activated foreign currencies, and uploading approved prices to an external system. The "Release Sales Prices" action writes each approved country price into the standard "Sales Price" table, archives the DE price as a versioned "CXW Sales Price Archive" entry, keeps the price of every country in "CXW Sales Price Export" and queues it as a "Data Export Entry"; a job queue job sends it to a configurable API interface. A second, independent component for file-based price import (not yet live) rounds out the project. The project is a migration from a legacy, long-grown Dynamics NAV system into modern, SaaS-capable AL.

> **Update 2026-08-10:** All 26 objects in this extension (previously IDs 51000–51007, "SL" prefix) were moved, as a pure rename/renumber, into the registered idRange block 60311–60336 ("CXW" prefix), as were all fields they define ("CXW "/"CXW" prefix). Business logic, behavior, and field captions are unchanged. Two identifiers additionally had to be shortened due to AL's 30-character limit: Table 60316 "CXW Price Import Protocol" (no "Sales" in the identifier) and the field "CXW Non Stock Price Thresh %" on Table 60311 (caption still "Non Stock Price Threshold %"). This manual has been updated accordingly.

As a second, functionally independent component, the extension includes **SellWatch**: purchase requests for used watches coming in from the SellWatch partner are automatically turned into a vendor and a purchase order (Codeunit 60305 "CXW SellWatch Mgt"); a read-only overview page (Page 60307 "CXW SellWatch-Overview") shows seller, watch, and order data. A separate mechanism checks over HTTP whether a watch is visible in the SellWatch online shop (Table 60301 "CXW Watch Online Approval"), and logs every call including failure telemetry (Table 60302 "CXW Http Call Log", Page 60309). SellWatch and sales price management are functionally separate but share the same interface master data table "CXW API Interface Setup" (Table 60317), and since the HTTP-logging update also the shared "CXW Http Call Log": the online check uses the hard-coded code `'WOA'` there.

As a third, likewise functionally independent component, the extension includes the **Workshop authenticity check** (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60339, Codeunit 60331, PermissionSets 60301/60302): once a purchased watch has arrived, it is handed over to an external workshop via the "Send to Workshop" action on the purchase order page (capturing the manufacturer serial number), and the workshop reports back authenticity and item attributes through a bidirectional custom API (Page 60339, OAuth2-S2S authenticated). A job-queue-driven codeunit (60331) processes checked lines: if authenticity is confirmed, only the goods receipt is posted and the reported attributes are written as standard item attributes; if authenticity is disproved, the purchase order is cancelled. See the "Workshop Authenticity Check" section below for details.

As a fourth, new component, the extension includes **Consignment Sales** (Enum 60343, Table 60341, Codeunit 60344/60345, Page 60342): when a sales invoice is posted with a line for an item whose `"CXB Consignment Sales"` = true (a field supplied by the CHX.Base dependency), an event subscriber on `Codeunit "Sales-Post"` creates a consignment posting entry and automatically resolves the matching, received-but-not-yet-invoiced purchase order. A job-queue-driven codeunit posts due entries (due date = sales invoice posting date + a configurable delay in days) automatically as a purchase invoice. See the "Consignment Sales" section below for details.

> **Update 2026-10-14 (margin taxation from the Salini Base App, version 27.0.0.26):** Availability changes (Codeunit 60348 "CXW Availability Change Mgt.": `QueueItemLedgerEntryChange`, refresh of "CXW Diff. Taxation Purchase", filter in `GetAvailableInventoryQuantity`) and realtime inventory (Codeunit 60350 "CXW Realtime Inventory Mgt.": "CXW Differential Taxation") now read the item ledger entry flag from `"SLPSBC Margin Taxation"` (Salini Base App) instead of the obsolete `"CXB Margin Taxation"` (CHX.Base). **Prerequisites:** CHX.Base ≥ 28.0.0.1 and Salini Base App ≥ 28.0.0.13 (new direct dependency). **Deploy only together with CHX.Base 28.0.0.1** in the same maintenance window; the CHX.Base upgrade migrates the item ledger entry values. No schema change, no upgrade code of its own. Details: `openspec/changes/margin-taxation-salini-field/`.

> **Update 2026-09-28 (sales price export via the job queue, version 27.0.0.6):** "Upload Sales Price" has been replaced by "Release Sales Prices". The action no longer sends; it writes back, archives **only the archive country** (new setup field "CXW Archive Country Code", default DE), stores the price of every country in the new Table 60320 "CXW Sales Price Export", and creates a "Data Export Entry" (`SALESPRICE`) in the new status **"CXW Pending"** (enumextension 60300 on "Data Export Statuses") that only points to Table 60320 via `Source Record ID`. Source lines without a country are skipped. Codeunit 60332 "CXW Export Sales Price Job" builds the JSON in the **NAV-compatible format** (29 camelCase keys, see below) and sends it; retries up to "CXW Max. Export Attempts", after that manually via "Requeue Sales Price" (PageExtension 60336). Details: `openspec/changes/sales-price-export-job-queue/`.
>
> Sample payload:
> ```json
> {"itemNo":"A61087","variantCode":"A61087","salesType":"2","salesCode":"","startingDate":"","currencyCode":"USD","countryRegionCode":"DM","unitOfMeasureCode":"","minimumQuantity":0,"unitPrice":2790,"priceIncludesVat":false,"allowInvoiceDisc":true,"vatBusPostingGrPrice":"","endingDate":"","allowLineDisc":true,"id":"{77BBD1E0-A4D4-451B-A55A-1395CC7230F7}","remark":"","nonStockPrice":0,"lastModifiedUserID":"","lastModifiedDate":"","reasonCode":"CatMan","comment":"","strikePriceInclVat":0,"recomRetailPriceInclVat":0,"unitPriceLcy":2446.72455,"startingTime":"","endingTime":"","profit":0,"unitCost":0,"vatProdPostingGroup":"MDE1900"}
> ```
> Sources: price, validity and text values from Table 60320; `salesType`, `salesCode`, `unitOfMeasureCode`, `minimumQuantity`, `priceIncludesVat`, `allowInvoiceDisc`, `vatBusPostingGrPrice`, `allowLineDisc` from "Sales Price"; `vatProdPostingGroup`, `unitCost` (`"Unit Cost"`) from Item; `itemNo`/`variantCode` = the item's "Old Item No."/"Old Variant Code", otherwise item no. or variant code (item no. when there is no variant); `profit` = margin in % (net LCY price via VAT Posting Setup); `reasonCode` = enum name (untranslated). Dropped compared to NAV: variant, promotion, set, DiVA and size/colour fields as well as `priceGroupId`, `fallBackPrice`, `documentUnitPrice`, `deliveryCostLimitCode`, `priceChangeSuggWriteOff`.

> **Update 2026-09-24 (sales price export logs to "Data Export Entry"):** Codeunit 60329 no longer writes each transmission to Table 60314 "CXW Sales Price Outbound File"; like the availability export (Codeunit 60347) it now writes to ChronextBC table 50103 "Data Export Entry" (Destination Code `SALESPRICE`, payload, file name, status Processed/Error, error message). The entry is only created **after** the HTTP call, directly with its final status (`CreateDataExportEntry`), because ChronextBC's "Data Export Mgt." (50102) would resend every entry in status "Waiting to Process" through "Data Export API Sender". `SALESPRICE` is reserved and must **not** be created as a "Data Export API Setup" code — otherwise "Export Data" on Page 50108 would send without AWS SigV4. "CXW Http Call Log" now points to the "Data Export Entry" ("CXW Source Table No." = 50103). Table 60314 is `ObsoleteState = Pending` (tag 27.0.0.3). Configuration and authentication ("CXW API Interface Setup") are unchanged. Details: `openspec/changes/sales-price-export-data-export-entry/`.

> **Update 2026-09-23 (Add all Countries):** Action "Add all Currencies" replaced by "Add all Countries" – activation and sales price currency now per country (table/page extension 60346/60347 on "Country/Region"), table/page extension 60320/60327 on "Currency" removed, new key field "CXW Country Code" on Table 60312/60313, country code in the export JSON. Details: `openspec/changes/add-all-countries-sales-price/`.

> **Update 2026-09-28 (Workshop API: purchase and watch data, version 27.0.0.7):** The `workshopLines` API additionally returns purchase and watch data (see Architecture, Workshop authenticity check section). They are copied as a snapshot onto Table 60318 by Codeunit 60335 on "Send to Workshop", so the workshop user needs no rights on purchase documents, vendors or items. Watch data comes from the standard item attributes with the IDs named by the workshop (1, 2, 3, 5, 8, 10, 11, 13), `seller_currency` from the order currency (blank → local currency), `tenant` from the new field "CXW Workshop Tenant" on the purchases & payables setup (TabExt 60322, field 60302); for that, "CXW Workshop API" additionally reads "Purchases & Payables Setup" (`InherentPermissions` on pages cannot cover other tables). Upgrade Codeunit 60336 fills existing lines in status New/WS checked once (upgrade tag `CXW-WORKSHOPLINE-PURCHASEDATA-20260928`). Details: `openspec/changes/workshop-line-api-purchase-data/`.

> **Update 2026-09-30 (workshop attribute fields prefilled, version 27.0.0.11):** The attribute fields the workshop writes back (`dialColor` … `attribute10`, fields 11–20 on Table 60318) are prefilled on "Send to Workshop" from the item attributes of the same name (`PrefillEmptyWorkshopAttributes` in Codeunit 60335, empty fields only, missing attributes are not created). If the item has no value for the English-named attribute, the German ChronextBC attribute is read by ID as fallback (Dial Color → 22, Case Diameter → 18, Bracelet Material → 23, Case Material → 16, Movement → 15, Gender → 24, Crystal → 20; Features and Attribut 9/10 have no fallback), otherwise the field stays empty. The fallback applies to the prefill only; the write-back still goes to the English-named attribute. A fallback value confirmed unchanged is not written back (`IsUnchangedFallbackValue` in Codeunit 60335: English attribute empty on the item and value = fallback value), so the English attribute is neither filled with the German text nor created. The workshop corrects them if needed; Codeunit 60331 writes them back as before. The field ↔ attribute name mapping now lives centrally in Codeunit 60335 (`GetWorkshopAttributeName`, `GetWorkshopAttributeValue`, `SetWorkshopAttributeValue`, `WorkshopAttributeCount`) and is shared by prefill and write-back. Upgrade tag `CXW-WORKSHOPLINE-ATTRIBUTEPREFILL-20260930` fills empty fields of open lines in status New once. Details: `openspec/changes/workshop-line-prefill-attributes/`.

> **Update 2026-10-06 (item attributes by ID, replaces the fallback behaviour of the 2026-09-30 update):** The workshop line check attributes are no longer mapped by English attribute names but by fixed attribute IDs (`GetWorkshopAttributeId` in codeunit 60335: Dial Color → 22, Case Diameter → 18, Bracelet Material → 23, Case Material → 16, Movement → 15, Gender → 24, Crystal → 20; Features/Attribut 9/10 → 0 = placeholder, neither prefilled nor written back). `GetWorkshopAttributeName`, `GetWorkshopAttributeFallbackId`, `IsUnchangedFallbackValue` and `FindItemAttributeId` are removed. The write logic now lives in codeunit 60335 (`internal SetItemAttributeValue(ItemNo, AttributeId, Value)` + `GetOrCreateAttributeValueId`); it creates missing attribute values but never attributes, and validates the value (integer/decimal). Codeunit 60331 and the SellWatch item creation (`SetSellWatchItemAttributes` in codeunit 60305: IDs 1, 2, 5, 8, 10, 11, 12, 13, 24) share it. Permission set 60310 has permissions on the attribute tables and codeunit 60335 for this. Details: `openspec/changes/item-attributes-by-id/`.

> **Update 2026-09-30 (SellWatch: item template per offer type, standard "Item Templ. Mgt."):** The purchases & payables setup has two SellWatch item templates: `"CXW SW Item Template Code"` (field 60300, now "Standard" — for all offer types except `commission`, existing value is kept) and the new `"CXW SW Consign. Item Templ."` (field 60303, "Commission" — for `"CXW Offer Type" = 'commission'`). `CreateSellWatchItem` (Codeunit 60305) no longer creates the item via `Item.TransferFields` but via `Codeunit "Item Templ. Mgt".CreateItemFromTemplate(Item, IsHandled, ItemTemplCode)`: the template's default dimensions are copied, template fields are validated, the standard creates the item unit of measure for the base unit (manual `Item Unit of Measure` insert removed), and the item no. comes from the template's `"No. Series"`, or from the inventory setup if the template has none. Description, Description 2 and `"CXB Consignment Sales"` are set afterwards (`Item.Modify(true)`). Template selection and checks live in the new local procedure `GetSellWatchItemTemplateCode`; if the commission template is missing there is no fallback to the standard template. Details: `openspec/changes/archive/2026-09-30-sellwatch-item-templates-per-offer-type/`.

> **Update 2026-09-30 (SellWatch: process offers individually, error stored on the offer):** `ValidateAndCreateVendor` (Codeunit 60305) processes every open offer in its own transaction: entry numbers are collected first, then each offer gets `Commit`, `ClearLastError` and `Codeunit.Run` on the new Codeunit 60351 "CXW SellWatch Process Offer" (`TableNo` = Table 60300), which calls the new internal procedure `ProcessOffer`. If an offer fails, only that offer is rolled back (no half-created vendor, no order without a line, no orphaned item), the error text and time go into the new fields `"CXW Last Error"` (46) / `"CXW Last Error DateTime"` (47) on Table 60300, and the run continues with the next offer; the job queue entry no longer ends in error. Failed offers stay open and are retried automatically on the next run; on success the error fields are cleared. Page 60307 shows both fields and highlights failed rows; the API (Page 60337) does not expose them. `Codeunit.Run` instead of `[TryFunction]` (as in 60331/60345) because a TryFunction does not roll back database writes. Details: `openspec/changes/archive/2026-09-30-sellwatch-process-offers-individually/`.

> **Update 2026-09-30 (Send to Workshop: serial no. information card instead of own dialog):** Page 60340 "CXW Serial No. Input" is removed. "Send to Workshop" (PageExtension 60328) determines, per arrived line, the serial no. from the purchase line's item tracking or draws the next one from `Item."Serial Nos."` and assigns it as item tracking (new internal procedures in Codeunit 60335), then opens Page 6504 "Serial No. Information Card" and copies `"CXB Manufacturer Serial No."` (CHX.Base) to the purchase and workshop line. Lines with quantity ≠ 1, without SN purchase tracking, without a serial no. series, with a blank manufacturer serial no. or missing CHX.Base mandatory data (`CheckPresenceMandatory`) go to the error list. This lets Codeunit 60331 post the receipt of serial-tracked items without manual item tracking. Permission set `CXW Workshop All`: Reservation Entry and Serial No. Information now RIM, new No. Series Line (RM) and Item Tracking Code (R). Details: `openspec/changes/archive/2026-09-30-workshop-send-serial-no-information/`.

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
app/app.json                      # Extension manifest, idRanges 51000-51049 + 60300-60349, CHX.Base dependency
app/src/
  Tables/                         # 12 tables (60300-60302 SellWatch; 60311-60317 sales price management; 60318 Workshop; 60341 Consignment Sales)
  TableExtensions/                # 6 extensions (Purchase Line, Purchase Header, Purchases & Payables Setup – SellWatch/Consignment; Sales Price, Country/Region – sales price management; Purchase Line – Workshop)
  PageExtensions/                 # 5 extensions (Sales Prices, Countries/Regions – sales price management; Purchase Order, Purchase Order Subform – Workshop; Purchases & Payables Setup – SellWatch/Consignment)
  Pages/                          # 13 pages + 1 xmlport (60307-60309 + 60337 SellWatch; 60321-60325 + Xmlport 60328 sales price management; 60338-60339 Workshop; 60342 Consignment Sales)
  Codeunits/                      # 6 codeunits (SellWatch Mgt, SellWatch Process Offer – SellWatch; Export Gateway Sales Price, Import Sales Prices – sales price management; Process Workshop Lines – Workshop; Consignment Sale Detection, Post Consignment Purchases – Consignment Sales)
  Enums/                          # 9 enums (SW Order Status – SellWatch; 6 more – sales price management; Workshop Line Status – Workshop; Consignment Posting Status – Consignment Sales)
  PermissionSets/                 # 5 permission sets (CXW SWChronWSAll, CXW Sell Watch API – SellWatch; CXWChronWSAll – sales price management; CXW Workshop All [also covers Consignment Sales since this update], CXW Workshop API – Workshop)
app/Translations/                 # .g.xlf (generated) + de-DE.xlf (maintained)
test/                             # test app "CHX.Webshop Tests" (IDs 50400-50499, see Running Tests)
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
   │   country = imported source line; no variant code)  Release Sales Prices)
   │
   │  Action "Release Sales Prices" — country lines only ("CXW Country Code" <> ''),
   │  each via Codeunit.Run(Codeunit 60333 "CXW Release Sales Price Line")
   │  in its own transaction (failure → line rolled back, Export Status = Error)
   │
   ├─► Codeunit 60329.WriteBackAndArchive: writes/updates standard table
   │      "Sales Price" (Sales Type = All Customers); only if the country equals
   │      "CXW Archive Country Code" (Table 60311, default DE) also inserts a new,
   │      incrementally versioned row into Table 60313 "CXW Sales Price Archive"
   │
   ├─► Codeunit 60329.QueueExport: Table 60320 "CXW Sales Price Export"
   │      (price of that country, Unit Price (LCY) calculated at release,
   │      SystemId of the "Sales Price") + ChronextBC "Data Export Entry"
   │      (Destination Code SALESPRICE, Source Record ID = Table 60320 record,
   │      status "CXW Pending" from enumextension 60300 — Insert + Modify in the
   │      same transaction, "Waiting to Process" is never committed)
   │      → checking line Export Status = Queued
   │
   ▼
Job queue: Codeunit 60332 "CXW Export Sales Price Job"
   │  selects SALESPRICE entries with status "CXW Pending", or Error with
   │  "Attempt Count" < "CXW Max. Export Attempts" (Table 60311, 0 → 3);
   │  per entry Commit + Codeunit.Run(Codeunit 60334 "CXW Export Sales Price
   │  Entry"), runtime error → SetAttemptResult(Error); the job run itself
   │  never ends with an error
   │
   └─► Codeunit 60329.ExportEntry: builds the JSON on the first attempt
          (BuildSalesPriceJson, 30 fixed camelCase keys from Table 60320,
          "Sales Price" via GetBySystemId and Item; profit = margin % based on
          VAT Posting Setup) and stores it as payload; retries send the stored
          payload unchanged. SendToApiInterface POSTs via HttpClient to the endpoint configured on
          Table 60317 "CXW API Interface Setup" (overview: Page 60324; per-interface
          detail setup incl. HTTP method/SOAPAction/authentication: Page 60325
          "CXW API Interface Setup Card", reachable via drilldown on the code or
          the "Edit Details" action on Page 60324), using the
          interface selected on Table 60311's "CXW API Interface Code" field,
          and sets status, Attempt Count, Last Attempt At, Processed At or
          Error Message on the existing entry via SetAttemptResult.
          PageExtension 60336 on ChronextBC Page 50108 offers "Requeue Sales
          Price" (Error → CXW Pending, Attempt Count = 0, payload kept).
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
          activation guard uses, so the two can't drift apart. The fields sit
          in caption-less subgroups (ApiKeyGroup/AwsGroup) whose Visible the
          page re-evaluates via CurrPage.Update — Visible on the field itself
          would only be evaluated when the page opens. Below each secret, a
          read-only field shows the last 4 characters of the stored value
          (Get…Hint on Table 60317). For AWSSigV4, activation only requires
          Access Key ID, Region, and Service, not the Secret Access Key. Page 60324
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
Stock/Recom. Retail/Strike Price of the country line are then always rounded up to the
next full ten (RoundUpToTen, change `round-country-sales-price-to-ten`).
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
Rows with "CXW Created" = false — entry numbers collected first, then PER
OFFER: Commit → Codeunit.Run(60351 "CXW SellWatch Process Offer")
   → SellWatchMgt.ProcessOffer (own transaction; a failure rolls back only
   this offer and writes "CXW Last Error"/"CXW Last Error DateTime"; the
   offer stays open and is retried on the next run):
   ├─► looks up an existing "Vendor" by Name/Address/Phone No./E-Mail;
   │      otherwise creates a new "Vendor" + "Vendor Bank Account"
   │      (bank account code = last 4 digits of the IBAN + currency code)
   │
   └─► CreatePurchaseOrder: creates a "Purchase Header" (Document Type =
          Order) and one "Purchase Line" — a new item is created
          (CreateSellWatchItem via "Item Templ. Mgt."; template per
          "CXW Offer Type": commission → field 60303, otherwise → field
          60300 of the purchases & payables setup), quantity 1, Amount
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
   │     Yes → quantity (base) = 1 and item tracking code with
   │              "SN Purchase Inbound Tracking"? otherwise error for line
   │            → serial no. from the line's item tracking (Reservation
   │              Entry); none → next no. from Item."Serial Nos." (missing
   │              → error) assigned as item tracking via "Create Reserv.
   │              Entry" (quantity 1, surplus)
   │            → get/create "Serial No. Information", Commit (RunModal is not
   │              allowed in a write transaction), open Page 6504
   │              "Serial No. Information Card" modally (CHX.Base fields
   │              manufacturer serial no., box/papers)
   │            → afterwards "CXB Manufacturer Serial No." blank or CHX.Base
   │              CheckPresenceMandatory (TryFunction) fails → error
   │              collected for this line, continues with the next line
   │              (serial no./item tracking are kept for the next attempt)
   ▼
When complete:
   "CXW Manufacturer Serial No." (from the serial no. information)
   + "CXW Sent to Workshop" := true on the
   Purchase Line (TableExtension 60321 "CXW Workshop Purchase Line")
   ▼
Table 60318 "CXW Workshop Line" created (PK: Document Type/No./Line No.),
Status = New, Item No. copied from the purchase line;
Codeunit 60335 "CXW Workshop Line Mgt.".FillPurchaseData copies a snapshot
of the purchase header (Vendor Order No., Buy-from Vendor No./Name,
Currency Code — blank → GL Setup "LCY Code"), the purchase line (Variant
Code, Description, Quantity, Direct Unit Cost, ChronextBC "Used Good") and
the item's standard item attributes ("Item Attribute Value Mapping",
attribute IDs 1 brand, 2 model, 3 sub model, 5 reference, 8 year via
Evaluate → Integer, 10 condition, 11 box, 13 certificate — a missing value
leaves the field empty or 0) into fields 30–38/40–47 of the Workshop Line
   │
   │  PageExtension 60329 "CXW Workshop Purch Order Subf" locks the
   │  standard line fields (Editable = false) once "Sent to Workshop" = true
   ▼
External workshop reads/writes via
Page 60339 "CXW Workshop Line API" (PageType = API, OAuth2-S2S,
   endpoint pattern .../api/saliniLife/workshop/v1.0/companies({companyId})/
   workshopLines; Insert/Delete blocked, status regressions blocked)
   │  workshop additionally reads (read-only, PATCH changes rejected):
   │  tenant (at runtime from "Purchases & Payables Setup"."CXW Workshop
   │  Tenant", e.g. "GmbH"), vendorOrderNo, vendorNo, vendorName,
   │  variantCode, description, quantity, unitPrice, seller_currency,
   │  usedGoods, brand, model, subModel, ref, year, condition, box,
   │  certificate — everything except tenant from the Workshop Line itself;
   │  "CXW Workshop API" = Workshop Line RM + Purchases & Payables Setup R
   │  workshop sets: isAuthentic, Attribute 1-10, Status = "WS checked"
   ▼
Codeunit 60331 "CXW Process Workshop Lines" (job-queue driven, OnRun
   → ProcessCheckedLines, SetRange Status = "WS checked")
   │  per line: ProcessLineWithErrorHandling wraps TryProcessLine
   │  ([TryFunction]) – a failure doesn't block the remaining lines
   │
   ├─► Genuine = true → ProcessGenuineLine:
   │      "Qty. to Receive" = order quantity, Codeunit "Purch.-Post"
   │      (Receive = true, Invoice = false), then SetItemAttributeValue
   │      (codeunit 60335) writes the check attributes via
   │      GetWorkshopAttributeId to attributes 22, 18, 23, 16, 15, 24, 20
   │      (Features/Attribut 9/10 = placeholders, not written); missing
   │      attribute values are created, attributes never
   │      → Status = "Processed", "CXW Last Error" := ''
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

View/correction: Page 60338 "CXW Workshop Lines" (list, all fields incl.
   status, attributes, last error; editable except key fields and item no.,
   no insert/delete; status regressions are blocked by the table's OnModify)

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
| Codeunit 60329 | `WriteBackAndArchive(SalesPriceChecking: Record "CXW Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Writes/updates a "Sales Price" record from an approved checking line (Sales Type = All Customers) and archives a new version if the country equals "CXW Archive Country Code". No longer a TryFunction — isolation via Codeunit 60333 and `Codeunit.Run`. |
| Codeunit 60329 | `QueueExport(SalesPriceChecking: Record "CXW Sales Price Checking"; SalesPrice: Record "Sales Price")` | Creates the Table 60320 record and the "Data Export Entry" (`SALESPRICE`, status "CXW Pending", file name `SalesPrice_<Item>_<Currency>_<Country>.json`). |
| Codeunit 60329 | `ExportEntry(var DataExportEntry: Record "Data Export Entry")` | Builds the payload (30 keys; `itemNo`/`variantCode` carry the old NAV numbers "Old Item No."/"Old Variant Code") on the first attempt and sends it to the configured API interface; result via `SetAttemptResult`, log in Table 60302 "CXW Http Call Log". Runtime errors (missing record, setup) are passed on to the caller. |
| Codeunit 60329 | `SetAttemptResult(var DataExportEntry; pSuccess: Boolean; pErrorMessage: Text)` / `GetDestinationCode(): Code[20]` | Records an attempt on the entry (Attempt Count +1, status, timestamps, error text) or returns the reserved destination code `SALESPRICE`. |
| Codeunit 60332 | `OnRun` (TableNo = "Job Queue Entry") | Job queue job for the sales price export, see Architecture. |
| Codeunit 60333 / 60334 | `OnRun` | Workers for `Codeunit.Run`: release of one checking line or export of one "Data Export Entry" in its own transaction. |
| Page 60322 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Calculates the non-stock price for lines within a price range. Currently not called from any active code path. |
| Codeunit 60330 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Raised when the automated file import changes an existing sales price. Currently has no subscriber. |
| Table 60317 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Stores/reads the API key for an interface in Isolated Storage (module scope) rather than in a plain table field. |
| Table 60317 | `GetApiKeyHint()` / `GetAwsSecretAccessKeyHint()` / `GetAwsSessionTokenHint(): Text` | Returns, for display on Page 60325, only the last 4 characters of the stored secret behind a mask prefix, "(not stored)" when empty, and a mask only for values of 4 characters or less. The plain text never leaves the table. |
| Codeunit 60305 | `OnRun` / `ValidateAndCreateVendor` (local) | Processes every Table 60300 row with "CXW Created" = false individually, each in its own transaction (`Commit` + `Codeunit.Run` on Codeunit 60351); if an offer fails, the error text/time are stored on the offer and the others continue. No caller of this `OnRun` found anywhere in the project (see Known Limitations). |
| Codeunit 60305 | `internal ProcessOffer(var SellWatchOffer: Record "CXW SellWatch Vendor Info")` | Processes exactly one offer: finds or creates a vendor plus bank account, then creates and releases a purchase order with a new item. Only called via Codeunit 60351 "CXW SellWatch Process Offer" (`TableNo` = Table 60300). |
| Codeunit 60305 | `CreateSourceFilePurchaseRequest(PurchaseHeader: Record "Purchase Header"): Text` | Builds the JSON for a purchase-order acknowledgment (SRid, purchase_order, optional tracking_number). Currently not called from anywhere else in the code. |
| Codeunit 60305 | `CreateSourceFileOrderStatusSE(SellWatchInfo: Record "CXW SellWatch Vendor Info"; Status: Enum "CXW SW Order Status"): Text` | Builds the JSON for a status update to SellWatch (name, e-mail, watch data, link to the online approval, payout currency/amount from the archived purchase line). Currently not called from anywhere else in the code. |
| Table 60301 | `CreateEntryInexternalFile(var WOA: Record "CXW Watch Online Approval")` | Sends an HTTP GET to the SellWatch endpoint to check whether a watch should be online, updates the row accordingly, and logs the call in Table 60302 ("CXW Source Table No." = 60301). Currently not called from anywhere else in the code. |
| Codeunit 60331 | `OnRun` / `ProcessCheckedLines` (local) | Job queue entry point; processes every Table 60318 row with status "WS checked" individually via `ProcessLineWithErrorHandling`. |
| Codeunit 60331 | `ProcessLineWithErrorHandling` / `TryProcessLine` (both local) | Wraps processing of a single line as a `[TryFunction]`; on failure, sets status to `Error` and writes `GetLastErrorText()` into "CXW Last Error", without blocking processing of the remaining lines (`Commit()` after each line). |
| Codeunit 60335 | `GetWorkshopAttributeId(AttributeIndex: Integer): Integer` | Central mapping check attribute → item attribute ID (index 1–7 → 22, 18, 23, 16, 15, 24, 20; index 8–10 Features/Attribut 9/10 → 0 = placeholder), shared by the prefill on "Send to Workshop" and the write-back in Codeunit 60331. Entering an ID for a placeholder here enables both. |
| Codeunit 60335 | `internal SetItemAttributeValue(ItemNo: Code[20]; AttributeId: Integer; Value: Text[250])` | Assigns a value of an existing attribute to the item; creates missing attribute values (Validate checks integer/decimal), fails on an unknown attribute ID, never creates attributes. Used by Codeunit 60331 and the SellWatch item creation (Codeunit 60305). |
| Codeunit 60335 | `internal IsSerialNoTracked` / `FindPurchLineSerialNo` / `AssignNextSerialNo` / `GetOrCreateSerialNoInformation` | Serial number logic for "Send to Workshop": checks SN purchase tracking on the item tracking code, reads the serial no. from the purchase line's item tracking, otherwise draws the next no. from `Item."Serial Nos."` and assigns it via `Create Reserv. Entry` (quantity 1, surplus), and gets/creates the "Serial No. Information" record. |
| Codeunit 60344 | `SetPurchaseOrder(var ConsignmentPostingEntry: Record "CXW Consignment Posting Entry"; ItemNo: Code[20])` | Resolves the open, received-but-not-yet-invoiced purchase order for an item and sets status/error text on the given entry accordingly. Made public deliberately so Codeunit 60345 can reuse it for the "Retry" action instead of duplicating the logic. |
| Codeunit 60345 | `OnRun` / `ProcessDueEntries` (local) | Job queue entry point; processes every Table 60341 entry with status "Open" and a reached "CXW Due Date" individually via `ProcessEntryWithErrorHandling`. |

Full list of all objects and their function counts: see `docs/funktionsregister/gesamtuebersicht.md`.

## Table Overview (Quick Reference)

| Table | Primary Key | Purpose |
|---|---|---|
| 60300 CXW SellWatch Vendor Info | Entry No | Incoming SellWatch purchase request: seller, bank, watch, and offer data; "CXW Created" flags whether the vendor/order have already been created automatically; "CXW Last Error"/"CXW Last Error DateTime" (not editable, not exposed in the API) hold the error of the last failed processing attempt and are cleared on success; FlowField "CXW Tracking Number" reads from table extension 60304 on "Purchase Header" |
| 60301 CXW Watch Online Approval | Entry No | Result of the online-visibility check per item/variant ("CXW Check Online", "CXW First Online Date", "CXW Remark"); FlowField "CXW SRid" reads the "Vendor Order No." of the related purchase order |
| 60302 CXW Http Call Log | Entry No | Shared log of every HTTP call made by `CreateEntryInexternalFile` (SellWatch) AND `SendToApiInterface` (sales price export) – success/failure, status code, redacted request, response as a blob; "CXW Source Table No." (60301, 50103 "Data Export Entry", or 60314 for legacy entries) + "CXW Source Entry No" identify the triggering record |
| 60311 CXW General Sales Price Setup | Primary Key (singleton) | Base settings, incl. export toggle and selected API interface |
| 60312 CXW Sales Price Checking | Item No., Currency Code, Country Code | Staging area for import/validation/approval |
| 60313 CXW Sales Price Archive | + Version No. | History; populated by "Release Sales Prices" (Page 60322) via Codeunit 60329 **for the archive country only** ("CXW Archive Country Code", default DE), "Version No." incremented per Item No./Currency Code/Country Code |
| 60320 CXW Sales Price Export | Entry No. (AutoIncrement) | Released price per country line (prices, Unit Price (LCY), validity, reason, comment, remark, modification info, SystemId of the "Sales Price", Data Export Entry No., FlowField Export Status); source of the JSON payload; view on Page 60320 "CXW Sales Price Export Entries" |
| 60314 CXW Sales Price Outbound File | Entry No. | **Obsolete Pending since 27.0.0.3** — no longer written (replaced by ChronextBC "Data Export Entry", Destination Code `SALESPRICE`); only holds legacy data up to 27.0.0.2 |
| 60315 CXW Sales Price Inbound File | Entry No. | For automated file import (not wired live) |
| 60316 CXW Price Import Protocol | Entry No. | Error log for the automated import (still the sales price import protocol table; "Sales" dropped from the identifier due to AL's 30-character limit) |
| 60317 CXW API Interface Setup | Code | Endpoint URL, auth type, and (isolated-storage) API key per external interface; when "CXW Auth Type" = AWSSigV4, also AWS Access Key ID/Region/Service (plain fields) and AWS Secret Access Key/Session Token (isolated storage) |
| 60318 CXW Workshop Line | Document Type, Document No., Line No. | One record per purchase line handed over to the workshop: Item No., Manufacturer Serial No., Status (Enum 60337: New/WS checked/Processed/Error), isAuthentic (authenticity flag), eight business-named attribute fields (Dial Color … Features) + two placeholders (Attribut 9/10), Created At, Checked At, Last Error |
| 60341 CXW Consignment Posting Entry | Entry No (AutoIncrement) | One record per posted sales invoice line for a consignment item: Item No., Purchase Order No. (blank on a detection failure), Sales Invoice No., Sales Posting Date, Due Date, Status (Enum 60343: Open/Posted/Error), Error Text |

**"Hold Order" flag:** The former Table Extension 60300 "CXW Sales Header" (field "CXW Hold Order") and PageExtension 60337 "CXW Sales Order List" were removed in version 27.0.0.10; the field now lives in CHX.Base (from 27.0.3.5, TableExt 60212 "CXB Sales Header Ext.", field "CXB Hold Order"). Change: `openspec/changes/move-hold-order-to-chx-base`.

## Permission Set

The **`CXWChronWSAll`** permission set (ID 60336, `app/src/PermissionSets/CXWChronWSAll.permissionset.al`) covers read/write access to all seven sales price management tables plus — since the HTTP-logging update — the shared Table 60302 "CXW Http Call Log", along with execute rights for both codeunits, Xmlport 60328, and the five pages (the four sales-price-management pages plus Page 60309 "CXW Http Call Log"). Table and page extensions don't need their own entries, since they're covered by the base object's permissions (e.g. standard access to "Currency"); the standard "Sales Price" table that Codeunit 60329 writes to is likewise covered by base app permissions, not by this set. Since 27.0.0.3 the set also grants `RIM` on the ChronextBC table "Data Export Entry" that the price export writes to. Since 27.0.0.6 it additionally covers `RIMD` on Table 60320, Page 60320 and Codeunits 60332–60334; the job queue entry's user needs this set. The set still needs to be actively assigned to a user group.

For SellWatch, the separate **`CXW SWChronWSAll`** permission set (ID 60310, `app/src/PermissionSets/CXWSWChronWSAll.permissionset.al`) covers RIMD access to the two SellWatch-only tables (60300–60301) plus the shared Table 60302 "CXW Http Call Log", along with execute rights for Codeunit 60305 and the three SellWatch pages (60307–60309, where Page 60309 "CXW Http Call Log" is likewise shared). Table extensions 60303/60304 on "Purchase Line"/"Purchase Header" don't need their own entries either, for the same reason as sales price management's extensions — they're covered by the base table's standard permissions. This set also still needs to be actively assigned to a user group.

For the Workshop authenticity check, there are two separate permission sets: **`CXW Workshop All`** (ID 60301, `app/src/PermissionSets/CXWWorkshopAll.permissionset.al`) for full internal access to Table 60318, all Workshop pages, and Codeunit 60331 — including the standard tables needed for goods receipt, cancellation, and item attributes (Purchase Header/Line, Item, Item Attribute, Item Attribute Value, Item Attribute Value Mapping; for "Send to Workshop" additionally Reservation Entry and Serial No. Information with RIM, No. Series Line with RM and Item Tracking Code with R), so the job queue codeunit can run standalone — and **`CXW Workshop API`** (ID 60302, `app/src/PermissionSets/CXWWorkshopAPI.permissionset.al`) as a lean counterpart exclusively for the external workshop user: only `tabledata "CXW Workshop Line" = RM`, no insert/delete, no access to Purchase Line or Item. Both sets still need to be actively assigned (`CXW Workshop All` to internal staff / the job queue execution user, `CXW Workshop API` exclusively to the workshop's dedicated OAuth2-S2S user).

**`CXW Workshop All`** now also covers Table 60341, Codeunit 60344/60345, and Page 60342 since the Consignment Sales update, including read access to the standard tables `Sales Invoice Header`/`Sales Invoice Line` (for the event subscriber) and `Purchases & Payables Setup` (for the new delay field) — the job queue execution user for Codeunit 60345 therefore needs the same permission set as for Workshop processing.

## Running Tests

The automated tests are in the test app **CHX.Webshop Tests** under `test/` (IDs 50400–50499; 50300–50399 is used by CHX.Base Tests). It is never shipped to customers. Open the workspace `CHX.Webshop.code-workspace`, run *AL: Download Symbols* in the `test` folder, publish the app and the test app, and run the tests in the Test Explorer (BC 28 or later). Please use a dedicated test sandbox (`test/.vscode/launch.json`: `ChronextAutoTest`).

| Codeunit | Content |
|---|---|
| 50400 CXW Test API Interface Setup | Field relevance per auth type, activation guard, display of secrets (simplest starting point) |
| 50401 CXW Test Workshop Line Data | Prefill of the check attributes, purchase and watch data for the workshop API |
| 50402 CXW Test Sales Price WriteBack | Write-back into "Sales Price", Unit Price (LCY), archive |
| 50403 CXW Test Sales Price Export | Release, payload, log, export job, settings |
| 50404 CXW Test Permissions | All objects are covered by the app's permission sets |
| 50499 CXW Test Library | Test data helpers |

`[HttpClientHandler]` is only available OnPrem. The export tests therefore send to a `.invalid` address that can never be reached, and only check what is stored before and after sending. A successful transmission is not tested automatically.

Not yet covered by automated tests (basis for further test codeunits): country expansion (`openspec/specs/sales-price-country-copy/spec.md`, logic on Page 60322), SellWatch, consignment sales, availability/delivery times, On Demand, and the processing of workshop lines. For SellWatch, `openspec/specs/sellwatch-http-call-logging/spec.md` (scenarios for success/failure logging, API key redaction, and telemetry from `CreateEntryInexternalFile`) and `openspec/specs/sellwatch-standard-table-extensions/spec.md` (scenarios for "CXW Used good" and "CXW Tracking Number") offer a comparable starting point. For the Workshop authenticity check, scenarios are still spread across several, partly unarchived OpenSpec changes (`openspec/changes/purchase-workshop-integration/specs/` plus the deltas built on top of it in `openspec/changes/archive/2026-08-13-workshop-line-error-handling/` and `openspec/changes/archive/2026-08-13-workshop-attribute-*`) — before writing tests, these should be consolidated into a canonical spec under `openspec/specs/workshop-line-processing/` (see Known Limitations).

## Deployment

Azure DevOps pipeline `azure-pipelines.yml` (scripts in `.pipelines/`): on every push, build with CodeCop/UICop and all tests of the test app in a BC container (agent pool `SelfHosted-BCServer`); nightly also against NextMinor/NextMajor. The dependencies (Salini Base App, CHX.Base, ChronextBC) are stored as `.app` files in `.pipelines/dependencies`, the SalLicenseCheckApp stub in `.pipelines/stubs`. The build artifact `CHXWebshop-de` contains only the app. Deployment is still manual via "AL: Publish" from VS Code or the admin center.

## Contributing / Conventions

- All new objects get IDs in the registered **60300–60349** range (see `app.json`, `idRanges`; the older 51000–51049 range remains registered but, since the 2026-08-10 rename, is no longer occupied), counted independently per object type.
- The code deliberately contains **no comments** (removed at the customer's explicit request) — business context and design decisions are documented here and in the function register instead. Please keep this style when making changes, and add context here rather than in the code.
- Completed, functional changes are documented as an OpenSpec change (`openspec/changes/`, archived under `openspec/changes/archive/` once finished) and captured as a durable spec under `openspec/specs/`.
- Translations: `.g.xlf` is generated by the compiler and must **not** be edited manually; maintain translations only in `app/Translations/CHX.Webshop.de-DE.xlf`.
- Add new tables, pages, reports, codeunits, queries and XMLports to a permission set of the app (X, for tables also `tabledata` RIMD), otherwise `CXW Test Permissions` (50404) fails.

## Known Limitations

- **"Add all Countries" only converts correctly from a source line in local currency.** The conversion (`price * (1 / rate)` via `GetLastestExchangeRate`) assumes the imported source line is in LCY. A source line in a foreign currency (e.g. CHF) would be converted incorrectly for countries with a different currency. Countries sharing the source line's currency receive the price unchanged.
- **"Sales Price" has no country.** For several countries sharing a currency, the same "Sales Price" record (key without country) is written several times — the last released price wins. The country and the price per country are kept in Table 60320 and in the transmitted JSON (`countryRegionCode`); the job therefore reads prices from Table 60320, not from "Sales Price".
- **Source lines without a country are not released.** Without an activated DE country line there is no EUR price in "Sales Price", no archive entry and no export.
- **Table 60320 has no retention policy** and grows with every release.
- **"Approve" itself does not carry prices into the standard "Sales Price" table or into "CXW Sales Price Archive".** The action only sets the approval flags on Table 60312. The carry-over happens in the downstream "Release Sales Prices" step (Page 60322, Codeunits 60333/60329).
- **(Fixed 2026-08-10) `"CXW Unit Price (LCY)"` was never populated automatically** — `WriteBackAndArchive` used to write only the standard `"Unit Price"` field, while Page 60322's `fnValidate` divided by `"CXW Unit Price (LCY)"` when comparing against the previous price. Since that field stayed `0` on every automated write, every second "Validate" run against an item/currency that already had an uploaded price reliably crashed with `Attempted to divide by zero.` and aborted the whole batch. `Codeunit 60329`'s new `ResolveUnitPriceLCY` now populates the field on every write (converting via the exchange rate already captured on the checking line, or a fallback lookup); `fnValidate` also now skips the comparison instead of dividing when the previous record's value is still `0`. "Sales Price" records written before this fix stay at `0` until the next time they're written back through "Upload Sales Price" — no retroactive backfill (see `openspec/changes/archive/2026-08-10-sales-price-unit-price-lcy-autofill/design.md`).
- **`Reason Code` as an enum with no true blank value**: the enum always has a default value (`CatMan`) — there is no "no reason given" state.
- **The file-based import component (Codeunit 60330, Tables 60315–60316)** is fully implemented but not wired into any live process or scheduled anywhere (no job queue entry). `WriteSalesPrices`'s `SalesPrice.Get(...)` call now passes exactly the standard "Sales Price" table's 8 real primary-key segments (verified against the symbols in `.alpackages/Microsoft_Base Application_*.app`), with `''` for "Variant Code" — the previously-documented key mismatch here is resolved.
- **No automated tests** exist.
- **The actual trigger for Codeunit 60305 "CXW SellWatch Mgt".OnRun is not part of the AL source code.** The project has no install/upgrade codeunit, no event subscriber, and no API page that calls `OnRun` or inserts rows into Table 60300. In practice, execution must happen via a job queue entry created at runtime, a manual invocation, or an integration outside this codebase — that doesn't contradict the automated processing described in the User Manual, but it isn't traceable in the code itself.
- **`CreateSourceFilePurchaseRequest`, `CreateSourceFileOrderStatusSE` (Codeunit 60305), and `CreateEntryInexternalFile` (Table 60301, for the actual online check) are currently not called from anywhere else in the project.** The two JSON builders in particular look like prepared but not-yet-wired status updates back to SellWatch.
- **`CreatePurchaseOrderinBV` and `CreatePurchaseOrderinGmBH` (Codeunit 60305, both local)** are likewise never called — leftovers of the GMBH/BV branching that, per a code comment, was already disabled in the source system. `ReadJSONFile` (Table 60301, local) is an empty stub with no function.
- **(Fixed) SellWatch item creation now uses a configurable item template instead of hard-coded variant codes.** Item/variant codes for SellWatch purchase lines used to be hard-coded (`C2C-SW`, `CPST-SW`, `TI-SW`); that was replaced with dynamic item creation via an item template (`CreateSellWatchItem`, Codeunit 60305, since 2026-09-30 via the standard `"Item Templ. Mgt".CreateItemFromTemplate` instead of `Item.TransferFields`). The templates are configurable in `TableExtension 60322 "CXW SW Purchases Setup"` / `PageExtension 60330` — `"CXW SW Item Template Code"` (standard) and `"CXW SW Consign. Item Templ."` (commission); `GetSellWatchItemTemplateCode` picks one by `"CXW Offer Type"` and aborts with a descriptive error if the relevant field is blank or points at a template that no longer exists — see `openspec/specs/sellwatch-item-template-setup/spec.md`.
- **Consignment Sales assumes "1 item = 1 open purchase order = 1 purchase line"** (the same assumption used by the Workshop authenticity check). If that assumption breaks (e.g. more than one open order for the same item), `SetPurchaseOrder` (Codeunit 60344) deliberately produces an `Error` entry instead of a more precise resolution.
- **`"Vendor Invoice No."` is populated with `"CXW Sales Invoice No." + "-CONS"` when posting automatically (Codeunit 60345), if blank on the purchase order.** This is a placeholder pattern for the actual vendor invoice reference, which isn't otherwise available in the automated flow — confirm with the business if needed.
- **No job queue entry for Codeunit 60345 "CXW Post Consignment Purchases" is pre-configured.** Must be set up manually after deployment (recommended: daily) — see Key User Manual.
- **The online check (`CreateEntryInexternalFile`) uses a hard-coded interface code `'WOA'`** on Table 60317 "CXW API Interface Setup" — the same table sales price management uses for its price export (there, via the configurable "CXW API Interface Code" field). For SellWatch, the code is not configurable; it must be exactly `'WOA'`.
- **The Workshop authenticity check only covers the standard case "one purchase order = one purchase line".** Mixed orders (multiple lines, some genuine, some not) are not implemented — on non-authenticity, `ProcessNonGenuineLine` (Codeunit 60331) currently cancels the *entire* purchase order even if only one of several lines were affected (marked `// TODO:` in the code).
- **Three of the ten Workshop check attributes (Features, Attribut 9/10) are placeholders without an item attribute** (ID 0 in `GetWorkshopAttributeId`). The workshop can fill them through the API, but they are neither prefilled nor written back to the item until an attribute ID is assigned.
- **The base spec for the Workshop authenticity check isn't cleanly archived.** The original `purchase-workshop-integration` change (Enum 60337, Table 60318, TableExtension 60321, PageExtension 60328/60329, Pages 60338–60339, Codeunit 60331, PermissionSets 60301/60302) sits misplaced under `openspec/changes/archive/2026-08-13-workshop-line-error-handling/purchase-workshop-integration/` instead of a proper, dated archive location, and is invisible to `openspec list`/`openspec status` (as of writing: 30/34 tasks). Several later changes (`workshop-line-error-handling`, `workshop-attribute-names`, `workshop-attribute-field-names`) ship delta specs against the `workshop-line-processing`/`workshop-line-api` capabilities that were consequently never consolidated into a canonical spec under `openspec/specs/`. This should be cleaned up before further changes to Workshop processing.
