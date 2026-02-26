# Project Units Configuration (Metric Only) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add project units configuration with `mm/cm/m`, keeping internal geometry values in base `mm`, and apply units only to typed value parsing (explicit typed suffix overrides selected unit for that value only).

**Architecture:** Keep mutation ownership in `ViewportNotifier`; add selected unit to `ViewportState`; add a pure metric-units utility for parser/conversion logic shared by logic and UI; keep cursor position overlay unchanged in base units; keep keyboard/pointer entry points in existing UI files.

**Tech Stack:** Dart 3, Flutter widgets and shortcuts, `flutter_test`, existing notifier/provider architecture.

---

Use @superpowers/test-driven-development for each task loop and @superpowers/verification-before-completion before final completion.

### Task 1: Add Metric Unit Model and Parsing/Conversion Utility

**Files:**
- Create: `lib/src/data/metric_unit.dart`
- Create: `lib/src/foundation/units/metric_value_input.dart`
- Create: `test/src/foundation/units/metric_value_input_test.dart`

**Step 1: Write the failing tests**

`test/src/foundation/units/metric_value_input_test.dart`

```dart
import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/foundation/units/metric_value_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MetricUnit conversions', () {
    test('converts to millimeters', () {
      expect(MetricUnit.mm.toMillimeters(30), 30);
      expect(MetricUnit.cm.toMillimeters(30), 300);
      expect(MetricUnit.m.toMillimeters(1.5), 1500);
    });

    test('converts from millimeters', () {
      expect(MetricUnit.mm.fromMillimeters(42), 42);
      expect(MetricUnit.cm.fromMillimeters(300), 30);
      expect(MetricUnit.m.fromMillimeters(2500), 2.5);
    });
  });

  group('parseMetricValueInput', () {
    test('uses fallback unit for unitless value', () {
      final parsed = parseMetricValueInput('30', fallbackUnit: MetricUnit.cm);
      expect(parsed?.unit, MetricUnit.cm);
      expect(parsed?.rawValue, 30);
      expect(parsed?.millimeters, 300);
    });

    test('explicit suffix overrides fallback', () {
      final parsed = parseMetricValueInput('30 mm', fallbackUnit: MetricUnit.m);
      expect(parsed?.unit, MetricUnit.mm);
      expect(parsed?.millimeters, 30);
    });

    test('accepts mixed case and no-space suffix', () {
      final parsed = parseMetricValueInput('1.5CM', fallbackUnit: MetricUnit.mm);
      expect(parsed?.unit, MetricUnit.cm);
      expect(parsed?.millimeters, 15);
    });

    test('returns null for invalid suffix', () {
      expect(
        parseMetricValueInput('12 km', fallbackUnit: MetricUnit.mm),
        isNull,
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `dart test test/src/foundation/units/metric_value_input_test.dart -r expanded`  
Expected: FAIL because unit model/parser files do not exist yet.

**Step 3: Write minimal implementation**

`lib/src/data/metric_unit.dart`

```dart
enum MetricUnit {
  mm('mm', 1),
  cm('cm', 10),
  m('m', 1000);

  const MetricUnit(this.symbol, this.millimetersFactor);

  final String symbol;
  final double millimetersFactor;

  double toMillimeters(double value) => value * millimetersFactor;

  double fromMillimeters(double value) => value / millimetersFactor;

  static MetricUnit? fromSuffix(String suffix) {
    final normalized = suffix.trim().toLowerCase();
    for (final unit in MetricUnit.values) {
      if (unit.symbol == normalized) {
        return unit;
      }
    }
    return null;
  }
}
```

`lib/src/foundation/units/metric_value_input.dart`

```dart
import '../../data/metric_unit.dart';

class ParsedMetricValueInput {
  const ParsedMetricValueInput({
    required this.rawValue,
    required this.unit,
    required this.millimeters,
  });

  final double rawValue;
  final MetricUnit unit;
  final double millimeters;
}

final _metricInputExpression = RegExp(
  r'^([0-9]+(?:\.[0-9]*)?|\.[0-9]+)\s*([a-zA-Z]{1,2})?$',
);

ParsedMetricValueInput? parseMetricValueInput(
  String input, {
  required MetricUnit fallbackUnit,
}) {
  final normalized = input.trim();
  if (normalized.isEmpty) {
    return null;
  }

  final match = _metricInputExpression.firstMatch(normalized);
  if (match == null) {
    return null;
  }

  final rawValue = double.tryParse(match.group(1)!);
  if (rawValue == null) {
    return null;
  }

  final suffix = match.group(2);
  final unit = suffix == null ? fallbackUnit : MetricUnit.fromSuffix(suffix);
  if (unit == null) {
    return null;
  }

  return ParsedMetricValueInput(
    rawValue: rawValue,
    unit: unit,
    millimeters: unit.toMillimeters(rawValue),
  );
}
```

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/foundation/units/metric_value_input_test.dart -r expanded`  
Expected: PASS for conversion and parser behavior.

