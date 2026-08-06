import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/presentation/workbench_sidebar.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  testWidgets('a deep-linked entry expands every sidebar ancestor', (
    tester,
  ) async {
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Deep link',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        folders: [
          DesyFolder(
            id: 'one',
            name: 'One',
            children: [
              DesyFolder(
                id: 'one.two',
                name: 'Two',
                children: [
                  DesyFolder(
                    id: 'one.two.three',
                    name: 'Three',
                    components: [_component('deep.component')],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    addTearDown(session.dispose);

    await tester.pumpWidget(
      FTheme(
        data: FTheme.neutral.light.desktop,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: DesyWorkbenchSidebar(
            session: session,
            location: Uri.parse('/entries/deep.component'),
          ),
        ),
      ),
    );

    for (final id in ['one', 'one.two', 'one.two.three']) {
      expect(
        tester
            .widget<FSidebarItem>(find.byKey(ValueKey('sidebar-folder-$id')))
            .initiallyExpanded,
        isTrue,
      );
    }
  });
}

DesyComponent _component(String id) =>
    DesyComponent(id: id, name: id, preview: (_) => const SizedBox());

Widget _wrap(BuildContext context, Widget child) => child;
