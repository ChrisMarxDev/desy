import 'package:desy_genui_example/experiments/change_impact/change_impact_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'sample change snapshots rotate and verification completes locally',
    () async {
      final loader = SampleChangeImpactLoader(latency: Duration.zero);
      final initial = loader.initial;

      expect(initial.id, 'live-bindings');
      expect(initial.focusedVerificationComplete, isFalse);
      expect(initial.completedChecks, 1);

      final verified = await loader.runFocusedVerification(initial);
      expect(verified.focusedVerificationComplete, isTrue);
      expect(verified.completedChecks, verified.checks.length);

      final next = await loader.loadNext();
      expect(next.id, 'chart-knobs');
    },
  );
}
