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

Simple incrementing counter (`_nextLayerId`) held in `ViewportNotifier`. No UUIDs needed for a local-only app.

## ViewportNotifier Changes

### New methods

- `addLayer(String name)` — creates a new layer with incremented ID, appends to `layers`, sets it as active
- `renameLayer(String id, String name)` — updates the layer's name
- `deleteLayer(String id)` — removes the layer and its geometries. If it's the active layer, active switches to the previous layer. Cannot delete the last remaining layer.
- `setActiveLayer(String id)` — sets `activeLayerId`
- `toggleLayerVisibility(String id)` — flips `visible` on the target layer

### Modified methods

- `addGeometries()` — finds the active layer and appends geometries to it. Snapping points recomputed from all visible layers.
- `deleteGeometries()` — searches across all layers to find and remove target geometries
- Undo/redo stacks change from `List<List<Geometry>>` to `List<List<Layer>>` — captures the full layers list so layer creation/deletion/visibility changes are all undoable
- `_snappingPoints` recomputed from visible layers only

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

- `_geometryBelowCursor()` — iterates geometries from visible layers only (reversed order, later layers on top)
- `_matchingGeometriesForRect()` — filters to visible layer geometries only
- The selection tool does not need layer awareness beyond filtering to visible geometries

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
- Panel width stored in widget local state (not `ViewportState` — UI concern, not document state)
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
