import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Components overview derives folder headings from its input', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Root primitives',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            _component('button.elevated', path: '/buttons'),
            _component('button.text', path: '/buttons'),
            _component('input.textfield', path: '/inputs/text'),
            _component('input.searchbar', path: '/inputs/text'),
            _component('input.date', path: '/inputs/date'),
          ],
        ),
      ),
    );

    expect(find.byType(DesyCatalogueCard), findsWidgets);
    expect(
      find.byKey(const ValueKey('atlas-folder-heading-/buttons')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('atlas-folder-heading-/inputs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('atlas-folder-heading-/inputs/text')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('atlas-card-button.elevated')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('atlas-card-input.searchbar')),
      findsOneWidget,
    );
  });

  testWidgets(
    'Components overview owns the content viewport below its header',
    (tester) async {
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
    },
  );

  testWidgets(
    'Atlas count shares the headline and scroll owns the search gap',
    (tester) async {
      await tester.pumpWidget(
        DesyBenchApp(
          registry: DesyRegistry(
            name: 'Compact catalogue header',
            themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
            components: [_component('header.component')],
          ),
        ),
      );

      final headline = find.byKey(const ValueKey('atlas-headline'));
      expect(
        find.descendant(
          of: headline,
          matching: find.byKey(const ValueKey('atlas-entry-count')),
        ),
        findsOneWidget,
      );
      expect(find.text('1 entries'), findsOneWidget);

      final scroll = find.byKey(const ValueKey('component-overview-scroll'));
      expect(scroll, findsOneWidget);
    },
  );

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

  testWidgets('component folder overviews include every descendant component', (
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
    expect(
      find.byKey(const ValueKey('atlas-card-nested.action')),
      findsOneWidget,
    );
  });

  testWidgets('component folder overviews keep their nested folder structure', (
    tester,
  ) async {
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Hierarchical catalogue',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            _component('input.text', path: '/inputs'),
            _component('input.button', path: '/inputs/buttons'),
          ],
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('atlas-folder-heading-/inputs')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('sidebar-folder-/inputs')));
    await tester.pumpAndSettle();

    final headline = tester.widget<Text>(
      find.byKey(const ValueKey('atlas-headline')),
    );
    expect(headline.textSpan?.toPlainText(), startsWith('Inputs'));
    expect(find.text('COMPONENTS'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('component-overview-scroll')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('atlas-card-input.text')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('atlas-folder-heading-/inputs/buttons')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('atlas-card-input.button')),
      findsOneWidget,
    );
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

  testWidgets(
    'component preview cards expose one tap action that opens the entry',
    (tester) async {
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

      final row = find.semantics.byLabel('Open $name');
      expect(row, findsOneWidget);

      tester.semantics.tap(row);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('atlas-search')), findsNothing);
      semantics.dispose();
    },
  );
}

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
