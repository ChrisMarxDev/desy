import 'package:desy_genui/desy_genui.dart';
import 'package:desy_genui_example/orbit/orbit_components.dart';
import 'package:desy_genui_example/orbit/orbit_registry.dart';
import 'package:desy_genui_example/orbit/orbit_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart' as md;
import 'package:flutter_mermaid/flutter_mermaid.dart' as mermaid;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Orbit exposes a stable, themed GenUI component catalog', () {
    final compiled = DesyGenUiCatalog.compile(orbitRegistry);

    expect(
      orbitRegistry.themes.map((theme) => theme.id),
      containsAll(<String>['orbit.theme.midnight', 'orbit.theme.daylight']),
    );
    expect(orbitRegistry.components, hasLength(17));
    expect(
      orbitRegistry.components.map((component) => component.path),
      containsAll(<String>[
        '/layout',
        '/actions/buttons',
        '/conversation/insights',
        '/agent/approval',
        '/data/tickets',
        '/content/rich-text',
        '/content/diagrams',
        '/data/charts',
        '/data/sources',
      ]),
    );
    expect(compiled.catalog.catalogId, 'demo.orbit-genui@0.2.0');
    expect(
      compiled.catalog.items.map((item) => item.name),
      containsAll(<String>[
        'orbit.component.approval',
        'orbit.component.button',
        'orbit.component.icon-button',
        'orbit.component.tool-activity',
        'orbit.component.ticket-list',
        'orbit.component.markdown',
        'orbit.component.mermaid',
        'orbit.component.bar-chart',
        'orbit.component.pie-chart',
        'orbit.component.source',
      ]),
    );
  });

  testWidgets('Orbit renders Markdown and Mermaid as native content blocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OrbitTheme(
            data: OrbitThemeData.midnight,
            child: const Column(
              children: [
                OrbitMarkdownCard(
                  title: 'Decision brief',
                  markdown: '## Evidence\n\n**Ship** the guided flow.',
                ),
                OrbitMermaidDiagramCard(
                  title: 'Decision flow',
                  code: 'flowchart LR\n  Start --> Ship',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(md.MarkdownBody), findsOneWidget);
    expect(find.byType(mermaid.MermaidDiagram), findsOneWidget);
  });
}
