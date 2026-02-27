import 'package:flutter/widgets.dart';

import '../constants/arcadia_color.dart';
import 'tool.dart';

/// A tool that measures temporary polylines without committing geometry.
class MeasureTool implements Tool {
  /// The default constructor for [MeasureTool].
  const MeasureTool();

  @override
  String get name => 'Measure';

  @override
  ShortcutActivator get shortcut => const SingleActivator(.keyM);

  @override
  Widget get icon => const _MeasureToolIcon();

  @override
  ToolActionFactory get toolActionFactory => _MeasureToolAction.new;
}

class _MeasureToolAction extends ToolAction {
  @override
  void onClickUp() {}

  @override
  void onCursorPositionChange() {}
}

class _MeasureToolIcon extends StatelessWidget {
  const _MeasureToolIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ArcadiaColor.primary),
          ),
        ),
        child: Align(
          alignment: .centerLeft,
          child: SizedBox(
            width: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: ArcadiaColor.primary),
                  right: BorderSide(color: ArcadiaColor.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
