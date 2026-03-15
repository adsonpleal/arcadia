# Layers (Baseline) Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add baseline layer support so users can organize geometry by layer — create, rename, select active, toggle visibility.

**Architecture:** Introduce a `Layer` data class that owns its `List<Geometry>`. Replace `ViewportState.geometries` with `List<Layer> layers` and `activeLayerId`. Update `ViewportNotifier` for layer CRUD, modify rendering and selection to filter by visible layers. Add a collapsible right-side `LayersPanel` UI.

**Tech Stack:** Flutter, Dart (no third-party dependencies)

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Create | `lib/src/data/layer.dart` | Immutable `Layer` data class |
| Create | `test/src/data/layer_test.dart` | Layer unit tests |
| Modify | `lib/src/data/viewport_state.dart` | Replace `geometries` with `layers` + `activeLayerId` |
| Modify | `test/src/data/viewport_state_test.dart` | Update tests for layers |
| Modify | `lib/src/logic/viewport_notifier.dart` | Layer CRUD, modify add/delete/undo/redo/snapping |
| Modify | `test/src/logic/viewport_notifier_test.dart` | Update + add layer tests |
| Modify | `lib/src/tools/selection_tool.dart` | Use `_visibleGeometries` instead of `state.geometries` |
| Modify | `lib/src/ui/viewport_paint.dart` | Flatten visible layers in selector |
| Create | `lib/src/ui/layers_panel.dart` | Layers panel widget |
| Create | `test/src/ui/layers_panel_test.dart` | Layers panel widget tests |
| Modify | `lib/src/ui/project_page.dart` | Add LayersPanel to layout |
| Modify | `test/src/ui/project_page_test.dart` | Update for layers in state |

---

## Chunk 1: Data Model

### Task 1: Layer data class

**Files:**
- Create: `lib/src/data/layer.dart`
- Create: `test/src/data/layer_test.dart`

- [ ] **Step 1: Write failing tests for Layer**

```dart
// test/src/data/layer_test.dart
import 'package:arcadia/src/data/layer.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: Offset(1, 2), end: Offset(3, 4), color: .primary);
const _lineB = Line(start: Offset(5, 6), end: Offset(7, 8), color: .primary);

void main() {
  group('Layer', () {
    test('has expected defaults', () {
      const layer = Layer(id: '0', name: 'Layer 0');

      expect(layer.id, '0');
      expect(layer.name, 'Layer 0');
      expect(layer.visible, isTrue);
      expect(layer.geometries, isEmpty);
    });

    test('copyWith updates each field', () {
      const layer = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA],
      );

      final updated = layer.copyWith(
        name: 'Renamed',
        visible: false,
        geometries: [_lineB],
      );

      expect(updated.id, '0');
      expect(updated.name, 'Renamed');
      expect(updated.visible, isFalse);
      expect(updated.geometries, [_lineB]);
    });

    test('copyWith preserves values when omitted', () {
      const layer = Layer(
        id: '1',
        name: 'Test',
        visible: false,
        geometries: [_lineA],
      );

      final copied = layer.copyWith();

      expect(copied, equals(layer));
    });

    test('uses deep equality for geometries list', () {
      final first = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA, _lineB],
      );
      final second = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA, _lineB],
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('layers are different when any field changes', () {
      const base = Layer(
        id: '0',
        name: 'Layer 0',
        geometries: [_lineA],
      );

      expect(base, isNot(equals(base.copyWith(name: 'Other'))));
      expect(base, isNot(equals(base.copyWith(visible: false))));
      expect(base, isNot(equals(base.copyWith(geometries: [_lineB]))));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/src/data/layer_test.dart`
Expected: Compilation error — `Layer` class does not exist.

- [ ] **Step 3: Implement Layer class**

```dart
// lib/src/data/layer.dart
import 'package:flutter/foundation.dart';

import '../geometry/geometry.dart';

/// A drawing layer that groups geometries together.
///
/// Each geometry belongs to exactly one layer.
/// Layers control visibility and provide organizational structure.
@immutable
class Layer {
  /// The default constructor for [Layer].
  const Layer({
    required this.id,
    required this.name,
    this.visible = true,
    this.geometries = const [],
  });

  /// Unique identifier for this layer.
  final String id;

  /// User-visible name.
  final String name;

  /// Whether the layer's geometries are rendered and interactive.
  final bool visible;

  /// The geometries belonging to this layer.
  final List<Geometry> geometries;

  /// Creates a copy of [Layer] with replaced values.
  Layer copyWith({
    String? name,
    bool? visible,
    List<Geometry>? geometries,
  }) {
    return Layer(
      id: id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      geometries: geometries ?? this.geometries,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Layer &&
            id == other.id &&
            name == other.name &&
            visible == other.visible &&
            listEquals(geometries, other.geometries);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      visible,
      Object.hashAll(geometries),
    ]);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/src/data/layer_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/data/layer.dart test/src/data/layer_test.dart
git commit -m "feat: add Layer data class with tests"
```

### Task 2: Update ViewportState to use layers

**Files:**
- Modify: `lib/src/data/viewport_state.dart`
- Modify: `test/src/data/viewport_state_test.dart`

- [ ] **Step 1: Update ViewportState tests**

