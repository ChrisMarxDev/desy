import 'package:desy_bench/src/workbench/presentation/prototype_widget_tree.dart';
import 'package:desy_bench/src/workbench/workbench_annotation.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('derives a scoped widget anatomy from live prototype content', (
    tester,
  ) async {
    final scopeKey = GlobalKey();
    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 600,
            height: 400,
            child: DesyWorkbenchInspectionHost(
              controller: DesyWorkbenchInspectionController(),
              screenId: '/prototypes/test',
              target: null,
              onTargetSelected: (_) {},
              child: Column(
                children: [
                  DesyWorkbenchInspectionScope(
                    key: scopeKey,
                    context: const DesyWorkbenchInspectionContext(
                      artifactId: 'prototype.test',
                      kind: 'Prototype',
                    ),
                    child: const Column(
                      children: [Text('Live title'), SizedBox(height: 12)],
                    ),
                  ),
                  Expanded(
                    child: DesyPrototypeWidgetTree(
                      prototypeId: 'prototype.test',
                      scopeKey: scopeKey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('prototype-widget-tree')), findsOneWidget);
    expect(find.textContaining('Column'), findsOneWidget);
    expect(find.text('Text · Live title'), findsOneWidget);
  });
}
