import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/draw_element.dart';
import '../models/note_page.dart';
import '../providers/page_provider.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/toolbar.dart';

class EditorScreen extends StatefulWidget {
  final String pageId;

  const EditorScreen({super.key, required this.pageId});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  static const _uuid = Uuid();

  ToolType _tool = ToolType.pen;
  Color _color = Colors.black;
  double _strokeWidth = 3.0;

  int _canvasIndex = 0;
  late List<DrawElement> _elements;
  DrawElement? _current;
  Timer? _saveDebounce;
  String? _currentCanvasPageId;

  @override
  void initState() {
    super.initState();
    final page = context.read<PageProvider>().findById(widget.pageId);
    final canvasPage = page?.pages[_canvasIndex];
    _currentCanvasPageId = canvasPage?.id;
    _elements = List.of(canvasPage?.elements ?? const <DrawElement>[]);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _flushSave();
    super.dispose();
  }

  void _flushSave() {
    final id = _currentCanvasPageId;
    if (id == null) return;
    context.read<PageProvider>().updateElements(widget.pageId, id, _elements);
  }

  void _scheduleSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), _flushSave);
  }

  void _switchToCanvas(int index) {
    _flushSave();
    _saveDebounce?.cancel();
    final page = context.read<PageProvider>().findById(widget.pageId);
    if (page == null) return;
    if (index < 0 || index >= page.pages.length) return;
    final cp = page.pages[index];
    setState(() {
      _canvasIndex = index;
      _currentCanvasPageId = cp.id;
      _elements = List.of(cp.elements);
      _current = null;
    });
  }

  Future<void> _addCanvasPage() async {
    _flushSave();
    final newPage =
        await context.read<PageProvider>().addCanvasPage(widget.pageId);
    final page = context.read<PageProvider>().findById(widget.pageId);
    if (page == null) return;
    final idx = page.pages.indexWhere((cp) => cp.id == newPage.id);
    _switchToCanvas(idx);
  }

  void _onStrokeStart(Offset p) {
    if (_tool == ToolType.eraser) {
      _eraseAt(p);
      return;
    }
    final id = _uuid.v4();
    setState(() {
      switch (_tool) {
        case ToolType.pen:
          _current = StrokeElement(
              id: id, color: _color, strokeWidth: _strokeWidth, points: [p]);
          break;
        case ToolType.line:
          _current = LineElement(
              id: id, color: _color, strokeWidth: _strokeWidth, start: p, end: p);
          break;
        case ToolType.rectangle:
          _current = RectangleElement(
              id: id,
              color: _color,
              strokeWidth: _strokeWidth,
              topLeft: p,
              bottomRight: p);
          break;
        case ToolType.circle:
          _current = CircleElement(
              id: id,
              color: _color,
              strokeWidth: _strokeWidth,
              center: p,
              radius: 0);
          break;
        case ToolType.eraser:
          break;
      }
    });
  }

  void _onStrokeUpdate(Offset p) {
    if (_tool == ToolType.eraser) {
      _eraseAt(p);
      return;
    }
    final cur = _current;
    if (cur == null) return;
    setState(() {
      if (cur is StrokeElement) {
        _current = StrokeElement(
          id: cur.id,
          color: cur.color,
          strokeWidth: cur.strokeWidth,
          points: [...cur.points, p],
        );
      } else if (cur is LineElement) {
        _current = LineElement(
          id: cur.id,
          color: cur.color,
          strokeWidth: cur.strokeWidth,
          start: cur.start,
          end: p,
        );
      } else if (cur is RectangleElement) {
        _current = RectangleElement(
          id: cur.id,
          color: cur.color,
          strokeWidth: cur.strokeWidth,
          topLeft: cur.topLeft,
          bottomRight: p,
        );
      } else if (cur is CircleElement) {
        final r = (p - cur.center).distance;
        _current = CircleElement(
          id: cur.id,
          color: cur.color,
          strokeWidth: cur.strokeWidth,
          center: cur.center,
          radius: r,
        );
      }
    });
  }

  void _onStrokeEnd() {
    if (_current == null) return;
    setState(() {
      _elements = [..._elements, _current!];
      _current = null;
    });
    _scheduleSave();
  }

  void _eraseAt(Offset p) {
    const hitThreshold = 14.0;
    final before = _elements.length;
    setState(() {
      _elements = _elements.where((e) {
        if (e is StrokeElement) {
          return !e.points.any((pt) => (pt - p).distance < hitThreshold);
        } else if (e is LineElement) {
          return !_isNearSegment(p, e.start, e.end, hitThreshold);
        } else if (e is RectangleElement) {
          return !e.rect.inflate(hitThreshold).contains(p);
        } else if (e is CircleElement) {
          final d = (p - e.center).distance;
          return (d - e.radius).abs() > hitThreshold;
        }
        return true;
      }).toList();
    });
    if (_elements.length != before) _scheduleSave();
  }

  bool _isNearSegment(Offset p, Offset a, Offset b, double threshold) {
    final ab = b - a;
    final ap = p - a;
    final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (len2 == 0) return (p - a).distance < threshold;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / len2).clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance < threshold;
  }

  void _undo() {
    if (_elements.isEmpty) return;
    setState(() {
      _elements = _elements.sublist(0, _elements.length - 1);
    });
    _scheduleSave();
  }

  void _clear() {
    if (_elements.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Очистить страницу?'),
        content: const Text('Все элементы будут удалены.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => _elements = []);
              _scheduleSave();
              Navigator.pop(ctx);
            },
            child: const Text('Очистить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = context.watch<PageProvider>().findById(widget.pageId);
    if (page == null) {
      return const Scaffold(body: Center(child: Text('Страница не найдена')));
    }
    if (_canvasIndex >= page.pages.length) {
      _canvasIndex = page.pages.length - 1;
    }
    final canvasPage = page.pages[_canvasIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          page.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: 'Отменить последнее',
            icon: const Icon(Icons.undo),
            onPressed: _elements.isEmpty ? null : _undo,
          ),
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _elements.isEmpty ? null : _clear,
          ),
        ],
      ),
      body: Column(
        children: [
          _pageSwitcher(page),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth - 16,
                    constraints.maxHeight - 16,
                  );
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<PageProvider>().updateCanvasSize(
                          widget.pageId,
                          size.width,
                          size.height,
                        );
                  });
                  return DrawingCanvas(
                    pageId: widget.pageId,
                    canvasPageId: canvasPage.id,
                    elements: _elements,
                    current: _current,
                    onStrokeStart: _onStrokeStart,
                    onStrokeUpdate: _onStrokeUpdate,
                    onStrokeEnd: _onStrokeEnd,
                  );
                },
              ),
            ),
          ),
          Toolbar(
            tool: _tool,
            color: _color,
            strokeWidth: _strokeWidth,
            onToolChanged: (t) => setState(() => _tool = t),
            onColorChanged: (c) => setState(() => _color = c),
            onStrokeWidthChanged: (w) => setState(() => _strokeWidth = w),
          ),
        ],
      ),
    );
  }

  Widget _pageSwitcher(NotePage page) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: page.pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final selected = i == _canvasIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _switchToCanvas(i),
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFEEF2FF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Стр. ${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? const Color(0xFF2F6BFF)
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Удалить страницу',
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: page.pages.length <= 1
                ? null
                : () => _deleteCanvasPage(page),
          ),
          IconButton(
            tooltip: 'Добавить страницу',
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: _addCanvasPage,
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCanvasPage(NotePage page) async {
    _flushSave();
    final cp = page.pages[_canvasIndex];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить страницу?'),
        content: Text('Страница ${_canvasIndex + 1} будет удалена.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await context.read<PageProvider>().deleteCanvasPage(widget.pageId, cp.id);
    if (_canvasIndex >= page.pages.length - 1) {
      _canvasIndex = page.pages.length - 2;
    }
    final updated = context.read<PageProvider>().findById(widget.pageId);
    if (updated == null) return;
    final newCp = updated.pages[_canvasIndex];
    setState(() {
      _currentCanvasPageId = newCp.id;
      _elements = List.of(newCp.elements);
      _current = null;
    });
  }
}