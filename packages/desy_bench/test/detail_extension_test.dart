import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builder declarations support const immutable identity', () {
    const extension = DesyDetailExtension.builder(
      id: 'constant',
      name: 'Constant',
      builder: _constantExtensionBody,
    );

    expect(extension.id, 'constant');
    expect(extension.name, 'Constant');

    const custom = _CustomDetailExtension();
    expect(custom.id, 'custom');
    expect(custom.name, 'Custom extension');
    expect(custom.description, 'Stored by the base declaration.');
  });

  testWidgets(
    'entry details render matching extensions in registration order',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final registry = _registry();
      final entry = registry.resolve('button')!;
      final contexts = <DesyDetailExtensionContext>[];
      var rejectedBuilds = 0;
      final declarations = <DesyDetailExtension>[
        DesyDetailExtension.builder(
          id: 'notes',
          name: 'Notes',
          description: 'Keep an entry-scoped draft.',
          builder: (context, extension) {
            contexts.add(extension);
            return const DesyTextField(key: ValueKey('notes-draft'));
          },
        ),
        DesyDetailExtension.builder(
          id: 'review',
          name: 'Review',
          builder: (context, extension) {
            contexts.add(extension);
            return const DesyTextField(key: ValueKey('review-draft'));
          },
        ),
        DesyDetailExtension.builder(
          id: 'not-for-buttons',
          name: 'Hidden extension',
          appliesTo: (extension) => extension.entry.id == 'other',
          builder: (context, extension) {
            rejectedBuilds++;
            return const SizedBox.shrink();
          },
        ),
      ];
      final session = DesyWorkbenchSession(
        registry: registry,
        detailExtensions: declarations,
      );
      addTearDown(session.dispose);

      // The session owns a defensive immutable declaration collection.
      declarations.clear();
      expect(session.detailExtensions, hasLength(3));
      expect(
        () => session.detailExtensions.add(session.detailExtensions.first),
        throwsUnsupportedError,
      );

      await tester.pumpWidget(
        _TestHarness(
          child: DesyDetailScreen(session: session, entry: entry),
        ),
      );

      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Keep an entry-scoped draft.'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Hidden extension'), findsNothing);
      expect(rejectedBuilds, 0);
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('detail-extension:button:notes')),
            )
            .dy,
        greaterThan(tester.getTopLeft(find.text('Controls')).dy),
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('detail-extension:button:notes')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('detail-extension:button:review')),
              )
              .dy,
        ),
      );
      expect(find.bySemanticsLabel('Notes detail extension'), findsOneWidget);

      expect(contexts, hasLength(2));
      expect(contexts.first, isNot(same(contexts.last)));
      for (final extension in contexts) {
        expect(extension.registry, same(registry));
        expect(extension.entry, same(entry));
        expect(extension.component, same(entry.component));
        expect(extension.activeTheme, same(registry.themes.first));
      }

      await tester.enterText(
        find.byKey(const ValueKey('notes-draft')),
        'Preserve this draft',
      );
      expect(
        _editableText(tester, const ValueKey('review-draft')).controller.text,
        isEmpty,
      );

      session.selectTheme(1);
      await tester.pump();

      expect(
        _editableText(tester, const ValueKey('notes-draft')).controller.text,
        'Preserve this draft',
      );
      expect(contexts.last.registry, same(registry));
      expect(contexts.last.activeTheme, same(registry.themes.last));
    },
  );

  testWidgets('detail extensions render for non-component entries', (
    tester,
  ) async {
    final registry = _registry();
    var appliesCalls = 0;
    var buildCalls = 0;
    final session = DesyWorkbenchSession(
      registry: registry,
      detailExtensions: [
        DesyDetailExtension.builder(
          id: 'entry-notes',
          name: 'Entry notes',
          appliesTo: (extension) {
            appliesCalls++;
            return true;
          },
          builder: (context, extension) {
            buildCalls++;
            return const Text('Extension body');
          },
        ),
      ],
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: DesyDetailScreen(
          session: session,
          entry: registry.resolve('token')!,
        ),
      ),
    );

    expect(find.text('Entry notes'), findsOneWidget);
    expect(find.text('Extension body'), findsOneWidget);
    expect(appliesCalls, 1);
    expect(buildCalls, 1);
  });

  testWidgets(
    'applicability and synchronous builder failures keep siblings visible',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final reports = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousOnError);
      final registry = _registry();
      final session = DesyWorkbenchSession(
        registry: registry,
        detailExtensions: [
          DesyDetailExtension.builder(
            id: 'bad-applicability',
            name: 'Bad applicability',
            appliesTo: (_) => throw StateError('predicate failed'),
            builder: (_, _) => const Text('Must not build'),
          ),
          DesyDetailExtension.builder(
            id: 'healthy',
            name: 'Healthy',
            builder: (_, _) => const Text('Healthy extension body'),
          ),
          DesyDetailExtension.builder(
            id: 'bad-builder',
            name: 'Bad builder',
            builder: (_, _) => throw StateError('builder failed'),
          ),
        ],
      );
      addTearDown(session.dispose);

      await tester.pumpWidget(
        _TestHarness(
          child: DesyDetailScreen(
            session: session,
            entry: registry.resolve('button')!,
          ),
        ),
      );
      FlutterError.onError = previousOnError;

      expect(find.text('Controls'), findsOneWidget);
      expect(find.text('Healthy extension body'), findsOneWidget);
      expect(find.text('Must not build'), findsNothing);
      expect(
        find.byKey(const ValueKey('detail-extension-error:bad-applicability')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('detail-extension-error:bad-builder')),
        findsOneWidget,
      );
      final failureSemantics = tester.widget<Semantics>(
        find.byKey(const ValueKey('detail-extension-error:bad-builder')),
      );
      expect(
        failureSemantics.properties.label,
        'Bad builder could not be loaded',
      );
      expect(failureSemantics.properties.liveRegion, isTrue);
      expect(reports, hasLength(2));
      expect(
        reports.map((details) => details.exception.toString()),
        containsAll(<String>[
          'Bad state: predicate failed',
          'Bad state: builder failed',
        ]),
      );
    },
  );

  testWidgets('returned descendant failures use Flutter ErrorWidget behavior', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = _registry();
    final session = DesyWorkbenchSession(
      registry: registry,
      detailExtensions: [
        DesyDetailExtension.builder(
          id: 'throwing-descendant',
          name: 'Throwing descendant',
          builder: (_, _) => const _ThrowingDescendant(),
        ),
        DesyDetailExtension.builder(
          id: 'healthy-after-descendant',
          name: 'Healthy after descendant',
          builder: (_, _) => const Text('Sibling remains visible'),
        ),
      ],
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: DesyDetailScreen(
          session: session,
          entry: registry.resolve('button')!,
        ),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('descendant failed'));
    expect(find.byType(ErrorWidget), findsOneWidget);
    expect(
      find.byKey(const ValueKey('detail-extension-error:throwing-descendant')),
      findsNothing,
    );
    expect(find.text('Sibling remains visible'), findsOneWidget);
    expect(find.text('Controls'), findsOneWidget);
  });

  testWidgets('public app routes registered detail extensions to components', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final registry = _registry();
    DesyDetailExtensionContext? receivedContext;

    await tester.pumpWidget(
      DesyBenchApp(
        registry: registry,
        detailExtensions: [
          DesyDetailExtension.builder(
            id: 'public-route',
            name: 'Public route extension',
            builder: (_, extension) {
              receivedContext = extension;
              return const Text('Public routed body');
            },
          ),
        ],
      ),
    );

    final componentCard = find.semantics.byLabel('Open Button');
    expect(componentCard, findsOneWidget);
    tester.semantics.tap(componentCard);
    await tester.pumpAndSettle();

    expect(find.text('Public route extension'), findsOneWidget);
    expect(find.text('Public routed body'), findsOneWidget);
    expect(receivedContext?.registry, same(registry));
    expect(receivedContext?.component, same(registry.allComponents.single));
    semantics.dispose();
  });

  testWidgets('mounted app replaces runtime when detail declarations change', (
    tester,
  ) async {
    final hostKey = GlobalKey<_UpdatingBenchHostState>();
    await tester.pumpWidget(_UpdatingBenchHost(key: hostKey));

    await _openButtonDetail(tester);
    expect(find.text('First extension body'), findsOneWidget);

    hostKey.currentState!.replaceExtension();
    await tester.pumpAndSettle();

    // A new declaration runtime starts at the catalogue, then exposes only the
    // replacement when the component route is opened again.
    expect(find.text('First extension body'), findsNothing);
    await _openButtonDetail(tester);
    expect(find.text('First extension body'), findsNothing);
    expect(find.text('Replacement extension body'), findsOneWidget);
  });

  testWidgets(
    'invalid mounted configuration hides stale content, deduplicates, and recovers',
    (tester) async {
      final hostKey = GlobalKey<_UpdatingBenchHostState>();
      await tester.pumpWidget(_UpdatingBenchHost(key: hostKey));
      await _openButtonDetail(tester);
      expect(find.text('First extension body'), findsOneWidget);

      final reports = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = reports.add;
      addTearDown(() => FlutterError.onError = previousOnError);
      hostKey.currentState!.invalidateExtension();
      await tester.pump();
      hostKey.currentState!.rebuildSameConfiguration();
      await tester.pump();
      FlutterError.onError = previousOnError;

      expect(reports, hasLength(1));
      expect(reports.single.exception, isA<FlutterError>());
      expect(
        reports.single.exception.toString(),
        contains('Duplicate registry ID "light" (extension).'),
      );
      expect(
        find.byKey(const ValueKey('workbench-configuration-error')),
        findsOneWidget,
      );
      expect(find.text('First extension body'), findsNothing);
      expect(find.text('Replacement extension body'), findsNothing);

      hostKey.currentState!.recoverExtension();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('workbench-configuration-error')),
        findsNothing,
      );
      await _openButtonDetail(tester);
      expect(find.text('Recovered extension body'), findsOneWidget);
      expect(find.text('First extension body'), findsNothing);
    },
  );

  test('session creates detail context for every resolved registry entry', () {
    final registry = _registry();
    final session = DesyWorkbenchSession(registry: registry);
    addTearDown(session.dispose);

    final tokenContext = session.detailExtensionContext(
      registry.resolve('token')!,
    );
    expect(tokenContext.entry.id, 'token');
    expect(tokenContext.component, isNull);

    final componentContext = DesyDetailExtensionContext(
      registry: registry,
      activeTheme: registry.themes.first,
      entry: registry.resolve('button')!,
    );
    expect(componentContext.component, same(componentContext.entry.component));
  });
}

