import 'dart:ui';

/// Builds a closed polyline approximation for a smooth quadratic lasso.
List<Offset> buildClosedQuadraticLassoPolyline(
  List<Offset> samples, {
  int stepsPerCurve = 6,
}) {
  if (samples.length < 2) {
    return const [];
  }

  final deduped = <Offset>[samples.first];
  for (final point in samples.skip(1)) {
    if ((point - deduped.last).distance > 0) {
      deduped.add(point);
    }
  }

  if (deduped.length < 2) {
    return const [];
  }

  if (deduped.length == 2) {
    return [deduped.first, deduped.last, deduped.first];
  }

  final count = deduped.length;
  final polyline = <Offset>[];

  for (var i = 0; i < count; i++) {
    final previous = deduped[(i - 1 + count) % count];
    final current = deduped[i];
    final next = deduped[(i + 1) % count];
    final start = (previous + current) / 2;
    final end = (current + next) / 2;

    for (var step = 0; step <= stepsPerCurve; step++) {
      if (i > 0 && step == 0) {
        continue;
      }

      final t = step / stepsPerCurve;
      final inverseT = 1 - t;
      final point =
          start * (inverseT * inverseT) +
          current * (2 * inverseT * t) +
          end * (t * t);
      polyline.add(point);
    }
  }

  if (polyline.isNotEmpty && polyline.first != polyline.last) {
    polyline.add(polyline.first);
  }

  return polyline;
}
