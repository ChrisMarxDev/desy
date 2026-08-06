import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

Widget _wrap(BuildContext context, Widget child) => child;
