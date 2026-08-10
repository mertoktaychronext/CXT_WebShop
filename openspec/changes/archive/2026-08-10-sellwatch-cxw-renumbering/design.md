## Context

The SellWatch feature was built up across several changes on `03-FEAT/Sellwatch` (`sellwatch-table-extensions`, `sellwatch-http-error-logging`, plus earlier uncommitted work) using object IDs `51001`-`51010`, borrowed from the app's original `idRanges` entry (`51000-51049`). That registered range has since been changed to `60300-60349` in `app.json` (already committed to the working tree, not part of this change), but the objects themselves were never moved. Two naming styles were used inconsistently along the way: a literal `SW` abbreviation (`"SW Http Call Log"`, `"SW Order Status"`, `"SW Purchase Line"`) and the spelled-out `SellWatch` (`"SellWatch Mgt"`, `"SellWatch Vendor Info"`), plus one table with no prefix at all (`"Watch Online Approval"`). This change is a pure renumber-and-rename: it settles both problems — bringing IDs back inside the registered range and giving every object and field a single `CXW ` prefix — before the branch merges and the IDs become load-bearing.

Two clarifying decisions were confirmed with the user before writing this design:
- `CXW` is *prepended* to the existing name, not substituted for the existing `SW`/`SellWatch` token (so `"SellWatch Mgt"` → `"CXW SellWatch Mgt"`, not `"CXW Mgt"`).
- Every field on every new object is renamed, not just the two fields added via table extension to standard tables — all ~70 fields across `CXW SellWatch Vendor Info`, `CXW Watch Online Approval`, and `CXW SW Http Call Log` get the `CXW ` prefix too, in addition to `CXW Used good` / `CXW Tracking Number`.

Field `Caption`s are explicitly **not** touched — captions are the end-user-facing label and stay as originally migrated from NAV (e.g. `Caption = 'Vendor Name'` stays as-is even though the field identifier becomes `"CXW Vendor Name"`). Enum values on `Enum "CXW SW Order Status"` are also untouched — the requirement said "objects (including fields)", and enum values are neither.

## Goals / Non-Goals

**Goals:**
- Move all 11 new SellWatch objects into `60300-60349`.
- Give all 11 objects and all fields they define a `CXW ` prefix.
- Keep every reference (CalcFormula, TableRelation, permission set, page bindings, codeunit code) consistent with the new names — the app must compile clean after this change.
- Keep documentation and translation files in sync.

**Non-Goals:**
- No data migration or upgrade codeunit — nothing under the old IDs has ever been deployed.
- No change to field `Caption`s, `ToolTip`s, or any other user-facing text.
- No change to enum values, keys, triggers, or business logic — this is a rename, not a refactor.
- The pre-existing `SL`-prefixed objects (`51000-51007`, already on `master`) are out of scope; only the SellWatch-branch objects listed below move.

## Decisions

### Object ID / name map (old → new)

| Type | Old ID | Old Name | New ID | New Name |
|---|---|---|---|---|
| Table | 51008 | `"SellWatch Vendor Info"` | 60300 | `"CXW SellWatch Vendor Info"` |
| Table | 51009 | `"Watch Online Approval"` | 60301 | `"CXW Watch Online Approval"` |
| Table | 51010 | `"SW Http Call Log"` | 60302 | `"CXW SW Http Call Log"` |
| Table Extension (extends Purchase Line) | 51003 | `"SW Purchase Line"` | 60303 | `"CXW SW Purchase Line"` |
| Table Extension (extends Purchase Header) | 51004 | `"SW Purchase Header"` | 60304 | `"CXW SW Purchase Header"` |
| Codeunit | 51002 | `"SellWatch Mgt"` | 60305 | `"CXW SellWatch Mgt"` |
| Enum | 51006 | `"SW Order Status"` | 60306 | `"CXW SW Order Status"` |
| Page (List) | 51004 | `"SellWatch-Overview"` | 60307 | `"CXW SellWatch-Overview"` |
| Page (CardPart) | 51005 | `"SellWatch info"` | 60308 | `"CXW SellWatch info"` |
| Page (List) | 51006 | `"SW Http Call Log"` | 60309 | `"CXW SW Http Call Log"` |
| Permission Set | 51001 | `SWChronWSAll` | 60310 | `"CXW SWChronWSAll"` |

IDs 60311-60349 stay free for future SellWatch objects.

### Field ID / name map

Table extension fields (field ID scoped per extension, mirrors the base range like the original `51000` mirrored `51000-51049`):

| Extension | Old Field | New Field ID | New Field Name |
|---|---|---|---|
| `CXW SW Purchase Line` (extends Purchase Line) | `field(51000; "Used good"; Boolean)` | 60300 | `"CXW Used good"` |
| `CXW SW Purchase Header` (extends Purchase Header) | `field(51000; "Tracking Number"; Text[30])` | 60300 | `"CXW Tracking Number"` |

