# Dependency and Macro Removal Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the macros dependency, migrate `ViewportState` to manual data-class methods, update SDK/dependencies to current local versions, and lock behavior with extensive model tests.

**Architecture:** Keep all behavior changes in the data layer by updating `lib/src/data/viewport_state.dart`, leaving mutation ownership in `ViewportNotifier` unchanged. Replace generated behavior with explicit `copyWith`, `operator ==`, and `hashCode`, then validate through focused model tests and repo-wide verification. Dependency and SDK updates are isolated to `pubspec.yaml`/`pubspec.lock`.

**Tech Stack:** Dart 3.10.8, Flutter 3.38.9, Flutter test, `collection` deep equality helpers, git.

---

Execution guardrails:
- `@test-driven-development`: write failing tests first for model behavior.
- `@systematic-debugging`: if tests fail unexpectedly after dependency updates.
- `@verification-before-completion`: do not claim done without command output.

### Task 1: Add Failing `ViewportState` Model Tests

**Files:**
- Create: `test/src/data/viewport_state_test.dart`
- Test: `test/src/data/viewport_state_test.dart`

**Step 1: Write the failing test**

Create `test/src/data/viewport_state_test.dart` with comprehensive tests:

```dart
import 'package:arcadia/src/data/viewport_state.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ViewportState', () {
    test('has expected defaults', () {
      const state = ViewportState();
      expect(state.geometries, isEmpty);
      expect(state.toolGeometries, isEmpty);
      expect(state.snappingGeometries, isEmpty);
      expect(state.selectionGeometries, isEmpty);
      expect(state.zoom, 1.0);
      expect(state.panOffset, Offset.zero);
      expect(state.cursorPosition, Offset.zero);
      expect(state.selectedTool, isNull);
      expect(state.userInput, '');
    });

    test('copyWith updates all non-nullable fields', () {
      const line = Line(start: Offset.zero, end: Offset(1, 1));
      const state = ViewportState();
      final updated = state.copyWith(
        geometries: [line],
        toolGeometries: [line],
        snappingGeometries: [line],
        selectionGeometries: [line],
        zoom: 2,
        panOffset: Offset(3, 4),
        cursorPosition: Offset(5, 6),
        userInput: '42',
      );
      expect(updated.geometries, hasLength(1));
      expect(updated.toolGeometries, hasLength(1));
      expect(updated.snappingGeometries, hasLength(1));
      expect(updated.selectionGeometries, hasLength(1));
      expect(updated.zoom, 2);
      expect(updated.panOffset, const Offset(3, 4));
      expect(updated.cursorPosition, const Offset(5, 6));
      expect(updated.userInput, '42');
    });

    test('copyWith can set selectedTool and can explicitly clear it', () {
      const state = ViewportState(selectedTool: LineTool());
      final cleared = state.copyWith(selectedTool: null);
      expect(cleared.selectedTool, isNull);
    });

    test('uses deep equality for all list fields', () {
      const left = ViewportState(
        geometries: [Line(start: Offset.zero, end: Offset(1, 1))],
      );
      const right = ViewportState(
        geometries: [Line(start: Offset.zero, end: Offset(1, 1))],
      );
      expect(left, equals(right));
      expect(left.hashCode, right.hashCode);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: FAIL due missing/incorrect manual methods until migration is implemented.

**Step 3: Write minimal implementation**

No implementation in this task.

**Step 4: Run test to verify it still fails**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: still FAIL (red phase complete).

**Step 5: Commit**

```bash
git add test/src/data/viewport_state_test.dart
git commit -m "test: add failing viewport state model tests"
```

### Task 2: Implement Manual `ViewportState` Data Methods

**Files:**
- Modify: `lib/src/data/viewport_state.dart`
- Test: `test/src/data/viewport_state_test.dart`

**Step 1: Write the failing test**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: FAIL before method implementation.

**Step 2: Run test to verify it fails**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: FAIL with assertion or missing method behavior.

**Step 3: Write minimal implementation**

Replace macro usage and add explicit methods in `lib/src/data/viewport_state.dart`:

```dart
import 'dart:ui';

import 'package:collection/collection.dart';

import '../geometry/geometry.dart';
import '../tools/tool.dart';

const _unset = Object();

class ViewportState {
  const ViewportState({
    this.geometries = const [],
    this.toolGeometries = const [],
    this.snappingGeometries = const [],
    this.selectionGeometries = const [],
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
    this.cursorPosition = Offset.zero,
    this.selectedTool,
    this.userInput = '',
  });

  final List<Geometry> geometries;
  final List<Geometry> toolGeometries;
  final List<Geometry> snappingGeometries;
  final List<Geometry> selectionGeometries;
  final double zoom;
  final Offset panOffset;
  final Offset cursorPosition;
  final Tool? selectedTool;
  final String userInput;

  static const _geometryListEquality = ListEquality<Geometry>();

