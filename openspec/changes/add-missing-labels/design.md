## Context

The project already has an established `Label` convention in the affected files — `Pag51001.SLSalesPriceCheckingList.al` declares `TXT001`, `TXT003`, `TXT006`, `TXT007`, `TXT009` (older numbered style) alongside newer descriptive names `ExportResultMsg`, `ResendAlreadySentQst` (added in the `sales-price-checking-writeback` change). `TXT005` exists but is unused (unrelated dead code, out of scope here). The 17 call sites identified in the proposal are the only remaining literal-string calls to `Error`/`Message`/`Confirm`/`Dialog.Open` in the codebase (verified via `grep` across `src/`), plus 2 `StrSubstNo` calls that build internal identifiers rather than UI text (also verified, and explicitly excluded — see proposal).

## Goals / Non-Goals

**Goals:**
- Every remaining literal string passed to `Error`, `Message`, `Confirm`, or `Dialog.Open` becomes a `Label`.
- Identical literal text used at multiple call sites within the same object shares one `Label` rather than being duplicated — reduces trans-unit count and gives a single place to update the wording later.
- `de-DE.xlf` has a German translation for every new trans-unit before this change is considered done (no new gaps of the kind `managing-bc-translations` exists to catch).

**Non-Goals:**
- Rewording any message — English text stays character-for-character identical; only its declaration mechanism changes.
- Touching `Caption`/`ToolTip` properties on fields, pages, or actions — those are already extracted into `.g.xlf` automatically by the AL compiler and don't need `Label` wrapping.
- Converting `StrSubstNo` calls that build non-UI internal identifiers (the outbound JSON filename in `Codeunit 51000`, the Isolated Storage key in `Table 51007`) — translating these would be meaningless or actively harmful (the storage key one would orphan already-stored API keys if its format string changed).
- `TXT005` (unused label) — pre-existing dead code, unrelated to "missing" labels.

## Decisions

### Shared Label per distinct text, not per call site
9 of the 17 call sites are `Error('Nothing to process')` and 2 are `Message('done')` — both within `Page 51001`. Rather than declaring 9 near-identical `Label`s (`NothingToProcessErr1`, `NothingToProcessErr2`, ...), each distinct string gets exactly one `Label`, referenced from every call site that used that literal. This mirrors how a developer would naturally consolidate duplicated string literals during cleanup, keeps the `var` section shorter, and gives translators one place to translate "Nothing to process" instead of nine identical-looking entries.

**Alternative considered**: one `Label` per call site (e­ven when text is identical), to allow each guard clause to diverge in wording later if needed. Rejected — none of the 9 "Nothing to process" guards have call-site-specific context today (they're all a generic "no eligible records" guard across different actions), so a future need to diverge is speculative; consolidating now is simpler and YAGNI-consistent. If a specific guard later needs its own wording, splitting one shared `Label` back into two is a small, obvious change.

### Labels stay object-local, no shared label codeunit
`Xmlport 51000`'s `Message('done')` and `Page 51001`'s `Message('done')`/`DoneMsg` have identical English text but live in different AL objects. AL `Label` variables are declared per-object; there is no built-in cross-object label sharing without introducing a shared codeunit purely to hold text constants. For 1 duplicated string, that indirection isn't worth it — `Xmlport 51000` gets its own local `ImportDoneMsg` label with the same text.

### Naming convention
New labels use the descriptive `PascalCaseErr`/`Msg`/`Qst` suffix style already established by `ExportResultMsg` and `ResendAlreadySentQst` (the more recent addition to this file), not the older `TXT0xx` numbered style — consistent with "match the most recently established convention in a file with mixed styles."

| Object | New Label | Text | Replaces |
|---|---|---|---|
| Page 51001 | `NothingToProcessErr` | `Nothing to process` | 9 `Error(...)` call sites |
| Page 51001 | `ValidateDoneMsg` | `validate data is done` | 1 `Message(...)` call site |
| Page 51001 | `AcceptNewPriceSetupQst` | `Are you sure want to Accept New Price Setup?` | 1 `Confirm(...)` call site |
| Page 51001 | `DoneMsg` | `done` | 2 `Message(...)` call sites (Approve, Add all Currencies) |
| Page 51001 | `ModifyNotAllowedErr` | `not possible` | 1 `Error(...)` call site (`OnModifyRecord`) |
| Page 51001 | `ValidatingProgressMsg` | `Validating Sales Price @1@@@@@@@@@@@@@@@` | 1 `Dialog.Open(...)` call site |
| Xmlport 51000 | `ImportDoneMsg` | `done` | 1 `Message(...)` call site |
| Table 51001 | `PleaseValidateErr` | `Please click Validate button.` | 1 `Error(...)` call site |

### German translations
Following the same translation workflow used throughout this project (`managing-bc-translations`): after adding the labels and recompiling (which regenerates `.g.xlf` with the 9 new trans-units), `de-DE.xlf` gets matching `<target>` translations, verified with the same diff/validation approach used in prior sessions (trans-unit count parity, no missing/orphaned/mismatched entries, placeholder counts preserved for `ValidatingProgressMsg`'s `@1@` progress-bar placeholder).

## Risks / Trade-offs

- **[Risk]** Consolidating 9 call sites onto one shared `Label` means a future change that needs one of those 9 guards to say something more specific would require un-sharing that one call site (declaring its own label and pointing just that call at it) → **Mitigation**: this is a small, mechanical, low-risk change to make later; not worth avoiding the consolidation today for a hypothetical future need.
- **[Trade-off]** `ValidatingProgressMsg`'s text includes AL's special progress-bar placeholder syntax (`@1@@@@@@@@@@@@@@@`) — this must be preserved exactly in both the label declaration and the German translation (the `@1@...@` sequence is a fixed-width placeholder for the percentage, not literal text a translator should touch). Flagged here so translation isn't done mechanically without this caveat.

## Migration Plan

Code-only change, no data/schema impact. Deploy via normal AL publish. Rollback is a straight revert — the visible English behavior is unchanged, so there's no user-facing risk either way.
