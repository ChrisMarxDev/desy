import 'dart:async';

import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('submission snapshots immutable entry, folder, and theme context', () {
    final fixture = _fixture();
    final folderIds = <String>['copy'];
    final folderNames = <String>['Copy'];
    final annotation = DesyAgentAnnotation(
      entryId: fixture.context.entry.id,
      entryName: fixture.context.entry.name,
      folderIds: folderIds,
      folderNames: folderNames,
      sourcePath: fixture.context.component?.source,
      activeThemeId: fixture.context.activeTheme.id,
      comment: 'Review the disabled state.',
      createdAt: DateTime.utc(2026, 8, 6, 10, 30),
    );
    folderIds.add('changed');
    folderNames.add('Changed');

    expect(annotation.entryId, 'acme.button.primary');
    expect(annotation.entryName, 'Primary button');
    expect(annotation.folderIds, ['copy']);
    expect(annotation.folderNames, ['Copy']);
    expect(annotation.sourcePath, 'lib/src/sample_button.dart');
    expect(annotation.activeThemeId, 'acme.dark');
    expect(annotation.displayPath, 'Copy / Primary button');
    expect(() => annotation.folderIds.add('forbidden'), throwsUnsupportedError);
  });

  test('fromContext supports non-component registry entries', () {
    final registry = DesyRegistry(
      name: 'Atoms',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      measurements: [
        DesyNumericEntry.spacing(
          id: 'space.small',
          name: 'Small space',
          value: 8,
          builder: _preview,
        ),
      ],
    );
    final annotation = DesyAgentAnnotation.fromContext(
      context: DesyDetailExtensionContext(
        registry: registry,
        activeTheme: registry.themes.single,
        entry: registry.resolve('space.small')!,
      ),
      comment: 'Check this atom.',
      createdAt: DateTime.utc(2026, 8, 7, 12),
    );

    expect(annotation.entryId, 'space.small');
    expect(annotation.entryName, 'Small space');
    expect(annotation.folderIds, [
      DesyAtomKind.rootId,
      DesyAtomKind.measurements.id,
    ]);
    expect(annotation.displayPath, 'Atoms / Measurements / Small space');
    expect(annotation.sourcePath, isNull);
  });

  testWidgets('blank input is disabled and submission is single-flight', (
    tester,
  ) async {
    final pending = Completer<DesyAgentAnnotationReceipt>();
    var calls = 0;
    final extension = DesyAgentAnnotationsExtension(
      onSubmit: (annotation) {
        calls++;
        return pending.future;
      },
    );
    await tester.pumpWidget(_harness(extension));

    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pump();
    expect(calls, 0);

    await tester.enterText(
      find.byKey(const ValueKey('agent-annotation-comment')),
      'Check the hover state',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pump();

    expect(calls, 1);
    expect(find.byKey(const ValueKey('agent-annotation-busy')), findsOneWidget);

    pending.complete(
      const DesyAgentAnnotationReceipt(message: 'Saved for the agent.'),
    );
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets(
    'success snapshots context, shows Uri receipt, and clears draft',
    (tester) async {
      DesyAgentAnnotation? received;
      final issue = Uri.parse(
        'https://github.com/acme/design-system/issues/42',
      );
      final beforeSubmit = DateTime.now().toUtc();
      final extension = DesyAgentAnnotationsExtension(
        onSubmit: (annotation) async {
          received = annotation;
          return DesyAgentAnnotationReceipt(
            message: 'Created GitHub issue #42.',
            location: issue,
          );
        },
      );
      await tester.pumpWidget(_harness(extension));

      await tester.enterText(
        find.byKey(const ValueKey('agent-annotation-comment')),
        '  Increase the focus contrast.  ',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
      await tester.pumpAndSettle();
      final afterSubmit = DateTime.now().toUtc();

      expect(received?.entryId, 'acme.button.primary');
      expect(received?.entryName, 'Primary button');
      expect(received?.folderIds, ['/components', '/components/action']);
      expect(received?.folderNames, ['Components', 'Action']);
      expect(received?.sourcePath, 'lib/src/sample_button.dart');
      expect(received?.activeThemeId, 'acme.dark');
      expect(received?.comment, 'Increase the focus contrast.');
      expect(received!.createdAt.isBefore(beforeSubmit), isFalse);
      expect(received!.createdAt.isAfter(afterSubmit), isFalse);
      expect(find.text('Created GitHub issue #42.'), findsOneWidget);
      expect(find.text(issue.toString()), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: find.byKey(const ValueKey('agent-annotation-comment')),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        isEmpty,
      );
    },
  );

  testWidgets('failure preserves the draft and remains retryable', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    FlutterErrorDetails? reportedError;
    FlutterError.onError = (details) => reportedError = details;
    addTearDown(() => FlutterError.onError = previousErrorHandler);
    final hostileMessage = [
      '<script>secret-token</script>',
      ...List.filled(200, 'private callback detail'),
    ].join(' ');
    var calls = 0;
    final extension = DesyAgentAnnotationsExtension(
      onSubmit: (annotation) async {
        calls++;
        if (calls == 1) throw StateError(hostileMessage);
        return const DesyAgentAnnotationReceipt(message: 'Retry succeeded.');
      },
    );
    await tester.pumpWidget(_harness(extension));
    await tester.enterText(
      find.byKey(const ValueKey('agent-annotation-comment')),
      'Keep this draft',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('agent-annotation-error')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Could not send the annotation. Check the destination and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('secret-token'), findsNothing);
    expect(find.textContaining('private callback detail'), findsNothing);
    expect(reportedError?.library, 'desy_agent_annotations');
    expect(reportedError?.exception, isA<StateError>());
    expect(
      reportedError?.context?.toDescription(),
      contains('desy.agent-annotations'),
    );
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Keep this draft',
    );

    await tester.tap(find.byKey(const ValueKey('agent-annotation-submit')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Retry succeeded.'), findsOneWidget);
    expect(find.byKey(const ValueKey('agent-annotation-error')), findsNothing);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );
  });

  testWidgets(
    'Cmd+Enter and Ctrl+Enter submit without changing multiline Enter guards',
    (tester) async {
      final completions = [
        Completer<DesyAgentAnnotationReceipt>(),
        Completer<DesyAgentAnnotationReceipt>(),
      ];
      var calls = 0;
      final extension = DesyAgentAnnotationsExtension(
        onSubmit: (annotation) {
          final completion = completions[calls];
          calls++;
          return completion.future;
        },
      );
      await tester.pumpWidget(_harness(extension));
      final field = find.byKey(const ValueKey('agent-annotation-comment'));

      await _sendModifiedEnter(tester, LogicalKeyboardKey.metaLeft);
      await _sendModifiedEnter(tester, LogicalKeyboardKey.controlLeft);
      expect(calls, 0, reason: 'Blank shortcuts must remain disabled.');

      await tester.enterText(field, 'First line\nSecond line');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(calls, 0, reason: 'Plain Enter remains multiline editing.');
      expect(
        tester
            .widget<EditableText>(
              find.descendant(of: field, matching: find.byType(EditableText)),
            )
            .controller
            .text,
        contains('\n'),
      );

      await _sendModifiedEnter(tester, LogicalKeyboardKey.metaLeft);
      expect(calls, 1);
      await _sendModifiedEnter(tester, LogicalKeyboardKey.controlLeft);
      expect(calls, 1, reason: 'A busy shortcut cannot duplicate submission.');
      completions.first.complete(
        const DesyAgentAnnotationReceipt(message: 'First shortcut sent.'),
      );
      await tester.pumpAndSettle();

      await tester.enterText(field, 'Second shortcut');
      await tester.pump();
      await _sendModifiedEnter(tester, LogicalKeyboardKey.controlLeft);
      expect(calls, 2);
      completions.last.complete(
        const DesyAgentAnnotationReceipt(message: 'Second shortcut sent.'),
      );
      await tester.pumpAndSettle();
    },
  );

  testWidgets('remains semantic and readable at large system text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final semantics = tester.ensureSemantics();
    final extension = DesyAgentAnnotationsExtension(
      onSubmit: (annotation) async =>
          const DesyAgentAnnotationReceipt(message: 'Saved.'),
    );

    await tester.pumpWidget(_harness(extension, textScale: 2.4));

    expect(tester.takeException(), isNull);
    expect(find.text('Comment for agent'), findsOneWidget);
    expect(find.bySemanticsLabel('Send annotation to agent'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('agent-annotation-composer')),
      findsOneWidget,
    );
    expect(find.byType(DesyCard), findsNothing);
    semantics.dispose();
  });
}

Future<void> _sendModifiedEnter(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

Widget _harness(
  DesyAgentAnnotationsExtension extension, {
  double textScale = 1,
}) {
  final fixture = _fixture();
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: DesyDesignSystemScope(
      theme: DesyDesignSystemTheme.light,
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) => extension.build(context, fixture.context),
          ),
        ),
      ),
    ),
  );
}

({DesyRegistry registry, DesyDetailExtensionContext context}) _fixture() {
  final registry = DesyRegistry(
    name: 'Acme',
    themes: const [DesyTheme(id: 'acme.dark', name: 'Dark', wrap: _wrap)],
    components: [
      DesyComponent(
        id: 'acme.button.primary',
        name: 'Primary button',
        path: '/components/action',
        source: 'lib/src/sample_button.dart',
        preview: _preview,
      ),
    ],
  );
  return (
    registry: registry,
    context: DesyDetailExtensionContext(
      registry: registry,
      activeTheme: registry.themes.single,
      entry: registry.resolve('acme.button.primary')!,
    ),
  );
}

Widget _wrap(BuildContext context, Widget child) => child;
Widget _preview(BuildContext context) => const SizedBox();
