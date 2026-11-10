import 'dart:convert';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:a2ui_flutter/a2ui_flutter.dart';
import 'package:desy_core/desy_core.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compilation requires identity and includes every component', () {
    final disabled = DesyRegistry(
      name: 'Disabled',
      themes: [_theme],
      components: [_leafComponent()],
    );
    expect(
      () => DesyGenUiCatalog.compile(disabled),
      throwsA(isA<StateError>()),
    );

    final registry = _registry(includeAdditionalComponent: true);
    final compiled = DesyGenUiCatalog.compile(registry);
    expect(compiled.catalog.id, 'dev.desy.test@2.0.0');
    expect(compiled.catalog.components.keys, contains('test.additional'));
    expect(
      compiled.catalog.instructions,
      contains(
        'Use only components declared by registry dev.desy.test. '
        'Component IDs are surface-local. Child slots refer to those IDs.',
      ),
    );
  });

  test('compilation rejects structurally invalid or empty catalogs', () {
    final invalid = DesyRegistry(
      name: 'Invalid',
      identity: const DesyRegistryIdentity(id: '', version: '1'),
      themes: [_theme],
      components: [_leafComponent()],
    );
    final empty = DesyRegistry(
      name: 'Empty',
      identity: const DesyRegistryIdentity(id: 'dev.desy.empty', version: '1'),
      themes: [_theme],
    );

    expect(() => DesyGenUiCatalog.compile(invalid), throwsA(isA<StateError>()));
    expect(() => DesyGenUiCatalog.compile(empty), throwsA(isA<StateError>()));
  });

  test('maps every knob kind to a documented A2UI schema', () {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final item = compiled.catalog.components['test.panel']!;
    final properties = item.schema.value['properties']! as Map<String, Object?>;

    expect(properties['title'], containsPair('default', 'Default title'));
    expect(jsonEncode(properties['title']), contains('"path"'));
    expect(jsonEncode(properties['count']), contains('"minimum":1'));
    expect(jsonEncode(properties['count']), contains('"maximum":9'));
    expect(jsonEncode(properties['count']), contains('"multipleOf":1'));
    expect(jsonEncode(properties['enabled']), contains('"type":"boolean"'));
    expect(
      jsonEncode(properties['tone']),
      allOf(contains('"Neutral"'), contains('"default":"Neutral"')),
    );
    expect(jsonEncode(properties['startsAt']), contains('"type":"string"'));
    expect(
      properties['startsAt'],
      containsPair('default', '2026-08-15T09:30:00.000Z'),
    );
    expect(jsonEncode(properties['color']), contains('"maximum":4294967295'));
    expect(jsonEncode(properties['labels']), contains('"type":"array"'));
    expect(
      jsonEncode(properties['labels']),
      contains('"items":{"type":"string"}'),
    );
    expect(jsonEncode(properties['values']), contains('"type":"array"'));
    expect(jsonEncode(properties['values']), contains('"minimum":0'));
    expect(properties['metadata'], containsPair('default', {'source': 'test'}));
    expect(properties['body'], containsPair('type', 'string'));
    expect(properties['children'], containsPair('type', 'array'));
    expect(
      properties['submit'],
      containsPair('commonTypesRef', r'common_types.json#/$defs/Action'),
    );
    expect(jsonEncode(item.schema.value), contains('Visible heading'));
  });

  test('backend artifact is serializable, complete, and deterministic', () {
    final first = DesyGenUiCatalog.compile(_registry());
    final second = DesyGenUiCatalog.compile(_registry());

    expect(first.digest, second.digest);
    expect(first.digest, hasLength(64));
    expect(() => jsonDecode(first.toJson()), returnsNormally);
    expect(first.backendArtifact['schemaVersion'], 'desy-genui-catalog/0.1');
    expect(first.backendArtifact, contains('capabilities'));
    expect(first.backendArtifact, contains('fullSchema'));
    expect(first.backendArtifact, contains('examples'));
    expect(first.backendArtifact, contains('desy'));
  });

  testWidgets('renders scalar, single-child, and multi-child values', (
    tester,
  ) async {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final controller = _processor(compiled);
    _send(controller, compiled, const [
      {
        'id': 'root',
        'component': 'test.panel',
        'title': 'Live panel',
        'count': 4,
        'enabled': true,
        'tone': 'Critical',
        'startsAt': '2026-08-16T14:45:00.000Z',
        'color': 0xff112233,
        'labels': ['Search', 'Invite'],
        'values': [38, 26],
        'body': 'body',
        'children': ['first', 'second'],
      },
      {'id': 'body', 'component': 'test.leaf', 'label': 'Body'},
      {'id': 'first', 'component': 'test.leaf', 'label': 'First'},
      {'id': 'second', 'component': 'test.leaf', 'label': 'Second'},
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyGenUiSurface(
          controller: controller,
          surfaceId: 'test-surface',
          theme: _theme,
        ),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'Live panel · 4 · true · Critical · '
        '2026-08-16T14:45:00.000Z · ff112233',
      ),
      findsOneWidget,
    );
    expect(find.text('Body'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('event knob resolves context and merges consumer payload', (
    tester,
  ) async {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final controller = _processor(compiled);
    _send(controller, compiled, const [
      {
        'id': 'root',
        'component': 'test.action',
        'label': 'Submit',
        'submit': {
          'event': {
            'name': 'submit',
            'context': {'origin': 'fixture'},
          },
        },
      },
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: DesyGenUiSurface(
          controller: controller,
          surfaceId: 'test-surface',
          theme: _theme,
        ),
      ),
    );
    await tester.pump();

    final actions = <a2ui.A2uiRendererAction>[];
    final subscription = controller.model.onAction.subscribe(actions.add);
    addTearDown(subscription.unsubscribe);
    await tester.tap(find.text('Submit'));
    await tester.pump();
    final action = actions.single;
    expect(action.name, 'submit');
    expect(action.sourceComponentId, 'root');
    expect(action.context, {'origin': 'fixture', 'label': 'Submit'});
  });

  testWidgets('data-bound props update a component without replacing it', (
    tester,
  ) async {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final controller = _processor(compiled);
    _send(controller, compiled, const [
      {
        'id': 'root',
        'component': 'test.leaf',
        'label': {'path': '/tickets/0/key'},
      },
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyGenUiSurface(
          controller: controller,
          surfaceId: 'test-surface',
          theme: _theme,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Leaf'), findsOneWidget);

    controller.processMessages({
      'version': 'v0.9',
      'updateDataModel': {
        'surfaceId': 'test-surface',
        'path': '/tickets/0/key',
        'value': 'APP-1',
      },
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('APP-1'), findsOneWidget);

    controller.processMessages({
      'version': 'v0.9',
      'updateDataModel': {
        'surfaceId': 'test-surface',
        'path': '/tickets/0/key',
        'value': 'APP-2',
      },
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('APP-2'), findsOneWidget);
  });

  testWidgets('shows the default builder until the surface exists', (
    tester,
  ) async {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final controller = _processor(compiled);
    await tester.pumpWidget(
      MaterialApp(
        home: DesyGenUiSurface(
          controller: controller,
          surfaceId: 'test-surface',
          theme: _theme,
          defaultBuilder: (_) => const Text('Waiting'),
        ),
      ),
    );
    expect(find.text('Waiting'), findsOneWidget);

    _send(controller, compiled, const [
      {'id': 'root', 'component': 'test.leaf', 'label': 'Ready'},
    ]);
    await tester.pump();
    expect(find.text('Waiting'), findsNothing);
    expect(find.text('Ready'), findsOneWidget);

    controller.processMessages({
      'version': 'v0.9',
      'deleteSurface': {'surfaceId': 'test-surface'},
    });
    await tester.pump();
    expect(find.text('Waiting'), findsOneWidget);
  });

  testWidgets('materialized named example is a renderable flat surface', (
    tester,
  ) async {
    final compiled = DesyGenUiCatalog.compile(_registry());
    final examples =
        compiled.backendArtifact['examples']! as Map<String, Object?>;
    final example = ((examples['test.panel']! as List).first as List)
        .cast<Map<String, dynamic>>();
    final controller = _processor(compiled);
    _send(controller, compiled, example);

    await tester.pumpWidget(
      MaterialApp(
        home: DesyGenUiSurface(
          controller: controller,
          surfaceId: 'test-surface',
          theme: _theme,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Named panel'), findsOneWidget);
    expect(find.text('Named body'), findsOneWidget);
  });
}

a2ui.MessageProcessor<ComponentImplementation> _processor(
  DesyGenUiCatalog compiled,
) {
  final processor = a2ui.MessageProcessor<ComponentImplementation>(
    catalogs: [compiled.catalog],
    validationConfig: a2ui.ValidationConfig.strict,
  );
  addTearDown(processor.dispose);
  return processor;
}

void _send(
  a2ui.MessageProcessor<ComponentImplementation> controller,
  DesyGenUiCatalog compiled,
  List<Map<String, dynamic>> components,
) {
  controller.processMessages([
    {
      'version': 'v0.9',
      'createSurface': {
        'surfaceId': 'test-surface',
        'catalogId': compiled.catalog.id,
      },
    },
    {
      'version': 'v0.9',
      'updateComponents': {
        'surfaceId': 'test-surface',
        'components': components,
      },
    },
  ]);
}

const _theme = DesyTheme(id: 'light', name: 'Light', wrap: _wrapTheme);

Widget _wrapTheme(BuildContext context, Widget child) => Material(child: child);

DesyRegistry _registry({bool includeAdditionalComponent = false}) {
  final leaf = _leafComponent();
  final action = _actionComponent();
  final panel = _panelComponent();
  return DesyRegistry(
    name: 'Test system',
    identity: const DesyRegistryIdentity(id: 'dev.desy.test', version: '2.0.0'),
    themes: [_theme],
    components: [
      leaf,
      action,
      panel,
      if (includeAdditionalComponent)
        DesyStaticComponent(
          id: 'test.additional',
          name: 'Additional',
          instances: {'default': (_) => const SizedBox()},
        ),
    ],
  );
}

DesyRegistryComponent _leafComponent() => DesyComponent(
  id: 'test.leaf',
  name: 'Leaf',
  description: 'Small text leaf.',
  knobs: (k) => (
    label: k.string('label', description: 'Visible label.', initial: 'Leaf'),
  ),
  build: (context, knobs) => Text(knobs.label.value),
  instances: (knobs) => {
    'body': [knobs.label('Named body')],
  },
);

DesyRegistryComponent _actionComponent() => DesyComponent(
  id: 'test.action',
  name: 'Action',
  knobs: (k) => (
    label: k.string('label', initial: 'Submit'),
    submit: k.event('submit', description: 'Submit the current choice.'),
  ),
  build: (context, knobs) => FilledButton(
    onPressed: () => knobs.submit.emit({'label': knobs.label.value}),
    child: Text(knobs.label.value),
  ),
  instances: (knobs) => {
    'submit': [knobs.label('Submit')],
  },
);

DesyRegistryComponent _panelComponent() => DesyComponent(
  id: 'test.panel',
  name: 'Panel',
  description: 'Composes a body and ordered children.',
  knobs: (k) => (
    title: k.string(
      'title',
      description: 'Visible heading.',
      initial: 'Default title',
    ),
    count: k.number(
      'count',
      initial: 2,
      unit: 'items',
      step: 1,
      minimum: 1,
      maximum: 9,
    ),
    enabled: k.boolean('enabled', initial: false),
    tone: k.choice('tone', options: const ['Neutral', 'Positive', 'Critical']),
    startsAt: k.dateTime('startsAt', initial: DateTime.utc(2026, 8, 15, 9, 30)),
    color: k.color('color', initial: const Color(0xff445566)),
    labels: k.stringList('labels', initial: const ['Search', 'Invite']),
    values: k.numberList('values', initial: const [38, 26], minimum: 0),
    metadata: k.jsonValue('metadata', initial: const {'source': 'test'}),
    body: k.widgetInstance(
      'body',
      initial: 'test.leaf.body',
      options: const ['test.leaf.body'],
    ),
    children: k.widgetInstances(
      'children',
      options: const ['test.leaf.body', 'test.action.submit'],
    ),
    submit: k.event('submit'),
  ),
  build: (context, knobs) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        '${knobs.title.value} · ${knobs.count.value.toInt()} · '
        '${knobs.enabled.value} · '
        '${knobs.tone.value} · '
        '${knobs.startsAt.value.toIso8601String()} · '
        '${knobs.color.value.toARGB32().toRadixString(16)}',
      ),
      knobs.body.widget,
      ...knobs.children.widgets,
    ],
  ),
  instances: (knobs) => {
    'named': [knobs.title('Named panel'), knobs.body('test.leaf.body')],
  },
);
