import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';

import 'desy_design_system_example.dart';

/// Launches the catalogue for Desy's own workbench design system.
Future<void> main() => runDesyBenchApp(
  registry: desyDesignSystemRegistry,
  extensions: const [DesyScreenshotBuilderExtension()],
);
