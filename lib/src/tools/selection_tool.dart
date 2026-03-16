import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../foundation/geometry/rectangle_generation.dart';
import '../geometry/geometry.dart';
import 'tool.dart';

const _selectionDragStartDistanceInPixels = 1.0;

/// The default selection tool.
class SelectionTool implements Tool {
  /// The default constructor for [SelectionTool].
  const SelectionTool();

  @override
  String get name => 'Selection';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyV);

  @override
  Widget get icon => const _SelectionToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _SelectionToolAction.new;
}

enum _SelectionDragMode {
  window,
  crossing,
}

class _SelectionDragSession {
  _SelectionDragSession({
    required this.start,
    required this.current,
    required this.baselineSelection,
  });

  final Offset start;
  Offset current;
  final List<Geometry> baselineSelection;

  Rect get rect => Rect.fromPoints(start, current);

  _SelectionDragMode get mode => current.dx >= start.dx
      ? _SelectionDragMode.window
      : _SelectionDragMode.crossing;
}

class _SelectionToolAction extends ToolAction {
  List<Geometry> _selectedGeometries = [];
  Geometry? _hoveringGeometry;
  _SelectionDragSession? _selectionDragSession;

  @override
  void onClickDown() {
    final cursorPosition = state.cursorPosition;
    _selectionDragSession = _SelectionDragSession(
      start: cursorPosition,
      current: cursorPosition,
      baselineSelection: _selectedGeometries,
    );
    _updateSelectionPropertiesLabel();
    _updateToolGeometries();
  }

  @override
  void onDelete() {
    if (_selectedGeometries.isEmpty) {
      return;
    }

    deleteGeometries(_selectedGeometries);
    _selectedGeometries = [];
    _hoveringGeometry = null;
    _updateSelectionPropertiesLabel();
    _updateToolGeometries();
  }

  @override
  void onClickUp() {
    if (_selectionDragSession case final session?) {
      if (!_hasDragStarted(session)) {
        _handleSingleSelection(baselineSelection: session.baselineSelection);
      }
      _selectionDragSession = null;
    } else {
      _handleSingleSelection(baselineSelection: _selectedGeometries);
    }

    _hoveringGeometry = _geometryBelowCursor();
    _updateSelectionPropertiesLabel();
    _updateToolGeometries();
  }

  @override
  void onCancel() {
    if (_selectionDragSession case final session?) {
      _selectedGeometries = session.baselineSelection;
    }
    _selectionDragSession = null;
    _hoveringGeometry = _geometryBelowCursor();
    _updateSelectionPropertiesLabel();
    _updateToolGeometries();
  }

  @override
  void onCursorPositionChange() {
    if (_selectionDragSession case final session?) {
      _updateDragSelectionPreview(session);
    } else {
      _hoveringGeometry = _geometryBelowCursor();
    }

    _updateSelectionPropertiesLabel();
    _updateToolGeometries();
  }

  @override
  void onSelectedUnitChange() {
    _updateSelectionPropertiesLabel();
  }

  void _updateDragSelectionPreview(_SelectionDragSession session) {
    session.current = state.cursorPosition;

    if (!_hasDragStarted(session)) {
      _selectedGeometries = session.baselineSelection;
      return;
    }

    _selectedGeometries = _selectionWithMatches(session);
  }

  bool _hasDragStarted(_SelectionDragSession session) {
    final dragDistanceInPixels =
        (session.current - session.start).distance *
        state.zoom *
        unitVirtualPixelRatio;
    return dragDistanceInPixels >= _selectionDragStartDistanceInPixels;
  }

  List<Geometry> _matchingGeometriesForRect(
    Rect selectionRect, {
    required _SelectionDragMode mode,
  }) {
    return [
      for (final layer in state.layers)
        if (layer.visible)
          for (final geometry in layer.geometries)
            if (switch (mode) {
              _SelectionDragMode.window => geometry.containedIn(selectionRect),
              _SelectionDragMode.crossing => geometry.intersects(selectionRect),
            })
              geometry,
    ];
  }

  List<Geometry> _selectionWithMatches(_SelectionDragSession session) {
    final matches = _matchingGeometriesForRect(
      session.rect,
      mode: session.mode,
    );
    final nextSelection = [...session.baselineSelection];

    for (final geometry in matches) {
      if (!nextSelection.contains(geometry)) {
        nextSelection.add(geometry);
      }
    }

    return nextSelection;
  }

  void _handleSingleSelection({required List<Geometry> baselineSelection}) {
    _selectedGeometries = [
      ...baselineSelection,
      if (_geometryBelowCursor() case final geometry?
          when !baselineSelection.contains(geometry))
        geometry,
    ];
  }

  void _updateSelectionPropertiesLabel() {
    final hovering = _selectionDragSession == null ? _hoveringGeometry : null;
    setOverlayLabel(hovering?.buildPropertiesText(state.selectedUnit));
  }

  void _updateToolGeometries() {
    clearToolGeometries();
    addToolGeometries([
      for (final geometry in _selectedGeometries)
        geometry.copyWith(strokeWidth: 5, color: .primaryActive),
      if (_hoveringGeometry case final hovering?
          when !_selectedGeometries.contains(hovering))
        hovering.copyWith(strokeWidth: 5, color: .accentMuted),
      if (_selectionDragSession case final session?)
        ...rectangleLinesFromRect(
          rect: session.rect,
          color: .accentActive,
          dashed: session.mode == _SelectionDragMode.crossing,
        ),
    ]);
  }

  Geometry? _geometryBelowCursor() {
    final tolerance = selectionTolerance / state.zoom;
    for (final layer in state.layers.reversed)
      if (layer.visible)
        for (final geometry in layer.geometries.reversed) {
          if (geometry.contains(state.cursorPosition, tolerance)) {
            return geometry;
          }
        }
    return null;
  }
}

class _SelectionToolIcon extends StatelessWidget {
  const _SelectionToolIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(16, 16),
      painter: _SelectionToolPainter(),
    );
  }
}

class _SelectionToolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArcadiaColor.primary
      ..strokeWidth = 1
      ..style = .stroke;
    const center = Offset(8, 8);
    const halfGap = 2.0;

    canvas
      ..drawLine(const Offset(8, 1), Offset(8, center.dy - halfGap), paint)
      ..drawLine(
        Offset(8, center.dy + halfGap),
        const Offset(8, 15),
        paint,
      )
      ..drawLine(const Offset(1, 8), Offset(center.dx - halfGap, 8), paint)
      ..drawLine(
        Offset(center.dx + halfGap, 8),
        const Offset(15, 8),
        paint,
      )
      ..drawRect(const Rect.fromLTWH(6.5, 6.5, 3, 3), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
