import 'package:desy_genui/desy_genui.dart';
import 'package:desy_genui_example/experiments/codex_checkpoints/checkpoint_task_driver.dart';
import 'package:desy_genui_example/genui_backend.dart';
import 'package:desy_genui_example/orbit/orbit_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'checkpoint task actions advance a coding task through acceptance',
    () async {
      final driver = CheckpointTaskDriver();
      final catalog = DesyGenUiCatalog.compile(orbitRegistry);

      final first = await driver.respond(
        turn: GenUiPromptTurn('Implement bindings.'),
        catalog: catalog,
      );
      expect(_title(first), 'Should live bindings become a public API?');

      final plan = await driver.respond(
        turn: _actionTurn('choose_public_api', first.components),
        catalog: catalog,
      );
      expect(_title(plan), 'Plan prepared for public package API');

      final review = await driver.respond(
        turn: _actionTurn('run_full_verification', plan.components),
        catalog: catalog,
      );
      expect(_title(review), 'Verification evidence is ready');

      final complete = await driver.respond(
        turn: _actionTurn('accept_implementation', review.components),
        catalog: catalog,
      );
      expect(_title(complete), 'Implementation accepted');
    },
  );
}

GenUiActionTurn _actionTurn(
  String name,
  List<Map<String, Object?>> currentSurface,
) => GenUiActionTurn(
  action: GenUiAction(
    name: name,
    sourceComponentId: 'checkpoint',
    surfaceId: 'codex-checkpoints',
    timestamp: DateTime.utc(2026).toIso8601String(),
  ),
  currentSurface: currentSurface,
);

String _title(GeneratedSurface surface) {
  final summary = surface.components.firstWhere(
    (component) => component['component'] == 'orbit.component.insight',
  );
  return summary['title']! as String;
}
