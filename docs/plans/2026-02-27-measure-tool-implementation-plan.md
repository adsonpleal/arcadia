# Measure Tool And Geometry Properties Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement a temporary polyline Measure tool plus geometry-owned single-selection property text for the Selection tool.

**Architecture:** Keep selection ownership inside `SelectionToolAction` and measure-session ownership inside a new `MeasureToolAction`. Add display-only overlay labels to `ViewportState`, publish them through `ViewportNotifier`, and keep rendering thin by having `ViewportOverlay` only render preformatted text from state.

**Tech Stack:** Dart, Flutter, `flutter_test`

---

Note: user explicitly requested local workspace execution instead of a dedicated git worktree.

### Task 1: Add Display-Only Overlay State And Tool Hooks

**Files:**
- Modify: `lib/src/data/viewport_state.dart`
- Modify: `lib/src/logic/viewport_notifier.dart`
- Modify: `lib/src/tools/tool.dart`
- Modify: `test/src/data/viewport_state_test.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`
- Modify: `test/src/tools/tool_test.dart`

**Step 1: Write the failing tests**

Add assertions for:

```dart
expect(state.selectionPropertiesLabel, isNull);
expect(state.measureLabel, isNull);

final updated = state.copyWith(
  selectionPropertiesLabel: 'Length: 10.0 mm',
  measureLabel: 'Perimeter: 40.0 mm',
);

expect(updated.selectionPropertiesLabel, 'Length: 10.0 mm');
expect(updated.measureLabel, 'Perimeter: 40.0 mm');
```

Add notifier coverage for label clearing and unit-change callbacks:

```dart
final action = _SpyToolAction();
final notifier = ViewportNotifier()..selectTool(_SpyTool(action));

notifier
  ..setSelectionPropertiesLabel('Length: 10.0 mm')
  ..setMeasureLabel('Length: 10.0 mm')
  ..selectTool(const SelectionTool());

expect(notifier.value.selectionPropertiesLabel, isNull);
expect(notifier.value.measureLabel, isNull);

notifier.setSelectedUnit(MetricUnit.cm);
expect(action.selectedUnitChangeCalls, 1);
```

Add tool-action helper expectations:

```dart
action
  ..setSelectionPropertiesLabel('X: 1.0 mm')
  ..setMeasureLabel('Length: 20.0 mm')
  ..clearSelectionPropertiesLabel()
  ..clearMeasureLabel();
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/data/viewport_state_test.dart test/src/logic/viewport_notifier_test.dart test/src/tools/tool_test.dart -r expanded`  
Expected: FAIL because the new state fields, notifier APIs, and tool hooks do not exist yet.

**Step 3: Write the minimal implementation**

Add two nullable state fields:

```dart
final String? selectionPropertiesLabel;
final String? measureLabel;
```

Add notifier APIs:

```dart
void setSelectionPropertiesLabel(String? text) {
  value = value.copyWith(selectionPropertiesLabel: text);
}

void setMeasureLabel(String? text) {
  value = value.copyWith(measureLabel: text);
}
```

Add `ToolAction` delegates and a unit-change hook:

```dart
void setSelectionPropertiesLabel(String? text) {
  _viewportNotifier.setSelectionPropertiesLabel(text);
}

void clearSelectionPropertiesLabel() {
  _viewportNotifier.setSelectionPropertiesLabel(null);
}

void onSelectedUnitChange() {}
```

