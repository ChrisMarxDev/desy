import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('animation components retain their playback fields', () {
    final component = DesyAnimationComponent<void>(
      id: 'component.inherited',
      name: 'Inherited duration',
      knobs: (_) {},
      builder: (_, _, _) => const SizedBox(),
      duration: const Duration(milliseconds: 280),
      curve: Curves.linear,
    );

    expect(component.duration, const Duration(milliseconds: 280));
    expect(component.curve, Curves.linear);
  });

  testWidgets('component details autoplay with one scrubbed timeline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var renderedProgress = 0.0;
    final registry = DesyRegistry(
      name: 'Component animation test',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyAnimationComponent<void>(
          id: 'component.reveal',
          name: 'Reveal',
          path: '/feedback',
          duration: const Duration(milliseconds: 300),
          curve: Curves.linear,
          knobs: (_) {},
          builder: (context, _, progress) => AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              renderedProgress = progress.value;
              return const FlutterLogo();
            },
          ),
        ),
      ],
    );
    final session = DesyWorkbenchSession(registry: registry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _Harness(
        child: DesyDetailScreen(
          session: session,
          entry: registry.resolve('component.reveal')!,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey('motion-playback-controls')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('desy-animation-scrubber-rail')),
      findsOneWidget,
    );
    expect(renderedProgress, greaterThan(0));

    final play = find.byKey(const ValueKey('motion-play-pause'));
    final duration = find.byKey(const ValueKey('motion-global-duration'));
    final loop = find.byKey(const ValueKey('motion-loop-mode'));
    expect(find.text('Once'), findsOneWidget);
    for (final control in [play, loop]) {
      expect(tester.getSize(control).height, 32);
      expect(
        tester.getCenter(control).dy,
        closeTo(tester.getCenter(duration).dy, 0.01),
      );
    }
    expect(tester.getSize(duration).height, 32);
    final durationTextField = tester.widget<TextField>(
      find.descendant(of: duration, matching: find.byType(TextField)),
    );
    expect(durationTextField.decoration?.labelText, 'ms');
    expect(durationTextField.decoration?.suffixIcon, isNull);
    expect(
      find.descendant(of: duration, matching: find.text('ms')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('motion-speed-mode')), findsNothing);
    expect(find.text('Playback speed'), findsNothing);
    expect(find.text('1.0×'), findsNothing);
    expect(find.text('2.0×'), findsNothing);

    _press(tester, const ValueKey('motion-loop-mode'));
    await tester.pump();
    expect(find.text('Loop'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(renderedProgress, lessThan(0.5));

    _press(tester, const ValueKey('motion-loop-mode'));
    await tester.pump();
    expect(find.text('Once'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(renderedProgress, closeTo(1, 0.001));

    await tester.enterText(duration, '12abc3');
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(of: duration, matching: find.byType(EditableText)),
          )
          .controller
          .text,
      '123',
    );
  });
}

void _press(WidgetTester tester, ValueKey<String> key) {
  tester.widget<DesyButton>(find.byKey(key)).onPress!.call();
}

Widget _wrap(BuildContext context, Widget child) => Material(child: child);

class _Harness extends StatelessWidget {
  const _Harness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FTheme(data: FTheme.neutral.light.desktop, child: child),
  );
}
