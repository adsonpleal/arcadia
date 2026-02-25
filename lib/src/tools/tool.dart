import 'package:flutter/widgets.dart';

import '../data/viewport_state.dart';
import '../geometry/geometry.dart';
import '../logic/viewport_notifier.dart';

/// A factory that creates a tool action.
typedef ToolActionFactory = ToolAction Function();

@immutable
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

  /// Whether or not this action accepts a value input.
  final acceptValueInput = false;

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

  /// Delete geometries from [ViewportState].
  void deleteGeometries(List<Geometry> geometries) {
    _viewportNotifier.deleteGeometries(geometries);
  }

  /// Add geometries to [ViewportState].
  void addGeometries(List<Geometry> geometries) {
    _viewportNotifier.addGeometries(geometries);
  }

  /// Clear the current user input.
  void clearUserInput() {
    _viewportNotifier.clearUserInput();
  }

  /// Add a snap point to the list.
  void addSnapPoint(Offset offset) {
    _viewportNotifier.addSnapPoint(offset);
  }

  /// Triggered on cursor position change.
  void onCursorPositionChange();

  /// Triggered on cursor click down.
  ///
  /// This has a body just for convenience, there is no implementation in
  /// the [ToolAction] class.
  void onClickDown() {}

  /// Triggered on cursor click up.
  void onClickUp();

  /// Triggered when a pointer interaction is canceled.
  ///
  /// This has a body just for convenience, there is no implementation in
  /// the [ToolAction] class.
  void onCancel() {}

  /// Triggered whenever the user types a value.
  ///
  /// You don't need to call super for this override.
  /// This has a body just for convenience, there is no implementation in
  /// the [Tool] class.
  /// Receiving null means the user canceled the value.
  /// If you want to use this you must override [acceptValueInput] setting
  /// it to true.
  void onValueTyped(double? value) {}

  /// Triggered when the user presses the delete key.
  ///
  /// You don't need to call super for this override.
  /// This has a body just for convenience, there is no implementation in
  /// the [Tool] class.
  ///
  /// This is called when the user presses the delete key and the tool does
  /// not accept value input.
  void onDelete() {}
}
