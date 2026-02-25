import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/providers/viewport_notifier_provider.dart';
import 'package:arcadia/src/tools/line_tool.dart';
import 'package:arcadia/src/ui/cursor_paint.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _line = Line(start: Offset(1, 2), end: Offset(3, 4), color: .primary);

void main() {
  group('CursorPaint', () {
    testWidgets('uses hidden system cursor', (tester) async {
      await _pumpCursor(tester);

      final mouseRegion = tester.widget<MouseRegion>(find.byType(MouseRegion));
      expect(mouseRegion.cursor, SystemMouseCursors.none);
    });

    testWidgets(
      'does not rebuild when unrelated state slices change',
      (tester) async {
        var builds = 0;
        final notifier = await _pumpCursor(
          tester,
          child: _CountingCursorPaint(onBuild: () => builds++),
        );

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          geometries: const [_line],
          toolGeometries: const [_line],
          snappingGeometries: const [_line],
        );
        await tester.pump();

        expect(builds, 1);

        notifier.value = notifier.value.copyWith(
          selectedTool: const LineTool(),
          userInput: '42',
        );
        await tester.pump();

        expect(builds, 1);
      },
    );
  });
}

Future<ViewportNotifier> _pumpCursor(
  WidgetTester tester, {
  Widget child = const CursorPaint(),
}) async {
  late ViewportNotifier notifierFromContext;

  await tester.pumpWidget(
    Directionality(
      textDirection: .ltr,
      child: SizedBox(
        width: 400,
        height: 300,
        child: ViewportNotifierProvider(
          child: Builder(
            builder: (context) {
              notifierFromContext = context.viewportNotifier;
              return child;
            },
          ),
        ),
      ),
    ),
  );

  return notifierFromContext;
}

class _CountingCursorPaint extends CursorPaint {
  const _CountingCursorPaint({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return super.build(context);
  }
}
