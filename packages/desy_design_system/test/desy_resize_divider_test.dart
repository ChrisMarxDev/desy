import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'vertical resize divider owns one hairline and the complete interaction',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final deltas = <double>[];
      var starts = 0;
      var ends = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: DesyDesignSystemScope(
            theme: DesyDesignSystemTheme.light,
            child: Center(
              child: SizedBox(
                height: 200,
                child: DesyResizeDivider(
                  key: const ValueKey('divider'),
                  axis: Axis.vertical,
                  value: 240,
                  semanticsLabel: 'Resize registry sidebar',
                  onResizeStart: () => starts++,
                  onResize: deltas.add,
                  onResizeEnd: () => ends++,
                ),
              ),
            ),
          ),
        ),
      );

      final divider = find.byKey(const ValueKey('divider'));
      final line = find.descendant(
        of: divider,
        matching: find.byType(FDivider),
      );
      expect(tester.getSize(divider), const Size(8, 200));
      expect(line, findsOneWidget);
      expect(tester.getSize(line), const Size(1, 200));
      expect(tester.getSemantics(divider).label, 'Resize registry sidebar');
      expect(tester.getSemantics(divider).value, '240 pixels');

      await tester.drag(divider, const Offset(32, 0));
      await tester.pumpAndSettle();
      expect(starts, 1);
      expect(ends, 1);
      expect(deltas.fold(0.0, (sum, delta) => sum + delta), closeTo(32, .01));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(deltas.last, 24);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(deltas.last, -24);
      semantics.dispose();
    },
  );

  testWidgets('horizontal resize divider follows vertical drag and keys', (
    tester,
  ) async {
    final deltas = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: DesyDesignSystemScope(
          theme: DesyDesignSystemTheme.light,
          child: Center(
            child: SizedBox(
              width: 200,
              child: DesyResizeDivider(
                key: const ValueKey('divider'),
                axis: Axis.horizontal,
                value: 120,
                semanticsLabel: 'Resize lower panel',
                onResize: deltas.add,
              ),
            ),
          ),
        ),
      ),
    );

    final divider = find.byKey(const ValueKey('divider'));
    final line = find.descendant(of: divider, matching: find.byType(FDivider));
    expect(tester.getSize(divider), const Size(200, 8));
    expect(line, findsOneWidget);
    expect(tester.getSize(line), const Size(200, 1));

    await tester.drag(divider, const Offset(0, 20));
    await tester.pumpAndSettle();
    expect(deltas.fold(0.0, (sum, delta) => sum + delta), closeTo(20, .01));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(deltas.last, 24);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    expect(deltas.last, -24);
  });
}