Update `ViewportNotifier.setSelectedUnit()` to call `onSelectedUnitChange()` on the active tool action after mutating state. Update `selectTool()` and `cancelToolAction()` to clear both overlay labels before binding the next action.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/data/viewport_state_test.dart test/src/logic/viewport_notifier_test.dart test/src/tools/tool_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/data/viewport_state.dart lib/src/logic/viewport_notifier.dart lib/src/tools/tool.dart test/src/data/viewport_state_test.dart test/src/logic/viewport_notifier_test.dart test/src/tools/tool_test.dart
git commit -m "refactor: add overlay label state hooks"
```

### Task 2: Add Unit Formatting And Polygon Measurement Utilities

**Files:**
- Modify: `lib/src/data/metric_unit.dart`
- Create: `lib/src/foundation/geometry/measurement_math.dart`
- Create: `lib/src/foundation/units/metric_value_format.dart`
- Modify: `test/src/foundation/units/metric_value_input_test.dart`
- Create: `test/src/foundation/geometry/measurement_math_test.dart`
- Create: `test/src/foundation/units/metric_value_format_test.dart`

**Step 1: Write the failing tests**

Add metric area conversion tests:

```dart
expect(MetricUnit.cm.fromSquareMillimeters(900), 9);
expect(MetricUnit.m.fromSquareMillimeters(2_000_000), 2);
```

Add measurement-math tests:

```dart
expect(polylineLength([.zero, const Offset(3, 4)]), 5);
expect(closedPolylinePerimeter([
  .zero,
  const Offset(10, 0),
  const Offset(10, 10),
  const Offset(0, 10),
]), 40);
expect(polygonArea([
  .zero,
  const Offset(10, 0),
  const Offset(10, 10),
  const Offset(0, 10),
]), 100);
```

Add formatting tests:

```dart
expect(formatMetricLength(1500, MetricUnit.m), '1.5 m');
expect(formatMetricArea(20_000, MetricUnit.cm), '200.0 cm²');
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/foundation/units/metric_value_input_test.dart test/src/foundation/geometry/measurement_math_test.dart test/src/foundation/units/metric_value_format_test.dart -r expanded`  
Expected: FAIL because the new conversions and helper modules are missing.

**Step 3: Write the minimal implementation**

Add square-unit conversion helpers:

```dart
double get squareMillimetersFactor => millimetersFactor * millimetersFactor;

double fromSquareMillimeters(double value) {
  return value / squareMillimetersFactor;
}
```

Create pure geometry math helpers:

```dart
double polylineLength(List<Offset> points) { ... }
double closedPolylinePerimeter(List<Offset> points) { ... }
double polygonArea(List<Offset> points) { ... }
```

Create formatting helpers used by both geometries and the measure tool:

```dart
String formatMetricLength(double millimeters, MetricUnit unit) { ... }
String formatMetricArea(double squareMillimeters, MetricUnit unit) { ... }
String formatMetricCoordinate(double millimeters, MetricUnit unit) { ... }
```

Keep all helpers pure and one-decimal formatted.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/foundation/units/metric_value_input_test.dart test/src/foundation/geometry/measurement_math_test.dart test/src/foundation/units/metric_value_format_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/data/metric_unit.dart lib/src/foundation/geometry/measurement_math.dart lib/src/foundation/units/metric_value_format.dart test/src/foundation/units/metric_value_input_test.dart test/src/foundation/geometry/measurement_math_test.dart test/src/foundation/units/metric_value_format_test.dart
git commit -m "feat: add measurement math and metric formatting"
```

### Task 3: Add Geometry-Owned Property Text

**Files:**
- Modify: `lib/src/geometry/geometry.dart`
- Modify: `lib/src/geometry/line.dart`
- Modify: `lib/src/geometry/circle.dart`
- Modify: `lib/src/geometry/arc.dart`
- Modify: `lib/src/geometry/point.dart`
- Create: `test/src/geometry/geometry_properties_test.dart`

**Step 1: Write the failing tests**

Add coverage for the default `null` behavior and concrete overrides:

```dart
expect(_TestGeometry(color: .primary).buildPropertiesText(MetricUnit.mm), isNull);

expect(
  const Line(start: .zero, end: Offset(3, 4), color: .primary)
      .buildPropertiesText(MetricUnit.mm),
  'Length: 5.0 mm',
);

expect(
  const Point(position: Offset(10, 20), color: .primary, shape: PointShape.square)
      .buildPropertiesText(MetricUnit.cm),
  'X: 1.0 cm\nY: 2.0 cm',
);
```

Circle and arc expectations should assert all requested lines:

```dart
expect(text, contains('Radius: 10.0 mm'));
expect(text, contains('Diameter: 20.0 mm'));
expect(text, contains('Circumference:'));
expect(text, contains('Area:'));
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/geometry/geometry_properties_test.dart -r expanded`  
Expected: FAIL because `Geometry.buildPropertiesText()` and overrides do not exist.

**Step 3: Write the minimal implementation**

Add the default API to `Geometry`:

```dart
String? buildPropertiesText(MetricUnit unit) => null;
```

Override in each supported geometry. Example for `Line`:

```dart
@override
String buildPropertiesText(MetricUnit unit) {
  return 'Length: ${formatMetricLength((end - start).distance, unit)}';
}
```

