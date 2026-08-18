import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home shows component previews without an atom text ledger', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Acme System',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      systemProfile: DesySystemProfile(
        id: 'acme.profile',
        summary: 'Unused by the compact Home overview.',
      ),
      colors: const [
        DesyColorEntry(
          id: 'acme.color.ink',
          name: 'Ink',
          color: Color(0xff111111),
        ),
      ],
      components: [
        DesyStaticComponent(
          id: 'acme.button',
          name: 'Button',
          instances: const {'default': _buttonPreview},
        ),
      ],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-overview')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('atlas-card-acme.button')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('atlas-card-acme.button')),
        matching: find.byKey(const ValueKey('home-button-preview')),
      ),
      findsOneWidget,
    );
    expect(find.text('ATOMS'), findsNothing);
    expect(find.text('COLORS'), findsNothing);
    expect(find.text('Ink'), findsNothing);
    expect(find.byKey(const ValueKey('consumer-hero')), findsNothing);
    expect(find.text('Clarity before decoration'), findsNothing);
    expect(find.byKey(const ValueKey('registry-home-nav')), findsOneWidget);
  });

  testWidgets('minimal registries can open the Home catalogue', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 760));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Minimal',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('home-overview')), findsNothing);

    tester
        .widget<DesySidebarItem>(
          find.byKey(const ValueKey('registry-home-nav')),
        )
        .onPress!();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('home-overview')), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('No components registered.'), findsOneWidget);
  });

  testWidgets('assets have a focused packaged-image collection surface', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final registry = DesyRegistry(
      name: 'Brand assets',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      assets: [
        const DesyAssetEntry(
          id: 'asset.logo.primary',
          fileName: 'primary.png',
          assetKey: 'assets/primary.png',
          description: 'Use on light neutral surfaces.',
        ),
        const DesyAssetEntry(
          id: 'asset.campaign.launch',
          fileName: 'launch.png',
          assetKey: 'assets/launch.png',
          description: 'Use for approved launch material.',
        ),
      ],
    );

    await tester.pumpWidget(DesyBenchApp(registry: registry));
    await tester.pumpAndSettle();

    tester
        .widget<DesySidebarItem>(
          find.byKey(ValueKey('sidebar-folder-${DesyAtomKind.assets.id}')),
        )
        .onPress!();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('assets-screen')), findsOneWidget);
    expect(find.text('Assets'), findsWidgets);
    expect(
      find.byKey(const ValueKey('asset-card-asset.logo.primary')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('asset-card-asset.campaign.launch')),
      findsOneWidget,
    );
    expect(find.text('primary.png'), findsOneWidget);
    expect(find.text('Use on light neutral surfaces.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('asset-download-asset.logo.primary')),
      findsOneWidget,
    );
  });
}

Widget _wrap(BuildContext context, Widget child) => Material(child: child);

Widget _buttonPreview(BuildContext context) =>
    const Text('Continue', key: ValueKey('home-button-preview'));
