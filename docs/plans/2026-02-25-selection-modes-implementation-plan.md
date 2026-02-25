# Selection Modes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement window, crossing, and `Alt+drag` lasso crossing selection with closed smooth preview, live preview highlights, and `Shift` additive merge while preserving existing click-selection and active-tool behavior.

**Architecture:** Keep pointer routing in `viewport.dart` and all state mutation in `ViewportNotifier`. Move selection matching ownership to geometry classes via three new abstract methods on `Geometry`, with each concrete geometry implementing its own mode-specific algorithm. Keep rendering layer order unchanged by reusing `toolGeometries` for drag previews and `selectionGeometries` for preview/selected highlights.

**Tech Stack:** Dart 3, Flutter widgets/pointer events, `flutter_test`, existing notifier/provider architecture.

---

Use @superpowers/test-driven-development for each task loop and @superpowers/verification-before-completion before final completion.

### Task 1: Geometry Selection Contract + Point/Line Implementations

**Files:**
- Create: `lib/src/geometry/selection_math.dart`
- Modify: `lib/src/geometry/geometry.dart`
- Modify: `lib/src/geometry/point.dart`
- Modify: `lib/src/geometry/line.dart`
- Create: `test/src/geometry/selection_matching_test.dart`

**Step 1: Write the failing tests (Point + Line)**

```dart
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point selection matching', () {
    const point = Point(position: Offset(5, 5), color: .primary, shape: .square);
    const rect = Rect.fromLTRB(0, 0, 10, 10);
    const lasso = [Offset(0, 0), Offset(10, 0), Offset(10, 10), Offset(0, 10)];

    test('window returns true when point is inside rect', () {
      expect(point.matchesWindowSelection(rect), isTrue);
    });

    test('lasso crossing returns false when point is outside polygon', () {
      const outside = Point(position: Offset(20, 20), color: .primary, shape: .square);
      expect(outside.matchesLassoCrossingSelection(lasso), isFalse);
    });
  });

  group('Line selection matching', () {
    const horizontal = Line(
      start: Offset(-5, 5),
      end: Offset(15, 5),
      color: .primary,
    );

    test('window requires both endpoints inside rect', () {
      const rect = Rect.fromLTRB(0, 0, 10, 10);
      expect(horizontal.matchesWindowSelection(rect), isFalse);
    });

    test('crossing matches when line intersects rect edge', () {
      const rect = Rect.fromLTRB(0, 0, 10, 10);
      expect(horizontal.matchesCrossingSelection(rect), isTrue);
    });

    test('lasso crossing matches when line intersects polygon edge', () {
      const lasso = [
        Offset(0, 0),
        Offset(10, 0),
        Offset(10, 10),
        Offset(0, 10),
      ];
      expect(horizontal.matchesLassoCrossingSelection(lasso), isTrue);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `dart test test/src/geometry/selection_matching_test.dart -r expanded`
Expected: FAIL with missing `matchesWindowSelection` / `matchesCrossingSelection` / `matchesLassoCrossingSelection` definitions.

**Step 3: Write minimal implementation**

`lib/src/geometry/geometry.dart`

```dart
abstract class Geometry {
  // ...existing API...

  bool matchesWindowSelection(Rect rect);

  bool matchesCrossingSelection(Rect rect);

  bool matchesLassoCrossingSelection(List<Offset> closedLassoPath);
}
```

`lib/src/geometry/selection_math.dart`

```dart
import 'dart:ui';

bool isPointInsideClosedPolygon(Offset point, List<Offset> polygon) {
  if (polygon.length < 3) return false;
  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final pi = polygon[i];
    final pj = polygon[j];
    final intersects =
        ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
        (point.dx < (pj.dx - pi.dx) * (point.dy - pi.dy) / ((pj.dy - pi.dy) == 0 ? 1 : (pj.dy - pi.dy)) + pi.dx);
    if (intersects) inside = !inside;
  }
  return inside;
}

