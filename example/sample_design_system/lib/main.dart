import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:simdeck_flutter_inspector/simdeck_flutter_inspector.dart';

import 'src/agent_annotations/agent_annotation_sink.dart';
import 'src/sample_platform.dart';
import 'sample_design_system.dart';

/// Launches the sample consumer's Desy Bench catalogue.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await prepareSamplePlatform();

  final sourceRoot = sampleSourceRoot;
  if (kDebugMode && sourceRoot != null) {
    startSimDeckFlutterInspector(port: 4310, sourceRoot: sourceRoot);
  }

  runApp(
    DesyBenchApp(
      registry: sampleRegistry,
      extensions: const [DesyScreenshotBuilderExtension()],
      detailExtensions: [
        DesyAgentAnnotationsExtension(
          onSubmit: createSampleAgentAnnotationSubmit(),
        ),
      ],
    ),
  );
}
