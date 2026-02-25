import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import '../constants/config.dart';
import '../data/viewport_state.dart';
import '../foundation/geometry/rectangle_generation.dart';
import '../geometry/geometry.dart';
import 'tool.dart';

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

/// Selection state owned by the selection tool module.
mixin SelectionToolState on ValueNotifier<ViewportState> {
  final List<Geometry> _selectedGeometries = [];
  Geometry? _hoveringGeometry;

  /// The currently selected geometries.
  List<Geometry> get selectedGeometries => [..._selectedGeometries];

  /// Set selected geometries and optional hovering geometry.
  void setSelectedGeometries(
    List<Geometry> geometries, {
    Geometry? hoveringGeometry,
  }) {
    _selectedGeometries
      ..clear()
      ..addAll(geometries);
    _hoveringGeometry = hoveringGeometry;
    _updateSelectedGeometries();
  }

  /// Return the geometry currently below the cursor.
  Geometry? geometryBelowCursor() {
    final tolerance = selectionTolerance / value.zoom;
    for (final geometry in value.geometries) {
      if (geometry.contains(value.cursorPosition, tolerance)) {
        return geometry;
      }
    }
    return null;
  }

  /// Clear selected and hovering geometries.
  void clearSelectedGeometries() {
    _selectedGeometries.clear();
    _hoveringGeometry = null;
    _updateSelectedGeometries();
  }

  void _updateSelectedGeometries() {
    value = value.copyWith(
      selectionGeometries: [
        if (_hoveringGeometry case final hovering?
            when !_selectedGeometries.contains(hovering))
          hovering.copyWith(strokeWidth: 5, color: .accentMuted),
        for (final geometry in _selectedGeometries)
          geometry.copyWith(strokeWidth: 5, color: .primaryActive),
      ],
    );
  }
}

const _selectionDragStartDistance = 0.1;

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
}

class _SelectionToolAction extends ToolAction {
  @override
  void onClickDown() {
    clearToolGeometries();
    final baselineSelection = selectedGeometries;
    final cursorPosition = state.cursorPosition;
    _selectionDragSession = _SelectionDragSession(
      start: cursorPosition,
      current: cursorPosition,
      baselineSelection: baselineSelection,
    );
    setSelectedGeometries(baselineSelection);
  }

  @override
  void onClickUp() {
    if (_selectionDragSession case final session?) {
      if (_hasDragStarted(session)) {
        final selectionRect = Rect.fromPoints(session.start, session.current);
        final mode = _resolvedRectSelectionMode(session);
        setSelectedGeometries(
          _selectionWithMatches(
            _matchingGeometriesForRect(selectionRect, mode: mode),
            baselineSelection: session.baselineSelection,
          ),
        );
      } else {
        _handleSingleSelection(baselineSelection: session.baselineSelection);
      }
      _selectionDragSession = null;
      clearToolGeometries();
      return;
    }

    _handleSingleSelection(baselineSelection: selectedGeometries);
  }

  @override
  void onCancel() {
    if (_selectionDragSession case final session?) {
      setSelectedGeometries(session.baselineSelection);
    }
    _selectionDragSession = null;
    clearToolGeometries();
  }

  @override
  void onCursorPositionChange() {
    if (_selectionDragSession case final session?) {
      _updateDragSelectionPreview(session);
      return;
    }

    setSelectedGeometries(
      selectedGeometries,
      hoveringGeometry: geometryBelowCursor(),
    );
  }

  _SelectionDragSession? _selectionDragSession;

  void _updateDragSelectionPreview(_SelectionDragSession session) {
    session.current = state.cursorPosition;

    if (!_hasDragStarted(session)) {
      clearToolGeometries();
      setSelectedGeometries(session.baselineSelection);
      return;
    }

    final selectionRect = Rect.fromPoints(session.start, session.current);
    final mode = _resolvedRectSelectionMode(session);
    clearToolGeometries();
    addToolGeometries(
      rectangleLinesFromRect(
        rect: selectionRect,
        color: .accentActive,
        dashed: mode == _SelectionDragMode.crossing,
      ),
    );
    setSelectedGeometries(
      _selectionWithMatches(
        _matchingGeometriesForRect(selectionRect, mode: mode),
        baselineSelection: session.baselineSelection,
      ),
    );
  }

  bool _hasDragStarted(_SelectionDragSession session) {
    return (session.current - session.start).distance >=
        _selectionDragStartDistance;
  }

  List<Geometry> _matchingGeometriesForRect(
    Rect selectionRect, {
    required _SelectionDragMode mode,
  }) {
    return [
      for (final geometry in state.geometries)
        if (switch (mode) {
          _SelectionDragMode.window => geometry.containedIn(selectionRect),
          _SelectionDragMode.crossing => geometry.intersects(selectionRect),
        })
          geometry,
    ];
  }

  _SelectionDragMode _resolvedRectSelectionMode(_SelectionDragSession session) {
    return session.current.dx >= session.start.dx
        ? _SelectionDragMode.window
        : _SelectionDragMode.crossing;
  }

  List<Geometry> _selectionWithMatches(
    List<Geometry> matches, {
    required List<Geometry> baselineSelection,
  }) {
    final nextSelection = [...baselineSelection];

    for (final geometry in matches) {
      if (!nextSelection.contains(geometry)) {
        nextSelection.add(geometry);
      }
    }

    return nextSelection;
  }

  void _handleSingleSelection({required List<Geometry> baselineSelection}) {
    final selected = geometryBelowCursor();
    final nextSelection = [...baselineSelection];

    if (selected case final geometry? when !nextSelection.contains(geometry)) {
      nextSelection.add(geometry);
    }

    setSelectedGeometries(nextSelection);
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
