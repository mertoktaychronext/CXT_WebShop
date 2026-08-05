# User Manual – SL Chronext Webshop (Sales Price Management)

## Introduction

This extension for Microsoft Dynamics 365 Business Central helps you import, check, and approve new webshop sales prices before they go live. You import a price list (CSV file), the system automatically checks the minimum margin and unusual price swings, and a staff member then approves the prices.

## Prerequisites

- Access to Business Central with a role that includes the "Sales Price Checking List" page.
- The base settings (minimum margin, thresholds) must already be configured by a key user (see the Key User Manual).
- A prepared CSV file with the new prices.

## Getting Started

### Opening the price checking list

Open the **"Sales Price Checking List"** page in Business Central. The list is automatically cleared when opened — only the prices you imported in the current run are shown.

## Main Features

### 1. Import a CSV file

Click **"Import CSV"** and select your prepared file. The first line of the file (column headers) is skipped automatically. The file must contain the following columns in this order: item no., variant code, stock price, strike price, recommended retail price, country code, reason code, comment.

> Note: Import is only possible while the list is empty. If there are already price lines present, reopen the page (the list clears itself automatically on open) before importing again.

### 2. Validate prices

Click **"Validate"** after the import has finished. The system:
- rounds the imported prices,
- automatically fills in the matching currency code for each country,
- compares every new price against the last active price and flags unusual jumps or an insufficient margin as a remark.

Review any line with a remark carefully before approving.

### 3. Approve prices

Click **"Approve"** to release the checked prices. You will be asked to confirm. After approval, the system automatically records which user approved the batch.

> Approved prices can no longer be changed afterwards.

### 4. Add prices for all foreign currencies

Once you have imported, validated, and approved a German (base) price, use **"Add all Currencies"** to automatically generate one converted price line per foreign currency in use. The system considers every country with sales-price activation enabled and creates **one** line per distinct currency — even if several countries share the same currency.

This action is only available while you are working in "German price" mode (see the "Non DE Price" field below).

### 5. The "Non DE Price" field

This toggle determines whether you are currently working with German or with international (non-German) prices. It can only be switched while the list is empty.

### 6. Viewing the archive

Use the **"Sales Price Archive"** page to look up previously processed prices (read-only, no changes possible).

## Frequently Asked Questions (FAQ)

**"Nothing to process" when clicking Validate/Approve/Add all Currencies**
There are no matching price lines for this step — check whether the previous step (import or validate) actually completed.

**"DE price not allowed" / "Non DE price not allowed"**
You are trying to mix German and international prices in the list at the same time. Clear the list (reopen the page) and start again in the correct mode ("Non DE Price" toggle).

**"Please click Validate button"**
You tried to approve a price line directly without running "Validate" first. Run "Validate" first.

**Why is the country code blank on some lines?**
Lines generated via "Add all Currencies" apply to **all** countries sharing that currency, not to a single country — so the country code is intentionally left blank for those.

## Help & Support

[TODO: add internal support / key user contact details]
