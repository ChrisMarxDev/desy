import 'package:flutter/widgets.dart';

import 'desy_design_system_example.dart';
import 'src/desy_platform.dart';

/// Launches the catalogue for Desy's own workbench design system.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await prepareDesyPlatform();

  runApp(
    buildDesyDesignSystemDogfoodApp(windowControls: createDesyWindowControls()),
  );
}
