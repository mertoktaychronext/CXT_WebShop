# multilingual-messages

All user-facing runtime messages, errors, confirmations, and progress text in this extension are declared as `Label`s (not string literals), so they are extractable and translatable via the standard BC translation file mechanism.

## Requirements

### Requirement: User-facing runtime text is declared as Label
Every string passed to `Error`, `Message`, `Confirm`, or a `Dialog`'s progress/status text within this extension's own objects SHALL be declared as a `Label` variable rather than a literal string, so it is extracted into the generated translation file and can be translated.

#### Scenario: Error call uses a Label
- **WHEN** any AL object in this extension raises an error shown to the user
- **THEN** the error text is sourced from a `Label` variable, not a string literal passed directly to `Error(...)`

#### Scenario: Message and Confirm calls use a Label
- **WHEN** any AL object in this extension shows a `Message` or asks for `Confirm`ation
- **THEN** the displayed text is sourced from a `Label` variable, not a string literal

#### Scenario: Progress dialog text uses a Label
- **WHEN** a `Dialog` is opened to show a progress indicator
- **THEN** its format text is sourced from a `Label` variable, not a string literal, and any progress-bar placeholder syntax (e.g. `@1@...@`) is preserved unchanged in the Label's text

### Requirement: Duplicate literal text shares one Label per object
Where the same literal message text was previously used at more than one call site within the same AL object, those call sites SHALL reference a single shared `Label` rather than each having its own separately-declared, textually-identical `Label`.

#### Scenario: Multiple guard clauses with identical text
- **WHEN** two or more call sites in the same object previously raised the same literal error text (e.g. a generic "nothing to process" guard used by multiple actions)
- **THEN** those call sites reference the same `Label` variable

### Requirement: Internal, non-UI identifiers are not converted to Labels
String-building calls that construct internal identifiers rather than user-facing text (e.g. generated filenames, Isolated Storage keys) SHALL NOT be converted to `Label`s, since translating such values would be meaningless or would change already-stored data.

#### Scenario: Filename construction is left as-is
- **WHEN** a procedure builds a filename for an outbound file using `StrSubstNo` with a fixed format string
- **THEN** that format string remains a literal, not a `Label`

#### Scenario: Storage key construction is left as-is
- **WHEN** a procedure builds an Isolated Storage key using `StrSubstNo` with a fixed format string
- **THEN** that format string remains a literal, not a `Label`, since changing it would orphan values already stored under the old key format

### Requirement: New Labels are translated in the maintained translation file
Every new `Label` added to satisfy this capability SHALL have a corresponding, non-empty German translation in `Translations/SL Chronext Webshop.de-DE.xlf` before the change is considered complete.

#### Scenario: New label has a German translation
- **WHEN** a new `Label` is added to an AL object as part of this capability
- **THEN** after the next compile regenerates `.g.xlf`, `de-DE.xlf` contains a matching trans-unit with a non-empty `<target>`
