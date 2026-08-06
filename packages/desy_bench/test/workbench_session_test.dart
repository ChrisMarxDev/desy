import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session rejects component knob values outside declared options', () {
    final allowed = DesyComponentInstance.widget(
      id: 'status.clear',
      name: 'Clear',
      builder: _emptyPreview,
    );
    final unrelated = DesyComponentInstance.widget(
      id: 'button.publish',
      name: 'Publish',
      builder: _emptyPreview,
    );
    final knob = DesyComponentKnob(
      id: 'trailing',
      name: 'Trailing',
      initial: allowed,
      options: [allowed],
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Session',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      ),
    );

    session.setKnob(knob, allowed);
    expect(session.knobValues.value['trailing'], same(allowed));
    expect(() => session.setKnob(knob, unrelated), throwsArgumentError);

    session.dispose();
  });
}

Widget _emptyPreview(BuildContext context) => const SizedBox();
Widget _wrap(BuildContext context, Widget child) => child;