  ViewportState copyWith({
    List<Geometry>? geometries,
    List<Geometry>? toolGeometries,
    List<Geometry>? snappingGeometries,
    List<Geometry>? selectionGeometries,
    double? zoom,
    Offset? panOffset,
    Offset? cursorPosition,
    Object? selectedTool = _unset,
    String? userInput,
  }) {
    return ViewportState(
      geometries: geometries ?? this.geometries,
      toolGeometries: toolGeometries ?? this.toolGeometries,
      snappingGeometries: snappingGeometries ?? this.snappingGeometries,
      selectionGeometries: selectionGeometries ?? this.selectionGeometries,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      selectedTool: identical(selectedTool, _unset)
          ? this.selectedTool
          : selectedTool as Tool?,
      userInput: userInput ?? this.userInput,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ViewportState &&
            _geometryListEquality.equals(geometries, other.geometries) &&
            _geometryListEquality.equals(toolGeometries, other.toolGeometries) &&
            _geometryListEquality.equals(
              snappingGeometries,
              other.snappingGeometries,
            ) &&
            _geometryListEquality.equals(
              selectionGeometries,
              other.selectionGeometries,
            ) &&
            zoom == other.zoom &&
            panOffset == other.panOffset &&
            cursorPosition == other.cursorPosition &&
            selectedTool == other.selectedTool &&
            userInput == other.userInput;
  }

  @override
  int get hashCode {
    return Object.hash(
      _geometryListEquality.hash(geometries),
      _geometryListEquality.hash(toolGeometries),
      _geometryListEquality.hash(snappingGeometries),
      _geometryListEquality.hash(selectionGeometries),
      zoom,
      panOffset,
      cursorPosition,
      selectedTool,
      userInput,
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/data/viewport_state.dart test/src/data/viewport_state_test.dart
git commit -m "feat: add manual viewport state copyWith equality and hashCode"
```

### Task 3: Remove Macro Source and Macro Tests

**Files:**
- Delete: `lib/src/macros/data.dart`
- Delete: `test/src/macros/data_test.dart`
- Test: `lib/src/data/viewport_state.dart`, `test/src/data/viewport_state_test.dart`

**Step 1: Write the failing test**

Run: `rg -n "macros|@Data|src/macros/data.dart" lib test pubspec.yaml`
Expected: matches found before cleanup.

**Step 2: Run test to verify it fails**

Run: `rg -n "macros|@Data|src/macros/data.dart" lib test pubspec.yaml`
Expected: non-empty output (failure for cleanup condition).

**Step 3: Write minimal implementation**

- Delete `lib/src/macros/data.dart`.
- Delete `test/src/macros/data_test.dart`.
- Ensure `lib/src/data/viewport_state.dart` has no macro import/annotation.

**Step 4: Run test to verify it passes**

Run: `rg -n "macros|@Data|src/macros/data.dart" lib test pubspec.yaml`
Expected: no results in `lib/` and `test/` (only possible `pubspec.yaml` line until Task 4).

**Step 5: Commit**

```bash
git add -A lib/src/macros test/src/macros lib/src/data/viewport_state.dart
git commit -m "refactor: remove macro-based data generation"
```

### Task 4: Update SDK Constraint and Dependencies

**Files:**
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`
- Test: dependency graph and lock consistency

**Step 1: Write the failing test**

Run: `dart pub outdated`
Expected: shows out-of-date direct dependencies and `macros` still present before edits.

**Step 2: Run test to verify it fails**

Run: `dart pub outdated`
Expected: reports upgrades available (failure for “updated” goal).

**Step 3: Write minimal implementation**

- Update `environment.sdk` to start at `3.10.8`.
- Remove `macros` from dependencies.
- Update direct dependency and dev dependency version constraints to latest
  compatible values.
- Run:

```bash
dart pub upgrade
```

**Step 4: Run test to verify it passes**

Run:

```bash
dart pub get
dart pub outdated
```

Expected: lockfile resolves cleanly; direct dependencies align with newest
compatible versions under the updated constraints.

**Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "build: update sdk and refresh dependencies"
```

### Task 5: Expand Model Regression Coverage

**Files:**
- Modify: `test/src/data/viewport_state_test.dart`
- Test: `test/src/data/viewport_state_test.dart`

**Step 1: Write the failing test**

Add tests for:

- omitted fields remain unchanged in `copyWith`
- every field participating in equality/hash causes inequality when changed
- equal objects keep identical hash code across deep list content
- `copyWith(selectedTool: null)` differs from omitted `selectedTool` argument

Example additions:

```dart
test('copyWith preserves selectedTool when omitted', () {
  const original = ViewportState(selectedTool: LineTool());
  final updated = original.copyWith(userInput: '1');
  expect(updated.selectedTool, same(original.selectedTool));
});

test('different userInput makes states unequal', () {
  const left = ViewportState(userInput: '10');
  const right = ViewportState(userInput: '11');
  expect(left, isNot(equals(right)));
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: FAIL until all assertions align with implementation.

**Step 3: Write minimal implementation**

Adjust only tests and, if needed, tiny implementation fixes in
`lib/src/data/viewport_state.dart` to satisfy explicit behavior contract.

**Step 4: Run test to verify it passes**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: PASS with complete model coverage.

**Step 5: Commit**

```bash
git add lib/src/data/viewport_state.dart test/src/data/viewport_state_test.dart
git commit -m "test: extend viewport state data model regression coverage"
```

### Task 6: Full Verification and Final Cleanup

**Files:**
- Modify: any files required by verification fallout only
- Test: full project checks

**Step 1: Write the failing test**

Run: `dart analyze`
Expected: should pass; if it fails, treat as failure to resolve.

**Step 2: Run test to verify it fails**

Run:

```bash
dart analyze
./run_all_tests.sh
```

Expected: if failures exist, capture exact errors and fix minimally.

**Step 3: Write minimal implementation**

Resolve any analyzer/test failures introduced by dependency updates or model
migration with smallest localized edits.

**Step 4: Run test to verify it passes**

Run:

```bash
dart analyze
./run_all_tests.sh
```

Expected: both commands PASS.

If rendering diffs unexpectedly appear, run impacted goldens before final signoff.

**Step 5: Commit**

```bash
git add -A
git commit -m "chore: complete macro removal and dependency upgrade verification"
```
