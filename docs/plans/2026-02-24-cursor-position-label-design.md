# Cursor Position Label Design

Date: 2026-02-24
Status: Approved
Related plan item: Cursor position label (`project_plan.md`)

## Goal

Add a persistent cursor position label to the viewport overlay, visually
aligned with the existing zoom label and positioned on the bottom-right side.

## Requirements

- Show cursor coordinates continuously in the viewport.
- Keep the label always visible (not only on interaction).
- Use world/drawing coordinates from viewport state.
- Use stable readable format: `X: <value>, Y: <value>`.
- Format values with fixed one decimal place.
- Keep the label read-only (no tap/click behavior).

## Architecture and Placement

- Keep mutation ownership in `ViewportNotifier`; no logic changes are required.
- Implement UI in `lib/src/ui/viewport_overlay.dart`.
- Add a new private overlay widget: `_ViewportCursorPositionLabel`.
- Keep existing overlay composition and add the new chip to the stack:
  - bottom-left: zoom label (existing, clickable reset)
  - bottom-right: cursor position label (new, read-only)
  - near cursor: typed input label (existing conditional)
- Reuse `_OverlayChip` for consistent styling with existing overlay labels.

## Data Flow and Formatting

- Source data from `ViewportState.cursorPosition`.
- Derive display text in the overlay via `selectViewportState`:
  - `x = cursorPosition.dx.toStringAsFixed(1)`
  - `y = cursorPosition.dy.toStringAsFixed(1)`
  - final text: `X: $x, Y: $y`
- Initial/default display should be `X: 0.0, Y: 0.0`.

## Testing Strategy

Update `test/src/ui/viewport_overlay_test.dart`:

- Add test: default cursor label is visible with `X: 0.0, Y: 0.0`.
- Add test: cursor label updates when `cursorPosition` changes, preserving
  one-decimal formatting (including rounding and negative values).
- Update/extend composition assertions so zoom and cursor labels are both
  present alongside existing input behavior.

Keep existing zoom interaction and user-input overlay tests unchanged unless
adjustments are needed for deterministic assertions.

## Verification Plan

1. Run static analysis: `dart analyze`.
2. Run targeted UI test: `dart test test/src/ui/viewport_overlay_test.dart`.
3. Perform dot shorthand pass on changed Dart lines.
4. Run formatting on changed files: `dart format`.

## Risks and Constraints

- Low implementation risk because this is a localized overlay change.
- Main regression risk is brittle text assertions in tests if format rules
  change later; mitigated by explicit formatting requirements in tests.
