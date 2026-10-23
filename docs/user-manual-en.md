# User Manual – CHX.Webshop

## Introduction

This extension for Microsoft Dynamics 365 Business Central covers four largely independent workflows:

1. **Sales price management** (this chapter): You import a price list (CSV file), the system automatically checks the minimum margin and unusual price swings, and a staff member then approves the prices before they are transmitted to the webshop.
2. **SellWatch purchase requests** (see the [dedicated chapter](#viewing-sellwatch-purchase-requests) below): A read-only overview of used-watch purchase requests coming in from the SellWatch partner.
3. **Workshop authenticity check** (see the [dedicated chapter](#sending-watches-to-the-workshop-for-authenticity-check) below): Purchased watches that have arrived are checked for authenticity by an external workshop before being put into stock. You record the manufacturer serial number per purchase line; the check itself runs automatically.
4. **Consignment Sales** (see the [dedicated chapter](#consignment-sales-delayed-purchase-invoice) below): For watches purchased on consignment, the purchase invoice is posted automatically after a delay once the watch is sold. No action is required from you as an end user.

## Prerequisites

- Access to Business Central with a role that includes the "Sales Price Checking List" page (permission set `SLChronWSAll`) or the "SellWatch-Overview" page (permission set `CXW SWChronWSAll`).
- The base settings (minimum margin, thresholds) must already be configured by a key user (see the Key User Manual).
- For "Release Sales Prices", a key user must have enabled the price export, configured an API interface and the archive country, and set up the sales price export job in the job queue (see the Key User Manual).
- A prepared CSV file with the new prices.

## Getting Started

### Opening the price checking list

Open the **"Sales Price Checking List"** page in Business Central. The list is automatically cleared when opened — only the prices you imported in the current run are shown.

The navigation buttons at the top of the page also give you direct access to:
- **"General Sales Price Setup"** – the base settings (see the Key User Manual)
- **"Sales Price Archive"** – the archive of released DE prices
- **"Sales Price Export Entries"** – the released prices of all countries and the state of their transmission

## Main Features

### 1. Import a CSV file

Click **"Import CSV"** and select your prepared file. The first line of the file (column headers) is skipped automatically. The file must contain the following columns in this order: item no., stock price, strike price, recommended retail price, **currency code**, reason code, comment.

> Note: Item variants are no longer supported — a price always applies to the whole item. The former variant code column is gone.

> Note: Import is only possible while the list is empty. If there are already price lines present, reopen the page (the list clears itself automatically on open) before importing again.

### 2. Validate prices

Click **"Validate"** after the import has finished. The system:
- rounds the imported prices,
- compares every new price against the last active price and flags unusual jumps or an insufficient margin as a remark.

Review any line with a remark carefully before approving.

### 3. Approve prices

Click **"Approve"** to release the checked prices. You will be asked to confirm. After approval, the system automatically records which user approved the batch.

> Approved prices can no longer be changed afterwards.

### 4. Add prices for all countries ("Add all Countries")

Once you have imported, validated, and approved a base price, use **"Add all Countries"** to automatically generate one price line per activated country. The system considers every country a key user has enabled (see the Key User Manual) and creates **one** line per country — in the currency set up for that country. If the country uses the same currency as the base price, the price is copied unchanged; otherwise it is converted with the latest exchange rate. The **"Country Code"** column shows which country a line applies to; the imported base line has no country.

### 5. Release prices and queue them for transmission ("Release Sales Prices")

Click **"Release Sales Prices"** to queue all approved **country lines** for transmission to the external system (e.g. the webshop). For each line, the system automatically:

1. Writes the price into the live sales price table (creating it or updating an existing one) — valid for **all customers**.
2. For the archive country only (**DE** by default), also stores a copy in the **price archive**, with a running version number.
3. Stores the price of the country as a **sales price export entry** and queues it for transmission. The line gets "Export Status" = "Queued".

The actual transmission happens **later, in the background**, through a job in the job queue. Nothing else is required from you.

> The imported base line without a country is **not** released and not transmitted. Always run "Add all Countries" before releasing. If only base lines are approved, the action stops with a corresponding message.

At the end you get a message showing how many prices were queued for transmission. Lines that were already queued ("Export Status" = "Queued") are **not** released again automatically when you click again — you are asked first whether you really want to do so.

> If the release fails for a single line (e.g. due to an invalid value), only that line is marked "Export Status" = "Error" and is not queued; all other lines are still processed.

### 6. Viewing the transmission and the archive

The **"Sales Price Export Entries"** page shows every released price per country, who released it and when, and in the **"Export Status"** column whether it has already been transmitted ("Processed"), is still pending ("Pending (Sales Price)"), or failed ("Error"). Failed transmissions are retried automatically; if an entry stays on "Error" permanently, contact a key user.

Use the **"Sales Price Archive"** page to look up the released DE prices (read-only). Every version appears here as its own, sequentially numbered entry. Prices of other countries are only available in the "Sales Price Export Entries".

## Viewing SellWatch purchase requests

The **"SellWatch-Overview"** page lists all used-watch purchase requests received from the SellWatch partner — read-only, with seller, watch, and offer details, plus, once available, the related purchase order number and shipment tracking number.

Use the **"Show Document"** action to open the purchase order created for a request.

> New purchase requests, and the creation of the vendor and purchase order, happen automatically in the background; this page is view-only. If a request shows no order number, the order hasn't been created for it automatically yet.

## Sending watches to the workshop for authenticity check

For purchased watches that need to be checked for authenticity by an external workshop before being put into stock, you record on the purchase order which lines have arrived.

### Running the "Send to Workshop" action

Open the relevant **purchase order** and click **"Send to Workshop"**. The system asks you, one line at a time, for every line not yet transmitted (type Item, quantity not 0):

1. **"Is item {item no.} {description} really arrived?"** – Confirm with "Yes" if the item has physically arrived. On "No" the line is marked "Not Arrived" and skipped; you can run the action again later once the item has arrived.
2. On "Yes", the watch's **Serial No. Information Card** opens. If the purchase line has no serial number yet, the system automatically assigns the next available number and shows it on the card. Enter the **manufacturer serial number** there and — if required for the item — the **box** and **papers** details, then close the card.
3. If the manufacturer serial number or a required detail is still missing, the line is skipped and listed with the reason in a summary message at the end of the action, while the remaining lines are still processed normally. The next time you run the action, the same serial number appears again.

> Lines with a quantity greater than 1 or items without serial number tracking cannot be sent to the workshop; they also appear in the summary message. In that case, contact a key user.

Once entered successfully, the line is marked "Sent to Workshop" and its fields on the purchase line become **read-only** (item, quantity, etc.) — this prevents a line already handed over to the workshop from being changed afterwards while the check is still in progress. Only the **direct unit cost** stays editable at all times; a later price change is not passed on to the workshop, though.

> A line that has already been sent cannot be transmitted a second time through this action.

If workshop lines already exist for the order, the system points this out when you run "Send to Workshop" again:

- If all lines have already been sent, a message states that there are no further lines to send to the workshop — nothing is processed.
- If there are still open lines (e.g. previously marked "Not Arrived"), the system shows the number of existing workshop lines and asks whether the remaining lines should be sent. Choosing "No" cancels the action.

### What happens automatically afterwards

The actual check by the workshop, and the follow-up processing based on the check result, run fully automatically in the background — no further action is needed on your part:

- If the workshop confirms authenticity, the system automatically posts **only the goods receipt** for the purchase line (no invoice), and the item attributes reported by the workshop (e.g. dial color, case diameter, bracelet material) are written to the item as item attributes.
- If the workshop disproves authenticity, the associated purchase order is automatically cancelled.

## Viewing Workshop lines

The **"CXW Workshop Lines"** page shows every line handed over to the workshop, its current check status (New / WS checked / Processed / Error), the item attributes reported by the workshop, and — if automatic processing failed — the most recent error message. You can correct the status and the attributes there; the purchase order reference and item no. are locked, and lines cannot be created there.

### Deleting a workshop line

If a watch was sent to the workshop by mistake or with wrong data, you can delete the workshop line on the **"CXW Workshop Lines"** page — provided you have been assigned the **"CXW Workshop Delete"** permission set.

- Only lines with status **"New"** or **"Error"** can be deleted. Lines with status **"WS checked"** (the workshop has already reported its result) and **"Processed"** (proof of the check) cannot be deleted.
- After deleting, the related purchase order line is open again: "Sent to Workshop" is reset, the manufacturer serial number on the line is blank, and the line can be edited again.
- You can then send the line again with **"Send to Workshop"**. The serial number already assigned and the serial no. information with the manufacturer serial number are kept and reused.

On the **purchase order** itself, the field **"No. of Workshop Lines"** (General FastTab) shows how many workshop lines exist for the order; blank means none. Choosing the value opens the workshop lines filtered to this order.

> If a line shows status "Error", a problem occurred during the last automatic processing attempt (e.g. a closed posting period). Contact a key user or the development team in this case (see the Key User Manual).

## Consignment Sales: Delayed purchase invoice

For watches purchased on consignment (item flagged as "Consignment Sales"), the related **purchase invoice is not posted immediately** on sale, but automatically after a set number of days following the posting of the sales invoice.

This workflow is **fully automated**: as soon as you post a sales invoice for a consignment watch, a consignment posting entry is created in the background; a background job then posts the purchase invoice on its due date. Nothing is required from you as an end user.

> Configuring the delay, monitoring the entries, and reprocessing failed cases ("CXW Cons. Posting Entries" page, "Retry" action) is handled by a key user — see the Key User Manual.

## Frequently Asked Questions (FAQ)

**"Nothing to process" when clicking Validate/Approve/Add all Countries**
There are no matching price lines for this step — check whether the previous step (import or validate) actually completed.

**"Please click Validate button"**
You tried to approve a price line directly without running "Validate" first. Run "Validate" first.

**"not possible" when editing a price line**
An already accepted/approved price line can no longer be changed afterwards.

**"Nothing to process" when clicking "Release Sales Prices"**
There are no approved (accepted) price lines. Run "Approve" first.

**"Only source lines without a country are approved" when clicking "Release Sales Prices"**
Only base lines without a country are approved. Run "Add all Countries" first.

**A price stays on "Pending (Sales Price)" in "Sales Price Export Entries" for a long time**
Transmission runs through a job in the job queue. If the entry stays pending longer than usual, the job may not be set up or may be on hold — contact a key user.

**Message that the interface is not active or no API interface is configured**
The price export has not been set up or is disabled. Contact a key user (see the Key User Manual).

**A SellWatch request shows no order number.**
The order hasn't been created for this request automatically yet.

**"Send to Workshop" opens the Serial No. Information Card even though I wanted to cancel.**
The card is mandatory for items marked as arrived. If you close it without a manufacturer serial number, the line is skipped (the assigned serial number is kept for the next attempt). Choose "No" in the preceding confirmation dialog if the item hasn't actually arrived yet — the line is then skipped without cancelling the rest of the action.

**A Workshop line stays on status "Error" permanently.**
Automatic processing failed for this line. This isn't something you can fix yourself as an end user — contact a key user (see the Key User Manual).
