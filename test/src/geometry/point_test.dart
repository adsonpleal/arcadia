import 'package:arcadia/src/geometry/point.dart';
import 'package:arcadia/src/ui/viewport_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point', () {
    testWidgets('should render a triangular point', (tester) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            zoom: 1,
            panOffset: .zero,
            geometries: const [
              Point(position: .zero, color: Colors.red, shape: .triangle),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/triangle.png'),
      );
    });

    testWidgets('should render a square point', (tester) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            panOffset: .zero,
            zoom: 1,
            geometries: const [
              Point(position: .zero, color: Colors.red, shape: .square),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/square.png'),
      );
    });

    testWidgets('should offset a point', (tester) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            zoom: 1,
            panOffset: const Offset(10, 10),
            geometries: [
              const Point(position: .zero, color: Colors.red, shape: .square),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/panOffset.png'),
      );
    });

    testWidgets('should render points with default zoom', (tester) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            panOffset: .zero,
            zoom: 1,
            geometries: const [
              Point(
                position: Offset(0, -10),
                color: Colors.red,
                shape: .square,
              ),
              Point(
                position: Offset(0, 10),
                color: Colors.blue,
                shape: .square,
              ),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/defaultZoom.png'),
      );
    });

    testWidgets('should change points distance when there is a zoom applied', (
      tester,
    ) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            zoom: 2,
            panOffset: .zero,
            geometries: const [
              Point(
                position: Offset(0, -10),
                color: Colors.red,
                shape: .square,
              ),
              Point(
                position: Offset(0, 10),
                color: Colors.blue,
                shape: .square,
              ),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/2xZoom.png'),
      );
    });

    testWidgets('should render multiple points', (tester) async {
      await tester.pumpWidget(
        CustomPaint(
          painter: ViewportPainter(
            zoom: 1,
            panOffset: const Offset(-25, -25),
            geometries: [
              for (var i = 0; i < 25; i++)
                Point(
                  position: Offset((i % 5) * 10, (i ~/ 5) * 10),
                  color: [Colors.red, Colors.blue][i % 2],
                  shape: .values[i % 2],
                ),
            ],
          ),
        ),
      );

      await expectLater(
        find.byType(CustomPaint),
        matchesGoldenFile('goldens/point/multiple.png'),
      );
    });
  });
}
