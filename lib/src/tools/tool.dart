import 'package:flutter/widgets.dart';

import '../data/viewport_state.dart';
import '../geometry/geometry.dart';
import '../logic/viewport_notifier.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// A factory that creates a tool action.
typedef ToolActionFactory = ToolAction Function();

/// The interface of a Tool.
abstract interface class Tool {
  /// The name of the tool.
  String get name;

  /// The tool icon.
  Widget get icon;

  /// The keyboard shortcut.
  ShortcutActivator get shortcut;

  /// The factory for [ToolAction].
  ToolActionFactory get toolActionFactory;
}

/// An action that is performed by a tool;
abstract class ToolAction {
  late final ViewportNotifier _viewportNotifier;

  /// The current [ViewportState].
  ViewportState get state => _viewportNotifier.value;

  /// Bind the tool to [ViewportNotifier].
  void bind(ViewportNotifier viewportNotifier) {
    _viewportNotifier = viewportNotifier;
  }

  /// Clear all tool geometries from [ViewportState].
  void clearToolGeometries() {
    _viewportNotifier.clearToolGeometries();
  }

  /// Add tool geometries to [ViewportState].
  void addToolGeometries(List<Geometry> geometries) {
    _viewportNotifier.addToolGeometries(geometries);
  }

  /// Add geometries to [ViewportState].
  void addGeometries(List<Geometry> geometries) {
    _viewportNotifier.addGeometries(geometries);
  }

  /// Triggered on cursor position change.
  void onCursorPositionChange();

  /// Triggered on cursor click.
  void onClick();
}