Replace the existing test file content. Key changes:
- Import `Layer`
- Replace all `geometries` references with `layers`
- Add `activeLayerId` tests
- Update default expectations, copyWith, equality, and hashCode tests

```dart
// test/src/data/viewport_state_test.dart
import 'package:arcadia/src/data/layer.dart';
import 'package:arcadia/src/data/metric_unit.dart';
import 'package:arcadia/src/data/viewport_state.dart';
import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/tools/selection_tool.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter_test/flutter_test.dart';

const _lineA = Line(start: Offset(1, 2), end: Offset(3, 4), color: .primary);
const _lineB = Line(start: Offset(5, 6), end: Offset(7, 8), color: .primary);
const _lineC = Line(start: Offset(8, 7), end: Offset(6, 5), color: .primary);
const Offset _zeroOffset = .zero;

const _defaultLayer = Layer(id: '0', name: 'Layer 0');
const _layerWithGeometry = Layer(
  id: '0',
  name: 'Layer 0',
  geometries: [_lineA],
);
const _secondLayer = Layer(id: '1', name: 'Layer 1');

void main() {
  group('ViewportState', () {
    test('has expected defaults', () {
      const state = ViewportState();

      expect(state.layers, const [_defaultLayer]);
      expect(state.activeLayerId, '0');
      expect(state.toolGeometries, isEmpty);
      expect(state.snappingGeometries, isEmpty);
      expect(state.zoom, 1.0);
      expect(state.panOffset, _zeroOffset);
      expect(state.cursorPosition, _zeroOffset);
      expect(state.selectedTool, const SelectionTool());
      expect(state.selectedUnit, MetricUnit.mm);
      expect(state.overlayLabel, isNull);
      expect(state.userInput, isEmpty);
    });

    test('copyWith updates each field', () {
      const initial = ViewportState(
        layers: [_layerWithGeometry],
        activeLayerId: '0',
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        zoom: 1.5,
        panOffset: Offset(10, 20),
        cursorPosition: Offset(30, 40),
        selectedTool: LineTool(),
        overlayLabel: 'Length: 10.0 mm',
        userInput: '100',
      );

      final updated = initial.copyWith(
        layers: const [_layerWithGeometry, _secondLayer],
        activeLayerId: '1',
        toolGeometries: const [_lineA],
        snappingGeometries: const [_lineA, _lineB],
        zoom: 2.5,
        panOffset: const Offset(20, 30),
        selectedTool: const SelectionTool(),
        selectedUnit: MetricUnit.cm,
        overlayLabel: 'Length: 1.0 cm',
        userInput: '200',
      );

      expect(updated.layers, const [_layerWithGeometry, _secondLayer]);
      expect(updated.activeLayerId, '1');
      expect(updated.toolGeometries, const [_lineA]);
      expect(updated.snappingGeometries, const [_lineA, _lineB]);
      expect(updated.zoom, 2.5);
      expect(updated.panOffset, const Offset(20, 30));
      expect(updated.cursorPosition, const Offset(30, 40));
      expect(updated.selectedTool, const SelectionTool());
      expect(updated.selectedUnit, MetricUnit.cm);
      expect(updated.overlayLabel, 'Length: 1.0 cm');
      expect(updated.userInput, '200');
    });

    test('copyWith preserves values when omitted', () {
      const initial = ViewportState(
        layers: [_layerWithGeometry],
        activeLayerId: '0',
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
        zoom: 1.25,
        panOffset: Offset(1, 2),
        cursorPosition: Offset(3, 4),
        selectedTool: LineTool(),
        selectedUnit: MetricUnit.m,
        overlayLabel: 'X: 1.0 m',
        userInput: '42',
      );

      final copied = initial.copyWith();

      expect(copied, equals(initial));
    });

    test('copyWith keeps selectedTool when null is provided', () {
      const initial = ViewportState(selectedTool: LineTool());
      // ignore: prefer_const_declarations
      final Tool? selectedTool = null;

      final cleared = initial.copyWith(selectedTool: selectedTool);

      expect(cleared.selectedTool, const LineTool());
    });

    test('copyWith preserves selectedTool when omitted', () {
      const tool = LineTool();
      const initial = ViewportState(selectedTool: tool);

      final copied = initial.copyWith(userInput: '10');

      expect(copied.selectedTool, same(tool));
    });

    test('uses deep equality for list fields', () {
      final layers = [_layerWithGeometry];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final first = ViewportState(
        layers: layers,
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
      );
      final second = ViewportState(
        layers: [...layers],
        toolGeometries: [...toolGeometries],
        snappingGeometries: [...snappingGeometries],
      );

      expect(first, equals(second));
      expect(first.hashCode, second.hashCode);
    });

    test('hashCode uses Object.hashAll for list hashes', () {
      final layers = [_layerWithGeometry];
      final toolGeometries = [_lineC];
      final snappingGeometries = [_lineB, _lineC];
      final state = ViewportState(
        layers: layers,
        activeLayerId: '0',
        toolGeometries: toolGeometries,
        snappingGeometries: snappingGeometries,
        zoom: 2,
        panOffset: const Offset(1, 2),
        cursorPosition: const Offset(3, 4),
        selectedTool: const LineTool(),
        selectedUnit: MetricUnit.cm,
        overlayLabel: 'Length: 1.0 cm',
        userInput: '10',
      );

      final expected = Object.hashAll([
        Object.hashAll(state.layers),
        state.activeLayerId,
        Object.hashAll(state.toolGeometries),
        Object.hashAll(state.snappingGeometries),
        state.zoom,
        state.panOffset,
        state.cursorPosition,
        state.selectedTool,
        state.selectedUnit,
        state.overlayLabel,
        state.userInput,
      ]);

      expect(state.hashCode, expected);
    });

    test('states are different when any scalar field changes', () {
      const base = ViewportState(
        zoom: 2,
        panOffset: Offset(1, 1),
        cursorPosition: Offset(2, 2),
        userInput: '1',
      );

      expect(base, isNot(equals(base.copyWith(zoom: 3))));
      expect(
        base,
        isNot(equals(base.copyWith(panOffset: const Offset(3, 3)))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(cursorPosition: const Offset(4, 4)))),
      );
      expect(base, isNot(equals(base.copyWith(selectedUnit: MetricUnit.cm))));
      expect(
        base,
        isNot(equals(base.copyWith(overlayLabel: 'Length: 10.0 mm'))),
      );
      expect(base, isNot(equals(base.copyWith(userInput: '2'))));
      expect(base, isNot(equals(base.copyWith(activeLayerId: '1'))));
    });

    test('states are different when any list field changes', () {
      const base = ViewportState(
        layers: [_defaultLayer],
        toolGeometries: [_lineB],
        snappingGeometries: [_lineC],
      );

      expect(
        base,
        isNot(equals(base.copyWith(layers: const [_secondLayer]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(toolGeometries: const [_lineC]))),
      );
      expect(
        base,
        isNot(equals(base.copyWith(snappingGeometries: const [_lineA]))),
      );
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: Compilation errors — `ViewportState` still uses `geometries`, not `layers`/`activeLayerId`.

- [ ] **Step 3: Update ViewportState implementation**

Replace `lib/src/data/viewport_state.dart`:

```dart
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../geometry/geometry.dart';
import '../tools/selection_tool.dart';
import '../tools/tool.dart';
import 'layer.dart';
import 'metric_unit.dart';

