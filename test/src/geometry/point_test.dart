import 'package:arcadia/src/geometry/geometry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Point', () {
    testWidgets('should render a triangular point', (tester) async {
      await tester.pumpWidget(
        const _PointsViewport(
          points: [
            Point(
              position: Offset.zero,
              color: Colors.red,
              shape: PointShape.triangle,
            ),
          ],
        ),
      );

      await expectLater(
        find.byType(_PointsViewport),
        matchesGoldenFile('goldens/triangle.png'),
      );
    });

    testWidgets('should render a square point', (tester) async {
      await tester.pumpWidget(
        const _PointsViewport(
          points: [
            Point(
              position: Offset.zero,
              color: Colors.red,
              shape: PointShape.square,
            ),
          ],
        ),
      );

      await expectLater(
        find.byType(_PointsViewport),
        matchesGoldenFile('goldens/square.png'),
      );
    });

    testWidgets('should offset a point', (tester) async {
      await tester.pumpWidget(
        const _PointsViewport(
          panOffset: Offset(10, 10),
          points: [
            Point(
              position: Offset.zero,
              color: Colors.red,
              shape: PointShape.square,
            ),
          ],
        ),
      );

      await expectLater(
        find.byType(_PointsViewport),
        matchesGoldenFile('goldens/panOffset.png'),
      );
    });

    testWidgets('should render points with default zoom', (tester) async {
      await tester.pumpWidget(
        const _PointsViewport(
          points: [
            Point(
              position: Offset(0, -10),
              color: Colors.red,
              shape: PointShape.square,
            ),
            Point(
              position: Offset(0, 10),
              color: Colors.blue,
              shape: PointShape.square,
            ),
          ],
        ),
      );

      await expectLater(
        find.byType(_PointsViewport),
        matchesGoldenFile('goldens/defaultZoom.png'),
      );
    });

    testWidgets(
      'should change points distance when there is a zoom applied',
      (tester) async {
        await tester.pumpWidget(
          const _PointsViewport(
            zoom: 2,
            points: [
              Point(
                position: Offset(0, -10),
                color: Colors.red,
                shape: PointShape.square,
              ),
              Point(
                position: Offset(0, 10),
                color: Colors.blue,
                shape: PointShape.square,
              ),
            ],
          ),
        );

        await expectLater(
          find.byType(_PointsViewport),
          matchesGoldenFile('goldens/2xZoom.png'),
        );
      },
    );

    testWidgets('should render multiple points', (tester) async {
      await tester.pumpWidget(
        _PointsViewport(
          panOffset: const Offset(-25, -25),
          points: [
            for (var i = 0; i < 25; i++)
              Point(
                position: Offset((i % 5) * 10, (i ~/ 5) * 10),
                color: [Colors.red, Colors.blue][i % 2],
                shape: PointShape.values[i % 2],
              ),
          ],
        ),
      );

      await expectLater(
        find.byType(_PointsViewport),
        matchesGoldenFile('goldens/multiple.png'),
      );
    });
  });
}

class _PointsViewport extends StatelessWidget {
  const _PointsViewport({
    required this.points,
    this.zoom = 1.0,
    this.panOffset = Offset.zero,
  });

  final List<Point> points;
  final double zoom;
  final Offset panOffset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TestPointPainter(
        points: points,
        zoom: zoom,
        panOffset: panOffset,
      ),
    );
  }
}

class _TestPointPainter extends CustomPainter {
  _TestPointPainter({
    required this.points,
    required this.zoom,
    required this.panOffset,
  });

  final List<Point> points;
  final double zoom;
  final Offset panOffset;

  @override
  void paint(Canvas canvas, Size size) {
    for (final point in points) {
      point.render(
        canvas,
        panOffset + Offset(size.width, size.height) / 2,
        zoom,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
