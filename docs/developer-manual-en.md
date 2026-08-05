# Developer Manual – SL Chronext Webshop

## Overview

This Business Central (AL) extension covers webshop sales price management: CSV import into a staging table, business validation (margin, price swings), approval by a staff member, and optionally expanding an approved price to all foreign currencies in use. A second, independent component for file-based price import (not yet live) rounds out the project. The project is a 1:1 migration from a legacy, long-grown Dynamics NAV system into modern, SaaS-capable AL.

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
  Tables/                         # 6 tables (51000, 51001, 51002, 51004, 51005, 51006)
  TableExtensions/                # 2 extensions (Country/Region, Sales Price)
  Pages/                          # 3 pages + 1 xmlport
  Codeunits/                      # 1 codeunit (Import Sales Prices)
  Enums/                          # 3 enums
Translations/                     # .g.xlf (generated) + de-DE.xlf (maintained)
openspec/
  specs/                          # durable capability specs (e.g. sales-price-currency-copy)
  changes/archive/                # completed, archived change proposals
docs/                             # this manual + function register
```

**File naming convention:** `Tab<ID>.<PascalCaseName>.al`, `Pag<ID>.<Name>.al`, `TabExt<ID>.<Name>.al`, `Enum<ID>.<Name>.al`, `Codeunit<ID>.<Name>.al`, `XmlPort<ID>.<Name>.al`.

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
   │                                        (Validate / Approve / Add all Currencies)
   │
   ├─► Table 51002 "SL Sales Price Archive"        (read-only via Page 51002;
   │                                                 automatic population currently inactive,
   │                                                 see "Known Limitations")
   │
   └─► Table Extension "SL Sales Price" (on standard table "Sales Price")
        (intended approval target — population currently disabled, see below)

Independent, not-yet-live component:
File (CSV) → Table 51005 "SL Sales Price Inbound File"
           → Codeunit 51001 "SL Import Sales Prices" (OnRun)
           → writes directly into standard table "Sales Price"
           → errors logged in Table 51006 "SL Sales Price Import Protocol"
```

The **"SL Country Region"** table extension (on the standard "Country/Region" table) supplies the control data (sales price activated, foreign currency) used by the "Add all Currencies" action.

## Object Interfaces (Public Procedures & Events)

Full list of all procedures, triggers, and events: see `docs/funktionsregister/funktionsregister-sl-chronext-webshop.md`. Key public interfaces:

| Object | Element | Purpose |
|---|---|---|
| Page 51001 | `fnCalcNonStockPrice(p_decStockPriceFrom, p_decStockPriceTo, p_decNonStockPercent: Decimal)` | Calculates the non-stock price for lines within a price range. Currently not called from any active code path. |
| Codeunit 51001 | `[IntegrationEvent] OnAfterSalesPriceModify(var SalesPriceRec, var SalesPricexRec: Record "Sales Price"; RunTrigger: Boolean)` | Raised when the automated file import changes an existing sales price. Currently has no subscriber (Codeunit 51000, which originally subscribed, has been removed — see below). |

## Table Overview (Quick Reference)

| Table | Primary Key | Purpose |
|---|---|---|
| 51000 SL General Sales Price Setup | Primary Key (singleton) | Base settings |
| 51001 SL Sales Price Checking | Item No., Variant Code, Currency Code, Country Code | Staging area for import/validation/approval |
| 51002 SL Sales Price Archive | + Version No. | History (currently read-only) |
| 51004 SL Sales Price Outbound File | Entry No. | For future price export (not live) |
| 51005 SL Sales Price Inbound File | Entry No. | For automated file import (not live) |
| 51006 SL Sales Price Import Protocol | Entry No. | Error log for the automated import |

## Running Tests

There are currently **no** AL test codeunits in this project. The specification `openspec/specs/sales-price-currency-copy/spec.md` (10 scenarios for the "Add all Currencies" action) is a good basis for future tests.

## Deployment

No CI/CD setup (e.g. an AL-Go workflow) was found in the project. Deployment is currently manual via "AL: Publish" from VS Code into the target environment.

## Contributing / Conventions

- All new objects get IDs in the **51000–51049** range (see `app.json`, `idRanges`).
- German-language code comments deliberately document deviations from the migrated legacy NAV system and open TODOs — please keep this style when making changes.
- Completed, functional changes are documented as an OpenSpec change (`openspec/changes/`, archived under `openspec/changes/archive/` once finished) and captured as a durable spec under `openspec/specs/`.
- Translations: `.g.xlf` is generated by the compiler and must **not** be edited manually; maintain translations only in `Translations/SL Chronext Webshop.de-DE.xlf`.

## Known Limitations

- **Codeunit 51000 "SL Export Gateway Sales Price" no longer exists** — it was deliberately removed as unnecessary. This removes the integration that would have automatically pushed approved prices to an external system. The reference to it in Page 51001 has been fully removed; the project compiles without it.
- **The "Upload Sales Price" action** in Page 51001 is fully commented out in code (a placeholder for future rework). As a result, approved prices are currently **not** automatically transferred into the standard "Sales Price" table or into "SL Sales Price Archive".
- **The `"Differential Taxation Purchase"` field** on the standard "Item Ledger Entry" table was used in the migrated NAV source system but was never delivered/migrated. The corresponding branch in `fnValidate` (Page 51001) is disabled and always uses the standard branch (see the code comment).
- **`Reason Code` as an enum with no true blank value**: the original NAV logic checked for an empty reason code; the current enum always has a default value (`CatMan`). This business question is still open (see the TODO in Page 51001, action "Approve").
- **The file-based import/export component (Codeunit 51001, Tables 51004–51006)** is fully implemented but not wired into any live process or scheduled anywhere (no job queue entry).
- **No automated tests** exist.
- **No permission sets** have been created for this extension's objects — add a `PermissionSet`/`PermissionSetExtension` before a production rollout.