const _unsetLabel = Object();
const _defaultLayer = Layer(id: '0', name: 'Layer 0');

/// The state of the viewport.
///
/// It contains all the [layers] being displayed,
/// the current [zoom] and the [panOffset].
@immutable
class ViewportState {
  /// The default [ViewportState] constructor
  const ViewportState({
    this.layers = const [_defaultLayer],
    this.activeLayerId = '0',
    this.toolGeometries = const [],
    this.snappingGeometries = const [],
    this.zoom = 1.0,
    this.panOffset = .zero,
    this.cursorPosition = .zero,
    this.selectedTool = const SelectionTool(),
    this.selectedUnit = MetricUnit.mm,
    this.overlayLabel,
    this.userInput = '',
  });

  /// The drawing layers.
  ///
  /// Each layer owns its own list of geometries.
  /// Layers are rendered in list order (index 0 = bottom).
  final List<Layer> layers;

  /// The ID of the layer that receives new geometry.
  final String activeLayerId;

  /// The tool [Geometry] list.
  ///
  /// These geometries are generated by the active tool and are removed
  /// once the tool finishes its action.
  final List<Geometry> toolGeometries;

  /// The snapping [Geometry] list.
  ///
  /// These geometries are used to represent snapping areas.
  final List<Geometry> snappingGeometries;

  /// The current zoom.
  final double zoom;

  /// The current pan (movement) offset.
  final Offset panOffset;

  /// The position of the cursor.
  final Offset cursorPosition;

  /// The selected tool.
  final Tool selectedTool;

  /// The selected project unit used for value input interpretation.
  final MetricUnit selectedUnit;

  /// Overlay text for tool output (measurement results, selection properties).
  final String? overlayLabel;

  /// Whether or not show value picker;
  final String userInput;