List<(Offset, Offset)> closedEdges(List<Offset> points) {
  if (points.length < 2) return const [];
  final edges = <(Offset, Offset)>[];
  for (var i = 0; i < points.length - 1; i++) {
    edges.add((points[i], points[i + 1]));
  }
  edges.add((points.last, points.first));
  return edges;
}

bool segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  double cross(Offset p, Offset q, Offset r) {
    return (q.dx - p.dx) * (r.dy - p.dy) - (q.dy - p.dy) * (r.dx - p.dx);
  }

  bool onSegment(Offset p, Offset q, Offset r) {
    return q.dx >= (p.dx < r.dx ? p.dx : r.dx) &&
        q.dx <= (p.dx > r.dx ? p.dx : r.dx) &&
        q.dy >= (p.dy < r.dy ? p.dy : r.dy) &&
        q.dy <= (p.dy > r.dy ? p.dy : r.dy);
  }

  final d1 = cross(a1, a2, b1);
  final d2 = cross(a1, a2, b2);
  final d3 = cross(b1, b2, a1);
  final d4 = cross(b1, b2, a2);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }

  if (d1 == 0 && onSegment(a1, b1, a2)) return true;
  if (d2 == 0 && onSegment(a1, b2, a2)) return true;
  if (d3 == 0 && onSegment(b1, a1, b2)) return true;
  if (d4 == 0 && onSegment(b1, a2, b2)) return true;

  return false;
}

List<(Offset, Offset)> rectEdges(Rect rect) {
  final topLeft = rect.topLeft;
  final topRight = rect.topRight;
  final bottomRight = rect.bottomRight;
  final bottomLeft = rect.bottomLeft;
  return [
    (topLeft, topRight),
    (topRight, bottomRight),
    (bottomRight, bottomLeft),
    (bottomLeft, topLeft),
  ];
}
```

`lib/src/geometry/point.dart`

```dart
@override
bool matchesWindowSelection(Rect rect) => rect.contains(position);

@override
bool matchesCrossingSelection(Rect rect) => rect.contains(position);

@override
bool matchesLassoCrossingSelection(List<Offset> closedLassoPath) {
  return isPointInsideClosedPolygon(position, closedLassoPath);
}
```

`lib/src/geometry/line.dart`

```dart
@override
bool matchesWindowSelection(Rect rect) {
  return rect.contains(start) && rect.contains(end);
}

@override
bool matchesCrossingSelection(Rect rect) {
  if (rect.contains(start) || rect.contains(end)) return true;
  for (final (a, b) in rectEdges(rect)) {
    if (segmentsIntersect(start, end, a, b)) return true;
  }
  return false;
}

@override
bool matchesLassoCrossingSelection(List<Offset> closedLassoPath) {
  if (isPointInsideClosedPolygon(start, closedLassoPath) ||
      isPointInsideClosedPolygon(end, closedLassoPath)) {
    return true;
  }
  for (final (a, b) in closedEdges(closedLassoPath)) {
    if (segmentsIntersect(start, end, a, b)) return true;
  }
  return false;
}
```

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/geometry/selection_matching_test.dart -r expanded`
Expected: PASS for Point + Line cases.

**Step 5: Commit**

```bash
git add lib/src/geometry/geometry.dart \
  lib/src/geometry/selection_math.dart \
  lib/src/geometry/point.dart \
  lib/src/geometry/line.dart \
  test/src/geometry/selection_matching_test.dart
git commit -m "feat: add geometry selection contract with point and line matching"
```

### Task 2: Circle and Arc Selection Algorithms

**Files:**
- Modify: `lib/src/geometry/circle.dart`
- Modify: `lib/src/geometry/arc.dart`
- Modify: `lib/src/geometry/selection_math.dart`
- Modify: `test/src/geometry/selection_matching_test.dart`

**Step 1: Extend failing tests (Circle + Arc)**

