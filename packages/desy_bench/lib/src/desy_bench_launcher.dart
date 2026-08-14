import 'package:flutter/widgets.dart';

import 'desy_bench_app.dart';
import 'detail_extension.dart';
import 'registry.dart';
import 'workbench/annotation_workspace.dart';
import 'workspace_extension.dart';
import 'window_controls.dart';
import 'window_platform.dart';

/// Prepares the host platform and runs a [DesyBenchApp].
///
/// This is the default executable entrypoint for a standalone Desy catalogue.
/// Embed [DesyBenchApp] directly when the workbench is part of a larger app.
Future<void> runDesyBenchApp({
  required DesyRegistry registry,
  List<DesyWorkspaceExtension> extensions = const [],
  List<DesyDetailExtension> detailExtensions = const [],
  DesyWindowControls? windowControls,
  DesyAnnotationWorkspace? annotations,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  await prepareDesyPlatform();

  runApp(
    DesyBenchApp(
      registry: registry,
      extensions: extensions,
      detailExtensions: detailExtensions,
      windowControls: windowControls ?? createDesyWindowControls(),
      annotations: annotations,
    ),
  );
}
