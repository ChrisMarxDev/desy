import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('missing instance links remain inspectable in the workbench', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Broken link',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyComponent(
          id: 'card',
          name: 'Card',
          knobs: (k) => (
            trailing: k.widgetInstance(
              'trailing',
              name: 'Trailing',
              initial: 'status.missing',
            ),
          ),
          build: (context, knobs) => knobs.trailing.widget,
          instances: (knobs) => {
            'missing': [knobs.trailing('status.missing')],
          },
        ),
      ],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('workbench-configuration-error')),
      findsNothing,
    );
    expect(find.text('REGISTRY'), findsOneWidget);
  });

  testWidgets(
    'workbench rejects duplicate registry and extension IDs at its boundary',
    (tester) async {
      final registry = DesyRegistry(
        name: 'Invalid',
        themes: const [DesyTheme(id: 'shared', name: 'Light', wrap: _wrap)],
      );
      final extension = DesyWorkspaceExtension.builder(
        id: 'shared',
        name: 'Conflicting extension',
        builder: (_, _) => const SizedBox(),
      );

      await tester.pumpWidget(
        DesyBenchApp(registry: registry, extensions: [extension]),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains(
          'DesyWorkbenchApp cannot start because the registry declaration is invalid.',
        ),
      );
      expect(
        error.toString(),
        contains('Duplicate registry ID "shared" (extension).'),
      );
    },
  );

  testWidgets('workbench validates prototype session and direction IDs', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Invalid prototypes',
      themes: const [DesyTheme(id: 'shared', name: 'Light', wrap: _wrap)],
      prototypes: [
        DesyPrototypeSession(
          id: 'shared',
          name: 'Conflicting session',
          prototypes: const [
            DesyPrototype(
              id: 'prototype.direction',
              name: 'Direction',
              builder: _prototype,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('Duplicate registry ID "shared" (prototype session).'),
    );
  });

  testWidgets(
    'workbench shares IDs across registry, workspace, and detail extensions',
    (tester) async {
      final registry = DesyRegistry(
        name: 'Invalid',
        themes: const [
          DesyTheme(id: 'registry-shared', name: 'Light', wrap: _wrap),
        ],
      );
      final workspace = DesyWorkspaceExtension.builder(
        id: 'extension-shared',
        name: 'Workspace extension',
        builder: (_, _) => const SizedBox(),
      );
      final detailWithRegistryId = DesyDetailExtension.builder(
        id: 'registry-shared',
        name: 'Registry conflict',
        builder: (_, _) => const SizedBox(),
      );
      final detailWithWorkspaceId = DesyDetailExtension.builder(
        id: 'extension-shared',
        name: 'Workspace conflict',
        builder: (_, _) => const SizedBox(),
      );

      await tester.pumpWidget(
        DesyBenchApp(
          registry: registry,
          extensions: [workspace],
          detailExtensions: [detailWithRegistryId, detailWithWorkspaceId],
        ),
      );

      final error = tester.takeException();
      expect(error, isA<FlutterError>());
      expect(
        error.toString(),
        contains('Duplicate registry ID "registry-shared" (extension).'),
      );
      expect(
        error.toString(),
        contains('Duplicate registry ID "extension-shared" (extension).'),
      );
    },
  );

  testWidgets('workbench rejects duplicate detail extension IDs directly', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Invalid details',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    await tester.pumpWidget(
      DesyBenchApp(
        registry: registry,
        detailExtensions: [
          DesyDetailExtension.builder(
            id: 'duplicate-detail',
            name: 'First',
            builder: (_, _) => const SizedBox(),
          ),
          DesyDetailExtension.builder(
            id: 'duplicate-detail',
            name: 'Second',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      ),
    );

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('Duplicate registry ID "duplicate-detail" (extension).'),
    );
  });

  testWidgets('mounted workbench revalidates changed detail declarations', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Updated details',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );
    final detailExtensions = <DesyDetailExtension>[
      DesyDetailExtension.builder(
        id: 'valid',
        name: 'Valid',
        builder: (_, _) => const SizedBox(),
      ),
    ];
    late StateSetter rebuild;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return DesyBenchApp(
            registry: registry,
            detailExtensions: detailExtensions,
          );
        },
      ),
    );

    rebuild(() {
      detailExtensions[0] = DesyDetailExtension.builder(
        id: 'light',
        name: 'Now invalid',
        builder: (_, _) => const SizedBox(),
      );
    });
    await tester.pump();

    final error = tester.takeException();
    expect(error, isA<FlutterError>());
    expect(
      error.toString(),
      contains('Duplicate registry ID "light" (extension).'),
    );
  });

  testWidgets('disposes only workspace extensions removed from the workbench', (
    tester,
  ) async {
    final registry = DesyRegistry(
      name: 'Extension lifecycle',
      themes: [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );
    final first = _TrackingExtension('first');
    final second = _TrackingExtension('second');
    var extensions = <DesyWorkspaceExtension>[first];
    late StateSetter rebuild;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return DesyBenchApp(registry: registry, extensions: extensions);
        },
      ),
    );

    rebuild(() => extensions = [second]);
    await tester.pump();
    expect(first.disposeCalls, 1);
    expect(second.disposeCalls, 0);

    await tester.pumpWidget(const SizedBox());
    expect(second.disposeCalls, 1);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _prototype(BuildContext context) => const SizedBox();

class _TrackingExtension extends DesyWorkspaceExtension {
  _TrackingExtension(this.id);

  @override
  final String id;

  @override
  String get name => id;

  var disposeCalls = 0;

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      const SizedBox();

  @override
  void dispose() => disposeCalls++;
}
