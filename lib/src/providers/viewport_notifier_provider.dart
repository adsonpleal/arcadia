import 'package:flutter/widgets.dart';

import '../data/viewport_state.dart';
import '../logic/viewport_notifier.dart';

/// Selects a value from [ViewportState].
typedef ViewportStateSelector<T> = T Function(ViewportState state);

/// The provider for [ViewportNotifier].
class ViewportNotifierProvider extends StatefulWidget {
  /// The default constructor for [ViewportNotifierProvider].
  const ViewportNotifierProvider({required this.child, super.key});

  /// The child widget, the [ViewportNotifierProvider] has no UI, so the [child]
  /// will be rendered without changes.
  final Widget child;

  @override
  State<ViewportNotifierProvider> createState() {
    return _ViewportNotifierProviderState();
  }
}

class _ViewportNotifierProviderState extends State<ViewportNotifierProvider> {
  final notifier = ViewportNotifier();

  @override
  void dispose() {
    notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ViewportInheritedNotifier(
      notifier: notifier,
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, state, child) {
          return _ViewportStateInheritedModel(state: state, child: child!);
        },
        child: widget.child,
      ),
    );
  }
}

/// Inherited wrapper that exposes [ViewportNotifier] to descendants.
///
/// This widget is part of the production provider tree and is also marked
/// `@visibleForTesting` so tests can inject a custom notifier.
@visibleForTesting
class ViewportInheritedNotifier extends InheritedWidget {
  /// Creates a [ViewportInheritedNotifier] with a [ViewportNotifier].
  const ViewportInheritedNotifier({
    required super.child,
    required this.notifier,
    super.key,
  });

  /// The notifier exposed to descendants for actions.
  final ViewportNotifier notifier;

  @override
  bool updateShouldNotify(covariant ViewportInheritedNotifier oldWidget) {
    return oldWidget.notifier != notifier;
  }
}

class _ViewportStateInheritedModel
    extends InheritedModel<ViewportStateSelector<Object?>> {
  const _ViewportStateInheritedModel({
    required this.state,
    required super.child,
  });

  /// The current viewport state snapshot.
  final ViewportState state;

  @override
  bool updateShouldNotifyDependent(
    covariant _ViewportStateInheritedModel oldWidget,
    Set<ViewportStateSelector<Object?>> dependencies,
  ) {
    return dependencies.any(
      (dependency) => dependency(state) != dependency(oldWidget.state),
    );
  }

  @override
  bool updateShouldNotify(covariant _ViewportStateInheritedModel oldWidget) {
    return oldWidget.state != state;
  }
}

/// Viewport provider accessors on [BuildContext].
extension ViewportNotifierBuildContextExtension on BuildContext {
  /// Gets the [ViewportNotifier] from the widget tree.
  ///
  /// This will NOT create a dependency, so you should not use this to
  /// get the state. Use it only to perform actions.
  /// If you want to depend on the state itself, use [selectViewportState].
  ViewportNotifier get viewportNotifier {
    return getInheritedWidgetOfExactType<ViewportInheritedNotifier>()!.notifier;
  }

  /// Creates a state dependency based on the [selector] mapped value.
  ///
  /// The widget will rebuild only when the selected projection changes.
  T selectViewportState<T>(ViewportStateSelector<T> selector) {
    return selector(
      dependOnInheritedWidgetOfExactType<_ViewportStateInheritedModel>(
        aspect: selector,
      )!.state,
    );
  }
}
