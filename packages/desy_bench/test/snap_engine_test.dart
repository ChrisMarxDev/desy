import 'dart:ui';

import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_engine.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_models.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_scene_index.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DesySnapEngine();

  test('move snaps adjacent element edges before the pixel grid', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 100, 50, 50)),
    ]);

    final result = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(57, 43, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );

    expect(result.rect, const Rect.fromLTWH(60, 40, 40, 20));
    expect(result.xSource, DesySnapSource.element);
    expect(result.ySource, DesySnapSource.grid);
    expect(result.guides.single.coordinate, 100);
  });

  test('element snap wins even when the grid correction is nearer', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 200, 50, 50)),
    ]);

    final result = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(95.5, 41, 20, 20),
        operation: DesySnapOperation.move,
      ),
    );

    expect(result.rect.left, 100);
    expect(result.xSource, DesySnapSource.element);
  });

  test('center anchors snap only to other centers', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 80, 40, 40)),
    ]);

    final result = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(101, 20, 38, 20),
        operation: DesySnapOperation.move,
      ),
    );

    expect(result.rect.center.dx, 120);
    expect(result.xSource, DesySnapSource.element);
  });

  test('snap lock holds until the larger release threshold is crossed', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 100, 50, 50)),
    ]);
    engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(57, 40, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );

    final held = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(68, 40, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );
    final released = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(72, 40, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );

    expect(held.rect.right, 100);
    expect(held.xSource, DesySnapSource.element);
    expect(released.xSource, DesySnapSource.grid);
  });

  test('screen scale converts acquisition tolerance to canvas units', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 100, 50, 50)),
    ], screenScale: 2);

    final result = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTWH(56, 40, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );

    expect(result.xSource, DesySnapSource.grid);
  });

  test('resize snaps only active edges and preserves the opposite edge', () {
    final session = _session(const [
      DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 100, 50, 50)),
    ]);

    final result = engine.resolve(
      session,
      const DesySnapRequest(
        rect: Rect.fromLTRB(20, 20, 97, 63),
        operation: DesySnapOperation.resize,
        edges: DesySnapEdges(right: true, bottom: true),
      ),
    );

    expect(result.rect.left, 20);
    expect(result.rect.top, 20);
    expect(result.rect.right, 100);
    expect(result.rect.bottom, 64);
    expect(result.xSource, DesySnapSource.element);
  });

  test('grid fallback preserves size while moving', () {
    final result = engine.resolve(
      _session(const []),
      const DesySnapRequest(
        rect: Rect.fromLTWH(11, 13, 37, 19),
        operation: DesySnapOperation.move,
      ),
    );

    expect(result.rect, const Rect.fromLTWH(8, 16, 37, 19));
    expect(result.xSource, DesySnapSource.grid);
    expect(result.ySource, DesySnapSource.grid);
  });

  test('aspect-authoritative resize uses one winning axis when needed', () {
    final result = engine.resolve(
      _session(const [
        DesySnapTarget(id: 'target', rect: Rect.fromLTWH(100, 100, 20, 20)),
      ]),
      const DesySnapRequest(
        rect: Rect.fromLTWH(20, 20, 77, 38.5),
        operation: DesySnapOperation.resize,
        edges: DesySnapEdges(right: true, bottom: true),
        aspectRatio: 2,
      ),
    );

    expect(result.rect.right, 100);
    expect(result.rect.size.aspectRatio, closeTo(2, 0.0001));
    expect(result.xSource, DesySnapSource.element);
    expect(result.ySource, DesySnapSource.none);
  });

  test('out-of-bounds element candidates are rejected', () {
    final result = engine.resolve(
      _session(const [
        DesySnapTarget(id: 'target', rect: Rect.fromLTWH(205, 20, 20, 20)),
      ]),
      const DesySnapRequest(
        rect: Rect.fromLTWH(165, 20, 35, 20),
        operation: DesySnapOperation.move,
        bounds: Rect.fromLTWH(0, 0, 200, 200),
      ),
    );

    expect(result.xSource, DesySnapSource.grid);
    expect(result.rect.right, lessThanOrEqualTo(200));
  });

  test('guide includes all collinear targets at the winning coordinate', () {
    final result = engine.resolve(
      _session(const [
        DesySnapTarget(id: 'b', rect: Rect.fromLTWH(100, 100, 20, 20)),
        DesySnapTarget(id: 'a', rect: Rect.fromLTWH(100, 160, 40, 20)),
      ]),
      const DesySnapRequest(
        rect: Rect.fromLTWH(57, 40, 40, 20),
        operation: DesySnapOperation.move,
      ),
    );

    final xGuide = result.guides.singleWhere(
      (guide) => guide.axis == DesySnapAxis.x,
    );
    expect(xGuide.targetIds, ['a', 'b']);
    expect(xGuide.start, 40);
    expect(xGuide.end, 180);
  });
}

DesySnapSession _session(
  List<DesySnapTarget> targets, {
  double screenScale = 1,
}) => DesySnapSession(
  index: DesySnapSceneIndex(targets),
  configuration: DesySnapConfiguration(gridStep: 8, screenScale: screenScale),
);
