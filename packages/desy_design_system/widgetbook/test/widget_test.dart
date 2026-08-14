import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:desy_widgetbook/main.dart';

void main() {
  testWidgets('mounts the local Desy Widgetbook catalogue', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DesyWidgetbook());

    expect(find.byType(Widgetbook), findsOneWidget);
  });
}
