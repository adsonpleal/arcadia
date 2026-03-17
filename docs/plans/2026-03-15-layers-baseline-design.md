# Layers (Baseline) Design

**Issue:** [#27 — Layers (baseline)](https://github.com/adsonpleal/arcadia/issues/27)
**Date:** 2026-03-15

## Goal

Organize geometry by layer. Users can create, rename, and select an active layer, toggle layer visibility, and new geometry is created on the active layer.

## Decisions

- One layer per geometry (each geometry belongs to exactly one layer)
- Undeletable default layer ("Layer 0" always exists)
- Right side panel, collapsible and resizable
- Hidden layers are non-selectable and non-interactive
- Double-click inline rename
- Layer wraps geometries (Approach A — `Layer` data class owns its `List<Geometry>`)
- Layer reordering is out of scope (deferred to issue #58 — advanced layers)

## Data Model

### New: `Layer` class (`lib/src/data/layer.dart`)

Immutable data class representing a drawing layer.

Fields:
- `id` (`String`) — unique identifier, generated via incrementing counter
- `name` (`String`) — user-visible name
- `visible` (`bool`, default `true`) — whether the layer's geometries are rendered and interactive
- `geometries` (`List<Geometry>`, default `const []`) — the geometries belonging to this layer

Implements `==` and `hashCode` comparing all fields, using `listEquals` for the geometries list. Provides `copyWith`.

### Modified: `ViewportState`

- Replace `List<Geometry> geometries` with `List<Layer> layers`
- Add `String activeLayerId` — the layer that receives new geometry
- Default state: `layers: [Layer(id: '0', name: 'Layer 0')]`, `activeLayerId: '0'`
- `toolGeometries` and `snappingGeometries` remain as flat `List<Geometry>` (temporary rendering artifacts, not user data)
- `copyWith`, `==`, and `hashCode` updated to include `layers` and `activeLayerId`

### ID Generation

Monotonically incrementing counter (`_nextLayerId`) held in `ViewportNotifier`. Never decremented on undo — undo restores the layers list but the counter only moves forward, preventing ID collisions with undo stack entries. No UUIDs needed for a local-only app.

## ViewportNotifier Changes

### New methods

- `addLayer(String name)` — creates a new layer with incremented ID, appends to `layers`, sets it as active
- `renameLayer(String id, String name)` — updates the layer's name
- `deleteLayer(String id)` — removes the layer and its geometries. If it's the active layer, active switches to the layer at `index - 1`, or `index 0` of the remaining list if the deleted layer was first. Cannot delete the last remaining layer.
- `setActiveLayer(String id)` — sets `activeLayerId`
- `toggleLayerVisibility(String id)` — flips `visible` on the target layer

### Modified methods

- `addGeometries()` — finds the active layer and appends geometries to it. Snapping points recomputed afterward.
- `deleteGeometries()` — searches across all layers to find and remove target geometries by identity. Since geometries are immutable value objects compared by `==`, identical geometries on different layers would both match — this is acceptable and consistent with the current behavior where duplicate geometries in the flat list would also both be removed.
- Undo/redo stacks change from `List<List<Geometry>>` to `List<List<Layer>>` — captures the full layers list so layer creation/deletion/visibility changes are all undoable. `activeLayerId` is **not** captured in the undo stack — it is a UI navigation concern, not document state. Undoing a layer deletion restores the layer but does not change which layer is active.
- `_snappingPoints` recomputed after any mutation that changes the set of visible geometries: `addGeometries`, `deleteGeometries`, `toggleLayerVisibility`, `deleteLayer`, `undo`, `redo`. Only geometries from visible layers are included.

### Hiding the active layer

If the user hides the active layer, it stays active. New geometry created on it will appear when the layer is made visible again. This matches AutoCAD behavior.

## Rendering Changes

### `ViewportPaint`

Subscribes to `state.layers` and flattens visible geometries inside the selector to avoid unnecessary rebuilds:

```dart
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
```

Rendering order: layers in list order (index 0 = bottom), geometries within a layer in insertion order.

### Other paint widgets

`SnappingViewportPaint`, `ToolViewportPaint`, `GridPaint`, `CursorPaint`, `ViewportOverlay` — no changes needed.

## Selection Tool Changes

The selection tool accesses `state.geometries` directly today. Since `state.geometries` is replaced by `state.layers`, the selection tool will flatten visible layers inline to get the geometry list:

```dart
List<Geometry> get _visibleGeometries => [
  for (final layer in state.layers)
    if (layer.visible) ...layer.geometries,
];
```

- `_geometryBelowCursor()` — uses `_visibleGeometries.reversed` (later layers on top)
- `_matchingGeometriesForRect()` — iterates `_visibleGeometries`
- The selection tool does not need further layer awareness beyond this filtering

## Layers Panel UI

### New widget: `LayersPanel` (`lib/src/ui/layers_panel.dart`)

Right-side panel in `ProjectPage`. Layout changes from:

```
Column: [Toolbar, Viewport]
```

to:

```
Column: [Toolbar, Expanded(Row: [Viewport, LayersPanel])]
```

### Panel structure

- Header row: "LAYERS" label + add layer button (+)
- Scrollable list of layer rows, each showing:
  - Visibility toggle (eye icon) — click toggles `toggleLayerVisibility(id)`
  - Layer name — double-click enters inline edit via `TextField`
  - Visual indicator for active layer (accent/highlight color)
- Single click on a layer row sets it as active via `setActiveLayer(id)`
- Delete button per layer (hidden on the last remaining layer)

### Collapse and resize

- Draggable divider between viewport and panel for horizontal resizing
- Collapse button in panel header hides the panel to a thin strip/icon
- Panel width and collapsed/expanded state stored in widget local state (not `ViewportState` — UI concern, not document state)
- Minimum width constraint to prevent unusably small panel

### Styling

Follows existing patterns: `ArcadiaColor.surface` background, `ArcadiaColor.border` for dividers, `ArcadiaColor.active` for active layer highlight. Matches toolbar visual language.

## Testing Strategy

### Unit tests

- `Layer` — equality, hashCode, copyWith
- `ViewportState` — construction with layers, copyWith for layers/activeLayerId, equality
- `ViewportNotifier`:
  - addLayer, renameLayer, deleteLayer (including last-layer guard)
  - setActiveLayer, toggleLayerVisibility
  - addGeometries goes to active layer
  - deleteGeometries across layers
  - Undo/redo captures layer state
  - Snapping points only from visible layers
- Selection tool — `_geometryBelowCursor` and `_matchingGeometriesForRect` skip hidden layers

### Widget tests

- `LayersPanel` — renders layer list, add button creates layer, click selects active, double-click enters rename, eye icon toggles visibility, delete button works, last layer can't be deleted
- `ViewportPaint` — only renders visible layers' geometries
- `ProjectPage` — layers panel present in layout
