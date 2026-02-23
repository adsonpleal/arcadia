# Arcadia Project Plan (2D CAD)

Date: 2026-02-23
Status: Draft roadmap
Scope: 2D drafting only

## Planning Model

This roadmap follows a capability ladder:

1. **Now** builds core drafting productivity and precision.
2. **Next** adds speed and repeatability workflows.
3. **Later** expands output quality, interoperability, and advanced editing.

## Rules for Prioritization

1. Keep state mutation in `ViewportNotifier`.
2. Keep tools focused on preview/final geometry orchestration.
3. Build dependencies first (example: units before measurement/dimensions).
4. Pair each feature with tests in the correct layer (`logic`, `tools`, `geometry`, `ui`).

## NOW (Core Drafting Productivity)

### 1) Zoom label
- Goal: show current zoom level continuously.
- Dependencies: existing zoom state.
- Acceptance:
  - Zoom indicator is visible in the viewport UI.
  - Value updates on wheel/pinch zoom changes.
  - Display format is stable and readable (e.g., `100%`).

### 2) Selection modes (Window, Crossing, and Lasso Crossing)
- Goal: make selection behavior match common CAD interaction patterns.
- Dependencies: existing selection and hover pipeline.
- Acceptance:
  - Window selection (left-to-right rectangle) selects only fully contained geometries.
  - Crossing selection (right-to-left rectangle) selects contained and intersecting geometries.
  - Freehand lasso crossing lets users draw a smooth quadratic Bezier path with a closed preview.
  - Intersecting geometries are preview-highlighted while the lasso path is still being drawn.

### 3) Project units configuration
- Goal: define drawing units (e.g., mm, cm, m, in).
- Dependencies: none.
- Acceptance:
  - User can set project unit in settings.
  - Unit is stored with project/session state.
  - Tools that display numeric values read current unit.

### 4) Measure tool (length and area)
- Goal: inspect geometry sizes without editing.
- Dependencies: project units.
- Acceptance:
  - Length measurement works for line/polyline-like selections.
  - Area measurement works for closed geometry.
  - Results show value + unit.

### 5) Dimension tool (view/edit line length)
- Goal: create drafting dimensions and edit line length numerically.
- Dependencies: project units, measure behavior patterns.
- Acceptance:
  - User can place a linear dimension for a line.
  - Editing a dimension value updates the line length.
  - Dimension graphics remain readable during zoom/pan.

### 6) Layers (baseline)
- Goal: organize geometry by layer.
- Dependencies: none.
- Acceptance:
  - User can create, rename, select active layer.
  - User can toggle layer visibility.
  - New geometry is created on active layer.

### 7) Rotate tool
- Goal: rotate selected geometry around a pivot.
- Dependencies: selection flow.
- Acceptance:
  - Pivot can be chosen.
  - Angle can be interactive and numeric.
  - Undo/redo works for rotations.

### 8) Copy tool
- Goal: duplicate selected geometry.
- Dependencies: selection flow.
- Acceptance:
  - User can copy by base point + target point.
  - Copied entities preserve properties and layer.
  - Undo/redo works for copies.

### 9) Transform tool (move/rotate/scale entry point)
- Goal: centralize common transformations.
- Dependencies: rotate + copy foundations.
- Acceptance:
  - User can choose transform mode from one tool.
  - Preview is shown before finalizing.
  - Finalization behavior is consistent with existing tool flows.

### 10) Offset tool
- Goal: create parallel/offset geometry at a set distance.
- Dependencies: units config.
- Acceptance:
  - Works for lines and circles first.
  - Distance supports numeric entry.
  - Tool preview matches final geometry.

### 11) Trim tool
- Goal: remove geometry portions using cutting boundaries.
- Dependencies: robust intersection checks.
- Acceptance:
  - User can trim target geometry against selected boundaries.
  - No-op trims do not corrupt geometry lists.
  - Undo/redo stays correct.

### 12) Fillet tool
- Goal: connect two edges with a radius arc.
- Dependencies: trim/extend and intersection handling.
- Acceptance:
  - Radius can be set before operation.
  - Tool creates arc + updates connected geometry as expected.
  - Edge cases (parallel/unreachable) fail safely with feedback.

## NEXT (Speed, Repeatability, and Project Continuity)

