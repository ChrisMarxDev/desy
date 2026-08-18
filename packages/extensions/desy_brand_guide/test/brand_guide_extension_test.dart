import 'package:desy_bench/desy_bench.dart';
import 'package:desy_brand_guide/desy_brand_guide.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares a read-only workbench extension and immutable guidance', () {
    final doExamples = <String>['Ship the clear answer.'];
    final config = DesyBrandGuideConfig(
      voice: [
        DesyVoicePrinciple(
          id: 'voice.clear',
          title: 'Say the true thing',
          guidance: 'Prefer direct, verifiable language.',
          doExamples: doExamples,
        ),
      ],
      imagery: DesyImageryGuidance(
        summary: 'Candid product work in natural light.',
        assetIds: const ['asset.photo'],
      ),
    );
    final extension = DesyBrandGuideExtension(config: config);
    doExamples.clear();

    expect(extension.id, 'brand-guide');
    expect(extension.name, 'Brand guide');
    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.workbench,
    );
    expect(extension.icon, isNotNull);
    expect(config.voice.single.doExamples, ['Ship the clear answer.']);
    expect(() => config.voice.clear(), throwsUnsupportedError);
    expect(() => config.imagery!.assetIds.clear(), throwsUnsupportedError);
  });

  test('rejects duplicate narrative and imagery identities', () {
    DesyVoicePrinciple voice(String id) =>
        DesyVoicePrinciple(id: id, title: id, guidance: id);

    expect(
      () => DesyBrandGuideConfig(voice: [voice('same'), voice('same')]),
      throwsArgumentError,
    );
    expect(
      () => DesyImageryGuidance(
        summary: 'Duplicate',
        assetIds: const ['asset', 'asset'],
      ),
      throwsArgumentError,
    );
  });

  testWidgets('assembles populated guide sections from the active registry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final registry = _registry();
    final extension = DesyBrandGuideExtension(
      config: DesyBrandGuideConfig(
        logoAssetIds: const ['asset.logo'],
        voice: [
          DesyVoicePrinciple(
            id: 'voice.direct',
            title: 'Direct, never inflated',
            guidance: 'State the useful fact and stop.',
            doExamples: const ['Saved.'],
            dontExamples: const ['Amazing! Your changes were saved!'],
          ),
        ],
        imagery: DesyImageryGuidance(
          summary: 'Show the work, not a staged abstraction of it.',
          assetIds: const ['asset.photo', 'asset.missing'],
        ),
      ),
    );

    await tester.pumpWidget(
      DesyBenchApp(registry: registry, extensions: [extension]),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('workspace-extension-brand-guide')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('brand-guide-screen')), findsOneWidget);
    expect(find.text('Acme Design System'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('brand-guide-introduction')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('brand-guide-logo')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-asset-asset.logo')), findsWidgets);

    final guideScroll = find
        .descendant(
          of: find.byKey(const ValueKey('brand-guide-screen')),
          matching: find.byType(Scrollable),
        )
        .first;
    Future<void> reveal(String key) => tester.scrollUntilVisible(
      find.byKey(ValueKey(key)),
      360,
      scrollable: guideScroll,
    );

    await reveal('brand-guide-color');
    expect(find.byKey(const ValueKey('brand-guide-color')), findsOneWidget);
    await reveal('brand-guide-typography');
    expect(
      find.byKey(const ValueKey('brand-guide-typography')),
      findsOneWidget,
    );
    await reveal('brand-guide-motion');
    expect(find.byKey(const ValueKey('brand-guide-motion')), findsOneWidget);
    await reveal('brand-guide-voice');
    expect(find.byKey(const ValueKey('brand-guide-voice')), findsOneWidget);
    expect(find.text('Direct, never inflated'), findsOneWidget);
    await reveal('brand-guide-imagery');
    expect(find.byKey(const ValueKey('brand-guide-imagery')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-asset-asset.photo')), findsWidgets);
    expect(find.textContaining('1 imagery reference'), findsOneWidget);
    await reveal('brand-guide-assets');
    expect(find.byKey(const ValueKey('brand-guide-assets')), findsOneWidget);
  });

  testWidgets('omits every empty optional section', (tester) async {
    tester.view.physicalSize = const Size(1000, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final registry = DesyRegistry(
      name: 'Minimal system',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    await tester.pumpWidget(
      DesyBenchApp(registry: registry, extensions: [DesyBrandGuideExtension()]),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('workspace-extension-brand-guide')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('brand-guide-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-guide-contents')), findsNothing);
    expect(find.byKey(const ValueKey('brand-guide-logo')), findsNothing);
    expect(find.byKey(const ValueKey('brand-guide-voice')), findsNothing);
    expect(find.byKey(const ValueKey('brand-guide-assets')), findsNothing);
  });
}

DesyRegistry _registry() => DesyRegistry(
  name: 'Acme Design System',
  themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
  systemProfile: DesySystemProfile(
    id: 'acme.profile',
    summary: 'The language shared by every Acme product.',
    purpose: 'Make complex work feel direct.',
    heroAssetId: 'asset.logo',
    principles: const [
      DesySystemPrinciple(
        id: 'principle.real',
        title: 'Show the real thing',
        guidance: 'Use production widgets and approved resources.',
      ),
    ],
  ),
  colors: const [
    DesyColorEntry(id: 'color.ink', name: 'Ink', color: Color(0xff111111)),
  ],
  fonts: [
    DesyTypographyEntry(
      id: 'type.body',
      name: 'Body',
      sample: 'Clear product language.',
      builder: (context, text) => Text(text),
    ),
  ],
  motion: [
    DesyMotionEntry(
      id: 'motion.enter',
      name: 'Enter',
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      builder: (context, child, duration) => child,
    ),
  ],
  assets: const [
    DesyAssetEntry(
      id: 'asset.logo',
      fileName: 'primary-logo.png',
      assetKey: 'assets/primary-logo.png',
      description: 'Use with generous clear space.',
    ),
    DesyAssetEntry(
      id: 'asset.photo',
      fileName: 'product-work.png',
      assetKey: 'assets/product-work.png',
      description: 'Use to show real product work.',
    ),
  ],
);

Widget _wrap(BuildContext context, Widget child) => Material(child: child);
