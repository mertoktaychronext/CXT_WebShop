# Key User Manual – SL Chronext Webshop (Sales Price Management & SellWatch)

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries and currencies for price generation, configure the external interface used by the SellWatch online check, and act as the first point of contact for the business department. It covers both functionally independent parts of the extension: sales price management and SellWatch (used-watch purchase requests).

## Base settings (General Sales Price Setup)

The **"General Sales Price Setup"** page holds the rules every imported price is checked against:

| Setting | Meaning |
|---|---|
| Minimum Margin % | Prices with a lower margin are flagged with a remark during "Validate" (note: in the webshop display itself, an item is deactivated if it falls below the margin — see the field's tooltip). |
| Stock Price Threshold % | The percentage price increase (vs. the last price) above which a remark is generated. |
| Non Stock Price Threshold % | Same idea for non-stock items (currently not actively used, see Developer Manual). |
| Cat 1–3 Non Stock % / Stock Price From/To | Prepared for automatic calculation of the non-stock price per price category. This calculation is not currently wired into the live approval flow. |
| Price Export Active | Must be enabled for the "Upload Sales Price" action (User Manual) to be able to send prices to an external system. |
| API Interface Code | Selects which of the interfaces configured under "API Interface Setup" is used for the price export. |

These settings **must** be filled in (Minimum Margin %, Stock Price Threshold %), otherwise import, validation, and approval cannot be run. "Upload Sales Price" additionally requires "Price Export Active" and "API Interface Code" to be set.

## Setting up an external interface (API Interface Setup)

The **"API Interface Setup"** navigation button on the "General Sales Price Setup" page opens the management of the external interfaces prices can be sent to:

| Field | Meaning |
|---|---|
| Code | Unique interface code — selected in the "API Interface Code" field on the base settings. |
| Description | Free-text description of the interface. |
| Endpoint URL | The target URL the price data is sent to via HTTP. Required once the interface is activated. |
| Auth Type | Authentication method: None, API Key (Header), or Basic Authentication. |
| API Key | The API key or token used for authentication. Stored encrypted and no longer shown in plain text after saving. Required once an authentication type other than "None" is selected. |
| Source Table No. | The table this interface transmits data for (for the price export: the table number of "Sales Price"). |
| Active | Must be enabled for the interface to be selectable on the base settings. Activating it automatically checks that the Endpoint URL and — if needed — the API Key are set. |

> Without an active, fully configured interface, "Upload Sales Price" fails, or marks the affected price lines with "Export Status" = "Error".

## Activating currencies for "Add all Currencies"

The following field was added to the **Currency** master data (the "Currencies" page):

| Field | Meaning |
|---|---|
| Sales Price Activated | Must be enabled for this currency to receive an automatically generated price line when "Add all Currencies" is run. |

> A currency without "Sales Price Activated" is ignored by "Add all Currencies".

## Country/Region – additional fields

The following fields were added to the **Country/Region** master data (the "Countries/Regions" page):

| Field | Meaning |
|---|---|
| Sales Price Currency Code | The standard foreign currency for this country. Informational only. |
| Taxation Type | Full, differential, or both — currently informational only, with no automatic effect on price calculation. |
| Delivery Time (Days) | Informational field, currently with no automatic effect on price checking. |

> **Important:** Activation for "Add all Currencies" now happens directly on the **currency**, not on the country. A country without a "Sales Price Currency Code" can still receive prices as long as the relevant currency itself is activated.

## Reason Code

Every price change can be tagged with a reason: **CatMan**, **Purchasing**, or **Marketing**. This supports traceability of why a price changed but is not currently evaluated further by any automated logic. "CatMan" is used as the default value when none is explicitly selected.

## Workflows and processes

The standard flow for the business department is: **Import → Validate → Approve → (optional) Add all Currencies → Upload Sales Price**. As a key user you are responsible for the framework (base settings, currency activation, API interface), not the day-to-day operation itself (see User Manual).

For SellWatch there is no flow the business department triggers manually: new purchase requests (seller, watch, and offer data) arrive automatically and are automatically turned into a vendor and a purchase order; the business department only ever sees the result, read-only, on the "SellWatch-Overview" page (see User Manual). As a key user you are responsible here for configuring the online-check interface (see below) and for assigning permissions.

## SellWatch – Setting up the online-check interface (API Interface Setup)

The SellWatch online check (verifies whether a watch should be visible in the SellWatch online shop) uses the same **"API Interface Setup"** page as sales price management's price export (see above) — but always the fixed interface code **`WOA`**. Create or maintain an entry with code `WOA` there:

| Field | Meaning for SellWatch |
|---|---|
| Code | Must be exactly `WOA` — this code is hard-coded in the SellWatch code and cannot be changed. |
| Endpoint URL | Base URL of the SellWatch online-check endpoint. The actual request is sent to `<Endpoint URL>/<item no.>/<variant code>/check`. |
| API Key | Sent as the `X-API-KEY` HTTP header, stored encrypted. |
| Active | Must be enabled, otherwise the online check makes no call. |

> Unlike sales price management's price export, there is no field in the base settings to select the interface code for the online check — the code `WOA` is hard-coded.

> You can trace failed calls on the **"Http Call Log"** page: it shows success/failure, HTTP status code, and error message for every call, and lets you download the sent request and the received response as text files (the API key is not shown in plain text in the stored request). Since the 2026-08-10 HTTP-logging update, this page also logs sales price export calls (see below) — the "Source Table No." column shows which area produced the entry.

## SellWatch – Setting up the item template for automatic item creation

When a SellWatch purchase request arrives, the system automatically creates a new item. Which item template is used for that is set on the **"Purchases & Payables Setup"** page, in the new "SellWatch" section, field **"SellWatch Item Template"**:

1. Open the "Purchases & Payables Setup" page.
2. In the "SellWatch" section, set the "SellWatch Item Template" field to the desired item template (the lookup shows all existing item templates).

> If this field is left empty, the next automatic SellWatch item creation aborts with an error message instead of using an arbitrary item template as before. If a configured item template is later deleted, a separate, distinguishable error message appears.

## Data management

- **Sales Price / Archive**: Every time "Upload Sales Price" runs, the approved price line is automatically written into the live sales price table (always valid for all customers) and stored as a new, sequentially numbered version in "Sales Price Archive" — including when an already-transmitted line is resent. These two tables are not meant to be maintained manually.
- **File-based import**: A prepared but not yet connected component exists for automated, file-based price import. It is currently not part of the live process (no job queue entry).
- **SellWatch purchase requests**: The tables behind "SellWatch-Overview" and the online-check log ("Http Call Log") are populated exclusively by automation; manual maintenance is not intended and isn't possible via the extension's pages either (all SellWatch pages are read-only).

## Permissions

Access to all sales price management objects is controlled through the **"CXWChronWSAll"** permission set (since the HTTP-logging update, also covers the "Http Call Log" page shared with SellWatch). SellWatch has its own **"CXW SWChronWSAll"** permission set (covers "SellWatch-Overview", "SellWatch info", and the likewise-shared "Http Call Log" page, plus the underlying tables; since the item template setup, also read access to "Purchases & Payables Setup"). Both sets still need to be assigned to the relevant users or user groups before they can use the respective extension pages.

## Troubleshooting

| Problem | Cause / Solution |
|---|---|
| "Import CSV" cannot be run | Base settings (Minimum Margin %, Stock Price Threshold %) are not filled in, or the list still contains price lines from a previous run. |
| "Add all Currencies" produces no line for a specific currency | Check that "Sales Price Activated" is enabled for that currency on the "Currencies" page. |
| A user cannot open the sales price management pages | Check whether the user has been assigned the "CXWChronWSAll" permission set. |
| A price isn't calculated with margin X% despite correct input | The category-based non-stock price calculation is not currently wired into the live flow — escalate to the development team if this feature is needed. |
| "Upload Sales Price" reports that no API interface is configured, or aborts | Check on the base settings that "Price Export Active" is enabled and an "API Interface Code" is selected, and that the corresponding interface under "API Interface Setup" is active and fully configured (Endpoint URL, API Key if required). Details on the specific failure (status code, error message) are on the "Http Call Log" page. |
| Individual price lines are left with "Export Status" = "Error" after "Upload Sales Price" | Other lines in the same run are still processed. Check the affected line for invalid values (e.g. a currency code that doesn't exist) and trigger the upload for that line again. |
| A user cannot open the SellWatch pages | Check whether the user has been assigned the "CXW SWChronWSAll" permission set. |
| A watch on "SellWatch-Overview" is never marked online, or "Http Call Log" shows failures | Check that an entry with code `WOA` exists under "API Interface Setup", is active, and has the Endpoint URL and API Key set. Details on the specific failure (status code, error message) are on the "Http Call Log" page. |
| No vendor/order is created for a SellWatch request | Creation happens fully automatically in the background; there is no action you can trigger manually as a key user. First check whether the request actually arrived completely, then escalate to the development team if not. |
| No item is created for a SellWatch request, error message about the item template | On the "Purchases & Payables Setup" page, "SellWatch" section, check that the "SellWatch Item Template" field is set to a valid, still-existing item template. |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
