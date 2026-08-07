import 'package:flutter/widgets.dart';

import 'detail_extension.dart';
import 'registry.dart';
import 'workbench/workbench_app.dart';
import 'workspace_extension.dart';

/// A polished Forui workbench for a consumer-owned [DesyRegistry].
class DesyBenchApp extends StatelessWidget {
  /// Creates the Desy Bench application.
  const DesyBenchApp({
    super.key,
    required this.registry,
    this.extensions = const [],
    this.detailExtensions = const [],
  });

  /// The consumer-owned system shown by the workbench.
  final DesyRegistry registry;

  /// Optional workspace screens supplied by separately installed packages.
  final List<DesyWorkspaceExtension> extensions;

  /// Optional component-scoped sections rendered in the detail inspector.
  final List<DesyDetailExtension> detailExtensions;

  @override
  Widget build(BuildContext context) => DesyWorkbenchApp(
    registry: registry,
    extensions: extensions,
    detailExtensions: detailExtensions,
  );
}
