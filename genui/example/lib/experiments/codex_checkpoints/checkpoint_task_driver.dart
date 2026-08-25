// ignore_for_file: public_member_api_docs

import 'package:desy_genui/desy_genui.dart';

import '../../genui_backend.dart';

/// A deterministic local stand-in for a coding agent that needs user input.
///
/// It deliberately implements the normal GenUI backend boundary. Replacing it
/// with a local Codex-backed implementation does not change the workbench:
/// both accept a prompt or [GenUiActionTurn] and return a generated surface.
final class CheckpointTaskDriver implements GenUiBackend {
  _CheckpointStage _stage = _CheckpointStage.apiScope;
  String? _apiScope;

  @override
  Future<GeneratedSurface> respond({
    required GenUiTurn turn,
    required DesyGenUiCatalog catalog,
  }) async {
    if (turn is GenUiPromptTurn) {
      _stage = _CheckpointStage.apiScope;
      _apiScope = null;
    } else if (turn is GenUiActionTurn) {
      _advance(turn.action.name);
    }
    return GeneratedSurface(
      components: _componentsForCurrentStage(),
      model: 'local-checkpoint-driver',
      responseId: 'checkpoint-${_stage.name}',
    );
  }

  void _advance(String action) {
    switch (action) {
      case 'choose_public_api':
        _apiScope = 'public package API';
        _stage = _CheckpointStage.implementationPlan;
      case 'keep_experimental':
        _apiScope = 'example-only experiment';
        _stage = _CheckpointStage.implementationPlan;
      case 'run_full_verification':
        _stage = _CheckpointStage.patchReview;
      case 'accept_implementation':
        _stage = _CheckpointStage.completed;
      case 'request_revision':
        _stage = _CheckpointStage.implementationPlan;
    }
  }

  List<Map<String, Object?>> _componentsForCurrentStage() => switch (_stage) {
    _CheckpointStage.apiScope => _apiScopeCheckpoint(),
    _CheckpointStage.implementationPlan => _implementationCheckpoint(),
    _CheckpointStage.patchReview => _patchReviewCheckpoint(),
    _CheckpointStage.completed => _completionCheckpoint(),
  };

  List<Map<String, Object?>> _apiScopeCheckpoint() => [
    {
      'id': 'root',
      'component': 'orbit.component.stack',
      'children': ['task', 'decision', 'evidence'],
    },
    {
      'id': 'task',
      'component': 'orbit.component.insight',
      'eyebrow': 'CODEX CHECKPOINT · ARCHITECTURE',
      'title': 'Should live bindings become a public API?',
      'detail':
          'The task can keep the feature inside Orbit, or commit to a reusable desy_genui contract with documentation and compatibility coverage.',
      'metric': '2 valid paths',
      'change': 'Decision blocks implementation',
      'tone': 'warning',
    },
    {
      'id': 'decision',
      'component': 'orbit.component.approval',
      'title': 'Choose the scope before Codex edits',
      'detail':
          'Public API affects the package contract and consumer documentation. Experimental scope keeps iteration local to the example.',
      'approveLabel': 'Make it public',
      'rejectLabel': 'Keep experimental',
      'onApprove': {
        'event': {
          'name': 'choose_public_api',
          'context': {
            'option': 'public',
            'affected': ['desy_genui', 'Orbit example', 'docs'],
          },
        },
      },
      'onReject': {
        'event': {
          'name': 'keep_experimental',
          'context': {
            'option': 'experimental',
            'affected': ['Orbit example'],
          },
        },
      },
    },
    {
      'id': 'evidence',
      'component': 'orbit.component.source',
      'title': 'Task evidence',
      'detail':
          'Binding compiler, consumer registry, and public contract documentation are in scope.',
      'meta': 'Fixture task · no filesystem write · choice required',
    },
  ];

