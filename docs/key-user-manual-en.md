# Key User Manual – SL Chronext Webshop (Sales Price Management)

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries and currencies for price generation, and act as the first point of contact for the business department.

## Base settings (General Sales Price Setup)

The **"General Sales Price Setup"** page holds the rules every imported price is checked against:

| Setting | Meaning |
|---|---|
| Minimum Margin % | Prices with a lower margin are flagged with a remark during "Validate" (note: in the webshop display itself, an item is deactivated if it falls below the margin — see the field's tooltip). |
| Stock Price Threshold % | The percentage price increase (vs. the last price) above which a remark is generated. |
| Non Stock Price Threshold % | Same idea for non-stock items (currently not actively used, see Developer Manual). |
| Cat 1–3 Non Stock % / Stock Price From/To | Prepared for automatic calculation of the non-stock price per price category. This calculation is not currently wired into the live approval flow. |
| Price Export Active | Toggle for a future automated price export to external systems (see Developer Manual — this component is not yet live). |

These settings **must** be filled in (Minimum Margin %, Stock Price Threshold %), otherwise import, validation, and approval cannot be run.

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

The standard flow for the business department is: **Import → Validate → Approve → (optional) Add all Currencies**. As a key user you are responsible for the framework (base settings, currency activation), not the day-to-day operation itself (see User Manual).

## Data management

- **Archive**: The "Sales Price Archive" page lets you look up previously processed prices. Automatically populating this archive during the approval step is **not** currently active (see Developer Manual).
- **File-based import**: A prepared but not yet connected component exists for automated, file-based price import. It is currently not part of the live process (no job queue entry).

## Permissions

Access to all objects in this extension is controlled through the **"SLChronWSAll"** permission set. It still needs to be assigned to the relevant users or user groups before they can use the extension's pages.

## Troubleshooting

| Problem | Cause / Solution |
|---|---|
| "Import CSV" cannot be run | Base settings (Minimum Margin %, Stock Price Threshold %) are not filled in, or the list still contains price lines from a previous run. |
| "Add all Currencies" produces no line for a specific currency | Check that "Sales Price Activated" is enabled for that currency on the "Currencies" page. |
| A user cannot open the extension's pages | Check whether the user has been assigned the "SLChronWSAll" permission set. |
| A price isn't calculated with margin X% despite correct input | The category-based non-stock price calculation is not currently wired into the live flow — escalate to the development team if this feature is needed. |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
