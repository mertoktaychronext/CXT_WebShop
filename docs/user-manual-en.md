# User Manual – CHX.Webshop

## Introduction

This extension for Microsoft Dynamics 365 Business Central covers two independent workflows:

1. **Sales price management** (this chapter): You import a price list (CSV file), the system automatically checks the minimum margin and unusual price swings, and a staff member then approves the prices before they are transmitted to the webshop.
2. **SellWatch purchase requests** (see the [dedicated chapter](#viewing-sellwatch-purchase-requests) below): A read-only overview of used-watch purchase requests coming in from the SellWatch partner.

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