  List<Map<String, Object?>> _implementationCheckpoint() => [
    {
      'id': 'root',
      'component': 'orbit.component.stack',
      'children': ['plan', 'verification', 'files', 'evidence'],
    },
    {
      'id': 'plan',
      'component': 'orbit.component.insight',
      'eyebrow': 'CODEX CHECKPOINT · PLAN READY',
      'title': 'Plan prepared for ${_apiScope ?? 'the selected scope'}',
      'detail':
          'The task now has an explicit architecture choice. Codex can prepare the smallest compatible change and verification set.',
      'metric': '4 planned edits',
      'change': 'Awaiting verification',
      'tone': 'info',
    },
    {
      'id': 'files',
      'component': 'orbit.component.markdown',
      'title': 'Proposed change set',
      'markdown': _apiScope == 'public package API'
          ? '## Public contract\n\n- `desy_genui_catalog.dart` — bind declared values to the A2UI data model\n- `desy_genui_catalog_test.dart` — cover scalar and JSON bindings\n- `knobs.md` — state the public handoff contract\n- `main.dart` — retain the consumer proof'
          : '## Experimental scope\n\n- `main.dart` — keep the data binding proof inside Orbit\n- `sample_ticket_loader.dart` — supply local snapshots\n- `app_test.dart` — cover the interaction\n\n> No reusable package contract changes in this path.',
    },
    {
      'id': 'verification',
      'component': 'orbit.component.recommendation',
      'title': 'Run the full verification checkpoint',
      'detail':
          'In a live task this asks the app to run its approved repository check, then returns evidence for patch acceptance.',
      'confidence': 0.91,
      'actionLabel': 'Run full verification',
      'onAction': {
        'event': {
          'name': 'run_full_verification',
          'context': {'scope': _apiScope},
        },
      },
    },
    {
      'id': 'evidence',
      'component': 'orbit.component.source',
      'title': 'Task boundary',
      'detail':
          'This fixture advances only after an explicit action. It never executes the proposed edits or commands.',
      'meta': 'Continuation: GenUiActionTurn · current surface retained',
    },
  ];

  List<Map<String, Object?>> _patchReviewCheckpoint() => [
    {
      'id': 'root',
      'component': 'orbit.component.stack',
      'children': [
        'summary',
        'approval',
        'checks',
        'evidence',
      ],
    },
    {
      'id': 'summary',
      'component': 'orbit.component.insight',
      'eyebrow': 'CODEX CHECKPOINT · PATCH REVIEW',
      'title': 'Verification evidence is ready',
      'detail':
          'The selected ${_apiScope ?? 'scope'} has a proposed patch and a completed verification receipt ready for review.',
      'metric': '4 files · 2 tests',
      'change': 'All checks passed',
      'tone': 'success',
    },
    {
      'id': 'checks',
      'component': 'orbit.component.task-list',
      'title': 'Verification receipt',
      'rows': ['check-analysis', 'check-tests'],
    },
    {
      'id': 'check-analysis',
      'component': 'orbit.component.task-row',
      'title': 'Static analysis',
      'detail': 'No issues found in the package and example boundary.',
      'state': 'done',
    },
    {
      'id': 'check-tests',
      'component': 'orbit.component.task-row',
      'title': 'Focused tests',
      'detail': 'Binding and interaction tests completed successfully.',
      'state': 'done',
    },
    {
      'id': 'approval',
      'component': 'orbit.component.approval',
      'title': 'Accept this implementation?',
      'detail':
          'Acceptance completes this fixture task. In a live adapter, it would be an explicit user record—not permission to write outside the approved task scope.',
      'approveLabel': 'Accept implementation',
      'rejectLabel': 'Request revision',
      'onApprove': {
        'event': {
          'name': 'accept_implementation',
          'context': {'scope': _apiScope},
        },
      },
      'onReject': {
        'event': {
          'name': 'request_revision',
          'context': {'scope': _apiScope},
        },
      },
    },
    {
      'id': 'evidence',
      'component': 'orbit.component.source',
      'title': 'Review evidence',
      'detail':
          'The task keeps the exact choice and current generated surface as continuation context.',
      'meta': 'Fixture verification · no repository command was run',
    },
  ];

  List<Map<String, Object?>> _completionCheckpoint() => [
    {
      'id': 'root',
      'component': 'orbit.component.stack',
      'children': ['complete', 'record'],
    },
    {
      'id': 'complete',
      'component': 'orbit.component.insight',
      'eyebrow': 'CODEX CHECKPOINT · COMPLETE',
      'title': 'Implementation accepted',
      'detail':
          'The task has a recorded scope choice, verification receipt, and explicit acceptance. A live driver could now return control to the coding session.',
      'metric': 'Accepted',
      'change': _apiScope ?? 'Scope recorded',
      'tone': 'success',
    },
    {
      'id': 'record',
      'component': 'orbit.component.markdown',
      'title': 'Checkpoint record',
      'markdown':
          '1. **Scope selected:** ${_apiScope ?? 'unknown'}\n2. **Verification:** complete\n3. **User decision:** implementation accepted\n\n> This is the point at which the agent task resumes or closes.',
    },
  ];

  @override
  void close() {}
}

enum _CheckpointStage { apiScope, implementationPlan, patchReview, completed }
