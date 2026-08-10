## Context

`02-DEV/SalesPrice` and `03-FEAT/Sellwatch` both branch off the same commit on `01-Master/master` (`901e2bc`) and neither has merged yet. On `03-FEAT/Sellwatch`, 11 objects were already renumbered from `51000s` into `60300-60349` with a `CXW ` prefix (see that branch's `sellwatch-cxw-renumbering` change). This branch's 26 Sales-Price objects still sit at their original `51000-51049` IDs under the `SL` prefix. Left alone, both branches would independently claim overlapping IDs in `60300-60349` once merged. The user confirmed the fix: this branch's objects take the next free block, `60311-60336`, directly after SellWatch's `60300-60310`.

Two clarifying decisions were confirmed with the user before writing this design:
- `SL` is **replaced** by `CXW`, not prepended — unlike the SellWatch rename (where `CXW` was prepended to a business term like `SellWatch`), `SL` already plays the exact same role `CXW` is meant to take over (a company/app prefix), so prepending would produce a redundant double prefix (`"CXW SL Sales Price Checking"`).
- Every field on every one of the 26 objects gets the `CXW ` prefix (not just the two AppSource-relevant custom fields on standard-table extensions), matching the scope decision already made for the SellWatch rename.

Field `Caption`s are not touched, same as the SellWatch precedent — only the AL identifier changes.

## Goals / Non-Goals

**Goals:**
- Move all 26 objects into `60311-60336`, immediately after the SellWatch branch's `60300-60310`, so the two branches don't collide once merged.
- Replace `SL` with `CXW` on all 26 object names and prefix every field they define with `CXW `.
- Keep every cross-reference (`TableRelation`, XMLport column mapping, both codeunits' logic, page/page-extension bindings, permission set entries, enum type references) consistent — the app must compile clean afterward.
- Preserve the one genuinely stateful string in this codebase — the Isolated Storage API-key lookup key — exactly as-is.

**Non-Goals:**
- No change to field `Caption`s, `ToolTip`s, ApplicationArea, or any other user-facing text.
- No change to business logic, validation rules, or triggers — this is a rename, not a refactor.
- No change to the two stray `namespace` declarations (`PermissionSets/SLChronWSAll.permissionset.al` uses `namespace SL;`; the `Currency`/`Currencies` extension pair uses `namespace SLChronextWebshop.SLChronextWebshop;`) — pre-existing, inconsistent (only 2 of 26 files use namespaces at all), and namespaces are an AL module-organization concept distinct from the object/field identifiers this change targets.
- The still-open, not-yet-archived `remove-country-code` change already present in `openspec/changes/` on this branch is unrelated and untouched — its "Country Code" field removal appears to already be reflected in the current code (neither `Table "SL Sales Price Archive"` nor `TableExtension "SL Sales Price"` currently carries that field), but reconciling that change's status is out of scope here.
- No data migration/upgrade codeunit is planned by default — see Open Questions; this assumes the same "nothing deployed yet" situation as the SellWatch precedent, but this branch is more mature (`app.json` version `1.0.0.1`, not a same-session addition) so that assumption needs the user's explicit confirmation before `/opsx:apply`.

## Decisions

### Object ID / name map (old → new)

| # | Type | Old ID | Old Name | New ID | New Name |
|---|---|---|---|---|---|
| 1 | Table | 51000 | `"SL General Sales Price Setup"` | 60311 | `"CXW General Sales Price Setup"` |
| 2 | Table | 51001 | `"SL Sales Price Checking"` | 60312 | `"CXW Sales Price Checking"` |
| 3 | Table | 51002 | `"SL Sales Price Archive"` | 60313 | `"CXW Sales Price Archive"` |
| 4 | Table | 51004 | `"SL Sales Price Outbound File"` | 60314 | `"CXW Sales Price Outbound File"` |
| 5 | Table | 51005 | `"SL Sales Price Inbound File"` | 60315 | `"CXW Sales Price Inbound File"` |
| 6 | Table | 51006 | `"SL Sales Price Import Protocol"` | 60316 | `"CXW Sales Price Import Protocol"` |
| 7 | Table | 51007 | `"SL API Interface Setup"` | 60317 | `"CXW API Interface Setup"` |
| 8 | Table Extension (extends Country/Region) | 51000 | `"SL Country Region"` | 60318 | `"CXW Country Region"` |
| 9 | Table Extension (extends Sales Price) | 51001 | `"SL Sales Price"` | 60319 | `"CXW Sales Price"` |
| 10 | Table Extension (extends Currency) | 51002 | `SLCurrency` | 60320 | `CXWCurrency` |
| 11 | Page (Card) | 51000 | `"SL General Sales Price Setup"` | 60321 | `"CXW General Sales Price Setup"` |
| 12 | Page (Worksheet) | 51001 | `"SL Sales Price Checking List"` | 60322 | `"CXW Sales Price Checking List"` |
| 13 | Page (List) | 51002 | `"SL Sales Price Archive"` | 60323 | `"CXW Sales Price Archive"` |
| 14 | Page (List) | 51003 | `"SL API Interface Setup"` | 60324 | `"CXW API Interface Setup"` |
| 15 | Page Extension (extends Countries/Regions) | 51000 | `"SL Country Region Card"` | 60325 | `"CXW Country Region Card"` |
| 16 | Page Extension (extends Sales Prices) | 51001 | `"SL Sales Prices"` | 60326 | `"CXW Sales Prices"` |
| 17 | Page Extension (extends Currencies) | 51002 | `SLCurrencies` | 60327 | `CXWCurrencies` |
| 18 | XMLport | 51000 | `"SL Import Sales Price"` | 60328 | `"CXW Import Sales Price"` |
| 19 | Codeunit | 51000 | `"SL Export Gateway Sales Price"` | 60329 | `"CXW Export Gateway Sales Price"` |
| 20 | Codeunit | 51001 | `"SL Import Sales Prices"` | 60330 | `"CXW Import Sales Prices"` |
| 21 | Enum | 51000 | `"SL Taxation Type"` | 60331 | `"CXW Taxation Type"` |
| 22 | Enum | 51001 | `"SL Sales Price Reason Code"` | 60332 | `"CXW Sales Price Reason Code"` |
| 23 | Enum | 51002 | `"SL Ext Interface File Status"` | 60333 | `"CXW Ext Interface File Status"` |
| 24 | Enum | 51003 | `"SL Sales Price Export Status"` | 60334 | `"CXW Sales Price Export Status"` |
| 25 | Enum | 51004 | `"SL API Auth Type"` | 60335 | `"CXW API Auth Type"` |
| 26 | Permission Set | 51000 | `SLChronWSAll` | 60336 | `CXWChronWSAll` |

Note rows 1/11, 3/13, and 7/14 pair a table and a page (or, for 7/14, a table and a differently-typed same-name page) that share an identical new name — allowed since AL only requires name-uniqueness within the same object type, and this exactly mirrors the pattern already present today (e.g. `Table 51000`/`Page 51000` already share the name `"SL General Sales Price Setup"`).

### Field policy

Every field defined by the 26 objects above gets a `CXW ` prefix on its AL identifier; `Caption` stays unchanged. This spans:
- All fields on the 7 tables (`Table "CXW General Sales Price Setup"` through `Table "CXW API Interface Setup"`) — including primary-key fields (e.g. `"Item No."` on `CXW Sales Price Checking`/`CXW Sales Price Archive` becomes `"CXW Item No."`, changing their `key(PK; ...)` declarations too).
- The custom fields added by the 3 table extensions (`CXW Country Region`, `CXW Sales Price`, `CXWCurrency`).
- The field-ID *identifier* stays a plain AL name in all cases — none of these fields are shared/looked-up by string name outside AL (e.g. no JSON/CSV payload keys them by field name), so there is no external-data-compatibility concern the way there is for the Table 60317 Isolated Storage key (see below).

### 30-character identifier limit (discovered during implementation)

`CXW ` is one character longer than `SL `, which pushed three identifiers over AL's 30-character limit for object/field names — not anticipated at design time, since the equivalent `SL`-prefixed originals happened to fit exactly at or under 30. Fixed by shortening the AL identifier only; `Caption` (the user-facing label) is untouched in all three cases:
- Table 60316: `"CXW Sales Price Import Protocol"` (31 chars, AL0305 hard error) → `"CXW Price Import Protocol"` (dropped "Sales"; still unambiguous given the table's role).
- Table 60311 field: `"CXW Non Stock Price Threshold %"` (31 chars, AL0468 warning) → `"CXW Non Stock Price Thresh %"` (abbreviated "Threshold" to "Thresh").
- TableExtension 60319 field: `"CXW Recom. Retail Price incl. VAT"` (33 chars, AL0468 warning) → `"CXW Rec. Retail Price incl VAT"` (30 chars exactly; further-abbreviated "Recom." to "Rec.", dropped the period after "incl").

### Table extension field-ID renumbering

Each extension's custom field IDs move to a contiguous block starting at `60300` within that extension's own field-ID space (independent per extension, mirroring the SellWatch precedent where `51000` → `60300`):

| Extension | Old Field IDs | New Field IDs | Fields |
|---|---|---|---|
| `CXW Country Region` (60318) | 51000, 51001, 51002 | 60300, 60301, 60302 | `CXW Taxation Type`, `CXW Delivery Time`, `CXW Sales Price Currency Code` |
| `CXW Sales Price` (60319) | 51000, 51001, 51002, 51003, 51004, 51006, 51007 (51005 already removed by an earlier change) | 60300, 60301, 60302, 60303, 60304, 60305, 60306 | `CXW Reason Code`, `CXW Comment`, `CXW Remark`, `CXW Recom. Retail Price incl. VAT`, `CXW Strike-Price incl. VAT`, `CXW Unit Price (LCY)`, `CXW Unit Price (LCY) incl. VAT` |
| `CXWCurrency` (60320) | 51000 | 60300 | `CXW Sales Price Activated` |

The historical gap at field 51005 (on `CXW Sales Price`) is not preserved — the new IDs are assigned contiguously.

### Preserved: Isolated Storage API-key lookup

`Table "CXW API Interface Setup"` (60317)'s `GetApiKeyIsolatedStorageKey` procedure builds its Isolated Storage key as `StrSubstNo('SLAPIInterfaceSetup_ApiKey_%1', Code)`. This literal string is **left unchanged** — it is the lookup key for a piece of *data* (an already-possibly-stored, encrypted API key), not an AL object/field identifier. Changing it would silently orphan any API key already saved in Isolated Storage under the old key format in any environment where this has been configured, with no compiler error to catch the mistake.

### Enum cross-references

Five fields across three tables are typed as one of the renamed enums and need both their field-name prefix (per the field policy above) and their `Enum "..."` type reference updated together:
- `CXW Sales Price Checking`.`"Reason Code"` → `"CXW Reason Code": Enum "CXW Sales Price Reason Code"`
- `CXW Sales Price Checking`.`"Export Status"` → `"CXW Export Status": Enum "CXW Sales Price Export Status"`
- `CXW Sales Price Archive`.`"Reason Code"` → `"CXW Reason Code": Enum "CXW Sales Price Reason Code"`
- `CXW Sales Price Outbound File`/`CXW Sales Price Inbound File`.`Status` → `"CXW Status": Enum "CXW Ext Interface File Status"`
- `CXW API Interface Setup`.`"Auth Type"` → `"CXW Auth Type": Enum "CXW API Auth Type"`
- `CXW Country Region`'s `CXW Taxation Type` field → `Enum "CXW Taxation Type"`
- `CXW Sales Price`'s `CXW Reason Code` field → `Enum "CXW Sales Price Reason Code"`

### Alternatives considered

- **Give SalesPrice its own idRange block (e.g. `60350-60399`) instead of sharing `60300-60349` with SellWatch**: presented to the user as an option; rejected in favor of `60311-60336` within the shared range, to keep the app's registered ranges to a minimum and because 50 slots comfortably fit both features (11 + 26 = 37 objects, 13 free).
- **Prepend `CXW` in front of `SL` (matching the literal mechanic used for SellWatch)**: rejected per the user's explicit choice — `SL` and `CXW` serve the identical role (company prefix), so replacing avoids the redundant `"CXW SL ..."` pattern that prepending would create here.
- **Also rename the Isolated Storage key string**: rejected — it's data, not code; renaming it breaks any already-stored secret with no compiler safety net.

## Risks / Trade-offs

- [26 objects touch far more call sites than the 11-object SellWatch rename — both codeunits (`CXW Export Gateway Sales Price`, `CXW Import Sales Prices`) reference nearly every field on every table, and `Page "CXW Sales Price Checking List"` alone has ~25 field/variable references] → Mitigation: compile after each file group (tables → extensions → pages/page extensions/XMLport → codeunits → permission set), not only at the end; the AL compiler turns any missed rename into a hard error, not a silent bug.
- [This branch is more mature than SellWatch was — `app.json` is already at version `1.0.0.1`, suggesting at least one prior internal release] → Mitigation: confirm with the user before `/opsx:apply` whether any environment holds real data under the current `51000s` table IDs; if so, this change needs an upgrade-codeunit companion (out of scope for this proposal) rather than being a plain rename. See Open Questions.
- [The XMLport's CSV import parses columns by position, not name — renaming fields doesn't change column order, but the column-header validation logic (`EvaluateHeaderRow`) and any field-name string literals inside it need the same rename applied] → Mitigation: read `Codeunit "CXW Import Sales Prices"` fully at apply time (not just skimmed, as this design phase did) before editing it, given it's flagged in the developer manual as "not yet wired into any live process" but still must compile and stay internally consistent.
- [Two files (`SLCurrency`/`SLCurrencies` extension pair, `SLChronWSAll` permission set) declare AL `namespace`s containing "SL" that this change deliberately does not touch] → Not a functional risk (namespaces don't participate in the `idRanges` check), but flagged so the implementer doesn't "fix" it as a drive-by and accidentally expand scope.

## Migration Plan

Not applicable — confirmed with the user that this branch has never been deployed to an environment with real data, so no upgrade codeunit or data migration is needed. This is a straight rename-then-compile change, same as the SellWatch precedent; rollback is `git checkout` of the affected files if needed.

## Open Questions

None outstanding — the idRange split, the SL→CXW naming decision, and the no-deployed-data assumption were all confirmed with the user before writing this design.