  /// Creates a copy of [ViewportState] with replaced values.
  ///
  /// For [selectedTool], passing `null` explicitly clears the selected tool.
  /// Omitting [selectedTool] preserves the previous value.
  ViewportState copyWith({
    List<Layer>? layers,
    String? activeLayerId,
    List<Geometry>? toolGeometries,
    List<Geometry>? snappingGeometries,
    double? zoom,
    Offset? panOffset,
    Offset? cursorPosition,
    Tool? selectedTool,
    MetricUnit? selectedUnit,
    Object? overlayLabel = _unsetLabel,
    String? userInput,
  }) {
    return ViewportState(
      layers: layers ?? this.layers,
      activeLayerId: activeLayerId ?? this.activeLayerId,
      toolGeometries: toolGeometries ?? this.toolGeometries,
      snappingGeometries: snappingGeometries ?? this.snappingGeometries,
      zoom: zoom ?? this.zoom,
      panOffset: panOffset ?? this.panOffset,
      cursorPosition: cursorPosition ?? this.cursorPosition,
      selectedTool: selectedTool ?? this.selectedTool,
      selectedUnit: selectedUnit ?? this.selectedUnit,
      overlayLabel: overlayLabel == _unsetLabel
          ? this.overlayLabel
          : overlayLabel as String?,
      userInput: userInput ?? this.userInput,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ViewportState &&
            listEquals(layers, other.layers) &&
            activeLayerId == other.activeLayerId &&
            listEquals(toolGeometries, other.toolGeometries) &&
            listEquals(snappingGeometries, other.snappingGeometries) &&
            zoom == other.zoom &&
            panOffset == other.panOffset &&
            cursorPosition == other.cursorPosition &&
            selectedTool == other.selectedTool &&
            selectedUnit == other.selectedUnit &&
            overlayLabel == other.overlayLabel &&
            userInput == other.userInput;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      Object.hashAll(layers),
      activeLayerId,
      Object.hashAll(toolGeometries),
      Object.hashAll(snappingGeometries),
      zoom,
      panOffset,
      cursorPosition,
      selectedTool,
      selectedUnit,
      overlayLabel,
      userInput,
    ]);
  }
}
```

- [ ] **Step 4: Run ViewportState tests to verify they pass**

Run: `flutter test test/src/data/viewport_state_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/data/viewport_state.dart test/src/data/viewport_state_test.dart
git commit -m "feat: replace ViewportState.geometries with layers and activeLayerId"
```

## Chunk 2: ViewportNotifier Layer Logic

### Task 3: Layer CRUD methods, undo/redo stack migration, and snapping

**Files:**
- Modify: `lib/src/logic/viewport_notifier.dart`
- Modify: `test/src/logic/viewport_notifier_test.dart`

This task adds all layer management methods AND migrates the undo/redo stack type in one step so the code compiles at every commit boundary.

- [ ] **Step 1: Write failing tests for layer CRUD and geometry operations**

Add the following test group to `test/src/logic/viewport_notifier_test.dart`, inside the existing `group('ViewportNotifier', () {` block, after the last existing test. Also add import at top: `import 'package:arcadia/src/data/layer.dart';`

```dart
    group('layer management', () {
      test('starts with a single default layer as active', () {
        final notifier = ViewportNotifier();

        expect(notifier.value.layers, hasLength(1));
        expect(notifier.value.layers.first.id, '0');
        expect(notifier.value.layers.first.name, 'Layer 0');
        expect(notifier.value.activeLayerId, '0');
      });

      test('addLayer creates a new layer and sets it active', () {
        final notifier = ViewportNotifier();

        notifier.addLayer('Dimensions');

        expect(notifier.value.layers, hasLength(2));
        expect(notifier.value.layers.last.name, 'Dimensions');
        expect(notifier.value.activeLayerId, notifier.value.layers.last.id);
      });

      test('addLayer uses monotonically incrementing IDs', () {
        final notifier = ViewportNotifier();

        notifier.addLayer('A');
        notifier.addLayer('B');

        expect(notifier.value.layers[1].id, '1');
        expect(notifier.value.layers[2].id, '2');
      });

      test('renameLayer updates the layer name', () {
        final notifier = ViewportNotifier();

        notifier.renameLayer('0', 'Renamed');

        expect(notifier.value.layers.first.name, 'Renamed');
      });

      test('renameLayer is undoable', () {
        final notifier = ViewportNotifier();

        notifier.renameLayer('0', 'Renamed');
        notifier.undo();

        expect(notifier.value.layers.first.name, 'Layer 0');
      });

      test('deleteLayer removes the layer', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');

        notifier.deleteLayer(notifier.value.layers.last.id);

        expect(notifier.value.layers, hasLength(1));
        expect(notifier.value.layers.first.name, 'Layer 0');
      });

      test('deleteLayer cannot delete the last remaining layer', () {
        final notifier = ViewportNotifier();

        notifier.deleteLayer('0');

        expect(notifier.value.layers, hasLength(1));
      });

      test('deleteLayer switches active to index-1 when deleting active', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');
        notifier.addLayer('Third');
        final thirdId = notifier.value.layers[2].id;
        final secondId = notifier.value.layers[1].id;

        expect(notifier.value.activeLayerId, thirdId);

        notifier.deleteLayer(thirdId);

        expect(notifier.value.activeLayerId, secondId);
      });

      test('deleteLayer switches active to index 0 when deleting first', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');
        notifier.setActiveLayer('0');

        notifier.deleteLayer('0');

        expect(notifier.value.activeLayerId, notifier.value.layers.first.id);
      });

      test('setActiveLayer updates activeLayerId', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');

        notifier.setActiveLayer('0');

        expect(notifier.value.activeLayerId, '0');
      });

      test('toggleLayerVisibility flips the visible flag', () {
        final notifier = ViewportNotifier();

        notifier.toggleLayerVisibility('0');

        expect(notifier.value.layers.first.visible, isFalse);

        notifier.toggleLayerVisibility('0');

        expect(notifier.value.layers.first.visible, isTrue);
      });

      test('addGeometries adds to the active layer', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');

        notifier.addGeometries(const [_lineA]);

        final secondLayer = notifier.value.layers.last;
        expect(secondLayer.geometries, const [_lineA]);
        expect(notifier.value.layers.first.geometries, isEmpty);
      });

      test('deleteGeometries removes from any layer', () {
        final notifier = ViewportNotifier();
        notifier.addGeometries(const [_lineA]);
        notifier.addLayer('Second');
        notifier.addGeometries(const [_lineB]);

        notifier.deleteGeometries(const [_lineA, _lineB]);

        expect(notifier.value.layers[0].geometries, isEmpty);
        expect(notifier.value.layers[1].geometries, isEmpty);
      });

      test('undo restores previous layers state', () {
        final notifier = ViewportNotifier();
        notifier.addGeometries(const [_lineA]);
        notifier.addLayer('Second');

        notifier.undo();

        expect(notifier.value.layers, hasLength(1));
      });

      test('redo reapplies layers state', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');
        notifier.undo();

        notifier.redo();

        expect(notifier.value.layers, hasLength(2));
      });

      test('undo falls back activeLayerId to first layer when orphaned', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('Second');
        final secondId = notifier.value.layers.last.id;

        // activeLayerId is secondId, but undo removes that layer
        notifier.undo();

        // activeLayerId should fall back to the first available layer
        expect(notifier.value.activeLayerId, isNot(secondId));
        expect(notifier.value.activeLayerId, notifier.value.layers.first.id);

        // addGeometries should work correctly after this fallback
        notifier.addGeometries(const [_lineA]);
        expect(notifier.value.layers.first.geometries, const [_lineA]);
      });

      test('snapping points only include visible layers', () {
        final notifier = ViewportNotifier()
          ..addGeometries(const [_lineA])
          ..selectTool(const LineTool());

        notifier.toggleLayerVisibility('0');

        // lineA endpoint is at (10, 0). Move cursor near it.
        // Should NOT snap because layer is hidden.
        _moveCursor(notifier, const Offset(10.5, 0));

        expect(notifier.value.snappingGeometries, isEmpty);
        expect(notifier.value.cursorPosition, isNot(const Offset(10, 0)));
      });

      test('ID counter does not decrement on undo', () {
        final notifier = ViewportNotifier();
        notifier.addLayer('First');
        notifier.undo();
        notifier.addLayer('Second');

        expect(notifier.value.layers.last.id, '2');
      });
    });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/src/logic/viewport_notifier_test.dart`
Expected: Compilation errors — `addLayer`, `renameLayer`, `deleteLayer`, `setActiveLayer`, `toggleLayerVisibility` do not exist, and `notifier.value.geometries` no longer exists.

- [ ] **Step 3: Implement all ViewportNotifier layer changes**

Modify `lib/src/logic/viewport_notifier.dart`:

1. Add import: `import '../data/layer.dart';`

2. Change undo/redo stack types and add counter:
```dart
  final List<List<Layer>> _undoStack = [];
  final List<List<Layer>> _redoStack = [];
  int _nextLayerId = 1;
