import 'dart:io';

import 'package:desy_bench/desy_bench.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:simdeck_flutter_inspector/simdeck_flutter_inspector.dart';
import 'package:window_manager/window_manager.dart';

import 'sample_design_system.dart';

/// Launches the sample consumer's Desy Bench catalogue.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    startSimDeckFlutterInspector(
      port: 4310,
      sourceRoot: Directory.current.path,
    );
  }

  if (Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(960, 640),
      center: true,
      backgroundColor: Color(0xfff8fbf9),
      title: 'Desy Bench',
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    DesyBenchApp(
      registry: sampleRegistry,
      extensions: const [DesyScreenshotBuilderExtension()],
    ),
  );
}
