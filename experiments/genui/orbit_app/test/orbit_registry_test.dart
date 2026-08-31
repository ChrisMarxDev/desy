import 'package:flutter_test/flutter_test.dart';
import 'package:mrx_design_system/mrx_design_system.dart';
import 'package:orbit_app/orbit_registry.dart';

void main() {
  test('the Orbit consumer registers MRX widgets under the shared theme', () {
    expect(orbitRegistry.themes, hasLength(1));
    expect(orbitRegistry.themes.single.id, OrbitThemeData.standard.id);
    expect(orbitRegistry.components, hasLength(9));
  });
}
