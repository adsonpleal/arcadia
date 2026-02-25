# Selection Modes Design (Window, Crossing, Lasso Crossing)

Date: 2026-02-25
Status: Approved design
Related plan item: [Selection modes (Window, Crossing, and Lasso Crossing)](https://github.com/adsonpleal/arcadia/issues/38)

## Goal

Implement CAD-style drag selection with:

- Window selection (left-to-right rectangle) for fully contained geometries.
- Crossing selection (right-to-left rectangle) for contained or intersecting geometries.
- Lasso crossing selection (`Alt + drag`) with a smooth, closed preview and live preview highlights.

## Validated Decisions

- Activation:
  - Plain drag starts rectangle selection.
  - `Alt + drag` starts lasso crossing selection.
- Rectangle mode:
  - Left-to-right drag = window.
  - Right-to-left drag = crossing.
- Selection merge behavior:
  - Replace selection by default.
  - `Shift` during drag adds to selection.
- Lasso preview:
  - Smooth quadratic path while dragging.
  - Always closed during preview and finalization.
- Tool priority:
  - If a drawing tool is active, drag selection is disabled.

## Approach

Use a notifier-centered implementation (minimal diff) while moving selection-matching algorithms into geometry classes.

Why this approach:

- Preserves ownership rule: `ViewportNotifier` remains single owner of viewport mutation.
- Keeps pointer routing in existing UI entry points.
- Avoids introducing selection as a new tool mode.
- Enables shape-specific, testable matching logic via geometry abstractions.

## Architecture and Ownership

- `lib/src/ui/viewport.dart`
  - Continue as pointer event entry point.
  - Forward pointer down/move/up inputs needed for drag selection lifecycle.
- `lib/src/logic/viewport_notifier.dart`
  - Own drag-session lifecycle and state mutation.
  - Resolve active selection mode and commit/merge behavior.
  - Drive preview geometry and live preview highlights.
- `lib/src/geometry/geometry.dart`
  - Add three abstract selection methods (one per mode).
- Concrete geometry files (`line.dart`, `circle.dart`, `arc.dart`, `point.dart`)
  - Implement each selection method with shape-specific algorithms.

Paint layer order remains unchanged:

`Grid -> Selection -> Geometry -> Snapping -> Tool -> Cursor`

## Geometry Contract Changes

Add to `Geometry`:

```dart
bool matchesWindowSelection(Rect rect);
bool matchesCrossingSelection(Rect rect);
bool matchesLassoCrossingSelection(List<Offset> closedLassoPath);
```

Method intent:

- `matchesWindowSelection`: true only when geometry is fully contained.
- `matchesCrossingSelection`: true when geometry is contained or intersects boundary.
- `matchesLassoCrossingSelection`: true when geometry is contained or intersects closed lasso boundary.

### Per-Geometry Algorithm Expectations

- `Point`
  - Window/crossing: point inside rect.
  - Lasso crossing: point inside closed polygon.
- `Line`
  - Window: both endpoints inside rect.
  - Crossing: endpoint inside rect or segment intersects any rectangle edge.
  - Lasso crossing: endpoint inside polygon or segment intersects polygon edges.
- `Circle`
  - Window: circle fully contained by rect.
  - Crossing: center inside rect or circle intersects rectangle edges.
  - Lasso crossing: center inside polygon or circle intersects polygon edges.
- `Arc`
  - Use deterministic segment approximation internally for all three methods.
  - Window: all sampled points inside bounds.
  - Crossing/lasso crossing: sampled segment intersects boundary or sampled points lie inside.

## Interaction and Data Flow

1. Pointer down (no active tool): start drag-selection session.
2. Pointer move:
   - Update cursor world position.
   - Update rectangle or lasso preview in `toolGeometries`.
   - Recompute preview-selected candidates via geometry selection methods.
   - Show preview-highlight candidates in `selectionGeometries`.
3. Pointer up:
   - Finalize candidate set.
   - Replace or additive-merge based on `Shift`.
   - Clear drag preview state.
4. Non-drag click behavior remains existing toggle selection flow.

## Preview Representation

- Rectangle selection preview:
  - Draw preview boundary geometry via `toolGeometries`.
- Lasso selection preview:
  - Draw a smooth quadratic path as a closed loop while dragging.
  - Keep path generation deterministic from sampled points.

## Error Handling and Edge Behavior

- Ignore drag selection when a tool is active.
- Treat negligible-delta drag as click (preserve click-toggle semantics).
- On pointer cancel/loss:
  - Abort drag session safely.
  - Clear preview geometries.
  - Leave persisted selection unchanged.
- Guard against invalid lasso input:
  - Require minimum sample count to evaluate closed lasso.
  - Fallback to no-op match when path is invalid.

## Testing Strategy

Add/extend tests in the correct layers:

- Geometry tests (`test/src/geometry/...`)
  - Validate each new abstract method for `Point`, `Line`, `Circle`, `Arc`.
  - Include containment and intersection edge cases.
- Logic tests (`test/src/logic/viewport_notifier_test.dart`)
  - Rectangle window selection by drag direction.
  - Rectangle crossing selection.
  - `Alt + drag` lasso crossing with live preview-highlight behavior.
  - Replace vs `Shift` additive selection finalization.
  - Active tool priority over drag selection.
- UI tests (`test/src/ui/viewport_test.dart`)
  - Pointer down/move/up routing for selection drag flow.
  - Regression for existing click selection and layer rendering assumptions.

## Risks and Constraints

- Arc and circle intersection math can become complex; approximation strategy should stay deterministic and tested.
- Live preview recomputation cost scales with geometry count; keep algorithms efficient and avoid unnecessary allocations.
- Must preserve existing hover/click selection behavior and undo/redo integrity.

## Out of Scope

- Dedicated selection toolbar mode.
- Multi-shape boolean lasso operations beyond crossing semantics.
- Refactoring selection into the tool framework.

