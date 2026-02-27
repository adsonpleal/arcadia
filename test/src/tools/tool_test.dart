import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/logic/viewport_notifier.dart';
import 'package:arcadia/src/tools/tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ToolAction', () {
    test('defaults acceptValueInput to false', () {
      final action = _NoopToolAction();

      expect(action.acceptValueInput, isFalse);
    });

    test('delegates state mutation helpers to ViewportNotifier', () {
      final notifier = ViewportNotifier();
      final action = _NoopToolAction()..bind(notifier);
      const geometry = Line(start: .zero, end: Offset(10, 0), color: .primary);

      notifier.value = notifier.value.copyWith(userInput: '42');

      action
        ..addGeometries(const [geometry])
        ..addToolGeometries(const [geometry])
        ..clearToolGeometries()
        ..clearUserInput()
        ..addSnapPoint(const Offset(5, 5))
        ..setSelectionPropertiesLabel('Length: 10.0 mm')
        ..setMeasureLabel('Perimeter: 10.0 mm')
        ..clearSelectionPropertiesLabel()
        ..clearMeasureLabel();

      expect(action.state.geometries, const [geometry]);
      expect(action.state.toolGeometries, isEmpty);
      expect(action.state.selectionPropertiesLabel, isNull);
      expect(action.state.measureLabel, isNull);
      expect(action.state.userInput, isEmpty);
    });

    test('default onValueTyped is a no-op', () {
      final action = _NoopToolAction();

      expect(() => action.onValueTyped(10), returnsNormally);
      expect(() => action.onValueTyped(null), returnsNormally);
    });

    test('default onSelectedUnitChange is a no-op', () {
      final action = _NoopToolAction();

      expect(() => action.onSelectedUnitChange(), returnsNormally);
    });
  });
}

class _NoopToolAction extends ToolAction {
  @override
  void onClickUp() {}

  @override
  void onCursorPositionChange() {}
}