Future<void> _openButtonDetail(WidgetTester tester) async {
  final semantics = tester.ensureSemantics();
  final componentCard = find.semantics.byLabel('Open Button');
  expect(componentCard, findsOneWidget);
  tester.semantics.tap(componentCard);
  await tester.pumpAndSettle();
  semantics.dispose();
}

EditableText _editableText(WidgetTester tester, ValueKey<String> key) =>
    tester.widget<EditableText>(
      find.descendant(of: find.byKey(key), matching: find.byType(EditableText)),
    );

DesyRegistry _registry() => DesyRegistry(
  name: 'Detail extensions',
  themes: const [
    DesyTheme(id: 'light', name: 'Light', wrap: _wrap),
    DesyTheme(id: 'dark', name: 'Dark', wrap: _wrap),
  ],
  tokens: [DesyToken(id: 'token', name: 'Token', builder: _emptyPreview)],
  components: [
    DesyStaticComponent(
      id: 'button',
      name: 'Button',
      instances: {'default': _emptyPreview},
    ),
  ],
);

Widget _emptyPreview(BuildContext context) => const SizedBox();
Widget _wrap(BuildContext context, Widget child) => child;
Widget _constantExtensionBody(
  BuildContext context,
  DesyDetailExtensionContext extension,
) => const SizedBox();

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FTheme(data: FTheme.neutral.light.desktop, child: child),
  );
}

