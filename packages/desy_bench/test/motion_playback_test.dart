import 'package:desy_bench/src/motion_playback.dart';
import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/presentation/atlas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion entries may inherit the global duration', () {
    final entry = DesyMotionEntry(
      id: 'motion.inherited',
      name: 'Inherited duration',
      curve: Curves.linear,
      builder: _motionBuilder,
      child: const DesyMotionChild.widget(
        id: 'square',
        name: 'Square',
        builder: _emptyBuilder,
      ),
    );

    expect(entry.duration, isNull);
    expect(entry.displayValue, contains('Global duration'));
  });

  testWidgets(
    'motion details autoplay and expose one shared playback timeline',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var renderedProgress = 0.0;
      final registry = DesyRegistry(
        name: 'Motion test',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        motion: [
          DesyMotionEntry(
            id: 'motion.reveal',
            name: 'Reveal',
            curve: Curves.linear,
            builder: (context, child) {
              final playback = DesyMotionPlaybackScope.maybeOf(context);
              expect(playback, isNotNull);
              return AnimatedBuilder(
                animation: playback!,
                builder: (context, child) {
                  renderedProgress = playback.value;
                  return child!;
                },
                child: child,
              );
            },
            child: const DesyMotionChild.widget(
              id: 'square',
              name: 'Square',
              builder: _motionTestChild,
            ),
            alternatives: const [
              DesyMotionChild.widget(
                id: 'wide-square',
                name: 'Wide square',
                builder: _motionTestChild,
              ),
            ],
          ),
        ],
      );
      final session = DesyWorkbenchSession(registry: registry);
      addTearDown(session.dispose);

      await tester.pumpWidget(
        _TestHarness(
          child: DesyDetailScreen(
            session: session,
            entry: registry.resolve('motion.reveal')!,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('motion-playback-controls')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('motion-playhead')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('motion-specimen-select')),
        findsOneWidget,
      );
      expect(find.text('Ping-pong'), findsOneWidget);
      expect(find.text('No controls declared.'), findsNothing);

      await tester.pump(const Duration(milliseconds: 50));
      expect(renderedProgress, closeTo(1 / 6, 0.05));

      _press(tester, const ValueKey('motion-play-pause'));
      await tester.pump();
      final pausedProgress = renderedProgress;
      expect(find.text('Play'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 80));
      expect(renderedProgress, closeTo(pausedProgress, 0.001));

      _press(tester, const ValueKey('motion-loop-mode'));
      await tester.pump();
      expect(find.text('Once'), findsOneWidget);
      _press(tester, const ValueKey('motion-loop-mode'));
      await tester.pump();
      expect(find.text('Loop'), findsOneWidget);

      _press(tester, const ValueKey('motion-speed-2.0'));
      await tester.pump();
      expect(find.text('2.0×'), findsOneWidget);

      _press(tester, const ValueKey('motion-play-pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(renderedProgress, isNot(closeTo(pausedProgress, 0.001)));
    },
  );

  testWidgets('Motion Atlas header controls one duration-aware global clock', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final renderedProgress = <String, double>{};
    DesyMotionEntry motion(String id, [Duration? duration]) => DesyMotionEntry(
      id: id,
      name: id,
      duration: duration,
      curve: Curves.linear,
      builder: (context, child) {
        final playback = DesyMotionPlaybackScope.maybeOf(context)!;
        return AnimatedBuilder(
          animation: playback,
          builder: (context, _) {
            renderedProgress[id] = playback.value;
            return child;
          },
        );
      },
      child: const DesyMotionChild.widget(
        id: 'square',
        name: 'Square',
        builder: _motionTestChild,
      ),
    );
    final registry = DesyRegistry(
      name: 'Global motion test',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      motion: [
        motion('motion.fast', const Duration(milliseconds: 100)),
        motion('motion.slow', const Duration(milliseconds: 200)),
        motion('motion.inherited'),
      ],
    );
    final session = DesyWorkbenchSession(registry: registry);
    addTearDown(session.dispose);

    await tester.pumpWidget(
      _TestHarness(
        child: DesyAtlasScreen(
          session: session,
          folderId: DesyAtomKind.motion.id,
          onOpen: (_) {},
        ),
      ),
    );

    final globalControls = find.byKey(
      const ValueKey('motion-global-playback-controls'),
    );
    expect(globalControls, findsOneWidget);
    final thermometer = find.byKey(
      const ValueKey('motion-playhead-thermometer'),
    );
    expect(thermometer, findsOneWidget);
    expect(tester.getSize(thermometer).width, 250);
    expect(find.text('Once'), findsOneWidget);
    final durationField = find.byKey(const ValueKey('motion-global-duration'));
    expect(durationField, findsOneWidget);
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: durationField,
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '200',
    );
    expect(
      tester.getTopLeft(globalControls).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('atlas-search'))).dy,
      ),
    );
    expect(
      tester.getCenter(durationField).dx,
      lessThan(
        tester.getCenter(find.byKey(const ValueKey('motion-loop-mode'))).dx,
      ),
    );
    expect(tester.getSize(durationField).height, 40);
    expect(
      tester.getSize(find.byKey(const ValueKey('motion-loop-mode'))).height,
      40,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('motion-speed-mode'))).height,
      40,
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('motion-loop-mode'))).dx,
      lessThan(tester.getCenter(thermometer).dx),
    );
    expect(
      tester.getCenter(thermometer).dx,
      lessThan(
        tester.getCenter(find.byKey(const ValueKey('motion-speed-mode'))).dx,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('motion-speed-mode'))).dy,
      closeTo(tester.getTopLeft(durationField).dy, 0.01),
    );

    await tester.pump(const Duration(milliseconds: 50));
    expect(renderedProgress['motion.fast'], closeTo(0, 0.001));
    expect(renderedProgress['motion.slow'], closeTo(0, 0.001));
    expect(renderedProgress['motion.inherited'], closeTo(0, 0.001));

    _press(tester, const ValueKey('motion-play-pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(renderedProgress['motion.fast'], closeTo(0.25, 0.05));
    expect(renderedProgress['motion.slow'], closeTo(0.25, 0.05));
    expect(renderedProgress['motion.inherited'], closeTo(0.25, 0.05));

    _press(tester, const ValueKey('motion-play-pause'));
    await tester.pump();
    final pausedFast = renderedProgress['motion.fast']!;
    final pausedSlow = renderedProgress['motion.slow']!;
    await tester.pump(const Duration(milliseconds: 60));
    expect(renderedProgress['motion.fast'], closeTo(pausedFast, 0.001));
    expect(renderedProgress['motion.slow'], closeTo(pausedSlow, 0.001));

    _press(tester, const ValueKey('motion-speed-mode'));
    await tester.pump();
    expect(find.text('2.0×'), findsOneWidget);

    await tester.enterText(durationField, '400');
    await tester.pump();
    expect(
      tester
          .widget<EditableText>(
            find.descendant(
              of: durationField,
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text,
      '400',
    );
  });
}

void _press(WidgetTester tester, ValueKey<String> key) {
  tester.widget<DesyButton>(find.byKey(key)).onPress!.call();
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _emptyBuilder(BuildContext context) => const SizedBox.shrink();

Widget _motionBuilder(BuildContext context, Widget child) => child;

Widget _motionTestChild(BuildContext context) =>
    const SizedBox(width: 120, height: 52);

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FTheme(data: FTheme.neutral.light.desktop, child: child),
  );
}
