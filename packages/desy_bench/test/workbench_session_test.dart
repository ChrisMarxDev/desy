import 'package:desy_bench/desy_bench.dart';
import 'package:desy_bench/src/workbench/workbench_session.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('session stores typed knob values under their declared definition', () {
    final definition = KnobDefinition(
      id: 'trailing',
      name: 'Trailing',
      kind: DesyKnobKind.string,
      initial: 'status.clear',
    );
    final session = DesyWorkbenchSession(
      registry: DesyRegistry(
        name: 'Session',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      ),
    );

    session.setKnob(definition, 'status.clear');
    expect(session.knobValues.value['trailing'], 'status.clear');

    session.dispose();
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
