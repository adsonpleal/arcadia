import 'package:flutter/foundation.dart';

import '../geometry/geometry.dart';

/// A drawing layer that groups geometries together.
///
/// Each geometry belongs to exactly one layer.
/// Layers control visibility and provide organizational structure.
@immutable
class Layer {
  /// The default constructor for [Layer].
  const Layer({
    required this.id,
    required this.name,
    this.visible = true,
    this.geometries = const [],
  });

  /// Unique identifier for this layer.
  final String id;

  /// User-visible name.
  final String name;

  /// Whether the layer's geometries are rendered and interactive.
  final bool visible;

  /// The geometries belonging to this layer.
  final List<Geometry> geometries;

  /// Creates a copy of [Layer] with replaced values.
  Layer copyWith({
    String? name,
    bool? visible,
    List<Geometry>? geometries,
  }) {
    return Layer(
      id: id,
      name: name ?? this.name,
      visible: visible ?? this.visible,
      geometries: geometries ?? this.geometries,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Layer &&
            id == other.id &&
            name == other.name &&
            visible == other.visible &&
            listEquals(geometries, other.geometries);
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      name,
      visible,
      Object.hashAll(geometries),
    ]);
  }
}
