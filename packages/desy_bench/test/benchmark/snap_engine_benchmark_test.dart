import 'dart:ui';

import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_engine.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_models.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_scene_index.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _benchmarkEnabled = bool.fromEnvironment('DESY_SNAP_BENCHMARK');

void main() {
  test(
    'snap resolution stays within the desktop/web p95 budget',
    () {
      const counts = [100, 1000, 10000];
      final budgetMicros = kIsWeb ? 2000 : 1000;
      for (final count in counts) {
        final targets = [
          for (var index = 0; index < count; index++)
            DesySnapTarget(
              id: 'node-${index.toString().padLeft(5, '0')}',
              rect: Rect.fromLTWH(
                (index % 250) * 19,
                (index ~/ 250) * 17,
                12,
                10,
              ),
            ),
        ];
        final buildWatch = Stopwatch()..start();
        final index = DesySnapSceneIndex(targets);
        buildWatch.stop();
        final session = DesySnapSession(
          index: index,
          configuration: const DesySnapConfiguration(gridStep: 8),
        );
        const engine = DesySnapEngine();

        for (var iteration = 0; iteration < 200; iteration++) {
          session.clear();
          engine.resolve(session, _request(iteration));
        }

        final samples = <int>[];
        var maximumVisited = 0;
        for (var iteration = 0; iteration < 1000; iteration++) {
          session.clear();
          final watch = Stopwatch()..start();
          final result = engine.resolve(session, _request(iteration));
          watch.stop();
          samples.add(watch.elapsedMicroseconds);
          if (result.examinedAnchors > maximumVisited) {
            maximumVisited = result.examinedAnchors;
          }
        }
        samples.sort();
        final p50 = samples[(samples.length * .50).floor()];
        final p95 = samples[(samples.length * .95).floor()];
        debugPrint(
          'snap-benchmark targets=$count '
          'index_us=${buildWatch.elapsedMicroseconds} '
          'p50_us=$p50 p95_us=$p95 max_anchors=$maximumVisited '
          'platform=${kIsWeb ? 'web' : 'desktop-vm'}',
        );

        expect(
          p95,
          lessThan(budgetMicros),
          reason: '$count targets exceeded the $budgetMicros µs p95 budget',
        );
        expect(
          maximumVisited,
          lessThan(100),
          reason: 'resolution should inspect a coordinate window, not a scene',
        );
      }
    },
    skip: _benchmarkEnabled
        ? false
        : 'Run task bench:benchmark:snap or bench:benchmark:snap:web.',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

DesySnapRequest _request(int iteration) {
  final jitter = (iteration % 9) * .17;
  return DesySnapRequest(
    rect: Rect.fromLTWH(2341 + jitter, 311 + jitter, 80, 48),
    operation: DesySnapOperation.move,
  );
}
