import 'package:flutter/material.dart';

import '../constants/arcadia_color.dart';
import '../data/metric_unit.dart';
import '../providers/viewport_notifier_provider.dart';
import '../tools/selection_tool.dart';
import '../tools/tool.dart';
import '../tools/tools.dart';

/// The toolbar with all the available tools.
class Toolbar extends StatelessWidget {
  /// The default constructor for [Toolbar].
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: ArcadiaColor.surface,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(8),
              scrollDirection: .horizontal,
              shrinkWrap: true,
              itemCount: tools.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tool = tools[index];

                return _ToolButton(tool: tool);
              },
            ),
          ),
          const SizedBox(width: 8),
          const _ProjectUnitsControl(),
          const SizedBox(width: 8),
        ],
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
    final selected = context.selectViewportState(
      (state) => state.selectedTool == widget.tool,
    );

    return Tooltip(
      message: tooltipMessage,
      preferBelow: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => hovering = true),
        onExit: (_) => setState(() => hovering = false),
        child: GestureDetector(
          onTap: () {
            if (selected) {
              context.viewportNotifier.selectTool(const SelectionTool());
            } else {
              context.viewportNotifier.selectTool(widget.tool);
            }
          },
          child: Container(
            width: 24,
            height: 24,
            decoration: ShapeDecoration(
              color: selected
                  ? ArcadiaColor.active
                  : hovering
                  ? ArcadiaColor.hover
                  : null,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                side: BorderSide(color: ArcadiaColor.primary),
              ),
            ),
            child: Center(child: widget.tool.icon),
          ),
        ),
      ),
    );
  }
}

class _ProjectUnitsControl extends StatelessWidget {
  const _ProjectUnitsControl();

  @override
  Widget build(BuildContext context) {
    final selectedUnit = context.selectViewportState((state) {
      return state.selectedUnit;
    });

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: ArcadiaColor.border),
        ),
      ),
      child: Row(
        children: [
          for (final unit in MetricUnit.values) ...[
            _UnitButton(
              unit: unit,
              selected: selectedUnit == unit,
            ),
            if (unit != MetricUnit.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _UnitButton extends StatefulWidget {
  const _UnitButton({
    required this.unit,
    required this.selected,
  });

  final MetricUnit unit;
  final bool selected;

  @override
  State<_UnitButton> createState() => _UnitButtonState();
}

class _UnitButtonState extends State<_UnitButton> {
  bool hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovering = true),
      onExit: (_) => setState(() => hovering = false),
      child: GestureDetector(
        onTap: () {
          context.viewportNotifier.setSelectedUnit(widget.unit);
        },
        child: Container(
          width: 28,
          height: 24,
          alignment: .center,
          decoration: ShapeDecoration(
            color: widget.selected
                ? ArcadiaColor.active
                : hovering
                ? ArcadiaColor.hover
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(widget.unit.symbol),
        ),
      ),
    );
  }
}