```

3. Replace `addGeometries`:
```dart
  /// Add geometries to the active layer.
  void addGeometries(List<Geometry> geometries) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == value.activeLayerId)
            layer.copyWith(
              geometries: [...layer.geometries, ...geometries],
            )
          else
            layer,
      ],
    );
    _recomputeSnappingPoints();
  }
```

4. Replace `deleteGeometries`:
```dart
  /// Delete the given geometries from all layers.
  void deleteGeometries(List<Geometry> geometries) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          layer.copyWith(
            geometries: [
              for (final geometry in layer.geometries)
                if (!geometries.contains(geometry)) geometry,
            ],
          ),
      ],
    );
    _recomputeSnappingPoints();
  }
```

5. Replace `undo` (with activeLayerId fallback guard):
```dart
  /// Undo the latest layers change.
  void undo() {
    if (_undoStack.isNotEmpty) {
      _redoStack.add([...value.layers]);
      final restoredLayers = _undoStack.removeLast();
      final activeLayerId = _validActiveLayerId(restoredLayers);
      value = value.copyWith(layers: restoredLayers, activeLayerId: activeLayerId);
      _recomputeSnappingPoints();
    }
  }
```

6. Replace `redo` (with activeLayerId fallback guard):
```dart
  /// Redo the latest undo.
  void redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add([...value.layers]);
      final restoredLayers = _redoStack.removeLast();
      final activeLayerId = _validActiveLayerId(restoredLayers);
      value = value.copyWith(layers: restoredLayers, activeLayerId: activeLayerId);
      _recomputeSnappingPoints();
    }
  }
```

7. Add `_recomputeSnappingPoints` and `_validActiveLayerId`:
```dart
  void _recomputeSnappingPoints() {
    _snappingPoints = [
      _origin,
      for (final layer in value.layers)
        if (layer.visible)
          for (final geometry in layer.geometries) ...geometry.snappingPoints,
    ];
  }

  /// Returns the current activeLayerId if it exists in [layers],
  /// otherwise falls back to the first layer's ID.
  String _validActiveLayerId(List<Layer> layers) {
    final current = value.activeLayerId;
    if (layers.any((l) => l.id == current)) return current;
    return layers.first.id;
  }
