import 'package:desy_bench/desy_bench.dart';

import 'orbit_registry.dart';

/// Runs Orbit as a local design-system workbench.
///
/// The workbench is deliberately the only executable surface: it previews the
/// real Orbit widgets under their one shared consumer theme.
void main() => runDesyBenchApp(registry: orbitRegistry);
