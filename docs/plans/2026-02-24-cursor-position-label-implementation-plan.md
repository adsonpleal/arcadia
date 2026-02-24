# Cursor Position Label Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a persistent, read-only cursor coordinate label in the viewport overlay at the bottom-right using world coordinates formatted as `X: <value>, Y: <value>` with one decimal place.

**Architecture:** Keep state mutation in `ViewportNotifier` and implement the new behavior only in the overlay UI layer. Extend `ViewportOverlay` with a new private label widget that derives display text via `context.selectViewportState`, and keep existing zoom/input overlay behavior unchanged.

**Tech Stack:** Flutter widgets (`Stack`, `Positioned`), `BuildContext` state selectors from `ViewportNotifierProvider`, Dart widget tests, `dart analyze`, `dart test`, `dart format`.

---

Execution note: follow @superpowers/test-driven-development for task flow and @superpowers/verification-before-completion before final success claims.

### Task 1: Add Failing Overlay Tests for Cursor Position Label

**Files:**
- Modify: `test/src/ui/viewport_overlay_test.dart`

**Step 1: Write the failing test**

Add tests in `group('ViewportOverlay')`:

```dart
testWidgets('shows cursor position label with default value', (tester) async {
  await _pumpOverlay(tester);

  expect(find.text('X: 0.0, Y: 0.0'), findsOneWidget);
});

testWidgets('updates cursor position label with one decimal precision', (
  tester,
) async {
  final notifier = await _pumpOverlay(tester);

  notifier.value = notifier.value.copyWith(
    cursorPosition: const Offset(3.25, -4),
  );
  await tester.pump();

  expect(find.text('X: 3.3, Y: -4.0'), findsOneWidget);
});
```

In `group('ViewportOverlay composition')`, extend expectations in
`does not rebuild wrapper when state changes` to keep validating zoom and input
plus the new cursor label:

```dart
expect(find.text('X: 3.0, Y: 4.0'), findsOneWidget);
```

**Step 2: Run test to verify it fails**

Run:
`dart test test/src/ui/viewport_overlay_test.dart -r expanded`

Expected: FAIL because `ViewportOverlay` does not render cursor coordinates yet.

**Step 3: Write minimal implementation**

No implementation in this task.

**Step 4: Run test to verify it still fails for expected reason**

Run:
`dart test test/src/ui/viewport_overlay_test.dart -r expanded`

Expected: same failure mode tied to missing cursor label.

**Step 5: Commit**

Do not commit yet; continue to Task 2 so test + implementation land together.

### Task 2: Implement Bottom-Right Cursor Position Label in Overlay

**Files:**
- Modify: `lib/src/ui/viewport_overlay.dart`
- Test: `test/src/ui/viewport_overlay_test.dart`

**Step 1: Write the failing test**

Use Task 1 tests as the active red bar.

**Step 2: Run test to verify it fails**

Run:
`dart test test/src/ui/viewport_overlay_test.dart -r expanded`

Expected: FAIL pre-implementation.

**Step 3: Write minimal implementation**

1. Add `_ViewportCursorPositionLabel()` to `ViewportOverlay` stack.
2. Implement the widget with right alignment:

```dart
class _ViewportCursorPositionLabel extends StatelessWidget {
  const _ViewportCursorPositionLabel();

  @override
  Widget build(BuildContext context) {
    final cursorLabel = context.selectViewportState((state) {
      final x = state.cursorPosition.dx.toStringAsFixed(1);
      final y = state.cursorPosition.dy.toStringAsFixed(1);
      return 'X: $x, Y: $y';
    });

    return Positioned(
      right: _viewportOverlayOffset,
      bottom: _viewportOverlayOffset,
      child: _OverlayChip(text: cursorLabel),
    );
  }
}
```

3. Keep zoom label behavior unchanged (left side, clickable reset).
4. Keep user input label behavior unchanged.

**Step 4: Run test to verify it passes**

Run:
`dart test test/src/ui/viewport_overlay_test.dart -r expanded`

Expected: PASS for overlay tests, including new cursor label assertions.

**Step 5: Commit**

```bash
git add test/src/ui/viewport_overlay_test.dart lib/src/ui/viewport_overlay.dart
git commit -m "feat: add persistent cursor position viewport label"
```

### Task 3: Dot Shorthand Style Pass + Formatting

**Files:**
- Modify: changed Dart files from Tasks 1-2 (only if needed):
  - `lib/src/ui/viewport_overlay.dart`
  - `test/src/ui/viewport_overlay_test.dart`

**Step 1: Write the failing test**

Review changed lines for avoidable non-dot shorthand in typed contexts.

**Step 2: Run test to verify it fails**

If any eligible non-dot shorthand exists in changed lines, treat that as style
failure until fixed.

**Step 3: Write minimal implementation**

Apply shorthand conversions in changed lines where type context allows.

**Step 4: Run test to verify it passes**

Run:
`dart format lib/src/ui/viewport_overlay.dart test/src/ui/viewport_overlay_test.dart`

Expected: formatting succeeds with no remaining style deltas.

**Step 5: Commit**

If this task changed files, amend via a new commit (do not amend previous):

```bash
git add lib/src/ui/viewport_overlay.dart test/src/ui/viewport_overlay_test.dart
git commit -m "style: apply dot shorthand and format cursor label changes"
```

### Task 4: Full Verification Before Completion

**Files:**
- Verify: implementation and tests from Tasks 1-3

**Step 1: Write the failing test**

Use repo verification commands as the quality gate.

**Step 2: Run test to verify it fails**

If any command fails, stop and fix before completion.

**Step 3: Write minimal implementation**

Address failures only in impacted files and rerun the failed command.

**Step 4: Run test to verify it passes**

Run in this order:
1. `dart analyze`
2. `dart test test/src/ui/viewport_overlay_test.dart -r expanded`
3. `dart test`

Expected: all commands PASS.

Golden note: no paint algorithm change is expected, so golden runs are not
mandatory unless test failures indicate visual regressions.

**Step 5: Commit**

If Task 4 required code fixes:

```bash
git add <impacted-files>
git commit -m "fix: resolve verification issues for cursor overlay label"
```