Use multiline strings for `Circle`, `Arc`, and `Point`, with all formatting delegated to the helpers from Task 2.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/geometry/geometry_properties_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/geometry/geometry.dart lib/src/geometry/line.dart lib/src/geometry/circle.dart lib/src/geometry/arc.dart lib/src/geometry/point.dart test/src/geometry/geometry_properties_test.dart
git commit -m "feat: add geometry properties text"
```

### Task 4: Register The Measure Tool And Keyboard Shortcut

**Files:**
- Create: `lib/src/tools/measure_tool.dart`
- Modify: `lib/src/tools/tools.dart`
- Modify: `lib/src/ui/project_page.dart`
- Modify: `test/src/tools/tools_test.dart`
- Create: `test/src/tools/measure_tool_test.dart`
- Modify: `test/src/ui/project_page_test.dart`
- Modify: `test/src/ui/toolbar_test.dart`

**Step 1: Write the failing tests**

Add metadata tests:

```dart
const tool = MeasureTool();

expect(tool.name, 'Measure');
expect(tool.shortcut, const SingleActivator(.keyM));
expect(tool.icon, isA<Widget>());
expect(tool.toolActionFactory(), isA<ToolAction>());
```

Update tool registration expectations:

```dart
expect(tools.map((tool) => tool.runtimeType).toList(), [
  SelectionTool,
  LineTool,
  MeasureTool,
  ArcTool,
  CircleTool,
  CenterRectangleTool,
  CornersRectangleTool,
]);
```

Add shortcut-routing coverage:

```dart
await tester.sendKeyEvent(.keyM);
await tester.pump();
expect(notifier.value.selectedTool, const MeasureTool());

await tester.sendKeyEvent(.keyL);
await tester.sendKeyEvent(.digit1);
await tester.sendKeyEvent(.keyM);
await tester.pump();
expect(notifier.value.userInput, '1m');
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/tools/tools_test.dart test/src/tools/measure_tool_test.dart test/src/ui/project_page_test.dart test/src/ui/toolbar_test.dart -r expanded`  
Expected: FAIL because the Measure tool is not defined or wired into the tool list and keyboard routing.

**Step 3: Write the minimal implementation**

Create a minimal `MeasureTool` shell:

```dart
class MeasureTool implements Tool {
  const MeasureTool();

  @override
  String get name => 'Measure';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyM);

  @override
  Widget get icon => const _MeasureToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _MeasureToolAction.new;
}
```

Add it to `tools` immediately after `LineTool`. Update `project_page.dart` shortcut conflict handling so `M` behaves like `C`: if the active tool accepts value input and `userInput` is non-empty, append `'m'` instead of switching tools.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/tools/tools_test.dart test/src/tools/measure_tool_test.dart test/src/ui/project_page_test.dart test/src/ui/toolbar_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/tools/measure_tool.dart lib/src/tools/tools.dart lib/src/ui/project_page.dart test/src/tools/tools_test.dart test/src/tools/measure_tool_test.dart test/src/ui/project_page_test.dart test/src/ui/toolbar_test.dart
git commit -m "feat: register measure tool"
```

### Task 5: Implement Open-Polyline Measure Preview

**Files:**
- Modify: `lib/src/tools/measure_tool.dart`
- Modify: `test/src/tools/measure_tool_test.dart`

**Step 1: Write the failing tests**

Add open-session behavior coverage:

```dart
final notifier = ViewportNotifier()..selectTool(const MeasureTool());

_moveCursor(notifier, const Offset(10, 10));
notifier.onCursorClickUp();
_moveCursor(notifier, const Offset(20, 10));

expect(notifier.value.toolGeometries.single, isA<Line>());
expect(notifier.value.measureLabel, 'Length: 10.0 mm');
expect(notifier.value.geometries, isEmpty);
```

Extend the test to verify chained length accumulation:

```dart
notifier.onCursorClickUp();
_moveCursor(notifier, const Offset(20, 20));

expect(notifier.value.measureLabel, 'Length: 20.0 mm');
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/tools/measure_tool_test.dart -r expanded`  
Expected: FAIL because the tool shell does not yet track vertices, preview lines, or measure text.

**Step 3: Write the minimal implementation**

Inside `_MeasureToolAction`, keep a mutable vertex list and update tool geometry on every cursor move:

```dart
final _points = <Offset>[];

@override
void onCursorPositionChange() {
  _updatePreview();
  _updateMeasureLabel();
}

@override
void onClickUp() {
  if (_isClosed) {
    _reset();
  }
  _points.add(state.cursorPosition);
  _updatePreview();
  _updateMeasureLabel();
}
```

