import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/desy_drag_box.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('component previews keep popup menus interactive', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final component = DesyStaticComponent(
      id: 'menu',
      name: 'Menu',
      instances: {
        'default': (_) => PopupMenuButton<String>(
          key: const ValueKey('component-menu-trigger'),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'inspect', child: Text('Inspect action')),
          ],
          child: const Text('Open menu'),
        ),
      },
    );
    final registry = DesyRegistry(
      name: 'Interactive preview',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );
    final entry = registry.resolve(component.id)!;
    final session = DesyWorkbenchSession(registry: registry)
      ..prepareEntry(entry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyDetailScreen(session: session, entry: entry),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('component-menu-trigger')));
    await tester.pumpAndSettle();

    expect(find.text('Inspect action'), findsOneWidget);
  });

  testWidgets(
    'size presets start full size, resize freely, and remain movable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final component = DesyStaticComponent(
        id: 'device-preview',
        name: 'Device preview',
        instances: {'default': (_) => const SizedBox.expand()},
      );
      final registry = DesyRegistry(
        name: 'Device preview',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        components: [component],
      );
      final entry = registry.resolve(component.id)!;
      final session = DesyWorkbenchSession(registry: registry)
        ..prepareEntry(entry);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        FTheme(
          data: FTheme.neutral.light.desktop,
          child: MaterialApp(
            home: Scaffold(
              body: DesyDetailScreen(session: session, entry: entry),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controls = tester.widgetList<DesyKnobSheet>(
        find.byType(DesyKnobSheet),
      );
      expect(
        controls.map((sheet) => sheet.segments.map((segment) => segment.title)),
        [
          ['COMPONENT'],
          ['CANVAS', 'ACCESSIBILITY', 'IMAGE'],
        ],
      );
      expect(find.text(component.id), findsOneWidget);

      session.selectPreviewDevice(DesyDevicePreset.iPhone15Pro);
      await tester.pumpAndSettle();

      final artboard = find.byKey(const ValueKey('detail-artboard'));
      expect(tester.getSize(artboard), DesyDevicePreset.iPhone15Pro.screenSize);

      final resizeHandle = find.byKey(
        const ValueKey('detail-resize-default-bottomRight'),
      );
      await tester.drag(resizeHandle, const Offset(40, 0));
      await tester.pumpAndSettle();
      final resized = tester.getSize(artboard);
      expect(
        resized.width,
        greaterThan(DesyDevicePreset.iPhone15Pro.screenSize.width),
      );
      expect(
        resized.height,
        DesyDevicePreset.iPhone15Pro.screenSize.height,
        reason: 'a named size does not lock the artboard aspect ratio',
      );
      expect(
        tester
            .widget<DesyDragBoxLabel>(
              find.byKey(const ValueKey('detail-selection-size')),
            )
            .size,
        resized,
      );

      final before = tester.getTopLeft(artboard);
      final gesture = await tester.startGesture(
        before + const Offset(64, 64),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(48, 24));
      await gesture.moveBy(const Offset(1, 1));
      await gesture.up();
      await tester.pumpAndSettle();

      final afterMove = tester.getTopLeft(artboard);
      expect(afterMove.dx, greaterThan(before.dx));
      expect(afterMove.dy, greaterThan(before.dy));
    },
  );

  testWidgets('device-sized artboard starts unscaled and supports zoom', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1050, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final component = DesyStaticComponent(
      id: 'zoomable-device-preview',
      name: 'Zoomable device preview',
      instances: {'default': (_) => const SizedBox.expand()},
    );
    final registry = DesyRegistry(
      name: 'Zoomable device preview',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );
    final entry = registry.resolve(component.id)!;
    final session = DesyWorkbenchSession(registry: registry)
      ..prepareEntry(entry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyDetailScreen(session: session, entry: entry),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    session.selectPreviewDevice(DesyDevicePreset.iPhone15Pro);
    await tester.pumpAndSettle();

    final zoomLevel = find.byKey(const ValueKey('detail-canvas-zoom-level'));
    final initialLabel = tester.widget<Semantics>(zoomLevel).properties.label!;
    expect(initialLabel, 'Zoom 100 percent');

    await tester.tap(find.byKey(const ValueKey('detail-canvas-zoom-in')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Semantics>(zoomLevel).properties.label,
      isNot(initialLabel),
    );

    final zoomOut = find.byKey(const ValueKey('detail-canvas-zoom-out'));
    for (var count = 0; count < 8; count++) {
      await tester.tap(zoomOut);
      await tester.pumpAndSettle();
    }
    expect(
      tester.widget<Semantics>(zoomLevel).properties.label,
      'Zoom 50 percent',
    );
  });

  testWidgets('selecting an instance binds its knobs to that viewer', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      knobs: (k) => (
        label: k.string('label', name: 'Label', initial: 'Default'),
        enabled: k.boolean('enabled', name: 'Enabled', initial: true),
      ),
      build: (context, knobs) =>
          Text('${knobs.label.value} · ${knobs.enabled.value}'),
      instances: (knobs) => {
        'default': [knobs.label('Default')],
        'alpha': [knobs.label('Alpha')],
        'bravo': [knobs.label('Bravo')],
      },
    );
    final registry = DesyRegistry(
      name: 'Editable instances',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );
    final entry = registry.resolve('action')!;
    final session = DesyWorkbenchSession(registry: registry)
      ..prepareEntry(entry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: MaterialApp(
          home: Scaffold(
            body: DesyDetailScreen(session: session, entry: entry),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final controls = tester.widgetList<DesyKnobSheet>(
      find.byType(DesyKnobSheet),
    );
    expect(
      controls.map((sheet) => sheet.segments.map((segment) => segment.title)),
      [
        ['COMPONENT'],
        ['CANVAS', 'ACCESSIBILITY', 'IMAGE'],
      ],
    );
    expect(find.text(component.id), findsOneWidget);
    expect(find.text('Editing Default'), findsNothing);
    expect(find.text('Default · true'), findsOneWidget);
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(find.text('Bravo · true'), findsOneWidget);
    final defaultRect = tester.getRect(
      find.byKey(const ValueKey('detail-artboard')),
    );
    final alphaRect = tester.getRect(
      find.byKey(const ValueKey('detail-instance-artboard-instance-alpha')),
    );
    final bravoRect = tester.getRect(
      find.byKey(const ValueKey('detail-instance-artboard-instance-bravo')),
    );
    expect(alphaRect.top, greaterThan(defaultRect.bottom));
    expect(bravoRect.top, greaterThan(alphaRect.bottom));

    await tester.tap(
      find.byKey(const ValueKey('detail-instance-artboard-instance-bravo')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editing Bravo'), findsNothing);
    expect(session.selectedComponentInstance.value?.instanceId, 'bravo');
    expect(session.knobValues.value, {'label': 'Bravo', 'enabled': true});
    final bravoSelector = tester.widget<Semantics>(
      find.byKey(const ValueKey('detail-instance-selector-instance-bravo')),
    );
    expect(bravoSelector.properties.selected, isTrue);

    tester
        .widget<DesyBooleanKnobRow>(
          find.byWidgetPredicate(
            (widget) =>
                widget is DesyBooleanKnobRow && widget.label == 'Enabled',
          ),
        )
        .onChanged!(false);
    await tester.pumpAndSettle();

    expect(session.knobValues.value, {'label': 'Bravo', 'enabled': false});
    expect(find.text('Bravo · false'), findsOneWidget);
    expect(find.text('Default · true'), findsOneWidget);
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(session.selectedComponentInstance.value?.instanceId, 'bravo');

    await tester.tap(
      find.byKey(const ValueKey('detail-instance-artboard-instance-alpha')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Editing Alpha'), findsNothing);
    expect(session.selectedComponentInstance.value?.instanceId, 'alpha');
    expect(session.knobValues.value, {'label': 'Alpha', 'enabled': true});
    expect(find.text('Alpha · true'), findsOneWidget);
    expect(find.text('Bravo · true'), findsOneWidget);
    expect(find.text('Bravo · false'), findsNothing);

    final controlsPanel = find.byKey(const ValueKey('detail-controls-panel'));
    final controlsResizeHandle = find.byKey(
      const ValueKey('detail-controls-resize-handle'),
    );
    final initialControlsWidth = tester.getSize(controlsPanel).width;
    await tester.drag(controlsResizeHandle, const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(controlsPanel).width,
      greaterThan(initialControlsWidth),
    );
    expect(
      tester.widget<DesyResizeDivider>(controlsResizeHandle).semanticsLabel,
      'Resize controls panel',
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
