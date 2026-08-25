import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart' show SelectableText;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('detail folder breadcrumbs navigate back to the matching Atlas', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Breadcrumb navigation',
          themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
          components: [
            DesyStaticComponent(
              id: 'button.primary',
              name: 'Primary button',
              path: '/actions',
              instances: {'default': _preview},
            ),
          ],
        ),
      ),
    );

    tester.semantics.tap(find.semantics.byLabel('Open Primary button'));
    await tester.pumpAndSettle();

    final breadcrumb = tester.widget<SelectableText>(
      find.byKey(const ValueKey('detail-breadcrumbs')),
    );
    expect(
      breadcrumb.textSpan?.toPlainText(includeSemanticsLabels: false),
      'all/ Actions / Primary button',
    );
    final rootSpan = breadcrumb.textSpan!.children!.first as TextSpan;
    expect(rootSpan.mouseCursor, SystemMouseCursors.click);
    expect(rootSpan.style?.decoration, TextDecoration.underline);
    final folderSpan = breadcrumb.textSpan!.children![2] as TextSpan;
    expect(folderSpan.mouseCursor, SystemMouseCursors.click);
    expect(folderSpan.style?.decoration, TextDecoration.underline);
    expect(find.semantics.byLabel('Open all/'), findsOneWidget);
    expect(find.semantics.byLabel('Open Actions'), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Open all/'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('atlas-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('atlas-breadcrumbs')), findsOneWidget);
    final headline = tester.widget<Text>(
      find.byKey(const ValueKey('atlas-headline')),
    );
    expect(headline.textSpan?.toPlainText(), startsWith('Components'));
    expect(find.text('Primary button'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('atlas-card-button.primary')));
    await tester.pumpAndSettle();
    tester.semantics.tap(find.semantics.byLabel('Open Actions'));
    await tester.pumpAndSettle();
    final folderHeadline = tester.widget<Text>(
      find.byKey(const ValueKey('atlas-headline')),
    );
    expect(folderHeadline.textSpan?.toPlainText(), startsWith('Actions'));
    semantics.dispose();
  });
}

Widget _preview(BuildContext context) => const SizedBox();

Widget _wrap(BuildContext context, Widget child) => child;
