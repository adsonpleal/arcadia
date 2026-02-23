import 'package:flutter/material.dart';

import '../constants/arcadia_colors.dart';
import '../providers/viewport_notifier_provider.dart';
import '../tools/tool.dart';
import '../tools/tools.dart';

// TODO: Add tests.
// this file depends on both flutter and macro stuff, so we can't test
// it for now.

/// The toolbar with all the available tools.
class Toolbar extends StatelessWidget {
  /// The default constructor for [Toolbar].
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: ArcadiaColors.componentBackground,
      alignment: Alignment.centerLeft,
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: tools.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tool = tools[index];

          return _ToolButton(tool: tool);
        },
      ),
    );
  }
}

class _ToolButton extends StatefulWidget {
  const _ToolButton({required this.tool});

  final Tool tool;

  @override
  State<_ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<_ToolButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    final toolName = widget.tool.name;
    final triggers = widget.tool.shortcut.triggers;
    // TODO handle shift, meta, alt and control.
    final shortcut = triggers?.map((key) => key.keyLabel).join('+');
    final tooltipMessage = '$toolName - $shortcut';

    return Tooltip(
      message: tooltipMessage,
      preferBelow: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovering = true),
        onExit: (_) => setState(() => hovering = false),
        child: ViewportStateBuilder(
          select: (state) => state.selectedTool == widget.tool,
          builder: (context, selected) => GestureDetector(
            onTap: () {
              if (selected) {
                context.viewportNotifier.cancelToolAction();
              } else {
                context.viewportNotifier.selectTool(widget.tool);
              }
            },
            child: Container(
              width: 24,
              height: 24,
              decoration: ShapeDecoration(
                color: selected
                    ? ArcadiaColors.selected
                    : hovering
                    ? ArcadiaColors.hover
                    : null,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  side: BorderSide(color: ArcadiaColors.geometry),
                ),
              ),
              child: Center(child: widget.tool.icon),
            ),
          ),
        ),
      ),
    );
  }
}
