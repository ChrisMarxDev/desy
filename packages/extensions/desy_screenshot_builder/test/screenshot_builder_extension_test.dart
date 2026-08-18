import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:object_canvas/object_canvas.dart';

void main() {
  const extension = DesyScreenshotBuilderExtension();

  test('declares a standalone ephemeral workspace boundary', () {
    expect(extension.id, 'screenshot-builder');
    expect(extension.name, 'Screenshot builder');
    expect(
      extension.description,
      'Compose and export an ephemeral image from your real design system.',
    );
    expect(extension.icon, isNotNull);
    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.standalone,
    );
    expect(extension, isA<DesyWorkspaceExtension>());
  });

  testWidgets('offers elements, scene, and page workflows', (tester) async {
    final context = _extensionContext();
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_harness(extension, context));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('EXPERIMENTAL'), findsOneWidget);
    expect(find.byKey(const ValueKey('elements-tab')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('screenshot-object-canvas')),
      findsOneWidget,
    );
    expect(
      (tester.widget(find.byKey(const ValueKey('screenshot-object-canvas')))
              as ObjectCanvas<dynamic>)
          .marqueeSelectionEnabled,
      isFalse,
    );
    expect(
      (tester.widget(find.byKey(const ValueKey('screenshot-object-canvas')))
              as ObjectCanvas<dynamic>)
          .controller
          .overflow,
      CanvasOverflow.show,
    );
    expect(
      find.byKey(const ValueKey('screenshot-canvas-zoom-level')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Semantics>(
            find.byKey(const ValueKey('screenshot-canvas-zoom-level')),
          )
          .properties
          .label,
      'Zoom 100 percent',
    );
    expect(find.byKey(const ValueKey('scene-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-tab')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-text-element')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-screenshot-catalog')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('add-misc-phoneBezel')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-misc-statusBar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('screenshot-layer-inspector-empty')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('add-widget-action.publish.default')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('add-widget-action.publish.default')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final elementSurface = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('object-canvas-object-widget-0')),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == Colors.transparent,
        ),
      ),
    );
    expect(elementSurface.color, Colors.transparent);
    expect(
      find.byKey(const ValueKey('screenshot-layer-inspector-content')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('screenshot-layer-inspector')))
          .dx,
      greaterThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('screenshot-object-canvas')))
            .dx,
      ),
    );
    expect(find.text('Label'), findsWidgets);
    expect(find.byKey(const ValueKey('layer-forward')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-hide')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-duplicate')), findsOneWidget);
    expect(find.byKey(const ValueKey('layer-delete')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('layer-duplicate')));
    await tester.pumpAndSettle();
    final canvas = tester.widget<ObjectCanvas<DesyScreenshotLayer>>(
      find.byKey(const ValueKey('screenshot-object-canvas')),
    );
    expect(canvas.controller.objects, hasLength(2));
    expect(canvas.controller.objects.last.id, isNot('widget-0'));
    expect(
      canvas.controller.objects.last.data.id,
      canvas.controller.objects.last.id,
    );

    await tester.tap(find.byKey(const ValueKey('scene-tab')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Publish · Default'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('layer-hide')));
    await tester.pump();
    expect(find.text('Show'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('page-tab')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('page-size-preset-control')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('page-width-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-height-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('page-theme-control')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('page-background-control')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('export-screenshot')), findsOneWidget);
    expect(find.textContaining('500 × 500 pixels'), findsOneWidget);

    await tester.tap(find.text('Instagram').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('iPhone 16').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('393 × 852 pixels'), findsOneWidget);
  });

  testWidgets('opens a visual catalog and adds component-only layers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness(extension, _extensionContext()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('open-screenshot-catalog')));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('screenshot-catalog-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('screenshot-catalog-grid')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('screenshot-catalog-component-action.publish')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('screenshot-catalog-component-display.card')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('screenshot-catalog-component-display.card')),
    );
    await tester.pumpAndSettle();

    final canvas = tester.widget<ObjectCanvas<DesyScreenshotLayer>>(
      find.byKey(const ValueKey('screenshot-object-canvas')),
    );
    final layer = canvas.controller.objects.single.data;
    expect(layer, isA<DesyScreenshotWidgetLayer>());
    final widgetLayer = layer as DesyScreenshotWidgetLayer;
    expect(widgetLayer.componentId, 'display.card');
    expect(widgetLayer.instanceId, isNull);
    expect(find.text('Component'), findsOneWidget);
    expect(find.text('Display card'), findsWidgets);
  });

  testWidgets('adds misc mockup overlays from elements', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness(extension, _extensionContext()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-misc-phoneBezel')));
    await tester.pumpAndSettle();

    var canvas = tester.widget<ObjectCanvas<DesyScreenshotLayer>>(
      find.byKey(const ValueKey('screenshot-object-canvas')),
    );
    expect(canvas.controller.objects.single.data.kindLabel, 'Misc');
    expect(find.text('Phone bezel'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('add-misc-statusBar')));
    await tester.pumpAndSettle();

    canvas = tester.widget<ObjectCanvas<DesyScreenshotLayer>>(
      find.byKey(const ValueKey('screenshot-object-canvas')),
    );
    expect(canvas.controller.objects, hasLength(2));
    expect(
      canvas.controller.objects.map((object) => object.data.kindLabel),
      everyElement('Misc'),
    );
  });

  testWidgets('adds editable registry-styled text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness(extension, _extensionContext()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-text-element')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('text-content-control')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('text-align-left-control')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('text-align-center-control')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('text-align-right-control')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('text-style-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('text-color-control')), findsOneWidget);
    expect(find.text('Your text'), findsWidgets);
    expect(find.text('Ink'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('text-align-center-control')));
    await tester.pumpAndSettle();

    final canvas = tester.widget<ObjectCanvas<DesyScreenshotLayer>>(
      find.byKey(const ValueKey('screenshot-object-canvas')),
    );
    final textLayer = canvas.controller.objects
        .map((object) => object.data)
        .whereType<DesyScreenshotTextLayer>()
        .single;
    expect(textLayer.textAlign, TextAlign.center);
    expect(
      tester
          .widget<DesyButton>(
            find.descendant(
              of: find.byKey(const ValueKey('text-align-center-control')),
              matching: find.byType(DesyButton),
            ),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('stacks the selected element inspector on compact layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_harness(extension, _extensionContext()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-text-element')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey('screenshot-layer-inspector-content')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('screenshot-inspector-resize-handle')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('text-content-control')), findsOneWidget);
  });
}