```

8. Add layer CRUD methods:
```dart
  /// Creates a new layer and sets it as active.
  void addLayer(String name) {
    final id = '${_nextLayerId++}';
    final layer = Layer(id: id, name: name);
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [...value.layers, layer],
      activeLayerId: id,
    );
    _recomputeSnappingPoints();
  }

  /// Renames the layer with the given [id].
  void renameLayer(String id, String name) {
    _undoStack.add([...value.layers]);
    _redoStack.clear();
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == id) layer.copyWith(name: name) else layer,
      ],
    );
  }

  /// Deletes the layer with the given [id].
  ///
  /// Cannot delete the last remaining layer.
  /// If the deleted layer was active, switches to the layer at index-1
  /// or index 0 of the remaining list.
  void deleteLayer(String id) {
    if (value.layers.length <= 1) return;

    final index = value.layers.indexWhere((l) => l.id == id);
    if (index == -1) return;

    _undoStack.add([...value.layers]);
    _redoStack.clear();

    final newLayers = [...value.layers]..removeAt(index);
    var activeLayerId = value.activeLayerId;

    if (activeLayerId == id) {
      final newIndex = index > 0 ? index - 1 : 0;
      activeLayerId = newLayers[newIndex].id;
    }

    value = value.copyWith(layers: newLayers, activeLayerId: activeLayerId);
    _recomputeSnappingPoints();
  }

  /// Sets the active layer.
  void setActiveLayer(String id) {
    value = value.copyWith(activeLayerId: id);
  }

  /// Toggles visibility of the layer with the given [id].
  void toggleLayerVisibility(String id) {
    value = value.copyWith(
      layers: [
        for (final layer in value.layers)
          if (layer.id == id)
            layer.copyWith(visible: !layer.visible)
          else
            layer,
      ],
    );
    _recomputeSnappingPoints();
  }
```

- [ ] **Step 4: Update existing tests that reference `state.geometries`**

Add a helper at the bottom of the test file (outside `main`):
```dart
List<Geometry> _allGeometries(ViewportNotifier notifier) {
  return [
    for (final layer in notifier.value.layers) ...layer.geometries,
  ];
}
```

Add import at top: `import 'package:arcadia/src/geometry/geometry.dart';`

Replace every `notifier.value.geometries` with `_allGeometries(notifier)`. The exact occurrences are:

In `'undo and redo apply geometry history...'` test (6 assertions):
- `expect(notifier.value.geometries, const [_lineA, _lineB]);` → `expect(_allGeometries(notifier), const [_lineA, _lineB]);`
- `expect(notifier.value.geometries, const [_lineA]);` → `expect(_allGeometries(notifier), const [_lineA]);`
- `expect(notifier.value.geometries, isEmpty);` → `expect(_allGeometries(notifier), isEmpty);`
- `expect(notifier.value.geometries, const [_lineA]);` → `expect(_allGeometries(notifier), const [_lineA]);`
- `expect(notifier.value.geometries, const [_lineA, _lineB]);` → `expect(_allGeometries(notifier), const [_lineA, _lineB]);`
- `expect(notifier.value.geometries, const [_lineA, _lineC]);` → `expect(_allGeometries(notifier), const [_lineA, _lineC]);`

In `'onUserInput deleteCharacter deletes selected selection'`:
- `expect(notifier.value.geometries, const [_lineB]);` → `expect(_allGeometries(notifier), const [_lineB]);`

In `'onUserInput deleteCharacter with no selection does not add undo'`:
- `expect(notifier.value.geometries, isEmpty);` → `expect(_allGeometries(notifier), isEmpty);`

- [ ] **Step 5: Run all ViewportNotifier tests**

Run: `flutter test test/src/logic/viewport_notifier_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/src/logic/viewport_notifier.dart test/src/logic/viewport_notifier_test.dart
git commit -m "feat: add layer management and migrate undo/redo to layers"
```

## Chunk 3: Selection Tool and Rendering

### Task 5: Update selection tool for visible layers

**Files:**
- Modify: `lib/src/tools/selection_tool.dart`

- [ ] **Step 1: Update selection tool to use visible layers**

In `lib/src/tools/selection_tool.dart`, in `_SelectionToolAction`:

1. Add a getter:
```dart
  List<Geometry> get _visibleGeometries => [
    for (final layer in state.layers)
      if (layer.visible) ...layer.geometries,
  ];
```

2. Replace `state.geometries` in `_matchingGeometriesForRect`:
```dart
  List<Geometry> _matchingGeometriesForRect(
    Rect selectionRect, {
    required _SelectionDragMode mode,
  }) {
    return [
      for (final geometry in _visibleGeometries)
        if (switch (mode) {
          _SelectionDragMode.window => geometry.containedIn(selectionRect),
          _SelectionDragMode.crossing => geometry.intersects(selectionRect),
        })
          geometry,
    ];
  }
```

3. Replace `state.geometries.reversed` in `_geometryBelowCursor`:
```dart
  Geometry? _geometryBelowCursor() {
    final tolerance = selectionTolerance / state.zoom;
    for (final geometry in _visibleGeometries.reversed) {
      if (geometry.contains(state.cursorPosition, tolerance)) {
        return geometry;
      }
    }
    return null;
  }
```

- [ ] **Step 2: Run all tests to check nothing is broken**

Run: `flutter test`
Expected: All tests PASS (selection behavior unchanged since all layers are visible by default).

- [ ] **Step 3: Commit**

```bash
git add lib/src/tools/selection_tool.dart
git commit -m "refactor: selection tool uses visible layers instead of flat geometries"
```

### Task 6: Update ViewportPaint for layers

**Files:**
- Modify: `lib/src/ui/viewport_paint.dart`

- [ ] **Step 1: Update ViewportPaint to flatten visible layers in selector**

Replace the build method in `lib/src/ui/viewport_paint.dart`:

```dart
  @override
  Widget build(BuildContext context) {
    final (zoom, panOffset, geometries) = context.selectViewportState(
      (state) => (
        state.zoom,
        state.panOffset,
        [
          for (final layer in state.layers)
            if (layer.visible) ...layer.geometries,
        ],
      ),
    );

    return CustomPaint(
      painter: ViewportPainter(
        zoom: zoom,
        panOffset: panOffset,
        geometries: geometries,
      ),
    );
  }
