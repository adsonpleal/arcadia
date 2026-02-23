import 'package:arcadia/src/geometry/arc.dart';
import 'package:arcadia/src/geometry/geometry.dart';
import 'package:arcadia/src/geometry/point.dart';
import 'package:arcadia/src/ui/viewport_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

@isTest
void _testArc(
  String description, {
  required List<Geometry> geometries,
  required String goldenName,
  Offset panOffset = .zero,
  double zoom = 1,
}) {
  testWidgets(description, (tester) async {
    await tester.pumpWidget(
      CustomPaint(
        painter: ViewportPainter(
          zoom: zoom,
          panOffset: panOffset,
          geometries: geometries,
        ),
      ),
    );

    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('goldens/arc/$goldenName.png'),
    );
  });
}

void main() {
  group('Arc', () {
    final points = [
      const Point(
        color: .snappingLine,
        shape: .square,
        position: Offset(14, 14),
      ),
      const Point(
        color: .snappingLine,
        shape: .square,
        position: Offset(-20, 20),
      ),
      const Point(
        color: .snappingLine,
        shape: .square,
        position: Offset(-40, 40),
      ),
    ];

    final arc = Arc.fromPoints(
      first: points[0].position,
      second: points[1].position,
      third: points[2].position,
      color: .snappingPoint,
    );

    _testArc(
      'should render arc given three points',
      geometries: [...points, arc],
      goldenName: 'threePoints',
    );

    _testArc(
      'should generate snaps in the arc edges and center',
      geometries: [arc, ...arc.snappingPoints],
      goldenName: 'snap',
    );

    _testArc(
      'should render arc with zoom',
      geometries: [...points, arc],
      zoom: 2,
      goldenName: 'zoom',
    );

    _testArc(
      'should render arc with pan',
      geometries: [...points, arc],
      panOffset: const Offset(50, 50),
      goldenName: 'pan',
    );

    _testArc(
      'should render arc with pan and zoom',
      geometries: [...points, arc],
      zoom: 0.5,
      panOffset: const Offset(25, 90),
      goldenName: 'panZoom',
    );
  });
}