```dart
group('Circle selection matching', () {
  const circle = Circle(center: Offset(10, 10), radius: 5, color: .primary);

  test('window requires full circle containment', () {
    const tightRect = Rect.fromLTRB(8, 8, 12, 12);
    expect(circle.matchesWindowSelection(tightRect), isFalse);
  });

  test('crossing matches boundary intersection', () {
    const rect = Rect.fromLTRB(0, 0, 12, 12);
    expect(circle.matchesCrossingSelection(rect), isTrue);
  });
});

group('Arc selection matching', () {
  final arc = Arc.fromPoints(
    first: const Offset(0, 10),
    second: const Offset(10, 0),
    third: const Offset(20, 10),
    color: .primary,
  );

  test('window only matches when sampled arc points are contained', () {
    const rect = Rect.fromLTRB(4, 4, 16, 16);
    expect(arc.matchesWindowSelection(rect), isFalse);
  });

  test('crossing matches when sampled segments hit rect', () {
    const rect = Rect.fromLTRB(9, 0, 11, 20);
    expect(arc.matchesCrossingSelection(rect), isTrue);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `dart test test/src/geometry/selection_matching_test.dart -r expanded`
Expected: FAIL for `Circle`/`Arc` unimplemented abstract methods.

**Step 3: Write minimal implementation**

`lib/src/geometry/selection_math.dart` (additions)

```dart
bool segmentIntersectsRect(Offset start, Offset end, Rect rect) {
  if (rect.contains(start) || rect.contains(end)) return true;
  for (final (a, b) in rectEdges(rect)) {
    if (segmentsIntersect(start, end, a, b)) return true;
  }
  return false;
}

bool segmentIntersectsPolygon(
  Offset start,
  Offset end,
  List<Offset> closedPolygon,
) {
  if (closedPolygon.length < 3) return false;
  if (isPointInsideClosedPolygon(start, closedPolygon) ||
      isPointInsideClosedPolygon(end, closedPolygon)) {
    return true;
  }
  for (final (a, b) in closedEdges(closedPolygon)) {
    if (segmentsIntersect(start, end, a, b)) return true;
  }
  return false;
}
```

`lib/src/geometry/circle.dart`

```dart
@override
bool matchesWindowSelection(Rect rect) {
  return rect.contains(center + Offset(radius, 0)) &&
      rect.contains(center + Offset(-radius, 0)) &&
      rect.contains(center + Offset(0, radius)) &&
      rect.contains(center + Offset(0, -radius));
}

@override
bool matchesCrossingSelection(Rect rect) {
  if (matchesWindowSelection(rect) || rect.contains(center)) {
    return true;
  }

  for (final (a, b) in rectEdges(rect)) {
    if (_segmentDistanceToCenter(a, b) <= radius) return true;
  }

  return false;
}

@override
bool matchesLassoCrossingSelection(List<Offset> closedLassoPath) {
  if (isPointInsideClosedPolygon(center, closedLassoPath)) {
    return true;
  }

  for (final (a, b) in closedEdges(closedLassoPath)) {
    if (_segmentDistanceToCenter(a, b) <= radius) return true;
  }

  return false;
}
```

`lib/src/geometry/arc.dart`

```dart
List<Offset> _samplePoints({int segments = 24}) {
  return [
    for (var i = 0; i <= segments; i++)
      center + Offset.fromDirection(startAngle + sweepAngle * (i / segments), radius),
  ];
}

@override
bool matchesWindowSelection(Rect rect) {
  return _samplePoints().every(rect.contains);
}

@override
bool matchesCrossingSelection(Rect rect) {
  final points = _samplePoints();
  if (points.any(rect.contains)) return true;
  for (var i = 0; i < points.length - 1; i++) {
    if (segmentIntersectsRect(points[i], points[i + 1], rect)) return true;
  }
  return false;
}

