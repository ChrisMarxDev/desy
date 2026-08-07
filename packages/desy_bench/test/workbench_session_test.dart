import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session rejects component knob values outside declared options', () {
    const allowed = 'status.clear';
    const unrelated = 'button.publish';
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
    expect(session.knobValues.value['trailing'], allowed);
    expect(() => session.setKnob(knob, unrelated), throwsArgumentError);

    session.dispose();
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
