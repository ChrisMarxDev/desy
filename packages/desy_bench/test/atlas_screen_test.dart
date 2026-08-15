import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart' show SelectableText;
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

  testWidgets('Atlas grid reaches the bottom of the content viewport', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Viewport edge',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [_component('viewport.component')],
        ),
      ),
    );

    final contentPadding = tester.widget<Padding>(
      find.byKey(const ValueKey('atlas-content-padding')),
    );
    expect(contentPadding.padding, const EdgeInsets.fromLTRB(28, 28, 28, 0));
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
    final ledger = find.byKey(const ValueKey('font-ledger'));
    expect(ledger, findsOneWidget);
    expect(
      find.descendant(of: ledger, matching: find.byType(DesyCard)),
      findsNothing,
    );
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

  testWidgets(
    'All components renders folder headings with depth-capped hierarchy',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        DesyBenchApp(
          registry: DesyRegistry(
            name: 'Hierarchical catalogue',
            themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
            components: [
              _component(
                'deep.button',
                path: '/inputs/buttons/elevated/colored/brand',
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final headings = [
        find.byKey(const ValueKey('atlas-folder-heading-/inputs')),
        find.byKey(const ValueKey('atlas-folder-heading-/inputs/buttons')),
        find.byKey(
          const ValueKey('atlas-folder-heading-/inputs/buttons/elevated'),
        ),
        find.byKey(
          const ValueKey(
            'atlas-folder-heading-/inputs/buttons/elevated/colored',
          ),
        ),
        find.byKey(
          const ValueKey(
            'atlas-folder-heading-/inputs/buttons/elevated/colored/brand',
          ),
        ),
      ];
      for (final heading in headings) {
        expect(heading, findsOneWidget);
      }

      final fontSizes = [
        for (final heading in headings)
          tester.widget<Text>(heading).style!.fontSize!,
      ];
      expect(fontSizes[0], greaterThan(fontSizes[1]));
      expect(fontSizes[1], greaterThan(fontSizes[2]));
      expect(fontSizes[2], greaterThan(fontSizes[3]));
      expect(fontSizes[3], fontSizes[4]);

      final headingTops = [
        for (final heading in headings) tester.getTopLeft(heading).dy,
      ];
      expect(headingTops, orderedEquals([...headingTops]..sort()));
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('atlas-card-deep.button')))
            .dy,
        greaterThan(headingTops.last),
      );
    },
  );

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
    final catalogueCard = find.byType(DesyCatalogueCard);
    expect(catalogueCard, findsOneWidget);
    expect(
      find.descendant(of: catalogueCard, matching: find.text(name)),
      findsNothing,
    );
    expect(
      card.evaluate().single,
      matchesSemantics(isButton: true, hasTapAction: true, label: 'Open $name'),
    );

    tester.semantics.tap(card);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-search')), findsNothing);
    semantics.dispose();
  });

  testWidgets('Atlas card IDs stay selectable on one line on narrow screens', (
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

    final idText = tester.widget<SelectableText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            widget.data == id &&
            widget.maxLines == 1,
      ),
    );
    expect(idText.maxLines, 1);
  });

  testWidgets('Atlas card paths and IDs are selectable without opening it', (
    tester,
  ) async {
    const id = 'button.primary';
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Selectable Atlas metadata',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [_component(id, path: '/actions')],
        ),
      ),
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == '/actions',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is SelectableText && widget.data == id,
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('desy-catalogue-card-identifier')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-search')), findsOneWidget);
  });

  testWidgets('Atlas keeps compact previews at their natural painted size', (
    tester,
  ) async {
    const previewKey = ValueKey('natural-atlas-preview');
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Readable Atlas',
          themes: const [
            DesyTheme(
              id: 'light',
              name: 'Light',
              previewBackgroundColor: Color(0xFFF4F4F4),
              wrap: _wrap,
            ),
          ],
          components: [
            DesyStaticComponent(
              id: 'compact.component',
              name: 'Compact component',
              instances: {
                'default': (_) =>
                    const SizedBox(key: previewKey, width: 120, height: 48),
              },
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(previewKey)).size, const Size(120, 48));
  });
}

DesyToken _token(String id) => DesyToken(
  id: id,
  name: id,
  value: 'value',
  builder: (_) => const SizedBox(),
);

DesyRegistryComponent _component(
  String id, {
  String? name,
  String path = '/',
}) => DesyStaticComponent(
  id: id,
  name: name ?? id,
  path: path,
  instances: {'default': (_) => const SizedBox()},
);

Widget _wrap(BuildContext context, Widget child) => child;