@override
bool matchesLassoCrossingSelection(List<Offset> closedLassoPath) {
  final points = _samplePoints();
  if (points.any((point) => isPointInsideClosedPolygon(point, closedLassoPath))) {
    return true;
  }
  for (var i = 0; i < points.length - 1; i++) {
    if (segmentIntersectsPolygon(points[i], points[i + 1], closedLassoPath)) {
      return true;
    }
  }
  return false;
}
```

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/geometry/selection_matching_test.dart -r expanded`
Expected: PASS for Point/Line/Circle/Arc matching tests.

**Step 5: Commit**

```bash
git add lib/src/geometry/circle.dart \
  lib/src/geometry/arc.dart \
  lib/src/geometry/selection_math.dart \
  test/src/geometry/selection_matching_test.dart
git commit -m "feat: implement circle and arc selection matching algorithms"
```

### Task 3: Drag Selection Session + Lasso Preview in ViewportNotifier

**Files:**
- Modify: `lib/src/logic/viewport_notifier.dart`
- Modify: `lib/src/constants/config.dart`
- Create: `lib/src/logic/lasso_path_builder.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`

**Step 1: Write failing notifier tests**

Add test coverage for:

- Left-to-right drag uses window selection semantics.
- Right-to-left drag uses crossing selection semantics.
- `Alt+drag` builds lasso-crossing session and preview highlights update during drag.
- `Shift` finalization adds matches to existing selection.
- Active drawing tool prevents drag-selection session from starting.

Example test skeleton:

```dart
test('left-to-right drag applies window selection', () {
  final notifier = ViewportNotifier()
    ..addGeometries(const [
      Line(start: Offset(1, 1), end: Offset(3, 3), color: .primary),
      Line(start: Offset(2, 2), end: Offset(20, 2), color: .primary),
    ]);

  notifier.onPointerDown(
    viewportPosition: .zero,
    viewportMidPoint: .zero,
    altPressed: false,
    shiftPressed: false,
  );
  notifier.onCursorMove(
    viewportPosition: const Offset(50, 50),
    viewportMidPoint: .zero,
  );
  notifier.onPointerUp();

  expect(notifier.value.selectionGeometries, hasLength(1));
});
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/logic/viewport_notifier_test.dart -r expanded`
Expected: FAIL due to missing drag-selection APIs and logic.

**Step 3: Write minimal implementation**

`lib/src/constants/config.dart` (add thresholds)

```dart
const selectionDragStartDistance = 2.0;
const lassoMinSamples = 3;
```

`lib/src/logic/lasso_path_builder.dart`

```dart
import 'dart:ui';

List<Offset> buildClosedQuadraticPreviewPoints(List<Offset> samples) {
  if (samples.length < 2) return samples;

  final points = <Offset>[samples.first];
  for (var i = 1; i < samples.length; i++) {
    final previous = samples[i - 1];
    final current = samples[i];
    points.add((previous + current) / 2);
    points.add(current);
  }

  if (points.first != points.last) {
    points.add(points.first);
  }

  return points;
}
```

`lib/src/logic/viewport_notifier.dart` (core API changes)

```dart
void onPointerDown({
  required Offset viewportPosition,
  required Offset viewportMidPoint,
  required bool altPressed,
  required bool shiftPressed,
}) {
  _updateCursorFromViewport(viewportPosition, viewportMidPoint);
  if (_toolAction != null) return;
  _startSelectionSession(
    start: value.cursorPosition,
    mode: altPressed ? SelectionDragMode.lassoCrossing : null,
    additive: shiftPressed,
  );
}

void onPointerUp() {
  if (_isDragSelecting && _dragMovedEnough()) {
    _finalizeDragSelection();
    return;
  }

  _cancelDragPreview();
  onCursorClick();
}
```

And in `onCursorMove`:

- Preserve existing snapping/hover behavior.
- If drag session active and no tool, update rectangle/lasso preview + live candidate highlights.
- For rectangle, call geometry `matchesWindowSelection` or `matchesCrossingSelection`.
- For lasso, call geometry `matchesLassoCrossingSelection` with closed lasso points.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/logic/viewport_notifier_test.dart -r expanded`
Expected: PASS including new drag-selection behavior.

**Step 5: Commit**

```bash
git add lib/src/constants/config.dart \
  lib/src/logic/lasso_path_builder.dart \
  lib/src/logic/viewport_notifier.dart \
  test/src/logic/viewport_notifier_test.dart
