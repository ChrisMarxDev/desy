import 'package:mrx_design_system/mrx_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MRX exposes one canonical theme configuration', () {
    expect(OrbitThemeData.standard.id, 'orbit.theme');
    expect(OrbitThemeData.standard.isDark, isTrue);
    expect(MrxThemeData.standard.id, 'mrx.midnight');
  });

  testWidgets('MRX foundation values resolve through its inherited theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MrxTheme(child: Text('MRX foundation')),
      ),
    );

    final context = tester.element(find.text('MRX foundation'));
    expect(MrxTheme.of(context).colors.surface, MrxPalettes.midnight.surface);
    expect(MrxTextStyles.body(context).color, MrxPalettes.midnight.text);
    expect(MrxTokens.radiusLg, 10);
  });

  testWidgets('Orbit primitives resolve their visual tokens from context', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OrbitTheme(
            data: OrbitThemeData.standard,
            child: const OrbitSurface(child: Text('Context-bound surface')),
          ),
        ),
      ),
    );

    final decoration =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
            as BoxDecoration;
    expect(decoration.color, OrbitPalettes.standard.card);
    expect(decoration.border, isA<Border>());
  });

  testWidgets('the overflow menu opens and closes as an animated card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OrbitTheme(
            data: OrbitThemeData.standard,
            child: const OrbitAppMenu(
              label: 'More actions',
              items: [OrbitMenuItem(label: 'Archive', onPressed: null)],
            ),
          ),
        ),
      ),
    );

    final opacity = find.byType(AnimatedOpacity);
    expect(tester.widget<AnimatedOpacity>(opacity).opacity, 0);

    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(opacity).opacity, 1);
  });
}
