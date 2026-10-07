# Key User Manual – SL Chronext Webshop (Sales Price Management, SellWatch, Workshop Authenticity Check & Consignment Sales)

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries and currencies for price generation, configure the external interface used by the SellWatch online check, set up the workshop connection for the authenticity check, set up the delayed purchase invoicing for consignment sales, and act as the first point of contact for the business department. It covers four functionally independent parts of the extension: sales price management, SellWatch (used-watch purchase requests), the Workshop authenticity check (external authenticity verification of purchased watches), and Consignment Sales (delayed, automatic purchase invoicing for watches sold on consignment).

## Base settings (General Sales Price Setup)

The **"General Sales Price Setup"** page holds the rules every imported price is checked against:

| Setting | Meaning |
|---|---|
| Minimum Margin % | Prices with a lower margin are flagged with a remark during "Validate" (note: in the webshop display itself, an item is deactivated if it falls below the margin — see the field's tooltip). |
| Stock Price Threshold % | The percentage price increase (vs. the last price) above which a remark is generated. |
| Non Stock Price Threshold % | Same idea for non-stock items (currently not actively used, see Developer Manual). |
| Cat 1–3 Non Stock % / Stock Price From/To | Prepared for automatic calculation of the non-stock price per price category. This calculation is not currently wired into the live approval flow. |
| Price Export Active | Must be enabled for the "Release Sales Prices" action (User Manual) to queue prices and for the sales price export job to send them to an external system. When disabled, the job leaves queued prices untouched. |
| API Interface Code | Selects which of the interfaces configured under "API Interface Setup" is used for the price export. |
| Max. Export Attempts | How often the sales price export job resends a failed price (default 3). After that the entry stays on "Error" until you requeue it manually (see below). |
| Archive Country Code | Only price lines of this country are archived in "Sales Price Archive" (default **DE**). The prices of all countries are kept in "Sales Price Export Entries" regardless. |

These settings **must** be filled in (Minimum Margin %, Stock Price Threshold %), otherwise import, validation, and approval cannot be run. "Release Sales Prices" additionally requires "Price Export Active", "API Interface Code" and "Archive Country Code" to be set.

> **After updating to version 27.0.0.6:** "Archive Country Code" is blank on the existing setup record. Enter **DE**, otherwise "Release Sales Prices" stops with a message.

## Setting up an external interface (API Interface Setup)

The **"API Interface Setup"** navigation button on the "General Sales Price Setup" page opens the management of the external interfaces prices can be sent to:

| Field | Meaning |
|---|---|
| Code | Unique interface code — selected in the "API Interface Code" field on the base settings. |
| Description | Free-text description of the interface. |
| Endpoint URL | The target URL the price data is sent to via HTTP. Required once the interface is activated. |
| HTTP Method | HTTP method for the call: POST, PATCH, PUT, GET, or DELETE. No request body is sent for GET/DELETE. |
| SOAP Action | Value for the `SOAPAction` header. Leave blank to omit the header. |
| Auth Type | Authentication method: **None**, **API Key (Header)**, **Basic Authentication**, or **AWS Signature V4**. The detail card shows the relevant input fields based on the selection. |
| API Key | The API key or token used for authentication (for "API Key (Header)" / "Basic Authentication"; for "AWS Signature V4" optionally as an additional `X-API-Key` header). Stored encrypted in isolated storage and no longer shown in plain text after saving. Required for "API Key (Header)" and "Basic Authentication". |
| AWS Access Key ID / AWS Region / AWS Service | Only for Auth Type = "AWS Signature V4": plain-text values for request signing (service typically `execute-api` for API Gateway). |
| AWS Secret Access Key / AWS Session Token | Only for Auth Type = "AWS Signature V4": stored encrypted in isolated storage. Secret Access Key is required; Session Token only for temporary/STS credentials. |
| Source Table No. | The table this interface transmits data for (for the price export: the table number of "Sales Price"). |
| Active | Must be enabled for the interface to be selectable on the base settings. Activating it automatically checks that the Endpoint URL and — depending on the Auth Type — the API Key or the AWS fields are fully set. |

> Without an active, fully configured interface, transmission by the sales price export job fails; the affected entries go to "Error" and are resent up to the maximum number of attempts.

## Setting up the sales price export job (job queue)

Since version 27.0.0.6, released prices are no longer sent by the action on the price checking list but by a job in the job queue. Create a **job queue entry** once:

| Field | Value |
|---|---|
| Object Type to Run | Codeunit |
| Object ID to Run | **60332** ("CXW Export Sales Price Job") |
| Recurring Job | Yes, e.g. every 5–15 minutes |
| Status | Ready |

The user running the job needs the permission set "CXWChronWSAll".

**How it works:** "Release Sales Prices" creates, per country line, one entry in **"Sales Price Export Entries"** (the price of that country) and one entry in **"Data Export Entries"** with destination code `SALESPRICE` and status **"Pending (Sales Price)"**. The job sends all pending entries plus failed entries whose attempt count is below "Max. Export Attempts". A failure on one price does not hold up the others, and the job itself keeps running even if single prices fail.

**Requeue manually:** Once an entry has reached the maximum number of attempts, it stays on "Error". Fix the cause (error message on the entry or on "Http Call Log"), select the entry on "Data Export Entries" and run **"Requeue Sales Price"**. The entry is resent with unchanged data on the next job run. If the price data should be regenerated instead, release the price line again.

## Activating countries for "Add all Countries"

The following fields were added to the **Country/Region** master data (the "Countries/Regions" page):

| Field | Meaning |
|---|---|
| Sales Price Activated | Must be enabled for this country to receive an automatically generated price line when "Add all Countries" is run. |
| Sales Price Currency Code | Currency in which the price line for this country is generated. Blank = local currency (e.g. EUR). |

> A country without "Sales Price Activated" is ignored by "Add all Countries". Every activated country receives its own line — even if several countries share the same currency (e.g. DE, AT, FR in EUR).

> **DE must be activated.** Since version 27.0.0.6 the imported base line without a country is neither written to the sales prices nor transmitted. Without an activated DE line there is therefore no EUR price and no archive entry.

> **Switch from currency to country activation:** Until "Add all Countries" was introduced, activation happened through the "Sales Price Activated" field on the **currency** (action "Add all Currencies"). That field has been removed. Before the update, note which currencies were activated, and afterwards set up the corresponding countries with a Sales Price Currency Code.
## Reason Code

Every price change can be tagged with a reason: **CatMan**, **Purchasing**, or **Marketing**. This supports traceability of why a price changed but is not currently evaluated further by any automated logic. "CatMan" is used as the default value when none is explicitly selected.

## Workflows and processes

The standard flow for the business department is: **Import → Validate → Approve → Add all Countries → Release Sales Prices**; the sales price export job then takes care of the transmission. As a key user you are responsible for the framework (base settings, country activation, API interface, job queue entry), not the day-to-day operation itself (see User Manual).

For SellWatch there is no flow the business department triggers manually: new purchase requests (seller, watch, and offer data) arrive automatically and are automatically turned into a vendor and a purchase order; the business department only ever sees the result, read-only, on the "SellWatch-Overview" page (see User Manual). As a key user you are responsible here for configuring the online-check interface (see below) and for assigning permissions.

For the Workshop authenticity check, the business department only triggers the first step itself (the "Send to Workshop" action on the purchase order, see User Manual); the actual check by the workshop and the subsequent goods-receipt posting or cancellation run automatically via the external Workshop API and a job queue entry. As a key user you set up the OAuth2 connection for the workshop, the job queue entry, and the item attribute mapping (see below), and you are the first point of contact if a Workshop line stays stuck on status "Error".

For Consignment Sales there is likewise no flow the business department triggers manually: as soon as a sales invoice for a consignment item is posted, a consignment posting entry is created automatically, and a job queue entry posts the related purchase invoice automatically once the configured delay has elapsed. As a key user you set up the delay in days and the job queue entry (see below), and you are the first point of contact if a consignment posting entry stays stuck on status "Error".

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

> Every queued sales price line appears on the **"Data Export Entries"** page (the same page the availability export uses), identified by the destination code `SALESPRICE`. It shows the status (Pending (Sales Price)/Processed/Error), attempt count, file name, error message and, in the FactBox, the JSON that was sent. **Important:** failed price transmissions are retried automatically by the sales price export job; once the maximum is reached, use **"Requeue Sales Price"**, **not** the "Export Data" action — that action cannot send price entries but uses up an attempt.

## SellWatch – Setting up item templates

For every incoming SellWatch offer, Business Central automatically creates a new item. Which item template is used depends on the offer type. You set up both templates on the **"Purchases & Payables Setup"** page in the "SellWatch" section:

| Field | Meaning |
|---|---|
| SellWatch Item Template (Standard) | Template for all offer types except commission (e.g. purchase, exchange). |
| SellWatch Item Template (Commission) | Template for offers with offer type commission. The item is also automatically flagged as consignment goods. |

The new item takes over all values maintained on the template (e.g. posting groups, base unit of measure, item category) as well as the template's **default dimensions**. Description (brand, model, construction year) and Description 2 (reference) always come from the SellWatch offer.

In addition, the system fills the watch data of the offer into **item attributes**: brand → Marke (1), model → Modell (2), reference → Referenz (5), construction year → Jahr (8), condition → Zustand (10), box available → Box (11, "ja"/"nein"), taxation → Besteuerung (12), papers available → Zertifikat (13, "ja"/"nein"), gender → Geschlecht (24). Empty values are skipped, as is a construction year that is not a whole number (e.g. "ca. 2015") — the offer is still created. If a value is not yet in the attribute's value list (e.g. a new model), it is added there. These attributes later appear as master data on the workshop line.

**Item numbers:** If a series is set in the template's **"No. Series"** field, the item gets its number from that series — this lets commission and standard items have their own number ranges. If none is set, the item number series from the inventory setup applies. The series must allow default numbers.

> **Important:** Both fields must be filled in before SellWatch processing runs. If the commission template is missing, processing does **not** fall back to the standard template — the offer stays unprocessed with an error message. Tip: test each template once via "Items → New" by selecting the template; if an item can be created there, it will also work for SellWatch.

> **Serial number tracking is mandatory:** Every SellWatch item is created with serial number tracking. Set up an **item tracking code** with serial number tracking for purchases on **both** templates. If it is missing or does not track serial numbers, no item is created and the offer stays open with an error message. Recommended: also maintain the **Serial Nos.** on the templates; without them, "Send to Workshop" cannot assign a serial number automatically later.

## SellWatch – Errors during automatic processing

Background processing handles each SellWatch offer on its own. If an offer fails (e.g. because an item template is missing or a setup is incomplete), the following happens:

- **Nothing** is created for that offer — no vendor, no purchase order, no item. All other offers are processed as usual.
- On the **SellWatch Overview**, the row is highlighted in red; the columns **"Last Error"** and **"Last Error Date/Time"** show what went wrong and when.
- The offer stays open and is **retried automatically on the next run**. You only need to fix the cause — nothing needs to be done on the offer itself. Once processed successfully, the error columns are empty again.

> **Tip:** On the SellWatch Overview, filter "Last Error" to not blank (`<>''`) to see all open problem cases at a glance. The job queue entry itself finishes successfully even when individual offers fail — so check for errors on the overview.

## Setting up the Workshop authenticity check

The workshop checks purchased watches externally for authenticity and reports the result back via its own bidirectional API. Three one-time setup steps are needed after initial installation of the extension:

> **Serial number prerequisite:** "Send to Workshop" identifies each watch by its BC serial number and captures the manufacturer serial number on the **Serial No. Information Card**. For a line to be sent, the item must have
> - an **item tracking code** with **SN purchase inbound tracking**, and
> - a **serial no. series** (item card, field "Serial Nos.") — the next number is drawn from it automatically if the purchase line has no serial number yet.
>
> For SellWatch items, the easiest way is to set both up in the **SellWatch item templates**. Which details are mandatory on the card (manufacturer serial no., box, papers) is controlled by the flags on the item tracking code from CHX.Base. Lines with a quantity other than 1 are not supported.

### 1. OAuth2 S2S (Entra) for the Workshop API

The custom API (endpoint pattern `.../api/saliniLife/workshop/v1.0/companies({companyId})/workshopLines`) uses standard BC API authentication — no custom auth logic:

1. Create an app registration for the workshop service in Microsoft Entra ID (client credentials flow, no interactive login).
2. Grant the app registration access to the Business Central API (Business Central Admin Center → API access, or the Azure AD app permission "Dynamics 365 Business Central").
3. In Business Central, create a dedicated user for the workshop service and assign it **only** the **"CXW Workshop API"** permission set (apart from read access to the purchases & payables setup, no access to Purchase Line, Item, or other tables).
4. Hand the Client ID, Client Secret, and Tenant ID to the workshop service operator.

> **Which data the workshop receives (from version 27.0.0.7):** Besides item and serial number, the API returns vendor, vendor order no., variant, description, quantity, unit cost, currency (`seller_currency`; the local currency for orders without a currency) and used-goods flag of the purchase order as well as, from the item's **item attributes**: brand (attribute ID 1), model (2), sub model (3), reference (5), year (8, as a number), condition (10), box (11) and certificate (13). The values are taken over when "Send to Workshop" is clicked — later changes to the order or the item do not reach the workshop. Therefore maintain the item attributes **before** "Send to Workshop"; if they are missing, the workshop receives empty values (year = 0). For condition the workshop expects the values **NEW, AAA, AA, A, VINT**, for box and certificate "ja"/"nein". If the year is not a plain number (e.g. a range), 0 is sent.

> **Tenant identifier (`tenant`):** On the **Purchases & Payables Setup** (group "Workshop"), enter **GmbH** in the field **"Workshop Tenant"**. The API returns it with every request. For this, the workshop user additionally has read access to the purchases & payables setup; purchase orders, vendors and items remain blocked for them. Users running "Send to Workshop" need the "CXW Workshop All" permission set.

### 2. Setting up the job queue entry for processing

Codeunit **"CXW Process Workshop Lines"** processes all Workshop lines with status "WS checked" (posting the goods receipt or cancelling the order):

1. Job Queue Entries → New.
2. Object Type: Codeunit, Object: "CXW Process Workshop Lines".
3. Recommended recurrence: every 5 minutes.
4. The executing user needs the **"CXW Workshop All"** permission set plus the standard purchasing/inventory permissions needed for posting the goods receipt and maintaining item attributes.

### 3. Item attributes — meaning of the attribute fields

The workshop reports back up to ten check attributes per watch. Seven of them are mapped to an existing item attribute (by attribute ID) and are automatically written to the item once authenticity is confirmed:

| Field on the workshop line | Item attribute (ID) |
|---|---|
| Dial Color | Zifferblatt Farbe 1 (22) |
| Case Diameter | Gehäuse Größe (18) — a number, e.g. "41" |
| Bracelet Material | Armband Material (23) |
| Case Material | Gehäuse Material (16) |
| Movement | Werk (15) |
| Gender | Geschlecht (24) |
| Crystal | Glas (20) |
| Features, Attribut 9, Attribut 10 | no attribute yet (placeholders) — neither prefilled nor written back |

> **No new item attributes** are created. If the workshop reports a value that is not yet in the attribute's value list, it is added there as a new value. A non-numeric value for "Gehäuse Größe" (e.g. "41 mm") sets the line to status **Error**.

> **Prefill:** On "Send to Workshop", the seven mapped fields are prefilled with the current values of these attributes; if the item has no value, the field stays empty. The workshop checks the values and corrects them if needed; on processing, the values are written back to the same attribute. A field cleared by the workshop does not remove the value from the item.

> **Where the attribute values come from:** For items created from a SellWatch offer, the system fills Marke (1), Modell (2), Referenz (5), Jahr (8), Zustand (10), Box (11), Besteuerung (12), Zertifikat (13) and Geschlecht (24) automatically from the offer (see SellWatch). For manually created items, the attributes must be maintained manually before "Send to Workshop".

## Status and error handling of Workshop lines

A Workshop line moves through the statuses **New → WS checked → Processed**. If automatic processing fails (e.g. a closed posting period, missing location), the line instead moves to status **Error**, and the error text is recorded in the "Last Error" field on the line (visible on the "CXW Workshop Lines" page).

**Manually retrying a failed line:** After fixing the underlying cause (e.g. reopening the posting period), manually reset the affected line's status back to "WS checked" (e.g. via the table test window or a suitable page with edit rights). The line is automatically reprocessed on the next job queue run; on success, "Last Error" is cleared automatically.

> A direct change to status "Error" from any status other than "WS checked" (e.g. accidentally via the API) is rejected by the system with an error — this status is set exclusively by the automatic processing itself.

## Setting up Consignment Sales

When an item flagged as consignment stock is sold via a sales invoice, the related purchase invoice should not be posted immediately, but automatically after a defined number of days. Two one-time setup steps are needed after initial installation of the extension:

### 1. Set the delay in days

On the **"Purchases & Payables Setup"** page, in the "SellWatch" section, you'll find:

| Field | Meaning |
|---|---|
| Consignment Invoice Delay (Days) | Number of days between posting the sales invoice and automatically posting the related purchase invoice. 0 means: on the next background processing run, with no additional wait. |

> If this field is blank (0), the purchase invoice is posted on the next background processing run without any delay.

### 2. Set up the job queue entry for processing

Codeunit **"CXW Post Consignment Purchases"** automatically posts all due consignment posting entries (status "Open", due date reached) as a purchase invoice:

1. Job Queue Entries → New.
2. Object Type: Codeunit, Object: "CXW Post Consignment Purchases".
3. Recommended recurrence: daily.
4. The executing user needs the **"CXW Workshop All"** permission set (also covers Consignment Sales since this update) plus the standard purchasing permissions needed for invoice posting.

## Status and error handling of consignment posting entries

The **"CXW Cons. Posting Entries"** page shows all consignment posting entries with the item, the resolved purchase order, the triggering sales invoice, the due date, the status, and — on failure — an error text. An entry moves through the statuses **Open → Posted**, or on failure **Open → Error**.

An entry shows status "Error" when either
- **no matching open purchase order, or more than one, was found** for the sold item (the error text names the item number), or
- **posting the purchase invoice itself failed** (e.g. a closed posting period) — the error text contains the specific error message.

**Retrying a failed entry:** Select the affected entry (or several) on the "CXW Cons. Posting Entries" page and run the **"Retry"** action. The status is reset to "Open"; the entry is automatically retried on the next background processing run — including re-resolving the matching purchase order if it wasn't found on the first attempt.

> A pure delivery without invoicing, and selling an item without the "Consignment Sales" flag, do not create an entry.

## "Hold Order" flag on sales orders

Since CHX.Webshop 27.0.0.10 the "Hold Order" field lives in the base extension **CHX.Base** (from 27.0.3.5, field "CXB Hold Order") – see the CHX.Base key user manual. Values from CHX.Webshop 27.0.0.8/27.0.0.9 were not migrated.

## Data management

- **Sales Price / Archive / Export Entries**: Every time "Release Sales Prices" runs, each approved country line is automatically written into the live sales price table (always valid for all customers) and stored as its own entry in "Sales Price Export Entries". Only the line of the archive country (DE) is additionally stored as a new, sequentially numbered version in "Sales Price Archive" — including when an already-queued line is released again. Archive entries of other countries from before version 27.0.0.6 are kept. These tables are not meant to be maintained manually; "Sales Price Export Entries" keeps growing (no retention policy is set up yet).
- **File-based import**: A prepared but not yet connected component exists for automated, file-based price import. It is currently not part of the live process (no job queue entry).
- **SellWatch purchase requests**: The tables behind "SellWatch-Overview" and the online-check log ("Http Call Log") are populated exclusively by automation; manual maintenance is not intended and isn't possible via the extension's pages either (all SellWatch pages are read-only).
- **Workshop lines**: Created or changed exclusively via the "Send to Workshop" action (business department) and the external Workshop API. The internal overview page "CXW Workshop Lines" is read-only. An already-processed Workshop line (status "Processed") remains as an audit record even if the associated purchase order is cancelled (deleted).
- **Consignment posting entries**: Created exclusively and automatically when a sales invoice is posted. The "CXW Cons. Posting Entries" overview page allows no manual editing other than the "Retry" action (status change Error → Open).

## Permissions

Access to all sales price management objects is controlled through the **"CXWChronWSAll"** permission set (since the HTTP-logging update, also covers the "Http Call Log" page shared with SellWatch). SellWatch has its own **"CXW SWChronWSAll"** permission set (covers "SellWatch-Overview", "SellWatch info", and the likewise-shared "Http Call Log" page, plus the underlying tables). The Workshop authenticity check has two separate permission sets: **"CXW Workshop All"** for full internal access (e.g. for the job queue execution user), and **"CXW Workshop API"** exclusively for the external workshop service user (read/modify access to Workshop lines only, no access to the purchase document or item). Consignment Sales does **not** have its own permission set — since this update it is covered by **"CXW Workshop All"** (including read access to sales invoices and the purchasing setup). All sets still need to be assigned to the relevant users or user groups before they can use the respective extension pages.

## Troubleshooting

| Problem | Cause / Solution |
|---|---|
| SellWatch offer is not processed; on the SellWatch Overview, "Last Error" says "No … item template is set up" or "The item template … no longer exists" | On the purchases & payables setup ("SellWatch" section), set or correct the template matching the offer type — commission → "SellWatch Item Template (Commission)", all others → "SellWatch Item Template (Standard)". The offer is processed again automatically on the next run. |
| "Last Error" says the item template has no item tracking code with serial number tracking | Set up an item tracking code with serial number tracking for purchases on the named item template. The offer is processed again automatically on the next run. |
| SellWatch offer stays open, "Last Error" shows a different message | Read the message and fix the setup it names (e.g. posting groups of the item template, payment methods `C2C`/`RG`, location `HL`). The offer is processed again automatically on the next run; other offers are not blocked. |
| "Import CSV" cannot be run | Base settings (Minimum Margin %, Stock Price Threshold %) are not filled in, or the list still contains price lines from a previous run. |
| "Add all Countries" produces no line for a specific country | Check that "Sales Price Activated" is enabled for that country on the "Countries/Regions" page. |
| A user cannot open the sales price management pages | Check whether the user has been assigned the "CXWChronWSAll" permission set. |
| A price isn't calculated with margin X% despite correct input | The category-based non-stock price calculation is not currently wired into the live flow — escalate to the development team if this feature is needed. |
| "Release Sales Prices" reports that no API interface or no archive country code is configured | Check "Price Export Active", "API Interface Code" and "Archive Country Code" on the base settings. |
| Individual price lines are left with "Export Status" = "Error" after "Release Sales Prices" | Releasing that line failed (e.g. a currency code that doesn't exist); nothing was queued. Other lines are still processed. Fix the cause and release the line again. |
| Prices stay on "Pending (Sales Price)" in "Data Export Entries" permanently | The sales price export job is not running: check the job queue entry for codeunit 60332 (exists, status "Ready", not in error) and that "Price Export Active" is enabled. |
| A `SALESPRICE` entry stays on "Error" permanently | The maximum number of attempts has been reached. Check the error message on the entry or on "Http Call Log" (interface, credentials, endpoint). After fixing it, run **"Requeue Sales Price"**. If the message says that the export record, sales price or item no longer exists, release the price line again. |
| "Export Data" on "Data Export Entries" reports an error for an entry with destination code `SALESPRICE` | This is intended: price transmissions only run through the sales price export job. Do **not** create a `SALESPRICE` entry under "Data Export API Setup". The entry goes to "Error" and the attempt count increases, but nothing is sent. If the count is still below "Max. Export Attempts", the job resends it on the next run; otherwise run "Requeue Sales Price". |
| A user cannot open the SellWatch pages | Check whether the user has been assigned the "CXW SWChronWSAll" permission set. |
| A watch on "SellWatch-Overview" is never marked online, or "Http Call Log" shows failures | Check that an entry with code `WOA` exists under "API Interface Setup", is active, and has the Endpoint URL and API Key set. Details on the specific failure (status code, error message) are on the "Http Call Log" page. |
| No vendor/order is created for a SellWatch request | Creation happens fully automatically in the background; there is no action you can trigger manually as a key user. First check whether the request actually arrived completely, then escalate to the development team if not. |
| A workshop user cannot access the API | Check the OAuth2 app registration in Entra ID, and whether the dedicated workshop user in BC has been assigned exactly the "CXW Workshop API" permission set. |
| Workshop lines aren't processed, staying stuck on "WS checked" | Check whether the job queue entry for Codeunit "CXW Process Workshop Lines" exists, is active, and isn't erroring, and whether the executing user has the "CXW Workshop All" permission set. |
| A Workshop line shows status "Error" | Check the error text in the "Last Error" field on the "CXW Workshop Lines" page. After fixing the cause (e.g. reopening the posting period), manually reset the status back to "WS checked" — the line is automatically reprocessed on the next job queue run. |
| Trying to set a Workshop line directly to status "Error" fails | This is intentional: status "Error" can only be set from "WS checked", and only by the automatic processing itself. |
| No consignment posting entry is created for a consignment sale | Check that the "Consignment Sales" flag is set on the sold item, and that the sales invoice was actually posted as an invoice (not just delivered). |
| A consignment posting entry stays stuck on status "Error" | Check the error text on the "CXW Cons. Posting Entries" page. For "no/multiple open purchase orders found": clarify the order situation for the item (e.g. was the order already cancelled or invoiced?). For a posting error message: fix the cause (e.g. reopen the posting period), then run the "Retry" action. |
| The automatic purchase invoice isn't posted even though the due date has passed | Check whether the job queue entry for Codeunit "CXW Post Consignment Purchases" exists, is active, and isn't erroring, and whether the executing user has the "CXW Workshop All" permission set. |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
