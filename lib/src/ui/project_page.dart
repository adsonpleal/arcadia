import 'package:flutter/material.dart' hide Viewport;
import 'package:flutter/services.dart';

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
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final numbersInput = [for (var i = 0; i <= 9; i++) '$i', '.'];

    return Shortcuts(
      shortcuts: {
        for (final tool in tools) tool.shortcut: _ToolIntent(tool),
        const SingleActivator(LogicalKeyboardKey.escape): const _CancelIntent(),
        for (final input in numbersInput)
          CharacterActivator(input): _ValueInputIntent(input),
        const SingleActivator(LogicalKeyboardKey.backspace):
            const _ValueInputIntent('back'),
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: isMacOS,
          control: !isMacOS,
        ): const _UndoIntent(),
        SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: isMacOS,
          control: !isMacOS,
          shift: true,
        ): const _RedoIntent(),
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
          _ValueInputIntent: CallbackAction<_ValueInputIntent>(
            onInvoke: (intent) {
              context.viewportNotifier.onUserInput(intent.input);
              return null;
            },
          ),
          _RedoIntent: CallbackAction<_RedoIntent>(
            onInvoke: (_) {
              context.viewportNotifier.redo();
              return null;
            },
          ),
          _UndoIntent: CallbackAction<_UndoIntent>(
            onInvoke: (_) {
              context.viewportNotifier.undo();
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
              Expanded(child: Viewport()),
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

class _ValueInputIntent extends Intent {
  const _ValueInputIntent(this.input);

  final String input;
}

class _RedoIntent extends Intent {
  const _RedoIntent();
}

class _UndoIntent extends Intent {
  const _UndoIntent();
}
