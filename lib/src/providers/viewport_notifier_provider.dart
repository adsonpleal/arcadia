import 'package:flutter/widgets.dart';

import '../data/viewport_state.dart';
import '../logic/viewport_notifier.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The provider for [ViewportNotifier]
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
    return _ViewportInheritedNotifier(notifier: notifier, child: widget.child);
  }
}

class _ViewportInheritedNotifier extends InheritedNotifier<ViewportNotifier> {
  const _ViewportInheritedNotifier({
    required super.child,
    required super.notifier,
  });
}

/// ViewportNotifier extension on BuildContext
extension ViewportNotifierBuildContextExtension on BuildContext {
  /// Gets the [ViewportNotifier] from the widget tree.
  ///
  /// This will NOT create a dependency, so you should not use this to
  /// get the state. Use it only to perform actions.
  /// If you want to depend on the state itself, use [ViewportStateBuilder].
  ViewportNotifier get viewportNotifier {
    return getInheritedWidgetOfExactType<_ViewportInheritedNotifier>()!
        .notifier!;
  }
}

/// A builder that listens to [ViewportNotifier.value] changes and map it's
/// value.
///
/// The [builder] function will only be called when the value mapped by
/// [select] changes. This improves the performance by avoiding unnecessary
/// rebuilds.
class ViewportStateBuilder<T> extends StatefulWidget {
  /// The default constructor for [ViewportStateBuilder].
  const ViewportStateBuilder({
    required this.select,
    required this.builder,
    super.key,
  });

  /// The function that maps the state.
  final T Function(ViewportState state) select;

  /// The builder function that will be called whenever the mapped,
  /// state changes.
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<ViewportStateBuilder<T>> createState() =>
      _ViewportStateBuilderState<T>();
}

class _ViewportStateBuilderState<T> extends State<ViewportStateBuilder<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    final notifier = context.viewportNotifier;
    // set the initial value
    value = widget.select(notifier.value);
    notifier.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    context.viewportNotifier.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, value);
  }

  void _onStateChanged() {
    final newValue = widget.select(context.viewportNotifier.value);
    // only rebuild the widget if the value changes.
    if (newValue != value) {
      setState(() {
        value = newValue;
      });
    }
  }
}
