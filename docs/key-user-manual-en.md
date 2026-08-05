# Key User Manual – SL Chronext Webshop (Sales Price Management)

## About this document

This manual is for key users who maintain the base settings of the sales price management module, activate countries for price export, and act as the first point of contact for the business department.

## Base settings (General Sales Price Setup)

The **"General Sales Price Setup"** page holds the rules every imported price is checked against:

| Setting | Meaning |
|---|---|
| Minimum Margin % | Prices with a lower margin are flagged with a remark during "Validate" (note: in the webshop display itself, an item is deactivated if it falls below the margin — see the field's tooltip). |
| Stock Price Threshold % | The percentage price increase (vs. the last price) above which a remark is generated. |
| Non Stock Price Threshold % | Same idea for non-stock items (currently not actively used, see Developer Manual). |
| Cat 1–3 Non Stock % / Stock Price From/To | Prepared for automatic calculation of the non-stock price per price category. This calculation is currently not enabled in day-to-day use. |
| Price Export Active | Toggle for a future automated price export to external systems (see Developer Manual — this component is not yet live). |

These settings **must** be filled in (Minimum Margin %, Stock Price Threshold %), otherwise import, validation, and approval cannot be run.

## Activating countries for price export

The following fields were added to the **Country/Region** master data:

| Field | Meaning |
|---|---|
| Sales Price Activated | Must be enabled for this country to be considered when automatically generating prices (e.g. via "Add all Currencies"). |
| Sales Price Currency Code | The currency prices are maintained in for this country. Countries sharing the same currency receive the same (single) price line when using "Add all Currencies". |
| Taxation Type | Full, differential, or both — currently informational only, with no automatic effect on price calculation. |
| Delivery Time (Days) | Informational field, currently with no automatic effect on price checking. |

> A country without "Sales Price Activated" is ignored by "Add all Currencies".

## Reason Code

Every price change can be tagged with a reason: **CatMan**, **Purchasing**, or **Marketing**. This supports traceability of why a price changed but is not currently evaluated further by any automated logic.

## Workflows and processes

The standard flow for the business department is: **Import → Validate → Approve → (optional) Add all Currencies**. As a key user you are responsible for the framework (base settings, country activation), not the day-to-day operation itself (see User Manual).

### "Non DE Price" mode

The price list has two modes: German prices (the basis for "Add all Currencies") and international prices. A staff member can only work in one mode at a time; the system actively prevents mixing both modes in the same list.

## Data management

- **Archive**: The "Sales Price Archive" page lets you look up previously processed prices. Automatically populating this archive during the approval step is **not** currently active (see Developer Manual, "Upload Sales Price").
- **File-based import/export**: A prepared but not yet connected component exists for automated, file-based price import/export. It is currently not part of the live process.

## Troubleshooting

| Problem | Cause / Solution |
|---|---|
| "Import CSV" cannot be run | Base settings (Minimum Margin %, Stock Price Threshold %) are not filled in, or the list still contains price lines from a previous run. |
| "Add all Currencies" is greyed out | The "Non DE Price" toggle is active — this action is only available in German price mode. |
| "Add all Currencies" produces no line for a specific country | Check that "Sales Price Activated" is enabled for that country and a sales price currency is set. |
| A price isn't calculated with margin X% despite correct input | The category-based non-stock price calculation is currently inactive — escalate to the development/project team if this feature is needed. |

## Escalation path

For technical questions beyond plain configuration (e.g. error messages not covered in the User or Key User Manual, or requests to enable the currently deferred features), contact the development team — see the Developer Manual.
