import 'package:flutter_test/flutter_test.dart';
import 'package:object_canvas_example/main.dart';

void main() {
  testWidgets('mixed object canvas example mounts', (tester) async {
    await tester.pumpWidget(const DemoApp());
    expect(find.text('External controls'), findsOneWidget);
    expect(find.text('Any real Flutter widget'), findsOneWidget);
  });
}