Use `polylineLength([..._points, state.cursorPosition])` for the open preview label and only draw preview lines in `toolGeometries`.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/tools/measure_tool_test.dart -r expanded`  
Expected: PASS for open-polyline coverage.

**Step 5: Commit**

```bash
git add lib/src/tools/measure_tool.dart test/src/tools/measure_tool_test.dart
git commit -m "feat: add open polyline measurement"
```

### Task 6: Implement Polygon Closure, Perimeter, Area, And Reset

**Files:**
- Modify: `lib/src/tools/measure_tool.dart`
- Modify: `test/src/tools/measure_tool_test.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`

**Step 1: Write the failing tests**

Add closure and reset coverage:

```dart
final notifier = ViewportNotifier()..selectTool(const MeasureTool());

_moveCursor(notifier, .zero);
notifier.onCursorClickUp();
_moveCursor(notifier, const Offset(10, 0));
notifier.onCursorClickUp();
_moveCursor(notifier, const Offset(10, 10));
notifier.onCursorClickUp();
_moveCursor(notifier, const Offset(0, 0));
notifier.onCursorClickUp();

expect(notifier.value.measureLabel, 'Perimeter: 34.1 mm\nArea: 50.0 mm²');
```

Add cancel/reset assertions:

```dart
notifier.cancelToolAction();

expect(notifier.value.selectedTool, const SelectionTool());
expect(notifier.value.measureLabel, isNull);
expect(notifier.value.toolGeometries, isEmpty);
```

Add fresh-session behavior after closure:

```dart
_moveCursor(notifier, const Offset(30, 30));
notifier.onCursorClickUp();
expect(notifier.value.measureLabel, isNull);
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/tools/measure_tool_test.dart test/src/logic/viewport_notifier_test.dart -r expanded`  
Expected: FAIL because closure detection, area/perimeter output, and session reset are not implemented.

**Step 3: Write the minimal implementation**

Add closure hit testing against the first vertex using a zoom-scaled tolerance:

```dart
bool _isClosingClick(Offset point) {
  if (_points.length < 3) {
    return false;
  }

  final tolerance = selectionTolerance / state.zoom;
  return (_points.first - point).distance <= tolerance;
}
```

When closure happens:

```dart
_isClosed = true;
setMeasureLabel(
  'Perimeter: ${formatMetricLength(closedPolylinePerimeter(_points), state.selectedUnit)}\n'
  'Area: ${formatMetricArea(polygonArea(_points), state.selectedUnit)}',
);
```

Draw the closing edge in preview geometry, clear everything in `onCancel()`, and reset the vertex list when the user clicks again after a closed measurement.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/tools/measure_tool_test.dart test/src/logic/viewport_notifier_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/tools/measure_tool.dart test/src/tools/measure_tool_test.dart test/src/logic/viewport_notifier_test.dart
git commit -m "feat: close measure polygons with area output"
```

### Task 7: Publish Single-Selection Geometry Properties From SelectionToolAction

**Files:**
- Modify: `lib/src/tools/selection_tool.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`

**Step 1: Write the failing tests**

Add selection-properties coverage:

```dart
final notifier = ViewportNotifier()..addGeometries(const [_lineA]);

_moveCursor(notifier, const Offset(5, 0));
notifier.onCursorClickUp();

expect(notifier.value.selectionPropertiesLabel, 'Length: 10.0 mm');
```

Add clearing and recompute coverage:

```dart
notifier.addGeometries(const [_lineB]);
_moveCursor(notifier, const Offset(25, 0));
notifier.onCursorClickUp();
expect(notifier.value.selectionPropertiesLabel, isNull);

notifier.cancelToolAction();
expect(notifier.value.selectionPropertiesLabel, isNull);
```

Add unit-change recompute while the Selection tool remains active:

```dart
final notifier = ViewportNotifier()..addGeometries(const [_lineA]);

_moveCursor(notifier, const Offset(5, 0));
notifier.onCursorClickUp();
notifier.setSelectedUnit(MetricUnit.cm);

expect(notifier.value.selectionPropertiesLabel, 'Length: 1.0 cm');
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/logic/viewport_notifier_test.dart -r expanded`  
Expected: FAIL because the Selection tool does not yet publish or recompute geometry property text.

**Step 3: Write the minimal implementation**

Add a small helper inside `SelectionToolAction`:

```dart
void _updateSelectionPropertiesLabel() {
  if (_selectedGeometries.length != 1) {
    clearSelectionPropertiesLabel();
    return;
  }

  setSelectionPropertiesLabel(
    _selectedGeometries.single.buildPropertiesText(state.selectedUnit),
  );
}
```

