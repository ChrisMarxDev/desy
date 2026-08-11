import 'package:flutter/widgets.dart';

import 'detail_extension.dart';
import 'registry.dart';
import 'workbench/workbench_app.dart';
import 'workbench/annotation_workspace.dart';
import 'workspace_extension.dart';
import 'window_controls.dart';

/// A polished Forui workbench for a consumer-owned [DesyRegistry].
class DesyBenchApp extends StatelessWidget {
  /// Creates the Desy Bench application.
  const DesyBenchApp({
    super.key,
    required this.registry,
    this.extensions = const [],
    this.detailExtensions = const [],
    this.windowControls,
    this.annotations,
  });

  /// The consumer-owned system shown by the workbench.
  final DesyRegistry registry;

  /// Optional workspace screens supplied by separately installed packages.
  final List<DesyWorkspaceExtension> extensions;

  /// Optional entry-scoped sections rendered in the detail inspector.
  final List<DesyDetailExtension> detailExtensions;

  /// Optional Flutter-rendered host-window actions.
  final DesyWindowControls? windowControls;

  /// Optional local review persistence and export destinations.
  final DesyAnnotationWorkspace? annotations;

  @override
  Widget build(BuildContext context) => DesyWorkbenchApp(
    registry: registry,
    extensions: extensions,
    detailExtensions: detailExtensions,
    windowControls: windowControls,
    annotations: annotations,
  );
}