```

- [ ] **Step 2: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 3: Commit**

```bash
git add lib/src/ui/viewport_paint.dart
git commit -m "refactor: ViewportPaint flattens visible layers in selector"
```

### Task 7: Update ProjectPage test for layers

**Files:**
- Modify: `test/src/ui/project_page_test.dart`

- [ ] **Step 1: Update test assertions that reference `state.geometries`**

In `test/src/ui/project_page_test.dart`, update the `'undo and redo shortcuts'` test. Replace:
```dart
      expect(notifier.value.geometries, const [_lineA, _lineB]);
```
with a helper or inline:
```dart
      List<Geometry> allGeometries() => [
        for (final layer in notifier.value.layers) ...layer.geometries,
      ];
```

Update each assertion from `notifier.value.geometries` to `allGeometries()`.

Add the necessary import:
```dart
import 'package:arcadia/src/geometry/geometry.dart';
```

- [ ] **Step 2: Run ProjectPage tests**

Run: `flutter test test/src/ui/project_page_test.dart`
Expected: All tests PASS.

- [ ] **Step 3: Run the full test suite**

Run: `flutter test`
Expected: All tests PASS. This confirms the data model migration is complete without regressions.

- [ ] **Step 4: Commit**

```bash
git add test/src/ui/project_page_test.dart
git commit -m "test: update ProjectPage tests for layers data model"
```

## Chunk 4: Layers Panel UI

### Task 8: LayersPanel widget — core structure

**Files:**
- Create: `lib/src/ui/layers_panel.dart`
- Create: `test/src/ui/layers_panel_test.dart`

- [ ] **Step 1: Write failing widget tests for LayersPanel**

```dart
// test/src/ui/layers_panel_test.dart
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/ui/layers_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LayersPanel', () {
    testWidgets('renders default layer', (tester) async {
      await _pumpLayersPanel(tester);

      expect(find.text('Layer 0'), findsOneWidget);
    });

    testWidgets('add button creates a new layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(notifier.value.layers, hasLength(2));
      expect(find.text('Layer 1'), findsOneWidget);
    });

    testWidgets('tapping a layer sets it as active', (tester) async {
      final notifier = await _pumpLayersPanel(tester);
      notifier.addLayer('Second');
      await tester.pump();

      notifier.setActiveLayer('0');
      await tester.pump();

      await tester.tap(find.text('Second'));
      await tester.pump();

      expect(notifier.value.activeLayerId, notifier.value.layers.last.id);
    });

    testWidgets('visibility toggle hides layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      expect(notifier.value.layers.first.visible, isFalse);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });

    testWidgets('delete button removes layer', (tester) async {
      final notifier = await _pumpLayersPanel(tester);
      notifier.addLayer('Second');
      await tester.pump();

      expect(notifier.value.layers, hasLength(2));

      final deleteButtons = find.byIcon(Icons.close);
      await tester.tap(deleteButtons.first);
      await tester.pump();

      expect(notifier.value.layers, hasLength(1));
    });

    testWidgets('delete button hidden when only one layer remains', (
      tester,
    ) async {
      await _pumpLayersPanel(tester);

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('double-tap layer name enters rename mode', (tester) async {
      final notifier = await _pumpLayersPanel(tester);

      // Two sequential tester.tap() won't trigger onDoubleTap.
      // Use the Offset-based approach within the double-tap timeout.
      final center = tester.getCenter(find.text('Layer 0'));
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tapAt(center);
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Renamed');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(notifier.value.layers.first.name, 'Renamed');
    });
  });
}

