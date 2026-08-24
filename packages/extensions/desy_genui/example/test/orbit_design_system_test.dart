import 'package:desy_genui/desy_genui.dart';
import 'package:desy_genui_example/orbit/orbit_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Orbit exposes a stable, themed GenUI component catalog', () {
    final compiled = DesyGenUiCatalog.compile(orbitRegistry);

    expect(
      orbitRegistry.themes.map((theme) => theme.id),
      containsAll(<String>['orbit.theme.midnight', 'orbit.theme.daylight']),
    );
    expect(orbitRegistry.components, hasLength(10));
    expect(
      orbitRegistry.components.map((component) => component.path),
      containsAll(<String>[
        '/layout',
        '/conversation/insights',
        '/agent/approval',
        '/data/sources',
      ]),
    );
    expect(compiled.catalog.catalogId, 'demo.orbit-genui@0.2.0');
    expect(
      compiled.catalog.items.map((item) => item.name),
      containsAll(<String>[
        'orbit.component.approval',
        'orbit.component.tool-activity',
        'orbit.component.source',
      ]),
    );
  });
}
