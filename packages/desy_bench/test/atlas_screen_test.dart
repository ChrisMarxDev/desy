import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Atlas renders every root primitive, not only components', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Root primitives',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          tokens: [_token('root.token')],
          components: [_component('root.component')],
        ),
      ),
    );

    expect(find.text('root.token'), findsWidgets);
    expect(find.text('root.component'), findsWidgets);
  });

  testWidgets('fonts use the typed Fonts board', (tester) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Fonts',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          fonts: [
            DesyTypographyEntry(
              id: 'mixed.type',
              name: 'Mixed type',
              sample: 'Sample',
              builder: (_, text) => Text(text),
            ),
          ],
        ),
      ),
    );

    await tester.tap(
      find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.fonts.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mixed type'), findsWidgets);
  });

  testWidgets('nested component folders remain navigable in the Atlas', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Nested folder entries',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            _component('nested.action', path: '/actions'),
            _component('deep.card', path: '/content/cards'),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('sidebar-folder-/actions')));
    await tester.pumpAndSettle();

    expect(find.text('1 entries'), findsWidgets);
    expect(find.text('nested.action'), findsWidgets);
  });

  testWidgets('typography entries build only the supplied preview text', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Typography builder',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          fonts: [
            DesyTypographyEntry(
              id: 'type.body',
              name: 'Body',
              builder: (_, text) => Text(
                'Built: $text',
                key: const ValueKey('built-typography-specimen'),
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(
      find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.fonts.id}')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('built-typography-specimen')),
      findsOneWidget,
    );

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('font-preview-text')),
        matching: find.byType(EditableText),
      ),
      'Dock status',
    );
    await tester.pump();

    expect(find.text('Built: Dock status'), findsOneWidget);
  });

  testWidgets('Atlas cards expose one native tap action that opens the entry', (
    tester,
  ) async {
    const name = 'Accessible component';
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Accessible Atlas',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [_component('accessible.component', name: name)],
        ),
      ),
    );

    final card = find.semantics.byLabel('Open $name');
    expect(
      card.evaluate().single,
      matchesSemantics(isButton: true, hasTapAction: true, label: 'Open $name'),
    );

    tester.semantics.tap(card);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-search')), findsNothing);
    semantics.dispose();
  });

  testWidgets('Atlas card IDs stay on one ellipsized line on narrow screens', (
    tester,
  ) async {
    const id = 'component.with.a.deliberately.long.stable.identifier';
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Narrow Atlas',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [_component(id)],
        ),
      ),
    );

    final idText = tester.widget<Text>(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == id && widget.maxLines == 1,
      ),
    );
    expect(idText.maxLines, 1);
    expect(idText.overflow, TextOverflow.ellipsis);
  });
}

DesyToken _token(String id) => DesyToken(
  id: id,
  name: id,
  value: 'value',
  builder: (_) => const SizedBox(),
);

DesyComponent _component(String id, {String? name, String path = '/'}) =>
    DesyComponent(
      id: id,
      name: name ?? id,
      path: path,
      preview: (_) => const SizedBox(),
    );

Widget _wrap(BuildContext context, Widget child) => child;
