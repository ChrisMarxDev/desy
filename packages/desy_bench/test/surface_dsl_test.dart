import 'dart:convert';

import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Desy surface DSL', () {
    test('parses the concise top-level component-list syntax', () {
      final surface = DesySurfaceDocument.parse('''
[
  {"id": "title.headerbar", "knobs": {"title": "Testing Screen"}},
  {
    "layout": "row",
    "gap": "space.medium",
    "children": [
      {"component": "status.badge", "instance": "ready"},
      {"component": "status.badge", "knobs": {"label": "Custom"}}
    ]
  }
]
''');

      expect(surface.version, 1);
      expect(surface.id, 'prototype');
      final root = surface.root as DesySurfaceColumn;
      expect(root.children, hasLength(2));
      final title = root.children.first as DesySurfaceComponent;
      expect(title.component, 'title.headerbar');
      expect(title.knobs, {'title': 'Testing Screen'});
      final row = root.children.last as DesySurfaceRow;
      expect((row.gap! as DesySurfaceMeasurement).id, 'space.medium');
      expect(row.children, hasLength(2));
    });

    test('round trips a full typed document through canonical JSON', () {
      final surface = DesySurfaceDocument(
        id: 'profile',
        root: DesySurfacePadding(
          padding: DesySurfaceInsets.symmetric(
            horizontal: DesySurfaceLength.measurement('space.medium'),
            vertical: DesySurfaceLength.pixels(8),
          ),
          child: DesySurfaceStack(
            alignment: Alignment.bottomRight,
            children: [
              DesySurfaceComponent(component: 'card.profile'),
              DesySurfaceSpacer(
                width: DesySurfaceLength.pixels(24),
                height: DesySurfaceLength.pixels(24),
              ),
            ],
          ),
        ),
      );

      final encoded = jsonEncode(surface.toJson());
      final reparsed = DesySurfaceDocument.parse(encoded);

      expect(reparsed.toJson(), surface.toJson());
    });

    test('parses explicit horizontal and vertical scrolling structure', () {
      final surface = DesySurfaceDocument.parse('''
{
  "layout":"scroll",
  "axis":"vertical",
  "scrollbar":true,
  "child":{
    "layout":"scroll",
    "axis":"horizontal",
    "child":{"component":"title.headerbar"}
  }
}
''');

      final vertical = surface.root as DesySurfaceScroll;
      expect(vertical.axis, Axis.vertical);
      expect(vertical.scrollbar, isTrue);
      final horizontal = vertical.child as DesySurfaceScroll;
      expect(horizontal.axis, Axis.horizontal);
      expect(horizontal.scrollbar, isFalse);
      expect(
        DesySurfaceDocument.parse(jsonEncode(surface.toJson())).toJson(),
        surface.toJson(),
      );
    });

    test('rejects UI elements that are not registry components', () {
      expect(
        () => DesySurfaceDocument.parse(
          '{"layout":"text","value":"Invented UI"}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('row, column, stack, padding, scroll, or spacer'),
          ),
        ),
      );
    });

    test('rejects unsupported fields and malformed spacing', () {
      expect(
        () => DesySurfaceDocument.parse(
          '{"component":"button","onTap":"deleteEverything"}',
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('unsupported field "onTap"'),
          ),
        ),
      );
      expect(
        () => DesySurfaceDocument.parse('{"layout":"spacer","width":-1}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('deeply freezes serialized knob data', () {
      final surface = DesySurfaceDocument.parse('''
{"component":"chart","knobs":{"series":[1,2,{"value":3}]}}
''');
      final component = surface.root as DesySurfaceComponent;
      final series = component.knobs['series']! as List<Object>;

      expect(() => series.add(4), throwsUnsupportedError);
      expect(
        () => (series.last as Map<String, Object>)['value'] = 4,
        throwsUnsupportedError,
      );
    });

    test('typed constructors reject states the JSON DSL cannot represent', () {
      expect(
        () => DesySurfaceRow(
          children: const [],
          crossAxisAlignment: CrossAxisAlignment.baseline,
        ),
        throwsArgumentError,
      );
      expect(
        () => DesySurfaceStack(
          children: const [],
          alignment: const Alignment(.25, .5),
        ),
        throwsArgumentError,
      );
    });
  });

  group('DesySurfaceValidator', () {
    test('validates components, knobs, instances, and spacing references', () {
      final surface = DesySurfaceDocument.parse('''
{
  "version": 1,
  "id": "invalid",
  "root": {
    "layout": "column",
    "gap": "radius.medium",
    "children": [
      {"component":"missing"},
      {"component":"title.headerbar","instance":"missing"},
      {"component":"title.headerbar","knobs":{"title":false,"other":"x"}},
      {"component":"card","knobs":{"trailing":"status.missing"}}
    ]
  }
}
''');

      final issues = DesySurfaceValidator(_registry).validate(surface);

      expect(
        issues.map((issue) => issue.path),
        containsAll([
          r'$.root.gap',
          r'$.root.children[0].component',
          r'$.root.children[1].instance',
          r'$.root.children[2].knobs.title',
          r'$.root.children[2].knobs.other',
          r'$.root.children[3].knobs.trailing',
        ]),
      );
      expect(
        issues.map((issue) => issue.message).join('\n'),
        contains('surface spacing requires a spacing entry'),
      );
    });

    test('respects the declared axis of registry spacing values', () {
      final surface = DesySurfaceDocument.parse('''
{"layout":"row","gap":"space.vertical","children":[]}
''');

      final issues = DesySurfaceValidator(_registry).validate(surface);

      expect(issues, hasLength(1));
      expect(issues.single.path, r'$.root.gap');
      expect(
        issues.single.message,
        contains('this layout position is horizontal'),
      );
    });

    test('accepts a surface composed only from legal registry data', () {
      final surface = DesySurfaceDocument.parse('''
{
  "layout":"padding",
  "padding":"space.medium",
  "child":{
    "layout":"column",
    "gap":8,
    "crossAxisAlignment":"start",
    "children":[
      {"component":"title.headerbar","knobs":{"title":"Hello"}},
      {"component":"card","knobs":{"trailing":"status.badge.ready"}}
    ]
  }
}
''');

      expect(DesySurfaceValidator(_registry).validate(surface), isEmpty);
    });

    test('accepts serializable ARGB values for literal color knobs', () {
      final surface = DesySurfaceDocument.parse('''
{"component":"color.box","knobs":{"color":2151961958}}
''');

      expect(DesySurfaceValidator(_registry).validate(surface), isEmpty);
    });

    test('accepts only declared strings for choice knobs', () {
      final valid = DesySurfaceDocument.parse('''
{"component":"visibility.label","knobs":{"visibility":"Disabled"}}
''');
      final invalid = DesySurfaceDocument.parse('''
{"component":"visibility.label","knobs":{"visibility":"Sometimes"}}
''');

      expect(DesySurfaceValidator(_registry).validate(valid), isEmpty);
      expect(
        DesySurfaceValidator(_registry).validate(invalid).single.message,
        contains('Automatic, Enabled, Disabled'),
      );
    });

    test('accepts ISO-8601 values for DateTime knobs', () {
      final component = DesyComponent(
        id: 'schedule.card',
        name: 'Schedule card',
        knobs: (knobs) => (
          startsAt: knobs.dateTime(
            'startsAt',
            initial: DateTime.utc(2026, 8, 15, 9, 30),
          ),
        ),
        build: (context, knobs) => Text(knobs.startsAt.value.toIso8601String()),
      );
      final registry = DesyRegistry(
        name: 'Surface DateTime',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [component],
      );
      final valid = DesySurfaceDocument.parse('''
{"component":"schedule.card","knobs":{"startsAt":"2026-08-15T09:30:00.000Z"}}
''');
      final invalid = DesySurfaceDocument.parse('''
{"component":"schedule.card","knobs":{"startsAt":"tomorrow"}}
''');

      expect(DesySurfaceValidator(registry).validate(valid), isEmpty);
      expect(
        DesySurfaceValidator(registry).validate(invalid).single.message,
        contains('ISO-8601'),
      );
    });

    test(
      'accepts ordered multi-instance values and rejects event bindings',
      () {
        final component = DesyComponent(
          id: 'feed',
          name: 'Feed',
          knobs: (knobs) => (
            children: knobs.widgetInstances(
              'children',
              options: const ['status.badge.ready', 'status.extra.waiting'],
            ),
            select: knobs.event('select'),
          ),
          build: (context, knobs) => Column(children: knobs.children.widgets),
          instances: (knobs) => const {},
        );
        final registry = DesyRegistry(
          name: 'Surface events',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            ..._registry.components,
            DesyStaticComponent(
              id: 'status.extra',
              name: 'Extra status',
              instances: {'waiting': (_) => const Text('Waiting')},
            ),
            component,
          ],
        );
        final legal = DesySurfaceDocument.parse('''
{"component":"feed","knobs":{"children":["status.badge.ready","status.extra.waiting"]}}
''');
        final illegal = DesySurfaceDocument.parse('''
{"component":"feed","knobs":{"select":{"action":"open"}}}
''');

        expect(DesySurfaceValidator(registry).validate(legal), isEmpty);
        expect(
          DesySurfaceValidator(registry).validate(illegal).single.message,
          contains('runtime adapter'),
        );
      },
    );

    test('same-axis nested scrolling is a non-blocking warning', () {
      final surface = DesySurfaceDocument.parse('''
{
  "layout":"scroll",
  "axis":"vertical",
  "child":{
    "layout":"scroll",
    "axis":"vertical",
    "child":{"component":"title.headerbar"}
  }
}
''');

      final issues = DesySurfaceValidator(_registry).validate(surface);

      expect(issues, hasLength(1));
      expect(issues.single.severity, DesySurfaceValidationSeverity.warning);
      expect(issues.single.isError, isFalse);
      expect(issues.single.path, r'$.root.child.axis');
    });
  });

  group('DesySurfacePreview', () {
    testWidgets(
      'renders real components with rows, columns, stacks, and spacing',
      (tester) async {
        final surface = DesySurfaceDocument.parse('''
{
  "layout":"padding",
  "padding":"space.medium",
  "child":{
    "layout":"column",
    "gap":8,
    "crossAxisAlignment":"start",
    "children":[
      {"id":"title.headerbar","knobs":{"title":"Testing Screen"}},
      {
        "layout":"row",
        "gap":4,
        "children":[
          {"component":"status.badge","instance":"ready"},
          {"layout":"spacer","width":12},
          {"component":"status.badge","knobs":{"label":"Waiting"}}
        ]
      },
      {
        "layout":"stack",
        "alignment":"bottomEnd",
        "children":[
          {"component":"title.headerbar","knobs":{"title":"Behind"}},
          {"component":"status.badge","instance":"ready"}
        ]
      }
    ]
  }
}
''');

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: DesySurfacePreview(registry: _registry, surface: surface),
          ),
        );

        expect(find.text('Testing Screen'), findsOneWidget);
        expect(find.text('Ready'), findsNWidgets(2));
        expect(find.text('Waiting'), findsOneWidget);
        expect(find.text('Behind'), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Stack), findsOneWidget);
        final outerPadding = tester.widget<Padding>(find.byType(Padding).first);
        expect(outerPadding.padding, const EdgeInsets.all(16));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('applies instance defaults before explicit knob overrides', (
      tester,
    ) async {
      final surface = DesySurfaceDocument.parse('''
{"component":"status.badge","instance":"ready","knobs":{"label":"Go"}}
''');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DesySurfacePreview(registry: _registry, surface: surface),
        ),
      );

      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('renders interactive horizontal and vertical scroll nodes', (
      tester,
    ) async {
      final surface = DesySurfaceDocument.parse('''
{
  "layout":"scroll",
  "axis":"vertical",
  "scrollbar":true,
  "child":{
    "layout":"scroll",
    "axis":"horizontal",
    "child":{"component":"title.headerbar","knobs":{"title":"Scrollable"}}
  }
}
''');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 200,
            height: 120,
            child: DesySurfacePreview(registry: _registry, surface: surface),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('surface-scroll-vertical')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('surface-scroll-horizontal')),
        findsOneWidget,
      );
      expect(find.byType(RawScrollbar), findsOneWidget);
      expect(find.text('Scrollable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders validation problems instead of unknown components', (
      tester,
    ) async {
      final surface = DesySurfaceDocument.parse('{"component":"missing"}');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DesySurfacePreview(registry: _registry, surface: surface),
        ),
      );

      expect(find.byType(ErrorWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

final _registry = DesyRegistry(
  name: 'Surface test system',
  themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
  measurements: const [
    DesyNumericEntry.spacing(
      id: 'space.medium',
      name: 'Medium space',
      value: 16,
    ),
    DesyNumericEntry.spacing(
      id: 'space.vertical',
      name: 'Vertical space',
      value: 12,
      axis: DesyNumericAxis.vertical,
    ),
    DesyNumericEntry.radius(
      id: 'radius.medium',
      name: 'Medium radius',
      value: 12,
    ),
  ],
  components: [
    DesyComponent(
      id: 'title.headerbar',
      name: 'Header bar',
      knobs: (knobs) => (title: knobs.string('title', initial: 'Title')),
      build: (context, knobs) => Text(knobs.title.value),
      instances: (knobs) => {
        'default': [knobs.title('Title')],
      },
    ),
    DesyComponent(
      id: 'status.badge',
      name: 'Status badge',
      knobs: (knobs) => (label: knobs.string('label', initial: 'Unknown')),
      build: (context, knobs) => Text(knobs.label.value),
      instances: (knobs) => {
        'ready': [knobs.label('Ready')],
      },
    ),
    DesyComponent(
      id: 'color.box',
      name: 'Color box',
      knobs: (knobs) =>
          (color: knobs.color('color', initial: const Color(0xff112233))),
      build: (context, knobs) => ColoredBox(color: knobs.color.value),
      instances: (knobs) => const {},
    ),
    DesyComponent(
      id: 'visibility.label',
      name: 'Visibility label',
      knobs: (knobs) => (
        visibility: knobs.choice(
          'visibility',
          options: const ['Automatic', 'Enabled', 'Disabled'],
        ),
      ),
      build: (context, knobs) => Text(knobs.visibility.value),
    ),
    DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (knobs) => (
        trailing: knobs.widgetInstance(
          'trailing',
          initial: 'status.badge.ready',
          options: ['status.badge.ready'],
        ),
      ),
      build: (context, knobs) => knobs.trailing.widget,
      instances: (knobs) => {
        'default': [knobs.trailing('status.badge.ready')],
      },
    ),
  ],
);

Widget _wrap(BuildContext context, Widget child) => child;