DesyWorkspaceExtensionContext _extensionContext() {
  final component = DesyComponent<({Knob<String> label})>(
    id: 'action.publish',
    name: 'Publish',
    path: '/actions',
    defaultSize: const Size(120, 44),
    knobs: (scope) =>
        (label: scope.string('label', name: 'Label', initial: 'Publish')),
    build: (context, knobs) =>
        SizedBox(width: 120, height: 44, child: Text(knobs.label.value)),
    instances: (knobs) => {'default': const []},
  );
  final card = DesyComponent<({Knob<String> title})>(
    id: 'display.card',
    name: 'Display card',
    path: '/display',
    defaultSize: const Size(220, 140),
    knobs: (scope) =>
        (title: scope.string('title', name: 'Title', initial: 'Card')),
    build: (context, knobs) => SizedBox(
      width: 220,
      height: 140,
      child: Center(child: Text(knobs.title.value)),
    ),
  );
  final registry = DesyRegistry(
    name: 'Acme',
    themes: const [
      DesyTheme(
        id: 'light',
        name: 'Light',
        previewBackgroundColor: Colors.white,
        wrap: _wrap,
      ),
    ],
    colors: const [DesyColorEntry(id: 'ink', name: 'Ink', color: Colors.black)],
    fonts: const [
      DesyTypographyEntry(id: 'body', name: 'Body', builder: _buildBody),
    ],
    components: [component, card],
  );
  return DesyWorkspaceExtensionContext(
    registry: registry,
    activeTheme: registry.themes.single,
  );
}

Widget _harness(
  DesyScreenshotBuilderExtension screenshotBuilder,
  DesyWorkspaceExtensionContext extensionContext,
) => MaterialApp(
  home: FTheme(
    data: FTheme.neutral.light.desktop,
    child: Builder(
      builder: (context) => screenshotBuilder.build(context, extensionContext),
    ),
  ),
);

Widget _wrap(BuildContext context, Widget child) => child;

Widget _buildBody(BuildContext context, String text) => Text(text);
