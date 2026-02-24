# Viewport InheritedModel Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace `ViewportStateBuilder` with an `InheritedModel`-based
`selectViewportState` API in
`lib/src/providers/viewport_notifier_provider.dart`, migrate all consumers, and
delete `test/inherited_model_test.dart`.

**Architecture:** Keep `ViewportNotifier` access as an action-only dependency
through `context.viewportNotifier`, and add a state dependency channel through
an `InheritedModel` keyed by selector functions (`selectViewportState`). `ViewportNotifierProvider`
will rebuild only the state model layer via `ValueListenableBuilder`, so widgets
rebuild only when their selected state projection changes.

**Tech Stack:** Flutter `InheritedWidget`/`InheritedModel`,
`ValueListenableBuilder`, Dart records/pattern matching, widget tests.

---

### Task 1: Lock In New Selector-Dependency Behavior (TDD First)

**Files:**
- Modify: `test/src/providers/viewport_notifier_provider_test.dart`
- Reference/Migrate behavior from: `test/inherited_model_test.dart`

**Step 1: Write the failing test**

Add tests to `viewport_notifier_provider_test.dart` that verify:
1. `context.selectViewportState((state) => state.zoom)` rebuilds when zoom changes.
2. `context.selectViewportState((state) => state.zoom)` does not rebuild when only
   pan/cursor/user input changes.
3. `context.selectViewportState((state) => (state.zoom, state.panOffset))` returns mapped
   record values correctly.

Use build counters to assert selective rebuild behavior, matching the dependency
pattern shown in `test/inherited_model_test.dart`.

**Step 2: Run test to verify it fails**

Run:
`dart test test/src/providers/viewport_notifier_provider_test.dart -r expanded`

Expected: test compile/runtime failure because `selectViewportState` + state model wiring
do not exist yet.

**Step 3: Write minimal implementation**

No implementation in this task. Move to Task 2 after confirming failure.

**Step 4: Run test to verify it still fails for the expected reason**

Run:
`dart test test/src/providers/viewport_notifier_provider_test.dart -r expanded`

Expected: same missing-API/state-model failure mode.

**Step 5: Checkpoint (No commit)**

Confirm the test file changes are staged only for local review if needed, but do
not run `git commit`.

### Task 2: Implement InheritedModel + selectViewportState in Provider

**Files:**
- Modify: `lib/src/providers/viewport_notifier_provider.dart`

**Step 1: Write the failing test**

Use Task 1 tests as the red bar.

**Step 2: Run test to verify it fails**

Run:
`dart test test/src/providers/viewport_notifier_provider_test.dart -r expanded`

Expected: fail before provider changes.

**Step 3: Write minimal implementation**

Refactor `viewport_notifier_provider.dart` to:
1. Add selector typedef (for model aspects), e.g.
   `typedef ViewportStateSelector<T> = T Function(ViewportState state);`
2. Keep `context.viewportNotifier` for actions (no state dependency).
3. Add a private `InheritedModel` holding `ViewportState` and implementing:
   - `updateShouldNotify` (state identity/equality change)
   - `updateShouldNotifyDependent` (run each registered selector against old/new
     state and notify only if mapped value changed)
4. Wrap `widget.child` in `ValueListenableBuilder<ViewportState>` inside
   `ViewportNotifierProvider.build`, producing the inherited model.
5. Add `BuildContext.selectViewportState<T>(ViewportStateSelector<T> selector)` extension.
6. Remove `ViewportStateBuilder` widget/state classes entirely.
7. Update provider comments to point to `selectViewportState` instead of
   `ViewportStateBuilder`.

**Step 4: Run test to verify it passes**

Run:
`dart test test/src/providers/viewport_notifier_provider_test.dart -r expanded`

Expected: all provider tests pass with selective rebuild assertions.

**Step 5: Checkpoint (No commit)**

Confirm provider refactor compiles and tests pass locally; do not run
`git commit`.

### Task 3: Migrate All View Consumers off ViewportStateBuilder