Call it after every selection change, after deletes, and from an `@override void onSelectedUnitChange()` implementation. Keep clearing behavior explicit when selection is empty, plural, or the selected geometry returns `null`.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/logic/viewport_notifier_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/tools/selection_tool.dart test/src/logic/viewport_notifier_test.dart
git commit -m "feat: show single selection geometry properties"
```

### Task 8: Render Measure And Selection Chips In The Viewport Overlay

**Files:**
- Modify: `lib/src/ui/viewport_overlay.dart`
- Modify: `test/src/ui/viewport_overlay_test.dart`
- Modify: `test/src/ui/toolbar_test.dart`

**Step 1: Write the failing tests**

Add overlay chip coverage:

```dart
notifier.value = notifier.value.copyWith(
  measureLabel: 'Length: 10.0 mm',
  selectionPropertiesLabel: 'Radius: 5.0 mm',
);
await tester.pump();

expect(find.text('Length: 10.0 mm'), findsOneWidget);
expect(find.text('Radius: 5.0 mm'), findsOneWidget);
```

Add conditional visibility assertions:

```dart
notifier.value = notifier.value.copyWith(
  measureLabel: null,
  selectionPropertiesLabel: null,
);
await tester.pump();

expect(find.textContaining('Length:'), findsNothing);
expect(find.textContaining('Radius:'), findsNothing);
```

Add a toolbar smoke assertion so the extra tool still renders correctly:

```dart
expect(find.byType(Tooltip), findsNWidgets(tools.length));
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/src/ui/viewport_overlay_test.dart test/src/ui/toolbar_test.dart -r expanded`  
Expected: FAIL because the overlay does not yet render the new chips.

**Step 3: Write the minimal implementation**

Add two conditional overlay chips:

```dart
const Positioned(
  left: _viewportOverlayOffset,
  top: _viewportOverlayOffset,
  child: _ViewportMeasureLabel(),
),
const Positioned(
  right: _viewportOverlayOffset,
  top: _viewportOverlayOffset,
  child: _ViewportSelectionPropertiesLabel(),
),
```

Keep measure output top-left and selection properties top-right so the existing zoom and cursor-position chips remain in the bottom corners unchanged.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/ui/viewport_overlay_test.dart test/src/ui/toolbar_test.dart -r expanded`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/src/ui/viewport_overlay.dart test/src/ui/viewport_overlay_test.dart test/src/ui/toolbar_test.dart
git commit -m "feat: render measurement overlay chips"
```

### Task 9: Final Verification, Style Pass, And Formatting

**Files:**
- Modify: all changed Dart files from Tasks 1-8
- Modify: `docs/plans/2026-02-27-measure-tool-implementation-plan.md` if task notes need to reflect final file set

**Step 1: Run the focused regression suite**

Run: `dart test test/src/foundation/units/metric_value_input_test.dart test/src/foundation/geometry/measurement_math_test.dart test/src/foundation/units/metric_value_format_test.dart test/src/geometry/geometry_properties_test.dart test/src/tools/measure_tool_test.dart test/src/tools/tools_test.dart test/src/logic/viewport_notifier_test.dart test/src/ui/project_page_test.dart test/src/ui/toolbar_test.dart test/src/ui/viewport_overlay_test.dart -r expanded`  
Expected: PASS.

**Step 2: Run broader verification**

Run: `dart test -r compact`  
Expected: PASS.

Run: `dart analyze`  
Expected: PASS, or the same known pre-existing warning already documented elsewhere with no new warnings introduced.

**Step 3: Apply the style pass**

- Use Dart LSP/code actions on every changed Dart file and apply any available dot-shorthand conversions.
- Manually convert any obvious remaining eligible changed lines to dot shorthand.
- Keep `ArcadiaColor` usage in place where color literals are introduced.

**Step 4: Format and rerun the critical suite**

Run: `dart format lib test`  
Expected: all changed Dart files formatted.

Run: `dart test test/src/tools/measure_tool_test.dart test/src/logic/viewport_notifier_test.dart test/src/ui/project_page_test.dart test/src/ui/viewport_overlay_test.dart -r expanded`  
Expected: PASS after formatting/style cleanup.

**Step 5: Commit**

```bash
git add lib test docs/plans/2026-02-27-measure-tool-implementation-plan.md
git commit -m "feat: add measure tool and geometry properties"
```
