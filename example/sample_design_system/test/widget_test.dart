import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';
import 'package:flutter/material.dart'
    show Brightness, InputBorder, SelectionArea, TextField, Theme;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:sample_design_system/sample_design_system.dart';

Widget _sampleBench() => DesyBenchApp(
  registry: sampleRegistry,
  extensions: const [DesyScreenshotBuilderExtension()],
);

void main() {
  testWidgets('renders consumer components in Desy Bench', (tester) async {
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    expect(find.byType(SelectionArea), findsOneWidget);
    expect(find.text('DESY BENCH'), findsWidgets);
    expect(find.text('Primary button'), findsWidgets);
  });

  testWidgets('uses a native Flutter editor for shared text entry', (
    tester,
  ) async {
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    final field = find.byKey(const ValueKey('atlas-search'));
    final editor = find.descendant(of: field, matching: find.byType(TextField));
    expect(editor, findsOneWidget);
    final decoration = tester.widget<TextField>(editor).decoration!;
    expect(decoration.hintText, 'Search');
    expect(decoration.labelText, isNull);
    expect(decoration.errorText, isNull);
    expect(decoration.filled, isFalse);
    expect(decoration.border, InputBorder.none);
    expect(
      find.descendant(of: field, matching: find.byType(EditableText)),
      findsOneWidget,
    );

    await tester.tap(editor);
    await tester.enterText(editor, 'navigation');
    await tester.pumpAndSettle();

    expect(find.text('Navigation row'), findsWidgets);
  });

  testWidgets('mounts an installed workspace extension below Workspace', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_sampleBench());

    await tester.tap(
      find.byKey(const ValueKey('workspace-extension-screenshot-builder')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Screenshot builder'), findsWidgets);
    expect(find.text('Recipe draft'), findsOneWidget);
    expect(find.text('Theme · Daylight'), findsOneWidget);
  });

  testWidgets('switches the live preview theme from the sidebar menu', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.byKey(const ValueKey('sidebar-theme-select')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('sidebar-theme-harbor.midnight')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Midnight'), findsWidgets);
    expect(
      tester
          .widgetList<Theme>(find.byType(Theme))
          .any((theme) => theme.data.brightness == Brightness.dark),
      isTrue,
    );
    expect(
      Theme.of(
        tester.element(find.byKey(const ValueKey('workbench-sidebar'))),
      ).brightness,
      Brightness.dark,
    );
  });

  testWidgets('traverses the registry-derived navigation tree with shortcuts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_sampleBench());

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(find.text('Screen sketch'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workbench-sidebar')), findsOneWidget);
  });

  testWidgets('folds and restores each top-level sidebar section', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_sampleBench());

    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-workspace-header')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('showcases-nav')), findsNothing);

    // The chevron remains an equivalent disclosure control.
    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-workspace-toggle')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('showcases-nav')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('sidebar-section-catalogue-header')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Colors'), findsNothing);
    expect(find.text('Action'), findsNothing);
  });

  testWidgets('collapses and restores the desktop sidebar', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    expect(
      find.byKey(const ValueKey('desktop-sidebar-collapse')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('desktop-sidebar-collapse')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workbench-sidebar')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('workbench-sidebar'))).width,
      0,
    );
    expect(
      find.byKey(const ValueKey('desktop-sidebar-restore')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('desktop-sidebar-restore')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('workbench-sidebar')), findsOneWidget);
  });

  testWidgets('renders the experimental consumer showcase', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.byKey(const ValueKey('showcases-nav')));
    await tester.pumpAndSettle();

    expect(find.text('EXPERIMENTAL'), findsOneWidget);
    expect(find.text('Berth brief'), findsOneWidget);
    expect(find.text('Publish schedule'), findsOneWidget);
  });

  testWidgets('opens the color, font, effects, and assets atlas screens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    final colors = find.byKey(const ValueKey('sidebar-folder-atoms.colors'));
    tester.widget<FSidebarItem>(colors).onPress!.call();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Color in context.'), findsOneWidget);

    final fonts = find.byKey(const ValueKey('sidebar-folder-atoms.fonts'));
    tester.widget<FSidebarItem>(fonts).onPress!.call();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Type styles'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('font-preview-text')),
      'Dockside signal',
    );
    await tester.pumpAndSettle();
    expect(find.text('Dockside signal'), findsWidgets);

    final effects = find.byKey(const ValueKey('sidebar-folder-atoms.effects'));
    tester.widget<FSidebarItem>(effects).onPress!.call();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('Floating surface'), findsWidgets);

    final assets = find.byKey(const ValueKey('sidebar-folder-atoms.assets'));
    tester.widget<FSidebarItem>(assets).onPress!.call();
    await tester.pumpAndSettle();
    expect(find.text('Application mark'), findsWidgets);
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('keeps the ShellRoute sidebar while inspecting an entry', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    tester
        .widget<FSidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-components.action')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Primary button').last);
    await tester.pumpAndSettle();

    expect(find.text('DESY BENCH'), findsOneWidget);
    expect(find.text('Back'), findsNothing);
    expect(find.byType(DesyKeyboardShortcutLabel), findsNothing);
    expect(find.text('Esc'), findsNothing);
    expect(find.text('Primary button'), findsWidgets);
  });

  testWidgets('adapts nested component-instance preset values for knobs', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    tester
        .widget<FSidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-components.content')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Content card').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('North quay · delayed'));
    await tester.pumpAndSettle();

    expect(find.text('North quay delayed'), findsWidgets);
  });

  testWidgets('switches detail previews between the two sample bezels', (
    tester,
  ) async {
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.text('Primary button').last);
    await tester.pumpAndSettle();
    final toolbar = find.byKey(const ValueKey('detail-preview-toolbar'));
    expect(toolbar, findsOneWidget);
    final breadcrumbs = find.byKey(const ValueKey('detail-breadcrumbs'));
    expect(breadcrumbs, findsOneWidget);
    expect(
      find.descendant(of: breadcrumbs, matching: find.text('Components')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: breadcrumbs, matching: find.text('Action')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Breadcrumb Components, Action, Primary button'),
      findsOneWidget,
    );
    expect(tester.getSize(toolbar).height, greaterThanOrEqualTo(36));
    final canvas = find.byKey(const ValueKey('detail-preview-canvas'));
    final artboard = find.byKey(const ValueKey('detail-artboard'));
    expect(find.byKey(const ValueKey('detail-selection-size')), findsOneWidget);
    expect(find.text('320 × 240 px'), findsOneWidget);
    expect(
      tester.getRect(toolbar).top,
      greaterThan(tester.getRect(canvas).top),
    );
    expect(tester.getRect(artboard).left - tester.getRect(canvas).left, 88);
    expect(
      tester.getRect(artboard).top,
      greaterThanOrEqualTo(tester.getRect(toolbar).bottom + 2),
    );
    await tester.tap(find.text('iPhone 15 Pro'));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('iPhone 15 Pro preview bezel'),
      findsOneWidget,
    );
    final phoneSelection = tester.getSize(artboard);
    expect(phoneSelection.height, greaterThan(phoneSelection.width));
    expect(
      tester.getSize(find.widgetWithText(FButton, 'Publish schedule')).height,
      lessThan(100),
    );

    await tester.tap(find.text('iPad Pro 11'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('iPad Pro 11 preview bezel'), findsOneWidget);
    final tabletSelection = tester.getSize(artboard);
    expect(
      tabletSelection.aspectRatio,
      greaterThan(phoneSelection.aspectRatio),
    );
    expect(tabletSelection.width, greaterThan(phoneSelection.width));
  });

  testWidgets('renders atlas previews at their natural widget size', (
    tester,
  ) async {
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    final preview = find.widgetWithText(FButton, 'Publish schedule');
    expect(preview, findsOneWidget);
    expect(tester.getSize(preview).height, lessThan(100));
  });

  testWidgets('selecting a named instance renders that exact instance', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    final navigationRow = find.text('Navigation row').last;
    await tester.tap(navigationRow);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Today’s schedule'));
    await tester.pumpAndSettle();

    expect(find.text('Six confirmed arrival windows'), findsOneWidget);
  });

  testWidgets('renders typed numeric entries on the Measurements board', (
    tester,
  ) async {
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    tester
        .widget<FSidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-atoms.measurements')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    expect(
      find.text('Compare the geometry that gives components their rhythm.'),
      findsOneWidget,
    );
    expect(find.text('Compact threshold'), findsWidgets);
  });

  testWidgets('offers named component instances as palette tree leaves', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.text('Components').first);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('palette-folder-components.action')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('palette-folder-components.action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('palette-component-harbor.button.primary')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Publish schedule'), findsOneWidget);
  });

  testWidgets('preserves intermediate registry folders in the palette', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.text('Components').first);
    await tester.pumpAndSettle();
    final operations = find.byKey(
      const ValueKey('palette-folder-components.operations'),
    );
    await tester.ensureVisible(operations);
    await tester.tap(operations);
    await tester.pumpAndSettle();
    final overview = find.byKey(
      const ValueKey('palette-folder-components.operations.overview'),
    );
    await tester.ensureVisible(overview);
    await tester.tap(overview);
    await tester.pumpAndSettle();
    final metrics = find.byKey(
      const ValueKey('palette-folder-components.operations.overview.metrics'),
    );
    await tester.ensureVisible(metrics);
    await tester.tap(metrics);
    await tester.pumpAndSettle();
    final metric = find.byKey(
      const ValueKey('palette-component-harbor.metric.operational'),
    );
    await tester.ensureVisible(metric);
    await tester.tap(metric);
    await tester.pumpAndSettle();

    expect(find.text('Available berths'), findsWidgets);
  });

  testWidgets(
    'selecting a palette instance reveals its knobs in the inspector',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

      await tester.tap(find.text('Components').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('palette-folder-components.action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('palette-component-harbor.button.primary')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Publish schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Knobs'), findsOneWidget);
      expect(find.text('Action label'), findsNothing);
    },
  );

  testWidgets('canvas outline tracks selection from the sketch stage', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.text('Components').first);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('palette-folder-components.action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('palette-component-harbor.button.primary')),
    );
    await tester.pumpAndSettle();
    final publishSchedule = find.byKey(
      const ValueKey('palette-instance-harbor.button.primary.publish-schedule'),
    );
    await tester.tap(publishSchedule);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('sketch-tab-layers')));
    await tester.pumpAndSettle();

    expect(find.text('LAYERS'), findsOneWidget);
    expect(find.text('1 element'), findsOneWidget);
    final firstNode = find.byKey(
      const ValueKey('canvas-node-harbor.button.primary.publish-schedule#0'),
    );
    expect(tester.widget<FTile>(firstNode).selected, isTrue);

    final background = tester.getRect(
      find.byKey(const ValueKey('sketch-background')),
    );
    await tester.tapAt(Offset(background.right - 20, background.bottom - 20));
    await tester.pumpAndSettle();
    expect(tester.widget<FTile>(firstNode).selected, isFalse);

    await tester.tap(
      find.byKey(
        const ValueKey('canvas-hit-harbor.button.primary.publish-schedule#0'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FTile>(firstNode).selected, isTrue);

    await tester.tapAt(Offset(background.right - 20, background.bottom - 20));
    await tester.pumpAndSettle();
    expect(tester.widget<FTile>(firstNode).selected, isFalse);

    await tester.tap(firstNode);
    await tester.pumpAndSettle();

    expect(tester.widget<FTile>(firstNode).selected, isTrue);
    expect(find.text('Publish schedule'), findsWidgets);
  });

  testWidgets(
    'opens the sketch as a child route with a collapsed shell sidebar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

      await tester.tap(find.text('Components').first);
      await tester.pumpAndSettle();

      expect(find.text('Screen sketch'), findsOneWidget);
      expect(find.byKey(const ValueKey('workbench-sidebar')), findsNothing);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Components'), findsWidgets);
      expect(
        tester.getSize(find.byKey(const ValueKey('workbench-sidebar'))).width,
        greaterThan(0),
      );
    },
  );

  testWidgets('adds a device bezel as a movable sketch artboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    await tester.tap(find.text('Components').first);
    await tester.pumpAndSettle();
    final toolbar = find.byKey(const ValueKey('sketch-preview-toolbar'));
    expect(toolbar, findsOneWidget);
    expect(tester.getSize(toolbar).height, greaterThanOrEqualTo(42));
    await tester.tap(
      find.byKey(const ValueKey('sketch-add-artboard-iPhone15Pro')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('artboard.iPhone15Pro#0')),
      findsOneWidget,
    );
  });

  testWidgets('keeps compact navigation reachable on a phone-sized surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(402, 874));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(DesyBenchApp(registry: sampleRegistry));

    expect(find.text('Navigate'), findsOneWidget);
    await tester.tap(find.text('Navigate'));
    await tester.pumpAndSettle();

    expect(find.text('DESY BENCH'), findsWidgets);
    expect(find.text('Measurements'), findsOneWidget);
  });
}
