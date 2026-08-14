# Key User Manual – SL Chronext Webshop (Sales Price Management, SellWatch & Workshop Authenticity Check)

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries and currencies for price generation, configure the external interface used by the SellWatch online check, set up the workshop connection for the authenticity check, and act as the first point of contact for the business department. It covers three functionally independent parts of the extension: sales price management, SellWatch (used-watch purchase requests), and the Workshop authenticity check (external authenticity verification of purchased watches).

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

For the Workshop authenticity check, the business department only triggers the first step itself (the "Send to Workshop" action on the purchase order, see User Manual); the actual check by the workshop and the subsequent goods-receipt posting or cancellation run automatically via the external Workshop API and a job queue entry. As a key user you set up the OAuth2 connection for the workshop, the job queue entry, and the item attribute mapping (see below), and you are the first point of contact if a Workshop line stays stuck on status "Error".

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

## Setting up the Workshop authenticity check

The workshop checks purchased watches externally for authenticity and reports the result back via its own bidirectional API. Three one-time setup steps are needed after initial installation of the extension:

### 1. OAuth2 S2S (Entra) for the Workshop API

The custom API (endpoint pattern `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`) uses standard BC API authentication — no custom auth logic:

1. Create an app registration for the workshop service in Microsoft Entra ID (client credentials flow, no interactive login).
2. Grant the app registration access to the Business Central API (Business Central Admin Center → API access, or the Azure AD app permission "Dynamics 365 Business Central").
3. In Business Central, create a dedicated user for the workshop service and assign it **only** the **"CXW Workshop API"** permission set (no access to Purchase Line, Item, or other tables).
4. Hand the Client ID, Client Secret, and Tenant ID to the workshop service operator.

### 2. Setting up the job queue entry for processing

Codeunit **"CXW Process Workshop Lines"** processes all Workshop lines with status "WS checked" (posting the goods receipt or cancelling the order):

1. Job Queue Entries → New.
2. Object Type: Codeunit, Object: "CXW Process Workshop Lines".
3. Recommended recurrence: every 5 minutes.
4. The executing user needs the **"CXW Workshop All"** permission set plus the standard purchasing/inventory permissions needed for posting the goods receipt and maintaining item attributes.

### 3. Item attributes — meaning of the attribute fields

The workshop reports back up to ten attributes per watch. Eight of them have a defined business meaning and are automatically written to the item as standard item attributes once authenticity is confirmed:

| Attribute no. | Meaning |
|---|---|
| 1 | Dial Color |
| 2 | Case Diameter |
| 3 | Bracelet Material |
| 4 | Case Material |
| 5 | Movement |
| 6 | Gender |
| 7 | Crystal |
| 8 | Features |
| 9–10 | Not yet assigned a business meaning (placeholder) |

> Missing standard item attributes are created automatically as needed (type Text) — no manual pre-setup required.

## Status and error handling of Workshop lines

A Workshop line moves through the statuses **New → WS checked → Processed**. If automatic processing fails (e.g. a closed posting period, missing location), the line instead moves to status **Error**, and the error text is recorded in the "Last Error" field on the line (visible on the "CXW Workshop Lines" page).

**Manually retrying a failed line:** After fixing the underlying cause (e.g. reopening the posting period), manually reset the affected line's status back to "WS checked" (e.g. via the table test window or a suitable page with edit rights). The line is automatically reprocessed on the next job queue run; on success, "Last Error" is cleared automatically.

> A direct change to status "Error" from any status other than "WS checked" (e.g. accidentally via the API) is rejected by the system with an error — this status is set exclusively by the automatic processing itself.

## Data management

- **Sales Price / Archive**: Every time "Upload Sales Price" runs, the approved price line is automatically written into the live sales price table (always valid for all customers) and stored as a new, sequentially numbered version in "Sales Price Archive" — including when an already-transmitted line is resent. These two tables are not meant to be maintained manually.
- **File-based import**: A prepared but not yet connected component exists for automated, file-based price import. It is currently not part of the live process (no job queue entry).
- **SellWatch purchase requests**: The tables behind "SellWatch-Overview" and the online-check log ("Http Call Log") are populated exclusively by automation; manual maintenance is not intended and isn't possible via the extension's pages either (all SellWatch pages are read-only).
- **Workshop lines**: Created or changed exclusively via the "Send to Workshop" action (business department) and the external Workshop API. The internal overview page "CXW Workshop Lines" is read-only. An already-processed Workshop line (status "Processed") remains as an audit record even if the associated purchase order is cancelled (deleted).

## Permissions

Access to all sales price management objects is controlled through the **"CXWChronWSAll"** permission set (since the HTTP-logging update, also covers the "Http Call Log" page shared with SellWatch). SellWatch has its own **"CXW SWChronWSAll"** permission set (covers "SellWatch-Overview", "SellWatch info", and the likewise-shared "Http Call Log" page, plus the underlying tables). The Workshop authenticity check has two separate permission sets: **"CXW Workshop All"** for full internal access (e.g. for the job queue execution user), and **"CXW Workshop API"** exclusively for the external workshop service user (read/modify access to Workshop lines only, no access to the purchase document or item). All sets still need to be assigned to the relevant users or user groups before they can use the respective extension pages.

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
| A workshop user cannot access the API | Check the OAuth2 app registration in Entra ID, and whether the dedicated workshop user in BC has been assigned exactly the "CXW Workshop API" permission set. |
| Workshop lines aren't processed, staying stuck on "WS checked" | Check whether the job queue entry for Codeunit "CXW Process Workshop Lines" exists, is active, and isn't erroring, and whether the executing user has the "CXW Workshop All" permission set. |
| A Workshop line shows status "Error" | Check the error text in the "Last Error" field on the "CXW Workshop Lines" page. After fixing the cause (e.g. reopening the posting period), manually reset the status back to "WS checked" — the line is automatically reprocessed on the next job queue run. |
| Trying to set a Workshop line directly to status "Error" fails | This is intentional: status "Error" can only be set from "WS checked", and only by the automatic processing itself. |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