git commit -m "feat: add drag selection lifecycle for window crossing and lasso"
```

### Task 4: Viewport Pointer Wiring and UI Regression Tests

**Files:**
- Modify: `lib/src/ui/viewport.dart`
- Modify: `test/src/ui/viewport_test.dart`

**Step 1: Write failing viewport tests**

Add tests that exercise real pointer down/move/up flow:

- Drag from left-to-right selects only fully contained geometry.
- Drag from right-to-left selects intersecting geometry.
- Click selection regression still passes.

Example test skeleton:

```dart
testWidgets('drag selection runs through pointer down/move/up', (tester) async {
  final notifier = await _pumpViewport(tester);
  notifier.addGeometries(const [
    Line(start: Offset(0, 0), end: Offset(10, 0), color: .primary),
  ]);

  final mouse = await tester.createGesture(kind: .mouse);
  final center = tester.getCenter(find.byType(Viewport));

  await mouse.addPointer(location: center);
  await mouse.down(center + const Offset(-20, -20));
  await mouse.moveTo(center + const Offset(40, 20));
  await mouse.up();
  await tester.pump();

  expect(notifier.value.selectionGeometries, isNotEmpty);
});
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/ui/viewport_test.dart -r expanded`
Expected: FAIL until viewport forwards pointer down/up drag APIs.

**Step 3: Write minimal implementation**

`lib/src/ui/viewport.dart`:

```dart
import 'package:flutter/services.dart';

bool _isAltPressed() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.altLeft) ||
      keys.contains(LogicalKeyboardKey.altRight);
}

bool _isShiftPressed() {
  final keys = HardwareKeyboard.instance.logicalKeysPressed;
  return keys.contains(LogicalKeyboardKey.shiftLeft) ||
      keys.contains(LogicalKeyboardKey.shiftRight);
}

onPointerDown: (event) {
  if (context.size case final size?) {
    context.viewportNotifier.onPointerDown(
      viewportPosition: event.localPosition,
      viewportMidPoint: Offset(size.width, size.height) / 2,
      altPressed: _isAltPressed(),
      shiftPressed: _isShiftPressed(),
    );
  }
},
onPointerUp: (_) => context.viewportNotifier.onPointerUp(),
```

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/ui/viewport_test.dart -r expanded`
Expected: PASS for drag selection routing and click regression.

**Step 5: Commit**

```bash
git add lib/src/ui/viewport.dart test/src/ui/viewport_test.dart
git commit -m "feat: wire viewport pointer down/up for drag selection"
```

### Task 5: Full Verification, Dot-Shorthand Pass, and Final Commit

**Files:**
- Modify: any files changed by formatter or dot-shorthand actions

**Step 1: Run static analysis**

Run: `dart analyze`
Expected: PASS (no errors).

**Step 2: Run targeted test set**

Run:

```bash
dart test test/src/geometry/selection_matching_test.dart -r expanded
dart test test/src/logic/viewport_notifier_test.dart -r expanded
dart test test/src/ui/viewport_test.dart -r expanded
```

Expected: PASS.

**Step 3: Run impacted golden/regression suites**

Run:

```bash
dart test test/src/ui/viewport_paints_test.dart -r expanded
dart test test/src/geometry/point_test.dart test/src/geometry/line_test.dart test/src/geometry/arc_test.dart -r expanded
```

Expected: PASS (no unintended rendering regressions).

**Step 4: Apply style pass + format**

- Use Dart MCP code actions on changed Dart files; apply available dot-shorthand conversions.
- Confirm no avoidable non-dot shorthand remains in changed lines.
- Run: `dart format lib test`

Expected: formatting/style clean.

**Step 5: Final commit**

```bash
git add -A
git commit -m "feat: implement window crossing and lasso crossing selection modes"
```

