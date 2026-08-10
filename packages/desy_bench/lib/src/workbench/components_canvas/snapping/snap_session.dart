// Internal gesture-scoped Sketch snapping state.
// ignore_for_file: public_member_api_docs

import 'snap_models.dart';
import 'snap_scene_index.dart';

class DesySnapSession {
  DesySnapSession({
    required this.index,
    required this.configuration,
    this.excludedTargetId,
  });

  final DesySnapSceneIndex index;
  final DesySnapConfiguration configuration;
  final String? excludedTargetId;
  DesySnapLock? _xLock;
  DesySnapLock? _yLock;

  DesySnapLock? lockFor(DesySnapAxis axis) =>
      axis == DesySnapAxis.x ? _xLock : _yLock;

  void setLock(DesySnapAxis axis, DesySnapLock? lock) {
    if (axis == DesySnapAxis.x) {
      _xLock = lock;
    } else {
      _yLock = lock;
    }
  }

  void clear() {
    _xLock = null;
    _yLock = null;
  }
}
