import 'package:flutter/material.dart' hide Viewport;

import '../constants/config.dart';
import '../providers/viewport_notifier_provider.dart';
import '../tools/circle_tool.dart';
import '../tools/measure_tool.dart';
import '../tools/selection_tool.dart';
import '../tools/tool.dart';
import '../tools/tools.dart';
import 'horizontal_separator.dart';
import 'layers_panel.dart';
import 'toolbar.dart';
import 'viewport.dart';

/// The main project page.
///
/// It contains the tools, viewport and toggles/actions.
class ProjectPage extends StatelessWidget {
  /// The main [ProjectPage] constructor.
  const ProjectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == .macOS;
    final valueInput = [for (var i = 0; i <= 9; i++) '$i', '.', 'm', 'M', ' '];

    return Shortcuts.manager(
      manager: _TextFieldAwareShortcutManager(
        shortcuts: {
          for (final tool in tools) tool.shortcut: _ToolIntent(tool),
          const SingleActivator(.escape): const _CancelIntent(),
          for (final input in valueInput)
            CharacterActivator(input): _ValueInputIntent(input),
          const SingleActivator(.backspace): const _ValueInputIntent(
            deleteCharacter,
          ),
          SingleActivator(.keyZ, meta: isMacOS, control: !isMacOS):
              const _UndoIntent(),
          SingleActivator(.keyZ, meta: isMacOS, control: !isMacOS, shift: true):
              const _RedoIntent(),
        },
      ),
      child: Actions(
        actions: {
          _ToolIntent: CallbackAction<_ToolIntent>(
            onInvoke: (intent) {
              final notifier = context.viewportNotifier;
              final selectedTool = notifier.value.selectedTool;
              final tool = intent.tool;
              final shortcutInputConflict =
                  notifier.acceptsValueInput && notifier.value.userInput != ''
                  ? switch (tool) {
                      CircleTool() => 'c',
                      MeasureTool() => 'm',
                      _ => null,
                    }
                  : null;

              if (shortcutInputConflict case final input?) {
                notifier.onUserInput(input);
                return null;
              }

              if (tool == selectedTool) {
                notifier.selectTool(const SelectionTool());
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
              Expanded(
                child: Row(
                  children: [
                    Expanded(child: Viewport()),
                    LayersPanel(),
                  ],
                ),
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

/// Ignores all shortcuts when a [TextField] (backed by [EditableText]) has
/// focus, so that key events flow to the platform text-input system instead.
class _TextFieldAwareShortcutManager extends ShortcutManager {
  _TextFieldAwareShortcutManager({super.shortcuts});

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    final focus = primaryFocus;
    if (focus?.context != null &&
        focus!.context!.findAncestorWidgetOfExactType<EditableText>() != null) {
      return KeyEventResult.ignored;
    }
    return super.handleKeypress(context, event);
  }
}