**Step 5: Commit**

```bash
git add lib/src/data/metric_unit.dart \
  lib/src/foundation/units/metric_value_input.dart \
  test/src/foundation/units/metric_value_input_test.dart
git commit -m "feat: add metric unit model and value parser"
```

### Task 2: Wire Selected Unit into Viewport State and Notifier Input Parsing

**Files:**
- Modify: `lib/src/data/viewport_state.dart`
- Modify: `lib/src/logic/viewport_notifier.dart`
- Modify: `test/src/data/viewport_state_test.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`

**Step 1: Write failing tests**

Add state expectations in `test/src/data/viewport_state_test.dart`:

```dart
expect(state.selectedUnit, MetricUnit.mm);
```

Add `copyWith/hashCode/equality` coverage for `selectedUnit`.

Add notifier behavior in `test/src/logic/viewport_notifier_test.dart`:

```dart
test('setSelectedUnit updates viewport state', () {
  final notifier = ViewportNotifier();
  notifier.setSelectedUnit(MetricUnit.cm);
  expect(notifier.value.selectedUnit, MetricUnit.cm);
});

test('unitless input uses selected unit', () {
  final action = _InputSpyToolAction();
  final notifier = ViewportNotifier();
  notifier.selectTool(_SpyTool(action));
  notifier.setSelectedUnit(MetricUnit.cm);

  notifier.onUserInput('3');
  notifier.onUserInput('0');

  expect(action.lastTypedValue, 300);
});

test('explicit suffix overrides selected unit for that value only', () {
  final action = _InputSpyToolAction();
  final notifier = ViewportNotifier();
  notifier.selectTool(_SpyTool(action));
  notifier.setSelectedUnit(MetricUnit.mm);

  notifier.onUserInput('3');
  notifier.onUserInput('0');
  notifier.onUserInput(' ');
  notifier.onUserInput('C');
  notifier.onUserInput('M');

  expect(notifier.value.selectedUnit, MetricUnit.mm);
  expect(action.lastTypedValue, 300);
});
```

Add a value-capturing spy in the test file:

```dart
class _InputSpyToolAction extends _SpyToolAction {
  double? lastTypedValue;

  @override
  void onValueTyped(double? value) {
    lastTypedValue = value;
  }
}
```

**Step 2: Run tests to verify they fail**

Run:
- `dart test test/src/data/viewport_state_test.dart -r expanded`
- `dart test test/src/logic/viewport_notifier_test.dart -r expanded`

Expected: FAIL because `selectedUnit` and conversion behavior are not implemented.

**Step 3: Write minimal implementation**

`lib/src/data/viewport_state.dart`:

```dart
import 'metric_unit.dart';

const ViewportState({
  // ...
  this.selectedUnit = MetricUnit.mm,
});

final MetricUnit selectedUnit;

ViewportState copyWith({
  // ...
  MetricUnit? selectedUnit,
}) {
  return ViewportState(
    // ...
    selectedUnit: selectedUnit ?? this.selectedUnit,
  );
}
```

Include `selectedUnit` in `==` and `hashCode`.

`lib/src/logic/viewport_notifier.dart`:

```dart
import '../data/metric_unit.dart';
import '../foundation/units/metric_value_input.dart';

void setSelectedUnit(MetricUnit unit) {
  value = value.copyWith(selectedUnit: unit);
}

bool get acceptsValueInput => _toolAction.acceptValueInput;
```

Update `onUserInput` to:
- preserve delete behavior,
- accept `0-9`, `.`, `c/C`, `m/M`, and space when value input is active,
- keep displayed `userInput` raw,
- parse via `parseMetricValueInput(userInput, fallbackUnit: value.selectedUnit)`,
- pass parsed `.millimeters` (or `null`) to `_toolAction.onValueTyped`.

**Step 4: Run tests to verify they pass**

Run:
- `dart test test/src/data/viewport_state_test.dart -r expanded`
- `dart test test/src/logic/viewport_notifier_test.dart -r expanded`

Expected: PASS with selected-unit state and converted typed values.

**Step 5: Commit**

```bash
git add lib/src/data/viewport_state.dart \
  lib/src/logic/viewport_notifier.dart \
  test/src/data/viewport_state_test.dart \
  test/src/logic/viewport_notifier_test.dart
git commit -m "feat: apply selected metric unit to typed values"
```

### Task 3: Add Right-Aligned Units Control in Toolbar

**Files:**
- Modify: `lib/src/ui/toolbar.dart`
- Modify: `test/src/ui/toolbar_test.dart`

**Step 1: Write failing widget tests**

In `test/src/ui/toolbar_test.dart`, add:

```dart
testWidgets('renders project units control separate from tools', (tester) async {
  await _pumpToolbar(tester);

  expect(find.text('mm'), findsOneWidget);
  expect(find.text('cm'), findsOneWidget);
  expect(find.text('m'), findsOneWidget);
});

testWidgets('tapping unit updates selected unit in notifier', (tester) async {
  await _pumpToolbar(tester);
  final notifier = tester.element(find.byType(Toolbar)).viewportNotifier;

  await tester.tap(find.text('cm'));
  await tester.pump();

  expect(notifier.value.selectedUnit, MetricUnit.cm);
});
```