**Files:**
- Modify: `lib/src/ui/grid_paint.dart`
- Modify: `lib/src/ui/viewport_paint.dart`
- Modify: `lib/src/ui/selection_paint.dart`
- Modify: `lib/src/ui/snapping_viewport_paint.dart`
- Modify: `lib/src/ui/tool_viewport_paint.dart`
- Modify: `lib/src/ui/cursor_paint.dart`
- Modify: `lib/src/ui/toolbar.dart`

**Step 1: Write the failing test**

Create a migration guard check:
`rg -n "ViewportStateBuilder" lib/src/ui lib/src/providers`

Expected now: matches still present (pre-migration), which is the failure
condition for this task.

**Step 2: Run test to verify it fails**

Run existing UI tests before edits to establish baseline:
`dart test test/src/ui/viewport_paints_test.dart test/src/ui/cursor_paint_test.dart test/src/ui/toolbar_test.dart -r expanded`

Expected: pass before migration.

**Step 3: Write minimal implementation**

For each listed UI file:
1. Replace `ViewportStateBuilder(select: ..., builder: ...)` usage with direct
   `context.selectViewportState(...)` reads in `build`.
2. Preserve exact selected fields/records currently used per widget.
3. Keep behavior and paint layer semantics unchanged.
4. Keep notifier action calls (`context.viewportNotifier`) unchanged.

**Step 4: Run test to verify it passes**

Run:
1. `rg -n "ViewportStateBuilder" lib/src/ui lib/src/providers`
   Expected: no matches.
2. `dart test test/src/ui/viewport_paints_test.dart test/src/ui/cursor_paint_test.dart test/src/ui/toolbar_test.dart -r expanded`
   Expected: all pass.

**Step 5: Checkpoint (No commit)**

Confirm all migrated UI files are ready for your manual review; do not run
`git commit`.

### Task 4: Remove Temporary InheritedModel Demo Test

**Files:**
- Delete: `test/inherited_model_test.dart`

**Step 1: Write the failing test**

Run:
`test -f test/inherited_model_test.dart`

Expected: success (file currently exists), which is failure for desired end
state.

**Step 2: Run test to verify it fails end-state expectation**

Run:
`test -f test/inherited_model_test.dart`

Expected: success (still present).

**Step 3: Write minimal implementation**

Delete `test/inherited_model_test.dart` after provider-level tests fully cover
the same dependency semantics.

**Step 4: Run test to verify it passes**

Run:
`test ! -f test/inherited_model_test.dart && rg -n "inherited_model_test" test`

Expected: file absence check passes; no references remain.

**Step 5: Checkpoint (No commit)**

Confirm test cleanup is complete and references are removed; do not run
`git commit`.

### Task 5: Dot Shorthand Pass + Full Verification

**Files:**
- Modify: changed Dart files from Tasks 1-3 (only if style updates required)

**Step 1: Write the failing test**

Run Dart LSP code actions on each changed Dart file and apply any
dot-shorthand conversion actions.

Then run a quick grep audit on changed lines/files to detect obvious
non-dot shorthand candidates.

**Step 2: Run test to verify it fails**

If code actions or audit reveal eligible shorthand conversions, treat as failure
until applied.

**Step 3: Write minimal implementation**

Apply code actions/manual edits for eligible shorthand in changed lines only.

**Step 4: Run test to verify it passes**

Run verification in this order:
1. `dart analyze`
2. `dart test`
3. `dart format lib test`
4. Re-run impacted tests:
   `dart test test/src/providers/viewport_notifier_provider_test.dart test/src/ui/viewport_paints_test.dart test/src/ui/cursor_paint_test.dart test/src/ui/toolbar_test.dart -r expanded`

Expected: all commands pass.

Golden coverage note: this refactor changes state subscription mechanics but not
paint algorithms; if any viewport-layer golden tests are added/identified during
implementation, run them before finalizing.

**Step 5: Checkpoint (No commit)**

Collect verification outputs for your review and stop without committing.
