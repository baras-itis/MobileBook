import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/draw_element.dart';
import '../models/note_page.dart';

class PdfExport {
  static const double _pageWidth = 595;
  static const double _pageHeight = 842;
  static const double _margin = 24;
  static const double _cellSize = 24;

  static Future<void> exportPage(NotePage page) async {
    final bytes = await buildPdf(page);
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFilename(page.title)}.pdf',
    );
  }

  static Future<Uint8List> buildPdf(NotePage page) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(_margin),
        build: (ctx) {
          const contentWidth = _pageWidth - _margin * 2;
          const contentHeight = _pageHeight - _margin * 2;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                page.title,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                width: contentWidth,
                height: contentHeight - 30,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                ),
                child: pw.Stack(
                  children: [
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        size: PdfPoint(contentWidth, contentHeight),
                        painter: (canvas, size) {
                          _paintGrid(canvas, size);
                          for (final e in page.elements) {
                            _paintElement(canvas, size, e);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static void _paintGrid(PdfGraphics canvas, PdfPoint size) {
    final minor = PdfColor.fromInt(0xFFD9E3F0);
    final major = PdfColor.fromInt(0xFFB7C7DE);

    final cols = (size.x / _cellSize).ceil();
    final rows = (size.y / _cellSize).ceil();

    for (var i = 1; i < cols; i++) {
      final x = i * _cellSize;
      canvas
        ..setStrokeColor(i % 5 == 0 ? major : minor)
        ..setLineWidth(i % 5 == 0 ? 0.6 : 0.3)
        ..moveTo(x, 0)
        ..lineTo(x, size.y)
        ..strokePath();
    }

    for (var j = 1; j < rows; j++) {
      final y = j * _cellSize;
      canvas
        ..setStrokeColor(j % 5 == 0 ? major : minor)
        ..setLineWidth(j % 5 == 0 ? 0.6 : 0.3)
        ..moveTo(0, y)
        ..lineTo(size.x, y)
        ..strokePath();
    }
  }

  static void _paintElement(PdfGraphics canvas, PdfPoint size, DrawElement e) {
    final color = PdfColor.fromInt(e.color.toARGB32());
    canvas
      ..setStrokeColor(color)
      ..setLineWidth(e.strokeWidth)
      ..setLineCap(PdfLineCap.round)
      ..setLineJoin(PdfLineJoin.round);

    PdfPoint d(Offset p) => PdfPoint(p.dx * size.x, (1 - p.dy) * size.y);

    if (e is LineElement) {
      final a = d(e.start);
      final b = d(e.end);
      canvas
        ..moveTo(a.x, a.y)
        ..lineTo(b.x, b.y)
        ..strokePath();
    } else if (e is RectangleElement) {
      final a = d(e.topLeft);
      final b = d(e.bottomRight);
      final left = a.x < b.x ? a.x : b.x;
      final right = a.x < b.x ? b.x : a.x;
      final bottom = a.y < b.y ? a.y : b.y;
      final top = a.y < b.y ? b.y : a.y;
      canvas
        ..drawRect(left, bottom, right - left, top - bottom)
        ..strokePath();
    } else if (e is CircleElement) {
      final c = d(e.center);
      final r = e.radius * size.x;
      canvas
        ..drawEllipse(c.x, c.y, r, r)
        ..strokePath();
    } else if (e is StrokeElement) {
      if (e.points.isEmpty) return;
      final pts = e.points.map(d).toList();
      if (pts.length == 1) {
        canvas
          ..setFillColor(color)
          ..drawEllipse(
            pts.first.x,
            pts.first.y,
            e.strokeWidth / 2,
            e.strokeWidth / 2,
          )
          ..fillPath();
        return;
      }
      canvas.moveTo(pts.first.x, pts.first.y);
      for (var i = 1; i < pts.length; i++) {
        canvas.lineTo(pts[i].x, pts[i].y);
      }
      canvas.strokePath();
    }
  }

  static String _safeFilename(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return cleaned.isEmpty ? 'note' : cleaned;
  }
}