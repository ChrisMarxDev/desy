import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('host bezel background follows the active workbench theme', (
    tester,
  ) async {
    final appliedColors = <Color>[];
    await tester.pumpWidget(
      DesyBenchApp(
        registry: DesyRegistry(
          name: 'Window background',
          themes: [
            const DesyTheme(id: 'light', name: 'Light', wrap: _wrap),
            const DesyTheme(
              id: 'dark',
              name: 'Dark',
              wrap: _wrap,
              isDark: true,
            ),
          ],
        ),
        windowControls: DesyWindowControls(
          onClose: () {},
          onMinimize: () {},
          onToggleMaximize: () {},
          onSetBackgroundColor: appliedColors.add,
        ),
      ),
    );
    await tester.pump();

    expect(appliedColors, [const Color(0xffffffff)]);

    await tester.tap(find.byKey(const ValueKey('top-bar-theme-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('top-bar-theme-dark')));
    await tester.pumpAndSettle();

    expect(appliedColors, [const Color(0xffffffff), const Color(0xff0f0f10)]);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
