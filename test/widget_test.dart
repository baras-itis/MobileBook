import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:notes_app/main.dart';
import 'package:notes_app/providers/page_provider.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('пустое состояние показывается при отсутствии страниц',
      (tester) async {
    await tester.pumpWidget(const NotesApp());
    await tester.pumpAndSettle();

    expect(find.text('Мои конспекты'), findsOneWidget);
    expect(find.text('Пока нет ни одной страницы'), findsOneWidget);
    expect(find.text('Создать'), findsOneWidget);
  });

  test('PageProvider создаёт и удаляет страницы', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = PageProvider();
    await provider.load();

    expect(provider.pages, isEmpty);

    final page = provider.createPage(title: 'Тест');
    expect(provider.pages.length, 1);
    expect(provider.findById(page.id)?.title, 'Тест');
    expect(provider.findById(page.id)?.pages.length, 1);

    await provider.addCanvasPage(page.id);
    expect(provider.findById(page.id)?.pages.length, 2);

    await provider.deletePage(page.id);
    expect(provider.pages, isEmpty);
  });
}