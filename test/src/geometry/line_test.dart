import 'package:arcadia/src/geometry/line.dart';
import 'package:arcadia/src/ui/viewport_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta/meta.dart';

@isTest
void _testLine(
  String description, {
  required List<Line> lines,
  required String goldenName,
  Offset panOffset = Offset.zero,
  double zoom = 1,
}) {
  testWidgets(description, (tester) async {
    await tester.pumpWidget(
      CustomPaint(
        painter: ViewportPainter(
          zoom: zoom,
          panOffset: panOffset,
          geometries: lines,
        ),
      ),
    );

    await expectLater(
      find.byType(CustomPaint),
      matchesGoldenFile('goldens/line/$goldenName.png'),
    );
  });
}

void main() {
  group('line', () {
    _testLine(
      'should render a line between two points',
      lines: const [
        Line(
          start: Offset(-50, 0),
          end: Offset(50, 0),
          color: Colors.white,
        ),
      ],
      goldenName: 'betweenPoints',
    );

    _testLine(
      'should render a line between two points with zoom',
      zoom: 2,
      lines: const [
        Line(
          start: Offset(-50, 0),
          end: Offset(50, 0),
          color: Colors.white,
        ),
      ],
      goldenName: 'betweenPointsZoom',
    );

    group('multiple lines', () {
      final lines = [
        for (var i = 0; i < 33; i++)
          switch (i % 3) {
            0 => Line(
                color: Colors.red,
                start: Offset(-50, 10 * i / 3 - 50),
                end: Offset(50, 10 * i / 3 - 50),
              ),
            1 => Line(
                color: Colors.blue,
                start: Offset(10 * (i - 1) / 3 - 50, -50),
                end: Offset(10 * (i - 1) / 3 - 50, 50),
              ),
            _ => Line(
                color: Colors.white,
                start: const Offset(-50, 50) + const Offset(5, 5) * (i - 2) / 3,
                end: const Offset(50, -50) + const Offset(5, 5) * (i - 2) / 3,
              ),
          },
      ];
      _testLine(
        'should render multiple lines with different colors',
        lines: lines,
        goldenName: 'multipleLines',
      );

      _testLine(
        'should render multiple lines with pan offset',
        panOffset: const Offset(50, 50),
        lines: lines,
        goldenName: 'multipleLinesPan',
      );

      _testLine(
        'should render multiple lines with zoom',
        zoom: 2,
        lines: lines,
        goldenName: 'multipleLinesZoom',
      );

      _testLine(
        'should render multiple lines with zoom and pan',
        zoom: 0.5,
        panOffset: const Offset(-50, 50),
        lines: lines,
        goldenName: 'multipleLinesZoomAndPan',
      );
    });
  });
}
