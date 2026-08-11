import 'package:desy_bench/desy_bench.dart';

/// Browser builds need no desktop window preparation.
Future<void> prepareDesyPlatform() async {}

/// Browser builds have no host-window actions.
DesyWindowControls? createDesyWindowControls() => null;
