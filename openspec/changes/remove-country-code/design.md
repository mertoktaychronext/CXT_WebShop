## Context

Two distinct fields carry a "country code" concept in this extension, and both are already functionally dead in the live path:

1. **`"Country Code"`** — owned by `Table 51002 "SL Sales Price Archive"`, part of its primary key, `TableRelation` to `"Country/Region"`. `Codeunit 51000`'s `ArchiveCheckingLine` already always writes it as `''` (`l_recSalesPriceArchive."Country Code" := '';`).
2. **`"Country/Region Code"`** — added to the *standard* `Table 7002 "Sales Price"` by `TableExtension 51001 "SL Sales Price"` (field ID 51005). Unlike `"Variant Code"` (a genuine base-app field removed in the previous change), this field is entirely owned by this extension — it does not exist on the standard table. `Codeunit 51000`'s `UpdateSalesPriceFields` already always writes it as `''` (`vSalesPrice.Validate("Country/Region Code", '');`).

This is the second primary-key reduction on `Table 51002` (after `remove-item-variants` dropped `"Variant Code"` from the same key). The same data-shape question applies: does existing archive data risk colliding on the reduced key? Since `"Country Code"` has been written blank on every row inserted since `Codeunit 51000`'s write-back went live, and no code path ever wrote a non-blank value, this risk is materially lower than the variant case (there, `"Variant Code"` could genuinely vary; here it never did). Per the accepted-risk policy established for `remove-item-variants` ("unsure/not relevant, just remove it"), no migration is built here either.

## Goals / Non-Goals

**Goals:**
- Remove `"Country Code"` as an owned field from `Table 51002`, including its `TableRelation` and primary-key membership.
- Remove the `"Country/Region Code"` field that `TableExtension 51001` adds to the standard `"Sales Price"` table, entirely (not just blanked) — this extension owns it outright.
- Remove every UI column and blanking-assignment in this extension's own code that touches either field.
- Fix, as a natural side effect, the pre-existing `SalesPrice.Get(...)` key mismatch in `Codeunit 51001` (documented in the developer manual's Known Limitations) by removing the extra `"Country/Region Code"` argument that never belonged in that key.

**Non-Goals:**
- `TableExtension 51000 "SL Country Region"` and its fields (`"Taxation Type"`, `"Delivery Time"`, `"Sales Price Currency Code"`) — these describe the country/region itself (informational, used for `"Add all Currencies"` documentation purposes), not a country code carried on price records. Untouched.
- Data migration or an upgrade codeunit for existing `"SL Sales Price Archive"` rows — out of scope, same policy as the previous change.
- Any change to `sales-price-currency-copy` — its spec text's stale `"Country Code" = 'DE'` precondition (predating the currency migration, already flagged in the developer manual as needing review before writing tests) is a pre-existing issue unrelated to this change and is left as-is.

## Decisions

### Field removal, not obsoletion
Same rationale as `remove-item-variants`: PTE, no AppSource constraint, no dependents — delete outright rather than mark `ObsoleteState`.

### `"Country/Region Code"` is fully deletable, unlike `"Variant Code"`
`"Variant Code"` (previous change) is a genuine field on the standard `"Sales Price"` table — this extension could only ever stop *populating* it, never remove it. `"Country/Region Code"` (field 51005) is different: it was *added* to `"Sales Price"` by this extension's own `TableExtension 51001`. There is no base-app field to preserve, so the field block is deleted from the table extension entirely, and `Codeunit 51000`'s `Validate("Country/Region Code", '')` call is removed rather than kept as a blank-write.

### Primary key reduction
`Table 51002` key becomes `Item No., Currency Code, Version No.`. `Codeunit 51000`'s `ArchiveCheckingLine` drops both the `SetRange("Country Code", '')` filter and the `l_recSalesPriceArchive."Country Code" := '';` assignment — there's no field left to filter or assign.

### CSV format change (file-based import, not live)
`Codeunit 51001`: remove the `"Country/Region Code"` case from `ProcessLine`, remove it from `EvaluateHeaderRow`'s `ExpectedValues`, renumber the remaining columns down by one. In `WriteSalesPrices`, the `SalesPrice.Get(...)` call drops the `vSalesPriceTemp."Country/Region Code"` argument — this argument never matched the standard table's real primary key in the first place (verified against `.alpackages` symbols during the `sales-price-checking-writeback` change; documented as a Known Limitation), so removing it doesn't just keep the code compiling, it makes the call *correct* for the first time. The `SalesPrice.Validate("Country/Region Code", ...)` line inside the insert branch is removed since the field no longer exists on `"Sales Price"`.

**Alternative considered**: leave `Codeunit 51001`'s CSV column in place, reading into a local variable that's discarded. Rejected for the same reason as the previous change — a column nobody reads is exactly the leftover complexity this change is meant to eliminate.

### Spec delta on `sales-price-checking-writeback`
Two scenarios reference the now-removed fields ("Country/Region Code is left blank" under the write-back requirement; the "'Country Code' is blank" clause inside the archive-snapshot requirement's "Archive row reflects checking line data" scenario). Both requirements get a `MODIFIED Requirements` delta: the first drops the now-meaningless scenario entirely, the second drops the clause from its scenario text.

## Risks / Trade-offs

- **[Risk]** Second primary-key reduction on `Table 51002` in a row — if the pattern of "reduce the archive's key without migration" repeats again in the future, it should prompt a bigger-picture question about whether `Table 51002`'s key needs redesigning up front rather than shrinking incrementally → **Mitigation**: none needed now (this is the last planned reduction per current scope), noted for awareness only.
- **[Risk]** Same archive-collision risk category as `remove-item-variants`, but lower probability (see Context) → **Mitigation**: none implemented, accepted per the same policy as the previous change. If publish fails on a key conflict in practice, resolve per that change's mitigation (clear conflicting rows or a one-off upgrade step).
- **[Trade-off]** Fixing the `Codeunit 51001` `SalesPrice.Get` key mismatch as a side effect of this change means that fix isn't independently reviewable/revertable from the field removal — accepted, since keeping the extra argument around just to preserve a broken call would be worse, and the component isn't live.

## Migration Plan

Code-only change plus a primary-key reduction on `Table 51002`. No upgrade codeunit (see Risk above). Deploy via normal AL publish; if publish is rejected due to a data conflict, resolve per the mitigation above before retrying. Rollback is a straight revert of the affected files.

## Open Questions

None — this follows the risk-acceptance policy already established for `remove-item-variants` rather than re-asking the same question.
