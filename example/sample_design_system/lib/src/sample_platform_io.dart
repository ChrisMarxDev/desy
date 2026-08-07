import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Native debug inspection resolves source relative to the launch directory.
String get sampleSourceRoot => Directory.current.path;

/// Applies the maintained macOS catalogue window; other native targets no-op.
Future<void> prepareSamplePlatform() async {
  if (!Platform.isMacOS) return;

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(960, 640),
    center: true,
    backgroundColor: Color(0xfff8fbf9),
    title: 'Desy Bench',
    titleBarStyle: TitleBarStyle.hidden,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}
