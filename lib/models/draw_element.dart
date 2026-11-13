import 'dart:ui';

enum ToolType { pen, line, rectangle, circle, eraser }

sealed class DrawElement {
  final String id;
  final Color color;
  final double strokeWidth;

  const DrawElement({
    required this.id,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toJson();

  static DrawElement fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'stroke':
        return StrokeElement.fromJson(json);
      case 'line':
        return LineElement.fromJson(json);
      case 'rectangle':
        return RectangleElement.fromJson(json);
      case 'circle':
        return CircleElement.fromJson(json);
      default:
        throw ArgumentError('Unknown element type: $type');
    }
  }
}

class StrokeElement extends DrawElement {
  final List<Offset> points;

  const StrokeElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required this.points,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'stroke',
        'id': id,
        'color': color.value,
        'strokeWidth': strokeWidth,
        'points': points.map((p) => [p.dx, p.dy]).toList(),
      };

  factory StrokeElement.fromJson(Map<String, dynamic> json) {
    final rawPoints = (json['points'] as List)
        .map((p) => Offset((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList();
    return StrokeElement(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      points: rawPoints,
    );
  }
}

class LineElement extends DrawElement {
  final Offset start;
  final Offset end;

  const LineElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required this.start,
    required this.end,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'line',
        'id': id,
        'color': color.value,
        'strokeWidth': strokeWidth,
        'start': [start.dx, start.dy],
        'end': [end.dx, end.dy],
      };

  factory LineElement.fromJson(Map<String, dynamic> json) {
    final s = json['start'] as List;
    final e = json['end'] as List;
    return LineElement(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      start: Offset((s[0] as num).toDouble(), (s[1] as num).toDouble()),
      end: Offset((e[0] as num).toDouble(), (e[1] as num).toDouble()),
    );
  }
}

class RectangleElement extends DrawElement {
  final Offset topLeft;
  final Offset bottomRight;

  const RectangleElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required this.topLeft,
    required this.bottomRight,
  });

  Rect get rect => Rect.fromPoints(topLeft, bottomRight);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'rectangle',
        'id': id,
        'color': color.value,
        'strokeWidth': strokeWidth,
        'topLeft': [topLeft.dx, topLeft.dy],
        'bottomRight': [bottomRight.dx, bottomRight.dy],
      };

  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    final tl = json['topLeft'] as List;
    final br = json['bottomRight'] as List;
    return RectangleElement(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      topLeft: Offset((tl[0] as num).toDouble(), (tl[1] as num).toDouble()),
      bottomRight: Offset((br[0] as num).toDouble(), (br[1] as num).toDouble()),
    );
  }
}

class CircleElement extends DrawElement {
  final Offset center;
  final double radius;

  const CircleElement({
    required super.id,
    required super.color,
    required super.strokeWidth,
    required this.center,
    required this.radius,
  });

  @override
  Map<String, dynamic> toJson() => {
        'type': 'circle',
        'id': id,
        'color': color.value,
        'strokeWidth': strokeWidth,
        'center': [center.dx, center.dy],
        'radius': radius,
      };

  factory CircleElement.fromJson(Map<String, dynamic> json) {
    final c = json['center'] as List;
    return CircleElement(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
      center: Offset((c[0] as num).toDouble(), (c[1] as num).toDouble()),
      radius: (json['radius'] as num).toDouble(),
    );
  }
}