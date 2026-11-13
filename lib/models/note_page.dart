import 'draw_element.dart';

class NotePage {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DrawElement> elements;

  const NotePage({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.elements,
  });

  NotePage copyWith({
    String? title,
    DateTime? updatedAt,
    List<DrawElement>? elements,
  }) {
    return NotePage(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      elements: elements ?? this.elements,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  factory NotePage.fromJson(Map<String, dynamic> json) {
    return NotePage(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      elements: (json['elements'] as List)
          .map((e) => DrawElement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}