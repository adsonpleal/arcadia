import 'dart:math';
import 'dart:ui';

const _epsilon = 1e-9;

/// Returns all edges from [points], including the closing edge.
List<(Offset, Offset)> closedEdges(List<Offset> points) {
  if (points.length < 2) {
    return const [];
  }

  final edges = <(Offset, Offset)>[];
  for (var i = 0; i < points.length - 1; i++) {
    edges.add((points[i], points[i + 1]));
  }

  if (points.first != points.last) {
    edges.add((points.last, points.first));
  }

  return edges;
}

/// Returns the four boundary edges for [rect].
List<(Offset, Offset)> rectEdges(Rect rect) {
  return [
    (rect.topLeft, rect.topRight),
    (rect.topRight, rect.bottomRight),
    (rect.bottomRight, rect.bottomLeft),
    (rect.bottomLeft, rect.topLeft),
  ];
}

/// Returns true when [point] is inside the closed [polygon] boundary.
bool isPointInsideClosedPolygon(Offset point, List<Offset> polygon) {
  if (polygon.length < 3) {
    return false;
  }

  for (final (a, b) in closedEdges(polygon)) {
    if (_isCollinear(a, b, point) && _onSegment(a, point, b)) {
      return true;
    }
  }

  var inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final first = polygon[i];
    final second = polygon[j];
    final spansY = (first.dy > point.dy) != (second.dy > point.dy);

    if (!spansY) {
      continue;
    }

    final xCross =
        (second.dx - first.dx) *
            (point.dy - first.dy) /
            (second.dy - first.dy) +
        first.dx;

    if (point.dx < xCross) {
      inside = !inside;
    }
  }

  return inside;
}

double _orientation(Offset a, Offset b, Offset c) {
  return (b.dy - a.dy) * (c.dx - b.dx) - (b.dx - a.dx) * (c.dy - b.dy);
}

bool _isCollinear(Offset a, Offset b, Offset c) {
  return _orientation(a, b, c).abs() <= _epsilon;
}

bool _onSegment(Offset a, Offset p, Offset b) {
  return p.dx <= max(a.dx, b.dx) + _epsilon &&
      p.dx + _epsilon >= min(a.dx, b.dx) &&
      p.dy <= max(a.dy, b.dy) + _epsilon &&
      p.dy + _epsilon >= min(a.dy, b.dy);
}

/// Returns true when segments [aStart]-[aEnd] and [bStart]-[bEnd] intersect.
bool segmentsIntersect(
  Offset aStart,
  Offset aEnd,
  Offset bStart,
  Offset bEnd,
) {
  final o1 = _orientation(aStart, aEnd, bStart);
  final o2 = _orientation(aStart, aEnd, bEnd);
  final o3 = _orientation(bStart, bEnd, aStart);
  final o4 = _orientation(bStart, bEnd, aEnd);

  final properIntersection =
      ((o1 > _epsilon && o2 < -_epsilon) ||
          (o1 < -_epsilon && o2 > _epsilon)) &&
      ((o3 > _epsilon && o4 < -_epsilon) || (o3 < -_epsilon && o4 > _epsilon));

  if (properIntersection) {
    return true;
  }

  if (_isCollinear(aStart, aEnd, bStart) && _onSegment(aStart, bStart, aEnd)) {
    return true;
  }
  if (_isCollinear(aStart, aEnd, bEnd) && _onSegment(aStart, bEnd, aEnd)) {
    return true;
  }
  if (_isCollinear(bStart, bEnd, aStart) && _onSegment(bStart, aStart, bEnd)) {
    return true;
  }
  if (_isCollinear(bStart, bEnd, aEnd) && _onSegment(bStart, aEnd, bEnd)) {
    return true;
  }

  return false;
}

/// Returns true when [segmentStart]-[segmentEnd] intersects [rect].
bool segmentIntersectsRect(Offset segmentStart, Offset segmentEnd, Rect rect) {
  if (rect.contains(segmentStart) || rect.contains(segmentEnd)) {
    return true;
  }

  for (final (a, b) in rectEdges(rect)) {
    if (segmentsIntersect(segmentStart, segmentEnd, a, b)) {
      return true;
    }
  }

  return false;
}

/// Returns true when [segmentStart]-[segmentEnd] intersects [closedPolygon].
bool segmentIntersectsPolygon(
  Offset segmentStart,
  Offset segmentEnd,
  List<Offset> closedPolygon,
) {
  if (closedPolygon.length < 3) {
    return false;
  }

  if (isPointInsideClosedPolygon(segmentStart, closedPolygon) ||
      isPointInsideClosedPolygon(segmentEnd, closedPolygon)) {
    return true;
  }

  for (final (a, b) in closedEdges(closedPolygon)) {
    if (segmentsIntersect(segmentStart, segmentEnd, a, b)) {
      return true;
    }
  }

  return false;
}
