# Developer Manual – SL Chronext Webshop

## Overview

This Business Central (AL) extension covers webshop sales price management: CSV import into a staging table, business validation (margin, price swings), approval by a staff member, optionally expanding an approved price to all activated foreign currencies, and uploading approved prices to an external system. The "Upload Sales Price" action writes each approved price into the standard "Sales Price" table and a versioned "SL Sales Price Archive" entry before sending it to a configurable API interface. A second, independent component for file-based price import (not yet live) rounds out the project. The project is a migration from a legacy, long-grown Dynamics NAV system into modern, SaaS-capable AL.

## Technical Stack

| Component | Technology | Version |
|---|---|---|
| Extension type | Microsoft Dynamics 365 Business Central (AL) | Platform/Application 26.0.0.0 |
| Runtime | AL Runtime | 17.0 |
| Object ID range | Customer range | 51000–51049 |
| Dependencies | – | none (`dependencies: []` in `app.json`) |
| Publisher | Salini Life | – |
| Extension ID | `5df32934-5708-418c-ba16-44b30feb51f4` | – |

## Project Structure

```
app.json                          # Extension manifest, idRanges 51000-51049
src/
  Tables/                         # 7 tables (51000-51002, 51004-51007)
  TableExtensions/                # 3 extensions (Country/Region, Sales Price, Currency)
  PageExtensions/                 # 3 extensions (Countries/Regions, Sales Prices, Currencies)
  Pages/                          # 4 pages + 1 xmlport
  Codeunits/                      # 2 codeunits (Export Gateway Sales Price, Import Sales Prices)
  Enums/                          # 5 enums
  PermissionSets/                 # 1 permission set (SLChronWSAll)
Translations/                     # .g.xlf (generated) + de-DE.xlf (maintained)
openspec/
  specs/                          # durable capability specs (e.g. sales-price-currency-copy)
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

No environment variables in the classic sense. Relevant configuration lives in `app.json` (`idRanges`, `features: ["NoImplicitWith","TranslationFile"]`) and, at runtime, in the **"SL General Sales Price Setup"** table (see Key User Manual).

## Architecture

```
CSV file
   │  Action "Import CSV"
   ▼
Xmlport 51000 "SL Import Sales Price"
   │  writes lines into
   ▼
Table 51001 "SL Sales Price Checking"  ◄── Page 51001 "SL Sales Price Checking List"
   │  (Item No./Currency Code — no country code          (Validate / Approve / Add all Currencies /
   │   and no variant code on this table)                Upload Sales Price)
   │
   │  Action "Upload Sales Price" → Codeunit 51000 "SL Export Gateway Sales Price"
   │
   ├─► WriteBackAndArchive: writes/updates standard table "Sales Price"
   │      (Sales Type = All Customers) and inserts a new, incrementally
   │      versioned row into Table 51002 "SL Sales Price Archive"
   │      (view via Page 51002, read-only)
   │
   └─► CreateExternalInterfaceFile: reflects the "Sales Price" record into
          JSON, stores it in Table 51004 "SL Sales Price Outbound File",
          and POSTs it via HttpClient to the endpoint configured on
          Table 51007 "SL API Interface Setup" (Page 51003), using the
          interface selected on Table 51000's "API Interface Code" field.

Control data for "Add all Currencies":
Table Extension "SLCurrency" (on standard table "Currency", field "Sales Price Activated")
   ◄── Page Extension "SLCurrencies" (on standard page "Currencies")

Country/Region now only supplies informational fields (taxation type, delivery time,
default foreign currency) via Table Extension "SL Country Region" / Page Extension
"SL Country Region Card" — no activation logic anymore.

Independent, not-yet-live component:
File (CSV) → Table 51005 "SL Sales Price Inbound File"
           → Codeunit 51001 "SL Import Sales Prices" (OnRun)
           → writes directly into standard table "Sales Price"
           → errors logged in Table 51006 "SL Sales Price Import Protocol"
```

## Object Interfaces (Public Procedures & Events)

Full list of all procedures, triggers, and events: see `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Key public interfaces:

| Object | Element | Purpose |
|---|---|---|
| Codeunit 51000 | `WriteBackAndArchive(SalesPriceChecking: Record "SL Sales Price Checking"; var SalesPrice: Record "Sales Price")` | Writes/updates a "Sales Price" record from an approved checking line (Sales Type = All Customers) and archives a new version. `[TryFunction]` — a failure is caught and reported as `false` instead of aborting the caller's whole batch. |
| Codeunit 51000 | `CreateExternalInterfaceFile(SalesPrice: Record "Sales Price"): Boolean` | Reflects a "Sales Price" record into JSON, stores it in Table 51004, and sends it to the configured API interface. |
| Page 51001 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Calculates the non-stock price for lines within a price range. Currently not called from any active code path. |
| Codeunit 51001 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Raised when the automated file import changes an existing sales price. Currently has no subscriber. |
| Table 51007 | `SetApiKey(NewApiKey: Text)` / `GetApiKey(): Text` | Stores/reads the API key for an interface in Isolated Storage (module scope) rather than in a plain table field. |