### 13) Mirror tool
- Goal: reflect geometry across an axis.
- Dependencies: transform/copy patterns.
- Acceptance:
  - Mirror axis is defined by two points.
  - User can choose keep original vs replace.
  - Works with mixed geometry selections.

### 14) Linear pattern tool
- Goal: array copies in a line with spacing/count.
- Dependencies: copy workflow.
- Acceptance:
  - User sets count and spacing.
  - Preview shows full result before apply.
  - Pattern result is undoable in one step.

### 15) Circular pattern tool
- Goal: array copies around a center.
- Dependencies: rotate + copy workflows.
- Acceptance:
  - User sets center, count, total angle.
  - Supports full-circle and partial arrays.
  - Preview and final output are consistent.

### 16) Text tool (single-line first)
- Goal: place editable annotation text.
- Dependencies: none.
- Acceptance:
  - User can place and edit single-line text.
  - Text has size and rotation controls.
  - Text stays selectable and layer-aware.

### 17) Local autosave/session restore
- Goal: prevent work loss between app restarts.
- Dependencies: project serialization baseline.
- Acceptance:
  - Current project state saves automatically on change intervals.
  - App startup restores latest unsaved session.
  - Corrupted autosave data fails safely.

### 18) Save project file
- Goal: persist a named project file.
- Dependencies: stable project schema.
- Acceptance:
  - User can save project to a file path.
  - Saved data includes geometry, layers, units, and view preferences.
  - Save errors surface actionable feedback.

### 19) Load project file
- Goal: reopen saved projects.
- Dependencies: save format.
- Acceptance:
  - User can load previously saved project files.
  - Unsupported/invalid files fail with clear errors.
  - Loaded content restores layers and units correctly.

## LATER (Output, Interop, and Advanced Editing)

### 20) Export to PDF with printing sheet
- Goal: generate printable sheets from drawings.
- Dependencies: save/load stability, layer visibility rules.
- Acceptance:
  - User can export a viewport/window to PDF.
  - Page setup supports paper size/orientation/scale.
  - Output preserves linework clarity and annotation legibility.

### 21) Advanced layers
- Goal: improve control for larger drawings.
- Dependencies: baseline layers.
- Acceptance:
  - Layer lock/unlock and reordering are supported.
  - By-layer style controls are available (color/line style).
  - Selection/editing respects layer locks.

### 22) Advanced dimensions
- Goal: improve drafting annotation quality.
- Dependencies: base dimension tool.
- Acceptance:
  - Dimension styles (text size, arrow style, precision) are configurable.
  - Dimension values remain associative after geometry edits where possible.
  - Style changes can apply globally or per-dimension.

### 23) Expanded snaps
- Goal: increase placement precision.
- Dependencies: current snapping architecture.
- Acceptance:
  - Add midpoint, intersection, perpendicular, tangent snaps.
  - Snapping feedback is visible and unambiguous.
  - Snap priority and toggles are user-configurable.

### 24) Properties inspector
- Goal: edit selected entity numerically.
- Dependencies: stable geometry model APIs.
- Acceptance:
  - Selected object properties appear in a side panel.
  - Numeric edits update geometry immediately or on apply.
  - Invalid input is validated with clear messaging.

### 25) Blocks/components
- Goal: reuse grouped geometry efficiently.
- Dependencies: save/load and transform stability.
- Acceptance:
  - User can define a block from selected geometry.
  - Block instances can be inserted/copied/rotated/scaled.
  - Editing definition updates instances based on policy.

### 26) Interoperability (DXF import/export candidate)
- Goal: exchange drawings with external CAD tools.
- Dependencies: project schema maturity.
- Acceptance:
  - Export supports a documented subset first.
  - Import validates unsupported entities safely.
  - Round-trip tests cover supported primitives.

## Suggested Cross-Cutting Milestones

1. **M1: Precision Drafting Beta**
- Units, measure, dimensions, rotate/copy/offset/trim, baseline layers.

2. **M2: Daily Use Workflow**
- Mirror/patterns/text + autosave + save/load.

3. **M3: Delivery and Exchange**
- PDF sheets + advanced layers/dimensions + properties + interop candidate.

## Risks and Constraints

- Geometry editing tools (trim/fillet/offset) can introduce complex edge cases.
- Associative dimensions require careful entity-link maintenance.
- Save/load format should be versioned early to avoid migration pain.

## Out of Scope (for this roadmap)

- 3D modeling workflows.
- Rendering engines beyond current 2D architecture.
