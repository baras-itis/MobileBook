import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/draw_element.dart';
import '../models/note_page.dart';

import 'pdf_download_web.dart'
    if (dart.library.io) 'pdf_download_stub.dart'
    if (dart.library.html) 'pdf_download_web.dart';

class PdfExport {
  static Future<void> exportPage(NotePage page) async {
    final bytes = await buildPdf(page);
    final filename = '${_safeFilename(page.title)}.pdf';

    if (kIsWeb) {
      downloadPdfOnWeb(bytes, filename);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: filename);
    }
  }

  static Future<Uint8List> buildPdf(NotePage page) async {
    final doc = pw.Document();
    const cellSize = 24.0;

    for (var i = 0; i < page.pages.length; i++) {
      final canvasPage = page.pages[i];
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (ctx) {
            final aspect = page.canvasWidth / page.canvasHeight;
            const availableWidth = 595.0 - 48;
            const availableHeight = 842.0 - 48;
            const headerHeight = 30.0;
            final maxH = availableHeight - headerHeight;
            double w = availableWidth;
            double h = w / aspect;
            if (h > maxH) {
              h = maxH;
              w = h * aspect;
            }

            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Page ${i + 1}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  width: w,
                  height: h,
                  decoration: pw.BoxDecoration(
                    border:
                        pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.CustomPaint(
                    size: PdfPoint(w, h),
                    painter: (canvas, size) {
                      _paintGrid(canvas, size, cellSize);
                      for (final e in canvasPage.elements) {
                        _paintElement(canvas, size, e);
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return doc.save();
  }

  static void _paintGrid(PdfGraphics canvas, PdfPoint size, double cellSize) {
    final minor = PdfColor.fromInt(0xFFD9E3F0);
    final major = PdfColor.fromInt(0xFFB7C7DE);

    final cols = (size.x / cellSize).ceil();
    final rows = (size.y / cellSize).ceil();

    for (var i = 1; i < cols; i++) {
      final x = i * cellSize;
      canvas
        ..setStrokeColor(i % 5 == 0 ? major : minor)
        ..setLineWidth(i % 5 == 0 ? 0.6 : 0.3)
        ..moveTo(x, 0)
        ..lineTo(x, size.y)
        ..strokePath();
    }
    for (var j = 1; j < rows; j++) {
      final y = j * cellSize;
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
              pts.first.x, pts.first.y, e.strokeWidth / 2, e.strokeWidth / 2)
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