import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';

import 'desy_design_system_registry.dart';

/// Builds Desy's maintained dogfood catalogue with its optional extensions.
Widget buildDesyDesignSystemDogfoodApp({DesyWindowControls? windowControls}) =>
    DesyBenchApp(
      registry: desyDesignSystemRegistry,
      windowControls: windowControls,
    );
