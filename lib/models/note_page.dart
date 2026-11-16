import 'draw_element.dart';

class CanvasPage {
  final String id;
  final List<DrawElement> elements;

  const CanvasPage({
    required this.id,
    required this.elements,
  });

  CanvasPage copyWith({List<DrawElement>? elements}) {
    return CanvasPage(
      id: id,
      elements: elements ?? this.elements,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory CanvasPage.fromJson(Map<String, dynamic> json) {
    return CanvasPage(
      id: json['id'] as String,
      elements: (json['elements'] as List)
          .map((e) => DrawElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class NotePage {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double canvasWidth;
  final double canvasHeight;
  final List<CanvasPage> pages;

  const NotePage({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.pages,
  });

  NotePage copyWith({
    String? title,
    DateTime? updatedAt,
    double? canvasWidth,
    double? canvasHeight,
    List<CanvasPage>? pages,
  }) {
    return NotePage(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      canvasWidth: canvasWidth ?? this.canvasWidth,
      canvasHeight: canvasHeight ?? this.canvasHeight,
      pages: pages ?? this.pages,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'canvasWidth': canvasWidth,
        'canvasHeight': canvasHeight,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory NotePage.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List?;
    final pages = rawPages != null
        ? rawPages
            .map((p) => CanvasPage.fromJson(p as Map<String, dynamic>))
            .toList()
        : <CanvasPage>[];
    return NotePage(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      canvasWidth: (json['canvasWidth'] as num?)?.toDouble() ?? 360,
      canvasHeight: (json['canvasHeight'] as num?)?.toDouble() ?? 560,
      pages: pages,
    );
  }
}