`Table "CXW SellWatch Vendor Info"` (field IDs unchanged, only names get the `CXW ` prefix): `Entry No`, `Vendor Name`, `Name 2`, `Address`, `Address 2`, `City`, `Contact`, `PhoneNo`, `IBAN`, `Email`, `CountryCode`, `Post Code`, `County`, `Created`, `Brand`, `Model`, `Reference`, `SKU`, `Construction Year`, `Watch Condition`, `Paper Available`, `Box Available`, `Offer Type`, `Taxation`, `Final Offer Price`, `Bank Name`, `BIC`, `PO Number`, `CurrencyCode`, `CreatePOinBV`, `SRid`, `VendorNo`, `BillToAddress`, `BillToName`, `BillToCity`, `BillToPostCode`, `BillToCountryCode`, `BillToCounty`, `PickupDate`, `Tracking Number` (FlowField — `CalcFormula` re-pointed at `CXW Tracking Number` on `CXW SW Purchase Header`), `CXTSalesPrice`, `Gender`, `LanguageCode`, `NuveiAccountCode` — each becomes `"CXW <name>"`.

`Table "CXW Watch Online Approval"` (field IDs unchanged): `Entry No`, `Item No`, `Variant Code`, `Inbound Posted date`, `Posted By`, `Check Online`, `First Online Date`, `Remark`, `Posting Time`, `Online Check Time`, `Serial No.`, `PO number`, `URL`, `C2C`, `SRid` (FlowField) — each becomes `"CXW <name>"`.

`Table "CXW SW Http Call Log"` (field IDs unchanged): `Entry No`, `Call DateTime`, `Source Entry No` (`TableRelation` re-pointed at `CXW Watch Online Approval."CXW Entry No"`), `Endpoint URL`, `Success`, `HTTP Status Code`, `Error Message`, `Request`, `Response` — each becomes `"CXW <name>"`.

### File renames

AL source files follow the project's `Tab<ID>.<PascalName>.al` / `Pag<ID>.<PascalName>.al` convention (see existing `SL...` files). New files are renamed to match the new IDs, e.g. `Tab51008.SellWatchVendorInfo.al` → `Tab60300.CXWSellWatchVendorInfo.al`. Full mapping is in tasks.md.

### Alternatives considered

- **Keep old IDs, only fix `app.json`'s idRange back to `51000-51049`**: rejected — the user explicitly asked to fix the *object* IDs to match the *new* range, not revert the range.
- **Replace `SW`/`SellWatch` token with `CXW` instead of prepending**: rejected per the user's explicit choice (see Context) — prepending is lower-risk and keeps the descriptive `SellWatch` business term intact.
- **Prefix only the 2 table-extension fields (the ones that actually risk colliding with another extension's fields on the same standard table)**: this is the AppSource-standard reason field prefixes exist. Rejected anyway per the user's explicit choice to prefix every field on every new object for full naming consistency across the feature, not just where collision risk exists.

## Risks / Trade-offs

- [Renaming ~70 field identifiers touches every page/codeunit reference to those fields — a missed rename fails compilation, not silently] → Mitigation: AL compiler catches every unresolved reference; tasks.md enumerates every file and every reference site found by the design review (Codeunit "CXW SellWatch Mgt", Pages "CXW SellWatch-Overview"/"CXW SellWatch info"/"CXW SW Http Call Log", the permission set); build after each file, not only at the end.
- [`.g.xlf` translation IDs are typically derived from object/field identifiers, so every rename invalidates the corresponding translation unit] → Mitigation: regenerate `.g.xlf` from source after the rename (standard AL "Generate Translation File" step) rather than hand-editing it; reconcile `de-DE.xlf` against the regenerated `.g.xlf` using the existing translation-sync tooling in this repo (`managing-bc-translations` skill) so no translated string is lost, only re-keyed.
- [Docs (funktionsregister, manuals) go stale the moment IDs/names change] → Mitigation: regenerate via the `al-funktionsregister` / `handbuch-generator` skills rather than hand-editing 8 markdown files, since both already exist as automation for this exact class of change.
- [Two objects share the display name `"CXW SW Http Call Log"` — one table (60302), one page (60309)] → Not a risk: AL requires name uniqueness only within the same object type, and this mirrors the pre-existing pattern (Table 51010 and Page 51006 already shared the name `"SW Http Call Log"` before this change).

## Migration Plan

Not applicable — no deployed environment carries data under the old IDs (branch not merged). This is a straight find-and-replace-then-compile change; rollback is `git checkout` of the affected files if needed.

## Open Questions

None outstanding — both ambiguous points (prefix style, field-rename scope) were confirmed with the user before writing this design.
