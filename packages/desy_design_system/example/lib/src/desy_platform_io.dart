import 'dart:async';
import 'dart:io';

import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';

/// Applies Desy's maintained macOS window; other native targets no-op.
Future<void> prepareDesyPlatform() async {
  if (!Platform.isMacOS) return;

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1440, 900),
    minimumSize: Size(960, 640),
    center: true,
    backgroundColor: Color(0xffffffff),
    title: 'Desy Bench',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

/// Connects Desy's Flutter window chrome to the native host through
/// `window_manager`; non-macOS native targets keep their system chrome.
DesyWindowControls? createDesyWindowControls() {
  if (!Platform.isMacOS) return null;
  return DesyWindowControls(
    onClose: () => unawaited(windowManager.close()),
    onMinimize: () => unawaited(windowManager.minimize()),
    onToggleMaximize: () => unawaited(_toggleMaximize()),
    onSetBackgroundColor: (color) =>
        unawaited(windowManager.setBackgroundColor(color)),
  );
}

Future<void> _toggleMaximize() async {
  if (await windowManager.isMaximized()) {
    await windowManager.unmaximize();
  } else {
    await windowManager.maximize();
  }
}
