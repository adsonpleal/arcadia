import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Viewport;

import '../providers/viewport_notifier_provider.dart';
import '../tools/tool.dart';
import '../tools/tools.dart';
import 'horizontal_separator.dart';
import 'toolbar.dart';
import 'viewport.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The main project page.
///
/// It contains the tools, viewport and toggles/actions.
class ProjectPage extends StatelessWidget {
  /// The main [ProjectPage] constructor.
  const ProjectPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: {
        for (final tool in tools) tool.shortcut: _ToolIntent(tool),
        const SingleActivator(LogicalKeyboardKey.escape): const _CancelIntent(),
      },
      child: Actions(
        actions: {
          _ToolIntent: CallbackAction<_ToolIntent>(
            onInvoke: (intent) {
              final notifier = context.viewportNotifier;
              final selectedTool = notifier.value.selectedTool;
              final tool = intent.tool;

              if (tool == selectedTool) {
                notifier.cancelToolAction();
              } else {
                notifier.selectTool(tool);
              }

              return null;
            },
          ),
          _CancelIntent: CallbackAction<_CancelIntent>(
            onInvoke: (_) {
              context.viewportNotifier.cancelToolAction();
              return null;
            },
          ),
        },
        child: const Focus(
          autofocus: true,
          child: Column(
            children: [
              HorizontalSeparator(),
              Toolbar(),
              HorizontalSeparator(),
              Expanded(
                child: Viewport(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolIntent extends Intent {
  const _ToolIntent(this.tool);

  final Tool tool;
}

class _CancelIntent extends Intent {
  const _CancelIntent();
}