Future<ViewportNotifier> _pumpLayersPanel(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: ViewportNotifierProvider(child: LayersPanel()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.element(find.byType(LayersPanel)).viewportNotifier;
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/src/ui/layers_panel_test.dart`
Expected: Compilation error — `LayersPanel` does not exist.

- [ ] **Step 3: Implement LayersPanel**

```dart
// lib/src/ui/layers_panel.dart
import 'package:flutter/material.dart';

import '../constants/arcadia_color.dart';
import '../data/layer.dart';
import '../providers/viewport_notifier_provider.dart';

/// A panel that displays and manages drawing layers.
class LayersPanel extends StatefulWidget {
  /// The default constructor for [LayersPanel].
  const LayersPanel({super.key});

  @override
  State<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends State<LayersPanel> {
  double _panelWidth = 180;
  bool _collapsed = false;
  String? _editingLayerId;

  static const _minWidth = 120.0;
  static const _maxWidth = 400.0;
  static const _collapsedWidth = 32.0;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return GestureDetector(
        onTap: () => setState(() => _collapsed = false),
        child: Container(
          width: _collapsedWidth,
          color: ArcadiaColor.surface,
          child: const Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Text('LAYERS', style: TextStyle(fontSize: 10)),
            ),
          ),
        ),
      );
    }

    final layers = context.selectViewportState((state) => state.layers);
    final activeLayerId = context.selectViewportState(
      (state) => state.activeLayerId,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _panelWidth =
                    (_panelWidth - details.delta.dx).clamp(_minWidth, _maxWidth);
              });
            },
            child: Container(width: 1, color: ArcadiaColor.border),
          ),
        ),
        SizedBox(
          width: _panelWidth,
          child: ColoredBox(
            color: ArcadiaColor.surface,
            child: Column(
              children: [
                _Header(
                  onCollapse: () => setState(() => _collapsed = true),
                  onAdd: () {
                    final notifier = context.viewportNotifier;
                    final index = notifier.value.layers.length;
                    notifier.addLayer('Layer $index');
                  },
                ),
                Container(height: 1, color: ArcadiaColor.border),
                Expanded(
                  child: ListView.builder(
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      return _LayerRow(
                        layer: layer,
                        isActive: layer.id == activeLayerId,
                        isEditing: _editingLayerId == layer.id,
                        showDelete: layers.length > 1,
                        onTap: () {
                          context.viewportNotifier.setActiveLayer(layer.id);
                        },
                        onDoubleTap: () {
                          setState(() => _editingLayerId = layer.id);
                        },
                        onRename: (name) {
                          context.viewportNotifier.renameLayer(layer.id, name);
                          setState(() => _editingLayerId = null);
                        },
                        onToggleVisibility: () {
                          context.viewportNotifier
                              .toggleLayerVisibility(layer.id);
                        },
                        onDelete: () {
                          context.viewportNotifier.deleteLayer(layer.id);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCollapse, required this.onAdd});

  final VoidCallback onCollapse;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCollapse,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(Icons.chevron_right, size: 16, color: ArcadiaColor.primary),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LAYERS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ArcadiaColor.primary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onAdd,
            child: const MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Icon(Icons.add, size: 16, color: ArcadiaColor.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.layer,
    required this.isActive,
    required this.isEditing,
    required this.showDelete,
    required this.onTap,
    required this.onDoubleTap,
    required this.onRename,
    required this.onToggleVisibility,
    required this.onDelete,
  });

  final Layer layer;
  final bool isActive;
  final bool isEditing;
  final bool showDelete;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final ValueChanged<String> onRename;
  final VoidCallback onToggleVisibility;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? ArcadiaColor.active : null,
        child: Row(
          children: [
            GestureDetector(
              onTap: onToggleVisibility,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(
                  layer.visible ? Icons.visibility : Icons.visibility_off,
                  size: 14,
                  color: ArcadiaColor.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditing
                  ? _RenameField(
                      initialName: layer.name,
                      onSubmit: onRename,
                    )
                  : Text(
                      layer.name,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
            if (showDelete)
              GestureDetector(
                onTap: onDelete,
                child: const MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: ArcadiaColor.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RenameField extends StatefulWidget {
  const _RenameField({required this.initialName, required this.onSubmit});

  final String initialName;
  final ValueChanged<String> onSubmit;

  @override
  State<_RenameField> createState() => _RenameFieldState();
}

class _RenameFieldState extends State<_RenameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      style: const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.zero,
        border: InputBorder.none,
      ),
      onSubmitted: widget.onSubmit,
    );
  }
}
```

- [ ] **Step 4: Run LayersPanel tests**

Run: `flutter test test/src/ui/layers_panel_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/src/ui/layers_panel.dart test/src/ui/layers_panel_test.dart
git commit -m "feat: add LayersPanel widget with tests"
```

### Task 9: Integrate LayersPanel into ProjectPage

**Files:**
- Modify: `lib/src/ui/project_page.dart`
- Modify: `test/src/ui/project_page_test.dart`

- [ ] **Step 1: Add LayersPanel to ProjectPage layout**

In `lib/src/ui/project_page.dart`:

1. Add import: `import 'layers_panel.dart';`

2. Replace the `Column` children in the `Focus` widget:
```dart
        child: const Focus(
          autofocus: true,
          child: Column(
            children: [
              HorizontalSeparator(),
              Toolbar(),
              HorizontalSeparator(),
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Viewport()),
                    LayersPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
```

- [ ] **Step 2: Add a ProjectPage test verifying LayersPanel is present**

Add to `test/src/ui/project_page_test.dart`:
```dart
import 'package:arcadia/src/ui/layers_panel.dart';
```

Add test:
```dart
    testWidgets('layers panel is present in layout', (tester) async {
      await _pumpProjectPage(tester);

      expect(find.byType(LayersPanel), findsOneWidget);
    });
```

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/src/ui/project_page.dart test/src/ui/project_page_test.dart
git commit -m "feat: integrate LayersPanel into ProjectPage layout"
```

### Task 10: Final verification

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests PASS.

- [ ] **Step 2: Run the app and verify manually**

Run: `flutter run -d macos` (or the user's preferred target)
Verify:
- Default "Layer 0" appears in the right panel
- Can create new layers with the + button
- Clicking a layer makes it active (highlighted)
- Double-clicking renames inline
- Eye icon toggles visibility — hidden layer geometry disappears from canvas
- Drawing on a layer adds geometry to that layer
- Delete button removes layers (not shown on last layer)
- Panel is resizable by dragging the divider
- Panel collapses and expands

- [ ] **Step 3: Commit any fixes from manual verification**

If any fixes were needed, commit them with specific file paths:
```bash
git add <specific-files-that-were-fixed>
git commit -m "fix: address issues found during manual layers verification"
```
