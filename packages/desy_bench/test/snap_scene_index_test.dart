import 'dart:ui';

import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_models.dart';
import 'package:desy_bench/src/workbench/components_canvas/snapping/snap_scene_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scene index stores three sorted anchors per target and axis', () {
    final index = DesySnapSceneIndex(const [
      DesySnapTarget(id: 'later', rect: Rect.fromLTWH(100, 80, 40, 20)),
      DesySnapTarget(id: 'earlier', rect: Rect.fromLTWH(20, 10, 30, 40)),
    ]);

    expect(index.targetCount, 2);
    expect(index.anchorCount, 12);
    final visited = <DesySnapAnchor>[];
    index.visitNear(DesySnapAxis.x, 50, 0.01, visited.add);
    expect(visited, hasLength(1));
    expect(visited.single.target.id, 'earlier');
    expect(visited.single.kind, DesySnapAnchorKind.trailing);
  });

  test('scene index returns every target sharing a winning coordinate', () {
    final index = DesySnapSceneIndex(const [
      DesySnapTarget(id: 'b', rect: Rect.fromLTWH(100, 80, 40, 20)),
      DesySnapTarget(id: 'a', rect: Rect.fromLTWH(60, 10, 40, 40)),
      DesySnapTarget(id: 'other', rect: Rect.fromLTWH(240, 10, 30, 40)),
    ]);

    expect(
      index.targetsAt(DesySnapAxis.x, 100).map((target) => target.id).toList(),
      ['a', 'b'],
    );
  });

  test('tolerance lookup visits a bounded window in a large index', () {
    final index = DesySnapSceneIndex([
      for (var i = 0; i < 10000; i++)
        DesySnapTarget(
          id: 'node-$i',
          rect: Rect.fromLTWH(i * 20, i * 12, 8, 8),
        ),
    ]);
    var visits = 0;

    index.visitNear(DesySnapAxis.x, 100000, 6, (_) => visits++);

    expect(visits, lessThan(10));
  });
}