Full list of all objects and their function counts: see `docs/funktionsregister/gesamtuebersicht.md`.

## Table Overview (Quick Reference)

| Table | Primary Key | Purpose |
|---|---|---|
| 51000 SL General Sales Price Setup | Primary Key (singleton) | Base settings, incl. export toggle and selected API interface |
| 51001 SL Sales Price Checking | Item No., Currency Code | Staging area for import/validation/approval |
| 51002 SL Sales Price Archive | + Country Code, Version No. | History; populated automatically by "Upload Sales Price" (Page 51001) via Codeunit 51000, "Version No." incremented per Item No./Currency Code |
| 51004 SL Sales Price Outbound File | Entry No. | Sent JSON payloads with delivery status and response message, for troubleshooting failed transmissions |
| 51005 SL Sales Price Inbound File | Entry No. | For automated file import (not wired live) |
| 51006 SL Sales Price Import Protocol | Entry No. | Error log for the automated import |
| 51007 SL API Interface Setup | Code | Endpoint URL, auth type, and (isolated-storage) API key per external interface |

> Note: Table 51002 "SL Sales Price Archive" still carries its own country code for historical reasons — the archive was not migrated to the currency model alongside Table 51001. `Codeunit 51000` always writes it blank, consistent with `sales-price-currency-copy`'s "applies to every country using that currency" model; see `openspec/changes/sales-price-checking-writeback/design.md` for the rationale.

## Permission Set

The **`SLChronWSAll`** permission set (ID 51000, `src/PermissionSets/SLChronWSAll.permissionset.al`) covers read/write access to all seven tables plus execute rights for both codeunits, Xmlport 51000, and the extension's four pages. Table and page extensions don't need their own entries, since they're covered by the base object's permissions (e.g. standard access to "Currency"/"Country/Region"); the standard "Sales Price" table that Codeunit 51000 writes to is likewise covered by base app permissions, not by this set. The set still needs to be actively assigned to a user group.

## Running Tests

There are currently **no** AL test codeunits in this project. The specification `openspec/specs/sales-price-currency-copy/spec.md` (10 scenarios for the "Add all Currencies" action) is a good basis for future tests — note that this spec predates the switch from country-based to currency-based activation and should be reviewed against the current behavior before writing tests from it.

## Deployment

No CI/CD setup (e.g. an AL-Go workflow) was found in the project. Deployment is currently manual via "AL: Publish" from VS Code into the target environment.

## Contributing / Conventions

- All new objects get IDs in the **51000–51049** range (see `app.json`, `idRanges`), counted independently per object type.
- The code deliberately contains **no comments** (removed at the customer's explicit request) — business context and design decisions are documented here and in the function register instead. Please keep this style when making changes, and add context here rather than in the code.
- Completed, functional changes are documented as an OpenSpec change (`openspec/changes/`, archived under `openspec/changes/archive/` once finished) and captured as a durable spec under `openspec/specs/`.
- Translations: `.g.xlf` is generated by the compiler and must **not** be edited manually; maintain translations only in `Translations/SL Chronext Webshop.de-DE.xlf`.

## Known Limitations

- **"Approve" itself does not carry prices into the standard "Sales Price" table or into "SL Sales Price Archive".** The action only sets the approval flags on Table 51001. The carry-over happens in the downstream "Upload Sales Price" step (Page 51001, Codeunit 51000), which writes both "Sales Price" (Sales Type = All Customers) and "SL Sales Price Archive" (with an incremented "Version No.") before the outbound file is generated.
- **`"Unit Price"` (standard field, written by Codeunit 51000) and `"Unit Price (LCY)"` (custom field, read by Page 51001's own `fnValidate` comparison logic) are two separate fields that can diverge** — `WriteBackAndArchive` only writes the former. `fnValidate` is unaffected today since it does its own separate lookup, but `"Unit Price (LCY)"` may go stale once prices are regularly uploaded; flagged for the business owner as a follow-up rather than resolved here (see `openspec/changes/sales-price-checking-writeback/design.md`, Risks/Trade-offs).
- **`Reason Code` as an enum with no true blank value**: the enum always has a default value (`CatMan`) — there is no "no reason given" state.
- **The file-based import component (Codeunit 51001, Tables 51005–51006)** is fully implemented but not wired into any live process or scheduled anywhere (no job queue entry). `WriteSalesPrices` calls `SalesPrice.Get(...)` with an extra "Country/Region Code" argument; the standard "Sales Price" table's actual primary key (verified against the symbols in `.alpackages/Microsoft_Base Application_*.app`) does not include that field. The call should be reviewed before this component is activated (Codeunit 51000 already accounts for this correctly).
- **No automated tests** exist.
- **Table 51002 "SL Sales Price Archive"** still carries its own country code instead of a currency code (see Table Overview above) — if automatic archiving is enabled in the future, consider whether the archive schema should be aligned with Table 51001's currency model.
