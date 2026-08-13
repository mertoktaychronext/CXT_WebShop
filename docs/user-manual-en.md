# User Manual – CHX.Webshop

## Introduction

This extension for Microsoft Dynamics 365 Business Central covers three independent workflows:

1. **Sales price management** (this chapter): You import a price list (CSV file), the system automatically checks the minimum margin and unusual price swings, and a staff member then approves the prices before they are transmitted to the webshop.
2. **SellWatch purchase requests** (see the [dedicated chapter](#viewing-sellwatch-purchase-requests) below): A read-only overview of used-watch purchase requests coming in from the SellWatch partner.
3. **Workshop authenticity check** (see the [dedicated chapter](#sending-watches-to-the-workshop-for-authenticity-check) below): Purchased watches that have arrived are checked for authenticity by an external workshop before being put into stock. You record the manufacturer serial number per purchase line; the check itself runs automatically.

## Prerequisites

- Access to Business Central with a role that includes the "Sales Price Checking List" page (permission set `SLChronWSAll`) or the "SellWatch-Overview" page (permission set `CXW SWChronWSAll`).
- The base settings (minimum margin, thresholds) must already be configured by a key user (see the Key User Manual).
- For "Upload Sales Price", a key user must have enabled the price export and configured an API interface (see the Key User Manual).
- A prepared CSV file with the new prices.

## Getting Started

### Opening the price checking list

Open the **"Sales Price Checking List"** page in Business Central. The list is automatically cleared when opened — only the prices you imported in the current run are shown.

The navigation buttons at the top of the page also give you direct access to:
- **"General Sales Price Setup"** – the base settings (see the Key User Manual)
- **"Sales Price Archive"** – the archive of previously processed prices

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

### 4. Add prices for all foreign currencies

Once you have imported, validated, and approved a base price, use **"Add all Currencies"** to automatically generate one converted price line per currency that has been activated for this. The system considers every currency a key user has enabled (see the Key User Manual) and creates **one** line per currency.

### 5. Upload prices ("Upload Sales Price")

Click **"Upload Sales Price"** to transmit all approved price lines to the external system (e.g. the webshop). For each line, the system automatically:

1. Writes the price into the live sales price table (creating it or updating an existing one) — valid for **all customers**.
2. Also stores a copy of the price in the **price archive**, with a running version number per item/variant/currency.
3. Sends the price to the external system via the configured interface.

At the end you get a message showing how many of the approved lines were transmitted successfully. Lines that were already sent successfully before ("Export Status" = "Sent") are **not** resent automatically when you click again — you are asked first whether you really want to resend them.

> If the transmission fails for a single line (e.g. due to an invalid value), only that line is marked "Export Status" = "Error"; all other lines are still processed.

### 6. Viewing the archive

Use the **"Sales Price Archive"** page to look up previously uploaded prices (read-only, no changes possible). Every version of an uploaded price line appears here as its own, sequentially numbered entry.

## Viewing SellWatch purchase requests

The **"SellWatch-Overview"** page lists all used-watch purchase requests received from the SellWatch partner — read-only, with seller, watch, and offer details, plus, once available, the related purchase order number and shipment tracking number.

Use the **"Show Document"** action to open the purchase order created for a request.

> New purchase requests, and the creation of the vendor and purchase order, happen automatically in the background; this page is view-only. If a request shows no order number, the order hasn't been created for it automatically yet.

## Sending watches to the workshop for authenticity check

For purchased watches that need to be checked for authenticity by an external workshop before being put into stock, you record on the purchase order which lines have arrived.

### Running the "Send to Workshop" action

Open the relevant **purchase order** and click **"Send to Workshop"**. The system asks you, one line at a time, for every line not yet transmitted (type Item, quantity not 0):

1. **"Is item {item no.} {description} really arrived?"** – Confirm with "Yes" if the item has physically arrived. On "No" the line is marked "Not Arrived" and skipped; you can run the action again later once the item has arrived.
2. On "Yes", an input dialog opens for the **manufacturer serial number**. This entry is mandatory — without a valid serial number the line is skipped and listed in a summary message at the end of the action, while the remaining lines are still processed normally.

Once entered successfully, the line is marked "Sent to Workshop" and its fields on the purchase line become **read-only** (item, quantity, price, etc.) — this prevents a line already handed over to the workshop from being changed afterwards while the check is still in progress.

> A line that has already been sent cannot be transmitted a second time through this action.

### What happens automatically afterwards

The actual check by the workshop, and the follow-up processing based on the check result, run fully automatically in the background — no further action is needed on your part:

- If the workshop confirms authenticity, the system automatically posts **only the goods receipt** for the purchase line (no invoice), and the item attributes reported by the workshop (e.g. dial color, case diameter, bracelet material) are written to the item as item attributes.
- If the workshop disproves authenticity, the associated purchase order is automatically cancelled.

## Viewing Workshop lines

The **"CXW Workshop Lines"** page shows every line handed over to the workshop, its current check status (New / WS checked / Processed / Error), the item attributes reported by the workshop, and — if automatic processing failed — the most recent error message. This page is read-only.

> If a line shows status "Error", a problem occurred during the last automatic processing attempt (e.g. a closed posting period). Contact a key user or the development team in this case (see the Key User Manual).

## Frequently Asked Questions (FAQ)

**"Nothing to process" when clicking Validate/Approve/Add all Currencies**
There are no matching price lines for this step — check whether the previous step (import or validate) actually completed.

**"Please click Validate button"**
You tried to approve a price line directly without running "Validate" first. Run "Validate" first.

**"not possible" when editing a price line**
An already accepted/approved price line can no longer be changed afterwards.

**"Nothing to process" when clicking "Upload Sales Price"**
There are no approved (accepted) price lines. Run "Approve" first.

**Message that the interface is not active or no API interface is configured**
The price export has not been set up or is disabled. Contact a key user (see the Key User Manual).

**A SellWatch request shows no order number.**
The order hasn't been created for this request automatically yet.

**"Send to Workshop" asks for the manufacturer serial number even though I wanted to cancel.**
The dialog is mandatory for items marked as arrived. Choose "No" in the preceding confirmation dialog if the item hasn't actually arrived yet — the line is then skipped without cancelling the rest of the action.

**A Workshop line stays on status "Error" permanently.**
Automatic processing failed for this line. This isn't something you can fix yourself as an end user — contact a key user (see the Key User Manual).
