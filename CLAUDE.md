# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Arcadia is an open-source 2D CAD application written in Flutter. It runs on Flutter web and is deployed via Firebase Hosting. The project enforces strict constraints: no code generation, no third-party dependencies (only dart/flutter SDK packages), tests whenever possible, and everything documented.

## Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/src/tools/line_tool_test.dart

# Analyze (lint)
flutter analyze

# Format
dart format .

# Build for web (requires macros experiment)
flutter build web --enable-experiment=macros
```

## Architecture

### State Management

Custom `ValueNotifier`-based system with no external packages:

- **`ViewportNotifier`** (`logic/viewport_notifier.dart`): A `ValueNotifier<ViewportState>` that holds all viewport logic — zoom, pan, tool delegation, snapping, user input parsing.
- **`ViewportState`** (`data/viewport_state.dart`): Immutable data class with `copyWith`. Contains geometries, tool geometries, snapping geometries, zoom, pan offset, cursor position, selected tool, selected unit, overlay label, and user input.
- **`ViewportNotifierProvider`** (`providers/viewport_notifier_provider.dart`): Combines `InheritedWidget` (for the notifier reference) with `InheritedModel` (for granular state subscriptions). Widgets use `context.viewportNotifier` for actions and `context.selectViewportState<T>(selector)` to depend on specific state projections without unnecessary rebuilds.

### Tool System

Plugin-based architecture where each tool implements the `Tool` interface and provides a `ToolActionFactory`:

- **`Tool`** (interface): Declares `name`, `icon`, `shortcut`, `toolActionFactory`.
- **`ToolAction`** (abstract class): Bound to `ViewportNotifier`. Implements lifecycle hooks: `onCursorPositionChange`, `onClickUp`, `onClickDown`, `onCancel`, `onValueTyped`, `onDelete`. Provides helper methods to manage tool geometries, snapping points, and overlay labels.
- Tools: SelectionTool, LineTool, ArcTool, CircleTool, CenterRectangleTool, CornersRectangleTool, MeasureTool.

### Geometry System

All shapes extend the `Geometry` abstract class:

- Each geometry implements `render(Canvas, Offset, double)` with zoom/pan-aware rendering.
- Provides `snappingPoints`, `contains(Offset, tolerance)`, `containedIn(Rect)`, `intersects(Rect)`.
- Types: `Point`, `Line`, `Arc`, `Circle`. All are immutable with `copyWith`.
- Colors use `ArcadiaColor` — a custom `Color` subclass with semantic static constants (dark-mode only).

### UI Layer

- **`ProjectPage`**: Root widget with keyboard shortcuts (via Flutter `Actions`/`Shortcuts`) for tool selection.
- **`Viewport`**: `Listener`-based pointer handler that delegates pan/zoom/click events to `ViewportNotifier`.
- **Painters** (all `CustomPainter`): `ViewportPainter`, `GridPaint`, `CursorPaint`, `SnappingViewportPaint`, `ToolViewportPaint`.
- **`ViewportOverlay`**: Positioned overlay labels for zoom, cursor position, selection properties.

### Coordinate System

`unitVirtualPixelRatio = 5.0` — each unit (mm) maps to 5 virtual pixels. All geometry coordinates are in virtual space; rendering applies zoom and panOffset transformations.

## Pull Requests

When creating a PR, check `project_plan.md` for an issue related to the changes. If one exists, include `Closes #<issue-number>` in the PR description to link and auto-close it.

## Code Conventions

- **Immutability**: All data classes use `@immutable` and const constructors. State updates go through `copyWith`.
- **Documentation**: `public_member_api_docs` lint is enforced — all public APIs require `///` doc comments.
- **Strict analysis**: `strict-casts`, `strict-inference`, `strict-raw-types` all enabled. ~180 lint rules active.
- **Single quotes**, **trailing commas** required, **lines ≤ 80 chars**.
- **Relative imports** within `lib/src/`.
- **No `print`** statements (`avoid_print` lint).
- **Tests** mirror `lib/src/` structure in `test/src/`. Tool tests interact directly with `ViewportNotifier` (not widget tests) — instantiate a notifier, select a tool, simulate cursor moves and clicks, and assert on state.

## Testing Patterns

- Widget tests use `ViewportInheritedNotifier` (marked `@visibleForTesting`) to inject a `ViewportNotifier` directly.
- Painter tests use golden files (`matchesGoldenFile`).
- Tool behavior tests are unit tests that drive `ViewportNotifier` directly — no widget tree needed.
