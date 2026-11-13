import 'package:flutter/material.dart';

import '../models/draw_element.dart';

class DrawingCanvas extends StatelessWidget {
  final List<DrawElement> elements;
  final DrawElement? current;
  final ValueChanged<Offset> onStrokeStart;
  final ValueChanged<Offset> onStrokeUpdate;
  final VoidCallback onStrokeEnd;

  const DrawingCanvas({
    super.key,
    required this.elements,
    required this.current,
    required this.onStrokeStart,
    required this.onStrokeUpdate,
    required this.onStrokeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        Offset normalize(Offset p) => Offset(
              (p.dx / size.width).clamp(0.0, 1.0),
              (p.dy / size.height).clamp(0.0, 1.0),
            );

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => onStrokeStart(normalize(d.localPosition)),
            onPanUpdate: (d) => onStrokeUpdate(normalize(d.localPosition)),
            onPanEnd: (_) => onStrokeEnd(),
            onPanCancel: onStrokeEnd,
            child: CustomPaint(
              painter: _CanvasPainter(
                elements: elements,
                current: current,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawElement> elements;
  final DrawElement? current;

  static const double _cellSize = 24.0;

  _CanvasPainter({required this.elements, required this.current});

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);

    for (final e in elements) {
      _drawElement(canvas, size, e);
    }
    final cur = current;
    if (cur != null) {
      _drawElement(canvas, size, cur);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final minor = Paint()
      ..color = const Color(0xFFD9E3F0)
      ..strokeWidth = 0.6;
    final major = Paint()
      ..color = const Color(0xFFB7C7DE)
      ..strokeWidth = 1.0;

    final cols = (size.width / _cellSize).ceil();
    final rows = (size.height / _cellSize).ceil();

    for (var i = 1; i < cols; i++) {
      final x = i * _cellSize;
      final paint = i % 5 == 0 ? major : minor;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var j = 1; j < rows; j++) {
      final y = j * _cellSize;
      final paint = j % 5 == 0 ? major : minor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  Offset _denorm(Offset p, Size size) =>
      Offset(p.dx * size.width, p.dy * size.height);

  Paint _strokePaint(DrawElement e) => Paint()
    ..color = e.color
    ..strokeWidth = e.strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;

  void _drawElement(Canvas canvas, Size size, DrawElement e) {
    if (e is StrokeElement) {
      _drawStroke(canvas, size, e);
    } else if (e is LineElement) {
      canvas.drawLine(
        _denorm(e.start, size),
        _denorm(e.end, size),
        _strokePaint(e),
      );
    } else if (e is RectangleElement) {
      final rect = Rect.fromPoints(
        _denorm(e.topLeft, size),
        _denorm(e.bottomRight, size),
      );
      canvas.drawRect(rect, _strokePaint(e));
    } else if (e is CircleElement) {
      final center = _denorm(e.center, size);
      final r = e.radius * size.shortestSide;
      canvas.drawCircle(center, r, _strokePaint(e));
    }
  }

  void _drawStroke(Canvas canvas, Size size, StrokeElement e) {
    if (e.points.isEmpty) return;
    if (e.points.length == 1) {
      final p = _denorm(e.points.first, size);
      canvas.drawCircle(p, e.strokeWidth / 2, Paint()..color = e.color);
      return;
    }

    final path = Path();
    final pts = e.points.map((p) => _denorm(p, size)).toList();
    path.moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    canvas.drawPath(path, _strokePaint(e));
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) {
    return old.elements != elements || old.current != current;
  }
}