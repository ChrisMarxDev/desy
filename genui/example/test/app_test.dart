import 'package:desy_genui/desy_genui.dart';
import 'package:desy_genui_example/genui_backend.dart';
import 'package:desy_genui_example/main.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the Orbit registry in the GenUI exploration workspace', (
    tester,
  ) async {
    _setDesktopViewport(tester);

    await tester.pumpWidget(const DesyGenUiExampleApp());
    await tester.pump();

    expect(find.text('ORBIT'), findsOneWidget);
    expect(find.text('Shape the next useful view.'), findsOneWidget);
    expect(
      find.text('Your GenUI experiment is ready for a real prompt'),
      findsOneWidget,
    );
    expect(find.text('Generate'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('No generated action yet.'), findsOneWidget);
  });

  testWidgets('replaces the Orbit fixture with backend-generated A2UI', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    final backend = _FakeBackend();
    await tester.pumpWidget(DesyGenUiExampleApp(backend: backend));
    await tester.pump();

    await tester.enterText(
      find.byType(EditableText),
      'Build an experiment plan.',
    );
    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();

    expect(
      (backend.turns.single as GenUiPromptTurn).text,
      'Build an experiment plan.',
    );
    expect(backend.catalog?.catalog.catalogId, 'demo.orbit-genui@0.2.0');
    expect(find.text('A focused experiment is ready'), findsOneWidget);
    expect(
      find.text('Your GenUI experiment is ready for a real prompt'),
      findsNothing,
    );
    expect(find.textContaining('test-model · response-test'), findsOneWidget);

    await tester.tap(find.text('Open experiment'));
    await tester.pumpAndSettle();
    expect(backend.turns, hasLength(2));
    final actionTurn = backend.turns.last as GenUiActionTurn;
    expect(actionTurn.action.name, 'open_experiment');
    expect(actionTurn.action.context['origin'], 'fake-backend');
    expect(actionTurn.action.context['title'], 'Test the early signal first');
    expect(
      actionTurn.currentSurface.first['component'],
      'orbit.component.stack',
    );
    expect(find.text('Experiment workspace opened'), findsOneWidget);
    expect(find.text('No generated action yet.'), findsNothing);
  });

  testWidgets('app policy can keep a generated action local', (tester) async {
    _setDesktopViewport(tester);
    final backend = _FakeBackend();
    await tester.pumpWidget(
      DesyGenUiExampleApp(backend: backend, shouldForwardAction: (_) => false),
    );
    await tester.pump();

    await tester.tap(find.text('Generate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open experiment'));
    await tester.pumpAndSettle();

    expect(backend.turns, hasLength(1));
    expect(backend.turns.single, isA<GenUiPromptTurn>());
    expect(find.text('A focused experiment is ready'), findsOneWidget);
    expect(find.textContaining('"name":"open_experiment"'), findsOneWidget);
  });

  testWidgets('desktop shortcut focuses the native composer', (tester) async {
    _setDesktopViewport(tester);
    await tester.pumpWidget(const DesyGenUiExampleApp());
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
  });

  testWidgets('local ticket requests update a bound surface without an agent', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    await tester.pumpWidget(const DesyGenUiExampleApp());
    await tester.pump();

    await tester.tap(find.text('Load next ticket'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('APP-1'), findsOneWidget);
    expect(find.text('APP-2'), findsNothing);

    await tester.tap(find.text('Load next ticket'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await tester.pump();
    expect(find.text('APP-1'), findsOneWidget);
    expect(find.text('APP-2'), findsOneWidget);
    expect(
      find.textContaining('LOCAL TICKET LOADER · request 2'),
      findsOneWidget,
    );
  });

  testWidgets('Codex checkpoints continue a separate generated coding task', (
    tester,
  ) async {
    _setDesktopViewport(tester);
    await tester.pumpWidget(const DesyGenUiExampleApp());
    await tester.pump();

    await tester.tap(find.text('Codex checkpoints').first);
    await tester.pumpAndSettle();
    expect(find.text('Decide, then let the task continue.'), findsOneWidget);
    expect(
      find.text('Should live bindings become a public API?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Make it public'));
    await tester.pump();
    expect(
      find.textContaining('Plan prepared for public package API'),
      findsOneWidget,
    );

    await tester.tap(find.text('Run full verification'));
    await tester.pump();
    expect(find.text('Accept this implementation?'), findsOneWidget);

    await tester.tap(find.text('Accept implementation'));
    await tester.pump();
    expect(find.text('Implementation accepted'), findsOneWidget);
  });
}

void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

final class _FakeBackend implements GenUiBackend {
  final turns = <GenUiTurn>[];
  DesyGenUiCatalog? catalog;

  @override
  Future<GeneratedSurface> respond({
    required GenUiTurn turn,
    required DesyGenUiCatalog catalog,
  }) async {
    turns.add(turn);
    this.catalog = catalog;
    if (turn is GenUiActionTurn) {
      return const GeneratedSurface(
        model: 'test-model',
        responseId: 'response-action',
        components: [
          {
            'id': 'root',
            'component': 'orbit.component.insight',
            'eyebrow': 'ACTION CONTINUATION',
            'title': 'Experiment workspace opened',
            'detail':
                'The generated action became the next structured agent turn.',
            'metric': 'Ready',
            'change': 'Continue',
            'tone': 'success',
          },
        ],
      );
    }
    return const GeneratedSurface(
      model: 'test-model',
      responseId: 'response-test',
      components: [
        {
          'id': 'root',
          'component': 'orbit.component.stack',
          'children': ['insight', 'recommendation'],
        },
        {
          'id': 'insight',
          'component': 'orbit.component.insight',
          'eyebrow': 'EXPERIMENT BRIEF',
          'title': 'A focused experiment is ready',
          'detail':
              'The fake backend returned a composed Orbit component tree.',
          'metric': '3 steps',
          'change': 'High signal',
          'tone': 'info',
        },
        {
          'id': 'recommendation',
          'component': 'orbit.component.recommendation',
          'title': 'Test the early signal first',
          'detail':
              'Review the compact brief before investing in a broader flow.',
          'confidence': 0.91,
          'actionLabel': 'Open experiment',
          'onAction': {
            'event': {
              'name': 'open_experiment',
              'context': {'origin': 'fake-backend'},
            },
          },
        },
      ],
    );
  }

  @override
  void close() {}
}
