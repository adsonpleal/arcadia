import 'dart:math';
import 'dart:ui';

const _epsilon = 1e-9;

/// Returns the four boundary edges for [rect].
List<(Offset, Offset)> rectEdges(Rect rect) {
  return [
    (rect.topLeft, rect.topRight),
    (rect.topRight, rect.bottomRight),
    (rect.bottomRight, rect.bottomLeft),
    (rect.bottomLeft, rect.topLeft),
  ];
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