class _UpdatingBenchHost extends StatefulWidget {
  const _UpdatingBenchHost({super.key});

  @override
  State<_UpdatingBenchHost> createState() => _UpdatingBenchHostState();
}

class _UpdatingBenchHostState extends State<_UpdatingBenchHost> {
  final registry = _registry();
  final detailExtensions = <DesyDetailExtension>[
    DesyDetailExtension.builder(
      id: 'changing',
      name: 'First extension',
      builder: (_, _) => const Text('First extension body'),
    ),
  ];

  void replaceExtension() => setState(() {
    // Mutate the same public input list to prove the workbench compares its
    // immutable declaration snapshot, not only the list object's identity.
    detailExtensions[0] = DesyDetailExtension.builder(
      id: 'replacement',
      name: 'Replacement extension',
      builder: (_, _) => const Text('Replacement extension body'),
    );
  });

  void invalidateExtension() => setState(() {
    detailExtensions[0] = DesyDetailExtension.builder(
      id: 'light',
      name: 'Invalid extension',
      builder: (_, _) => const Text('Invalid extension body'),
    );
  });

  void rebuildSameConfiguration() => setState(() {
    // Recreate the declaration object to mirror a normal parent rebuild. The
    // validation problem and stable identity snapshot are still equivalent.
    detailExtensions[0] = DesyDetailExtension.builder(
      id: 'light',
      name: 'Invalid extension',
      builder: (_, _) => const Text('Invalid extension body'),
    );
  });

  void recoverExtension() => setState(() {
    detailExtensions[0] = DesyDetailExtension.builder(
      id: 'recovered',
      name: 'Recovered extension',
      builder: (_, _) => const Text('Recovered extension body'),
    );
  });

  @override
  Widget build(BuildContext context) =>
      DesyBenchApp(registry: registry, detailExtensions: detailExtensions);
}

final class _CustomDetailExtension extends DesyDetailExtension {
  const _CustomDetailExtension()
    : super(
        id: 'custom',
        name: 'Custom extension',
        description: 'Stored by the base declaration.',
      );

  @override
  Widget build(BuildContext context, DesyDetailExtensionContext extension) =>
      const SizedBox();
}

class _ThrowingDescendant extends StatelessWidget {
  const _ThrowingDescendant();

  @override
  Widget build(BuildContext context) => throw StateError('descendant failed');
}
