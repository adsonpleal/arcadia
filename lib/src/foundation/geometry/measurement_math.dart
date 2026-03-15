import 'dart:ui';

/// Returns the accumulated distance of each segment in [points].
double polylineLength(List<Offset> points) {
  if (points.length < 2) {
    return 0;
  }

  var length = 0.0;
  for (var i = 1; i < points.length; i++) {
    length += (points[i] - points[i - 1]).distance;
  }

  return length;
}

/// Returns the perimeter of a closed polyline described by [points].
double closedPolylinePerimeter(List<Offset> points) {
  if (points.length < 2) {
    return 0;
  }

  final openLength = polylineLength(points);
  if (points.first == points.last) {
    return openLength;
  }

  return openLength + (points.first - points.last).distance;
}

/// Returns the absolute polygon area defined by [points].
double polygonArea(List<Offset> points) {
  if (points.length < 3) {
    return 0;
  }

  var sum = 0.0;
  for (var i = 0; i < points.length; i++) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    sum += current.dx * next.dy - next.dx * current.dy;
  }

  return sum.abs() / 2;
}
