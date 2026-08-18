import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:desy_design_system_example/desy_design_system_example.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('compact dogfood previews keep their natural width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-/actions')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await _openAtlasEntry(tester, 'desy.component.button');
    final defaultViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    final specimenButton = find.descendant(
      of: defaultViewer,
      matching: find.byType(DesyButton),
    );
    final defaultArtboard = find.descendant(
      of: defaultViewer,
      matching: find.byKey(const ValueKey('detail-artboard')),
    );
    expect(
      tester.getSize(specimenButton).width,
      lessThan(tester.getSize(defaultArtboard).width),
    );

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-/feedback')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await _openAtlasEntry(tester, 'desy.component.badge');
    final badgeViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    expect(
      tester
          .getSize(
            find.descendant(of: badgeViewer, matching: find.byType(DesyBadge)),
          )
          .width,
      lessThan(
        tester
            .getSize(
              find.descendant(
                of: badgeViewer,
                matching: find.byKey(const ValueKey('detail-artboard')),
              ),
            )
            .width,
      ),
    );
  });

  testWidgets('launches the dogfood registry through the real workbench', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('REGISTRY'), findsNothing);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sketch'), findsNothing);
    expect(find.text('Prototypes'), findsWidgets);
    expect(find.text('JSON prototypes'), findsNothing);
    expect(
      find.byKey(const ValueKey('sidebar-section-label-Components')),
      findsOneWidget,
    );
  });

  testWidgets('opens the annotation inbox prototype session', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(
            const ValueKey(
              'prototype-session-desy.prototype-session.annotation-inbox',
            ),
          ),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    expect(find.text('Annotation inbox'), findsWidgets);
    expect(find.text('Review sheet'), findsOneWidget);
    expect(find.text('Annotation ledger'), findsOneWidget);
    expect(find.text('Focused queue'), findsOneWidget);
  });

  testWidgets('annotation review can be cancelled with Escape', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(
            const ValueKey(
              'prototype-session-desy.prototype-session.annotation-inbox',
            ),
          ),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    const dialogKey = ValueKey('annotation-review-dialog-reviewSheet');
    expect(find.byKey(dialogKey), findsOneWidget);
    expect(
      find.byKey(const ValueKey('annotation-cancel-reviewSheet')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('annotation-cancel-reviewSheet')),
        matching: find.text('Esc'),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byKey(dialogKey), findsNothing);
  });

  testWidgets('dogfood exposes its approved brand assets', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.assets.id}')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('assets-screen')), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('asset-card-desy.asset.workspace.signature.primary'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('asset-card-desy.asset.workspace.system-map')),
      findsOneWidget,
    );
    expect(find.text('desy-primary-mark.png'), findsOneWidget);
    expect(find.text('Download image'), findsWidgets);
  });

  testWidgets('switch Atlas preview keeps its label horizontal', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-/inputs')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();

    final switchCard = find.byKey(
      const ValueKey('atlas-card-desy.component.switch'),
    );
    final previewSwitch = find.descendant(
      of: switchCard,
      matching: find.byType(DesySwitch),
    );
    expect(tester.getSize(previewSwitch).width, greaterThan(0));
    final labelSize = tester.getSize(
      find.descendant(of: switchCard, matching: find.text('Show grid')),
    );
    expect(labelSize.width, greaterThan(labelSize.height));
  });

  testWidgets('dogfoods registry-backed swaps', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(DesyBenchApp(registry: desyDesignSystemRegistry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('sidebar-folder-/molecules/navigation')),
        )
        .onPress!
        .call();
    await tester.pumpAndSettle();
    await _openAtlasEntry(tester, 'desy.component.tile');

    final swapControl = find.byKey(
      const ValueKey('instance-swap-current-suffix'),
    );
    expect(swapControl, findsOneWidget);
    await tester.tap(swapControl);
    await tester.pumpAndSettle();

    final shortcutOption = find.byKey(
      const ValueKey(
        'instance-swap-option-desy.component.shortcut-label.single-key',
      ),
    );
    expect(shortcutOption, findsOneWidget);
    await tester.ensureVisible(shortcutOption);
    await tester.tap(shortcutOption);
    await tester.pumpAndSettle();

    final defaultViewer = find.byKey(
      const ValueKey('detail-instance-viewer-default'),
    );
    expect(
      find.descendant(
        of: defaultViewer,
        matching: find.byType(DesyKeyboardShortcutLabel),
      ),
      findsOneWidget,
    );
  });
}

Future<void> _openAtlasEntry(WidgetTester tester, String id) async {
  final card = find.byKey(ValueKey('atlas-card-$id'));
  await tester.ensureVisible(card);
  tester.widget<GestureDetector>(card).onTap!.call();
  await tester.pumpAndSettle();
}
