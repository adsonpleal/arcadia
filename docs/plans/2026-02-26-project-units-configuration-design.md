# Project Units Configuration Design (Metric Only)

Date: 2026-02-26
Status: Approved design

## Goal

Add project units configuration with metric-only options (`mm`, `cm`, `m`) while keeping geometry internals unchanged in base `mm`.

The unit configuration affects value input parsing only, not geometry storage and not cursor overlay coordinates.

## Validated Decisions

- Scope: implementation approach 2 (shared unit model + parser/converter).
- Supported units: `mm`, `cm`, `m`.
- Internal storage: unchanged; all tool values remain interpreted in base `mm`.
- Explicit typed unit suffix overrides selected unit for that typed value only.
- Selected unit must not auto-switch when explicit suffix is typed.
- Cursor position overlay remains base unit display (no conversion by selected unit).
- Keyboard input accepts mixed case unit suffixes (`CM`, `cM`, `Mm`, etc.).
- Unit control must be visually separated from tool buttons and aligned to the right side of toolbar.
- Shortcut conflict handling: `C` remains Circle shortcut unless value input is active and already non-empty.

## Approach

Introduce a small metric-units domain utility shared by logic and UI:

- enum/model for selected project unit (`mm`, `cm`, `m`)
- conversion helpers between selected unit and base `mm`
- parser for unit-annotated user input (`30`, `30cm`, `30 cm`, mixed case)

Keep all viewport state mutation in `ViewportNotifier`. UI remains thin and reads selected values through selectors.

## Architecture and Ownership

- `lib/src/data`
  - Extend viewport state with selected unit.
- `lib/src/foundation`
  - Add pure unit parsing and conversion utility.
- `lib/src/logic/viewport_notifier.dart`
  - Add selected unit mutation method.
  - Apply parser/conversion in value input handling.
- `lib/src/ui/project_page.dart`
  - Route additional keyboard characters (`c`, `m`, space) for value input.
  - Preserve existing tool shortcuts by conditional routing.
- `lib/src/ui/toolbar.dart`
  - Add right-aligned project units control distinct from tool strip.
- `lib/src/ui/viewport_overlay.dart`
  - Keep cursor position overlay formatting unchanged (base `mm` values).

## Input Semantics

- Unitless numeric input:
  - interpreted using selected unit.
  - converted to `mm` before calling tool action `onValueTyped`.
- Explicit suffix input:
  - suffix parsing is case-insensitive.
  - `mm`, `cm`, `m` supported.
  - explicit suffix wins over selected unit for that entry only.
- Accepted entry forms:
  - `30`
  - `30cm`
  - `30 cm`
  - `1.5 m`
  - mixed-case suffixes.
- Invalid or partial entries:
  - preserve raw `userInput` text for display while typing.
  - parse result is `null` until expression is valid.

## Keyboard Routing Rules

- Existing numeric and decimal input behavior stays.
- Add `c`, `m`, and space as value input candidates.
- Conditional precedence:
  - if active tool accepts value input and `userInput` is non-empty, `c/m/space` are routed as value-input characters.
  - otherwise existing tool shortcuts stay active (`C` selects Circle).

## UI Behavior

- Toolbar layout updates to keep tools on left and units control on right.
- Units control is separate from tools and clearly styled as project configuration, not as a drawing tool.
- Cursor overlay X/Y remains current base-unit values and decimal precision.

## Testing Strategy

- Unit utility tests:
  - conversion factors between `mm/cm/m` and base `mm`
  - parser accepts spaced/unspaced and mixed-case suffix
  - parser precedence: explicit suffix overrides selected unit
- State and logic tests:
  - viewport state default/copy/equality includes selected unit
  - notifier updates selected unit
  - notifier value input conversion by selected unit
  - notifier explicit suffix conversion without mutating selected unit
- UI tests:
  - toolbar renders right-side units control
  - unit selection mutates notifier selected unit
  - project page keyboard routing preserves Circle shortcut when no active value text
  - `c/m/space` append to value input when active input is non-empty
- Overlay tests:
  - existing cursor label expectations remain unchanged.

## Risks and Constraints

- Shortcut conflict around key `C` can regress tool switching if routing precedence is wrong.
- Parser must stay permissive enough for intermediate typing states while avoiding invalid numeric conversions.
- Layout changes in toolbar should not trigger avoidable rebuilds of tool buttons.

## Out of Scope

- Imperial units.
- Persistence layer for project settings.
- Geometry/storage migration from base `mm`.
- Cursor overlay unit switching based on selected project unit.