**Step 2: Run test to verify it fails**

Run: `dart test test/src/ui/toolbar_test.dart -r expanded`  
Expected: FAIL because toolbar has no units control.

**Step 3: Implement minimal UI**

In `lib/src/ui/toolbar.dart`:
- keep tools list on the left (`Expanded`),
- add a right-side container for units control, separated from tools,
- render unit options (`mm/cm/m`) and call `context.viewportNotifier.setSelectedUnit(unit)` on tap,
- style to visually distinguish from tool buttons.

Recommended skeleton:

```dart
return Container(
  height: 40,
  color: ArcadiaColor.surface,
  child: Row(
    children: [
      Expanded(child: _ToolsStrip()),
      const SizedBox(width: 12),
      const _ProjectUnitsControl(),
    ],
  ),
);
```

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/ui/toolbar_test.dart -r expanded`  
Expected: PASS for units control rendering and state updates.

**Step 5: Commit**

```bash
git add lib/src/ui/toolbar.dart test/src/ui/toolbar_test.dart
git commit -m "feat: add right-aligned project units control"
```

### Task 4: Route `C/M/Space` for Value Input Without Breaking Tool Shortcuts

**Files:**
- Modify: `lib/src/ui/project_page.dart`
- Modify: `test/src/ui/project_page_test.dart`

**Step 1: Write failing tests**

Add shortcut precedence tests:

```dart
testWidgets('C still selects Circle when value input is empty', (tester) async {
  final notifier = await _pumpProjectPage(tester);

  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.pump();

  expect(notifier.value.selectedTool, isA<CircleTool>());
});

testWidgets('C/M/space append to value input when input already started', (tester) async {
  final notifier = await _pumpProjectPage(tester);

  await tester.sendKeyEvent(LogicalKeyboardKey.keyL);
  await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyM);
  await tester.sendKeyEvent(LogicalKeyboardKey.space);
  await tester.pump();

  expect(notifier.value.userInput, '1cm ');
});
```

**Step 2: Run test to verify it fails**

Run: `dart test test/src/ui/project_page_test.dart -r expanded`  
Expected: FAIL due missing conditional key routing.

**Step 3: Implement conditional routing**

In `lib/src/ui/project_page.dart`:
- add value-input shortcuts for `m/M` and space,
- in `_ToolIntent` action branch for Circle shortcut:
  - if `context.viewportNotifier.acceptsValueInput` and `userInput` is not empty, call `onUserInput('c')` instead of selecting Circle,
  - otherwise keep existing tool-selection behavior.

Keep existing keyboard entry points and shortcut architecture unchanged.

**Step 4: Run tests to verify they pass**

Run: `dart test test/src/ui/project_page_test.dart -r expanded`  
Expected: PASS for both shortcut precedence and value input suffix typing.

**Step 5: Commit**

```bash
git add lib/src/ui/project_page.dart test/src/ui/project_page_test.dart
git commit -m "feat: support typed unit suffix shortcuts with C-key precedence"
```

### Task 5: Full Verification and Style Pass

**Files:**
- Modify if needed after formatting/lints:
  - `lib/src/data/metric_unit.dart`
  - `lib/src/foundation/units/metric_value_input.dart`
  - `lib/src/data/viewport_state.dart`
  - `lib/src/logic/viewport_notifier.dart`
  - `lib/src/ui/toolbar.dart`
  - `lib/src/ui/project_page.dart`
  - related test files

**Step 1: Run static analysis**

Run: `dart analyze`  
Expected: PASS (no errors/warnings in changed files).

**Step 2: Run focused tests**

Run:
- `dart test test/src/foundation/units/metric_value_input_test.dart -r expanded`
- `dart test test/src/data/viewport_state_test.dart -r expanded`
- `dart test test/src/logic/viewport_notifier_test.dart -r expanded`
- `dart test test/src/ui/toolbar_test.dart -r expanded`
- `dart test test/src/ui/project_page_test.dart -r expanded`
- `dart test test/src/ui/viewport_overlay_test.dart -r expanded`

Expected: PASS.

**Step 3: Dot shorthand pass**

Run Dart LSP/code actions on changed Dart files and apply available dot-shorthand actions.  
If no actions are available, manually convert obvious eligible changed lines.

**Step 4: Format changed code**

Run: `dart format lib test`  
Expected: all changed files formatted.

**Step 5: Re-run critical checks**

Run:
- `dart analyze`
- `dart test test/src/logic/viewport_notifier_test.dart -r compact`
- `dart test test/src/ui/project_page_test.dart -r compact`

Expected: PASS after formatting/style pass.

**Step 6: Commit final cleanup if needed**

```bash
git add lib test
git commit -m "chore: finalize metric units configuration verification and formatting"
```
