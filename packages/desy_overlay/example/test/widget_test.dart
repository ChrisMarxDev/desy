import 'package:desy_overlay_example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example mounts the app and compact overlay controls', (
    tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('Delivery dashboard'), findsOneWidget);
    expect(find.byKey(const ValueKey('desy-overlay-controls')), findsOneWidget);
  });
}
