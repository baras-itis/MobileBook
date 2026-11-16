import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/draw_element.dart';
import '../models/note_page.dart';

class PageProvider extends ChangeNotifier {
  static const _storageKey = 'note_pages_v2';
  static const _uuid = Uuid();

  final List<NotePage> _pages = [];
  bool _loaded = false;

  List<NotePage> get pages => List.unmodifiable(_pages);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        _pages
          ..clear()
          ..addAll(decoded.map(
            (e) => NotePage.fromJson(e as Map<String, dynamic>),
          ));
      } catch (e) {
        debugPrint('Failed to load pages: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_pages.map((p) => p.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  NotePage createPage({String title = 'Новая страница'}) {
    final now = DateTime.now();
    final page = NotePage(
      id: _uuid.v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
      canvasWidth: 360,
      canvasHeight: 560,
      pages: [
        CanvasPage(id: _uuid.v4(), elements: const []),
      ],
    );
    _pages.insert(0, page);
    notifyListeners();
    _persist();
    return page;
  }

  NotePage? findById(String id) {
    for (final p in _pages) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> deletePage(String id) async {
    _pages.removeWhere((p) => p.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> renamePage(String id, String title) async {
    final idx = _pages.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    _pages[idx] = _pages[idx].copyWith(
      title: title,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }

  Future<void> updateCanvasSize(String id, double w, double h) async {
    final idx = _pages.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final p = _pages[idx];
    if (p.canvasWidth == w && p.canvasHeight == h) return;
    _pages[idx] = p.copyWith(canvasWidth: w, canvasHeight: h);
    notifyListeners();
    await _persist();
  }

  Future<void> updateElements(
    String id,
    String canvasPageId,
    List<DrawElement> elements,
  ) async {
    final idx = _pages.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final p = _pages[idx];
    final pages = p.pages.map((cp) {
      if (cp.id == canvasPageId) {
        return cp.copyWith(elements: elements);
      }
      return cp;
    }).toList();
    _pages[idx] = p.copyWith(pages: pages, updatedAt: DateTime.now());
    notifyListeners();
    await _persist();
  }

  Future<CanvasPage> addCanvasPage(String noteId) async {
    final idx = _pages.indexWhere((p) => p.id == noteId);
    if (idx == -1) throw StateError('Note not found');
    final newPage = CanvasPage(id: _uuid.v4(), elements: const []);
    final p = _pages[idx];
    _pages[idx] = p.copyWith(
      pages: [...p.pages, newPage],
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
    return newPage;
  }

  Future<void> deleteCanvasPage(String noteId, String canvasPageId) async {
    final idx = _pages.indexWhere((p) => p.id == noteId);
    if (idx == -1) return;
    final p = _pages[idx];
    if (p.pages.length <= 1) return;
    _pages[idx] = p.copyWith(
      pages: p.pages.where((cp) => cp.id != canvasPageId).toList(),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    await _persist();
  }
}