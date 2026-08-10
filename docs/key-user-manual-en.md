# Key User Manual – CHX.Webshop

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries and currencies for price generation, configure the SellWatch interface, and act as the first point of contact for the business department.

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

## Setting up the SellWatch interface

The check that decides whether a purchased watch may go live online ("Watch Online Approval") uses the **same** interface management as the price export (the "API Interface Setup" page, see above). Create a dedicated entry there with **Code = `WOA`**:

| Field | Value for SellWatch |
|---|---|
| Code | `WOA` (fixed value — this is the exact code the code looks up) |
| Endpoint URL | Base URL of the SellWatch check API (the path `/<item no.>/<variant code>/check` is appended automatically). |
| API Key | The API key provided by SellWatch. |
| Active | Must be enabled, otherwise the online-approval check is silently skipped. |

> **Important:** Unlike the price export, the **"Auth Type"** field is not evaluated for this entry — for SellWatch the API key is always sent as an `X-API-KEY` header, regardless of the selected authentication type. It's enough to maintain "Code", "Endpoint URL", "API Key", and "Active".

Without this entry (or if it's inactive or has no API key), the online-approval check aborts silently — the watch in question is simply left unchanged.

**Every call that is actually made** (successful or failed) is logged on the **"SW Http Call Log"** page — request and response can be downloaded as .txt files per entry there. The API key never appears in plain text (only as a placeholder). Failed calls are additionally reported via telemetry (for the development team, see the Developer Manual).

## Reason Code

Every price change can be tagged with a reason: **CatMan**, **Purchasing**, or **Marketing**. This supports traceability of why a price changed but is not currently evaluated further by any automated logic. "CatMan" is used as the default value when none is explicitly selected.

## Workflows and processes

The standard flow for the business department is: **Import → Validate → Approve → (optional) Add all Currencies → Upload Sales Price**. As a key user you are responsible for the framework (base settings, currency activation, API interface), not the day-to-day operation itself (see User Manual).

## Data management

- **Sales Price / Archive**: Every time "Upload Sales Price" runs, the approved price line is automatically written into the live sales price table (always valid for all customers) and stored as a new, sequentially numbered version in "Sales Price Archive" — including when an already-transmitted line is resent. These two tables are not meant to be maintained manually.
- **File-based import**: A prepared but not yet connected component exists for automated, file-based price import. It is currently not part of the live process (no job queue entry).

## Permissions

Access is controlled through two separate permission sets, which still need to be assigned to the relevant users or user groups:

| Permission Set | Covers |
|---|---|
| `SLChronWSAll` | All sales price management objects |
| `SWChronWSAll` | All SellWatch purchase integration objects (SellWatch Vendor Info, Watch Online Approval, SW Http Call Log, SellWatch-Overview, SellWatch info) |

## Troubleshooting

| Problem | Cause / Solution |
|---|---|
| "Import CSV" cannot be run | Base settings (Minimum Margin %, Stock Price Threshold %) are not filled in, or the list still contains price lines from a previous run. |
| "Add all Currencies" produces no line for a specific currency | Check that "Sales Price Activated" is enabled for that currency on the "Currencies" page. |
| A user cannot open the extension's pages | Check whether the user has been assigned the right permission set ("SLChronWSAll" for price management, "SWChronWSAll" for SellWatch). |
| A price isn't calculated with margin X% despite correct input | The category-based non-stock price calculation is not currently wired into the live flow — escalate to the development team if this feature is needed. |
| "Upload Sales Price" reports that no API interface is configured, or aborts | Check on the base settings that "Price Export Active" is enabled and an "API Interface Code" is selected, and that the corresponding interface under "API Interface Setup" is active and fully configured (Endpoint URL, API Key if required). |
| Individual price lines are left with "Export Status" = "Error" after "Upload Sales Price" | Other lines in the same run are still processed. Check the affected line for invalid values (e.g. a currency code that doesn't exist) and trigger the upload for that line again. |
| A watch never gets approved for online sale even though it should be | First open the **"SW Http Call Log"** page and filter for entries related to the affected watch ("Source Entry No" column = the watch's entry number on "Watch Online Approval"): if there's an entry with "Success" = No, the "Error Message" and the downloadable request/response show the exact cause (e.g. network error, wrong HTTP status). If there's **no** entry at all for the affected watch, the call was never made — then check the API interface entry with Code "WOA" (see above): does it exist, is it active, and are the API key and Endpoint URL set? This configuration check still aborts without a log entry if the interface is missing/inactive. |
| New SellWatch requests never show up in "SellWatch-Overview", or a vendor/order is never created automatically | Processing (vendor/order creation) currently has to be triggered separately — no automatic job queue entry exists for it. Escalate to the development team (see Developer Manual, "Known Limitations"). |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
