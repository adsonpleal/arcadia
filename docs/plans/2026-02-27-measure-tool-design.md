# Measure Tool And Geometry Properties Design

Date: 2026-02-27
Status: Approved design

## Goal

Add a temporary Measure tool for chained polyline measurement and add
single-selection geometry properties display without changing existing drawing
geometry.

The Measure tool is inspection-only. Selection-based properties are always
available when exactly one geometry is selected.

## Validated Decisions

- Add a dedicated Measure tool.
- The Measure tool handles only temporary polyline measurement.
- Measure interaction follows the current Line tool chaining model.
- Closing a measured polygon happens only by clicking the first vertex.
- Open measurement shows total length only.
- Closed measurement shows both perimeter and area.
- The Measure tool never commits geometry into the drawing model.
- Selection state remains owned by `SelectionToolAction`.
- Single-selection properties are shown whenever exactly one geometry is
  selected, not only when the Measure tool is active.
- Geometry-specific properties are computed by each geometry class.
- `Geometry` gets a default nullable formatted-properties method so future
  geometries may opt out.
- First version properties:
  - `Line`: length
  - `Circle`: radius, diameter, circumference, area
  - `Arc`: radius, arc length
  - `Point`: coordinates

## Approach

Keep all interaction state mutation in `ViewportNotifier`, but keep selection
ownership inside `SelectionToolAction` as it works today.

Introduce two display-only overlay labels in viewport state:

- `selectionPropertiesLabel`
- `measureLabel`

Selection and measurement tools compute their own derived text and publish only
those strings to state. UI remains thin and renders whichever labels are
present.

## Architecture And Ownership

- `lib/src/geometry`
  - Add a default nullable properties-text method on `Geometry`.
  - Override it in supported concrete geometries.
  - Add a small reusable measurement utility for polyline length, perimeter,
    and polygon area.
- `lib/src/tools/selection_tool.dart`
  - Preserve existing selection interaction and internal selection state.
  - Publish single-selection properties text when exactly one geometry is
    selected.
- `lib/src/tools/measure_tool.dart`
  - Own polyline measurement session state.
  - Render preview geometry through `toolGeometries`.
  - Publish running measurement text through viewport state.
- `lib/src/logic/viewport_notifier.dart`
  - Add display-label setters/clearers used by tools.
  - Clear measure-specific label state when switching tools or canceling the
    active measurement session.
- `lib/src/ui/viewport_overlay.dart`
  - Render conditional chips for selection properties and measure output.

## Geometry Properties API

Add a default method to `Geometry`:

```dart
String? buildPropertiesText(MetricUnit unit) => null;
```

Rules:

- Return preformatted overlay text.
- Use the selected project unit for conversion and symbol display.
- Return `null` for geometries that should expose no properties.
- Keep the formatting logic inside each geometry implementation.

## Selection Properties Behavior

- Existing click and drag selection behavior remains unchanged.
- When `SelectionToolAction` updates selection:
  - if exactly one geometry is selected, call
    `geometry.buildPropertiesText(state.selectedUnit)`.
  - if the result is non-null, publish it as `selectionPropertiesLabel`.
  - otherwise clear `selectionPropertiesLabel`.
- When zero or multiple geometries are selected, clear the label.
- When delete or cancel changes selection, recompute the label.
- If the selected project unit changes while one geometry remains selected, the
  selection properties label should recompute immediately.

## Measure Tool Behavior

The Measure tool is a temporary polyline inspection tool.

### Interaction Flow

1. First click sets the first vertex.
2. Each next click adds a segment and continues the chain.
3. Cursor movement updates the live preview segment.
4. With at least three vertices, clicking the first vertex closes the path.
5. After closure, the tool shows perimeter and area and keeps the preview
   visible until canceled or restarted.
6. A new click after a closed measurement starts a fresh measurement session.

### Measurement Output

- Before two points exist: no measure label.
- Open path:
  - show total polyline length.
- Closed path:
  - show perimeter
  - show area

### Lifecycle Rules

- The Measure tool never adds geometry to `state.geometries`.
- `Escape`, tool switch, and cancel clear measure preview and `measureLabel`.
- Closing only succeeds by clicking the first vertex.
- Degenerate closed polygons may report `Area: 0.0`.

## Formatting

Use compact multiline text with one decimal place, matching current overlay
label style.

Examples:

- Line: `Length: 42.0 mm`
- Circle:
  - `Radius: 10.0 mm`
  - `Diameter: 20.0 mm`
  - `Circumference: 62.8 mm`
  - `Area: 314.2 mm²`
- Closed measure:
  - `Perimeter: 120.0 mm`
  - `Area: 900.0 mm²`

## Testing Strategy

- Geometry tests:
  - default `Geometry` properties method returns `null`
  - `Line`, `Circle`, `Arc`, and `Point` return expected formatted text
  - unit conversion is reflected in formatted output
- Measurement utility tests:
  - open polyline length
  - closed perimeter
  - polygon area including degenerate shapes
- Measure tool tests:
  - metadata and registration
  - chained preview updates running length
  - clicking first vertex closes the polygon
  - closed measurement shows perimeter and area
  - cancel/tool switch clears preview and label
  - no geometry is committed to the drawing
- Selection/notifier tests:
  - single selection publishes properties label
  - multiple selection clears properties label
  - delete/cancel recomputes or clears properties label
  - selected unit change recomputes single-selection properties
- Overlay tests:
  - selection properties chip renders conditionally
  - measure chip renders conditionally
  - existing zoom, cursor position, and input labels remain intact

## Risks And Constraints

- Selection properties now need a recompute path on unit changes even though
  selection ownership stays inside the selection tool.
- Measure-tool closure depends on reliable snapping/hit detection against the
  first vertex.
- Overlay growth must not regress current label layout or cause avoidable
  rebuilds.
- Adding formatted text directly on geometry keeps v1 small, but a later
  inspector model may require refactoring to structured properties.

## Out Of Scope

- Measuring existing selected geometry from the Measure tool.
- Multi-selection aggregated properties.
- Editing geometry from properties output.
- Dimensions, labels attached to drawing, or persistent annotation entities.
