import 'package:desy_bench/src/motion_playback.dart';
import 'package:desy_bench/src/registry.dart';
import 'package:desy_bench/src/workbench/presentation/atlas_screen.dart';
import 'package:desy_bench/src/workbench/presentation/detail_screen.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion entries require and expose an intended duration', () {
    final entry = DesyMotionEntry(
      id: 'motion.inherited',
      name: 'Inherited duration',
      duration: const Duration(milliseconds: 280),
      curve: Curves.linear,
      builder: _motionBuilder,
    );

    expect(entry.duration, const Duration(milliseconds: 280));
    expect(entry.displayValue, contains('280 ms'));
  });

  testWidgets(
    'motion details autoplay and expose one shared playback timeline',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var renderedProgress = 0.0;
      Duration? builderDuration;
      final registry = DesyRegistry(
        name: 'Motion test',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        motion: [
          DesyMotionEntry(
            id: 'motion.reveal',
            name: 'Reveal',
            duration: const Duration(milliseconds: 300),
            curve: Curves.linear,
            builder: (context, child, duration) {
              builderDuration = duration;
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
      expect(
        find.byKey(const ValueKey('motion-playhead-thermometer')),
        findsOneWidget,
      );
      expect(find.byType(FlutterLogo), findsOneWidget);
      expect(
        find.byKey(const ValueKey('motion-specimen-select')),
        findsNothing,
      );
      final durationField = find.byKey(
        const ValueKey('motion-global-duration'),
      );
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
        '300',
      );
      expect(find.text('Ping-pong'), findsOneWidget);
      expect(find.text('No controls declared.'), findsNothing);
      expect(builderDuration, const Duration(milliseconds: 300));

      await tester.enterText(durationField, '600');
      await tester.pump();
      expect(builderDuration, const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 50));
      expect(renderedProgress, closeTo(1 / 12, 0.05));

      _press(tester, const ValueKey('motion-play-pause'));
      await tester.pump();
      final pausedProgress = renderedProgress;
      await tester.pump(const Duration(milliseconds: 80));
      expect(renderedProgress, closeTo(pausedProgress, 0.001));

      _press(tester, const ValueKey('motion-loop-mode'));
      await tester.pump();
      expect(find.text('Once'), findsOneWidget);
      _press(tester, const ValueKey('motion-loop-mode'));
      await tester.pump();
      expect(find.text('Loop'), findsOneWidget);

      _press(tester, const ValueKey('motion-speed-mode'));
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
    DesyMotionEntry motion(String id, Duration duration) => DesyMotionEntry(
      id: id,
      name: id,
      duration: duration,
      curve: Curves.linear,
      builder: (context, child, _) {
        final playback = DesyMotionPlaybackScope.maybeOf(context)!;
        return AnimatedBuilder(
          animation: playback,
          builder: (context, _) {
            renderedProgress[id] = playback.value;
            return child;
          },
        );
      },
    );
    final registry = DesyRegistry(
      name: 'Global motion test',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      motion: [
        motion('motion.fast', const Duration(milliseconds: 100)),
        motion('motion.slow', const Duration(milliseconds: 200)),
        motion('motion.default', const Duration(milliseconds: 150)),
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
    expect(renderedProgress['motion.default'], closeTo(0, 0.001));

    _press(tester, const ValueKey('motion-play-pause'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(renderedProgress['motion.fast'], closeTo(0.25, 0.05));
    expect(renderedProgress['motion.slow'], closeTo(0.25, 0.05));
    expect(renderedProgress['motion.default'], closeTo(0.25, 0.05));

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

Widget _motionBuilder(BuildContext context, Widget child, Duration duration) =>
    child;

class _TestHarness extends StatelessWidget {
  const _TestHarness({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: FTheme(data: FTheme.neutral.light.desktop, child: child),
  );
}
