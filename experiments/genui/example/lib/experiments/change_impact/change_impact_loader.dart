// ignore_for_file: public_member_api_docs

import 'dart:async';

/// App-owned sample data for the Change Impact Workbench.
///
/// This deliberately resembles a repository adapter without invoking local
/// commands. A later adapter can replace this loader with git, analyzer, test,
/// and package-graph sources without changing the generated review contract.
final class SampleChangeImpactLoader {
  SampleChangeImpactLoader({this.latency = const Duration(milliseconds: 180)});

  final Duration latency;
  var _nextIndex = 0;

  ChangeImpactReport get initial => _reports.first;

  Future<ChangeImpactReport> loadNext() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    _nextIndex = (_nextIndex + 1) % _reports.length;
    return _reports[_nextIndex];
  }

  Future<ChangeImpactReport> runFocusedVerification(
    ChangeImpactReport report,
  ) async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return report.copyWith(focusedVerificationComplete: true);
  }

  static const _reports = <ChangeImpactReport>[
    ChangeImpactReport(
      id: 'live-bindings',
      title: 'Live A2UI bindings',
      summary:
          'A registry component now observes A2UI paths so its values can refresh without replacing the surface.',
      risk: ChangeImpactRisk.medium,
      changedFiles: [
        'desy_genui_catalog.dart',
        'orbit_registry.dart',
        'main.dart',
      ],
      affectedPackages: ['desy_genui', 'Orbit example'],
      checks: [
        ChangeImpactCheck(
          title: 'Binding compiler tests',
          detail: 'Data-bound scalar and JSON knobs resolve through a surface.',
          complete: true,
        ),
        ChangeImpactCheck(
          title: 'Example interaction test',
          detail: 'Loading APP-2 preserves APP-1 and avoids an agent turn.',
        ),
        ChangeImpactCheck(
          title: 'Repository check',
          detail: 'Run the package-boundary and workspace verification suite.',
        ),
      ],
      decision:
          'Keep live bindings as an opt-in GenUI catalog capability, or limit them to the example until more consumers need the protocol seam.',
      recommendation:
          'Run the focused verification, then decide whether the binding compiler is a public contract.',
      evidence: 'Local fixture · adapter source · focused widget coverage',
    ),
    ChangeImpactReport(
      id: 'chart-knobs',
      title: 'Portable chart knobs',
      summary:
          'Orbit charts accept primitive label and number lists, so an external author can describe chart data without a Dart model type.',
      risk: ChangeImpactRisk.low,
      changedFiles: [
        'orbit_components.dart',
        'orbit_registry.dart',
        'knobs.md',
      ],
      affectedPackages: ['Orbit example'],
      checks: [
        ChangeImpactCheck(
          title: 'Knob schema test',
          detail: 'Labels and values remain length-compatible and validated.',
          complete: true,
        ),
        ChangeImpactCheck(
          title: 'Visual chart review',
          detail: 'Verify bars do not animate during live provider refresh.',
        ),
      ],
      decision:
          'Decide whether chart data remains primitive-only or gains an explicitly typed record-list capability later.',
      recommendation:
          'Keep the primitive API for now; it is portable and covers the present experiment.',
      evidence: 'Orbit registry · fl_chart renderer · knobs documentation',
    ),
    ChangeImpactReport(
      id: 'codex-driver',
      title: 'Local Codex GenUI driver',
      summary:
          'The desktop sample can route a constrained prompt to local Codex and validate returned A2UI operations before rendering.',
      risk: ChangeImpactRisk.high,
      changedFiles: [
        'codex_genui_backend.dart',
        'genui_protocol.dart',
        'codex-genui-local-driver.html',
      ],
      affectedPackages: ['Orbit example', 'desy_genui'],
      checks: [
        ChangeImpactCheck(
          title: 'Invalid message rejection',
          detail: 'Unknown operation types never reach the renderer.',
          complete: true,
        ),
        ChangeImpactCheck(
          title: 'Process permission boundary',
          detail: 'The app surfaces a clear error when it cannot launch Codex.',
          complete: true,
        ),
        ChangeImpactCheck(
          title: 'Manual interaction review',
          detail:
              'Confirm generated actions remain user-approved before execution.',
        ),
      ],
      decision:
          'Keep the driver as a desktop research adapter, not a provider-neutral production runtime.',
      recommendation:
          'Review the permission and action boundaries before expanding the driver.',
      evidence: 'Local app-server adapter · A2UI validation · desktop fixture',
    ),
  ];
}

enum ChangeImpactRisk { low, medium, high }

final class ChangeImpactCheck {
  const ChangeImpactCheck({
    required this.title,
    required this.detail,
    this.complete = false,
  });

  final String title;
  final String detail;
  final bool complete;

  ChangeImpactCheck copyWith({bool? complete}) => ChangeImpactCheck(
    title: title,
    detail: detail,
    complete: complete ?? this.complete,
  );
}

final class ChangeImpactReport {
  const ChangeImpactReport({
    required this.id,
    required this.title,
    required this.summary,
    required this.risk,
    required this.changedFiles,
    required this.affectedPackages,
    required this.checks,
    required this.decision,
    required this.recommendation,
    required this.evidence,
    this.focusedVerificationComplete = false,
    this.scopeAccepted = false,
  });

  final String id;
  final String title;
  final String summary;
  final ChangeImpactRisk risk;
  final List<String> changedFiles;
  final List<String> affectedPackages;
  final List<ChangeImpactCheck> checks;
  final String decision;
  final String recommendation;
  final String evidence;
  final bool focusedVerificationComplete;
  final bool scopeAccepted;

  int get completedChecks => checks.where((check) => check.complete).length;

  ChangeImpactReport copyWith({
    bool? focusedVerificationComplete,
    bool? scopeAccepted,
  }) => ChangeImpactReport(
    id: id,
    title: title,
    summary: summary,
    risk: risk,
    changedFiles: changedFiles,
    affectedPackages: affectedPackages,
    checks: focusedVerificationComplete == true
        ? [for (final check in checks) check.copyWith(complete: true)]
        : checks,
    decision: decision,
    recommendation: recommendation,
    evidence: evidence,
    focusedVerificationComplete:
        focusedVerificationComplete ?? this.focusedVerificationComplete,
    scopeAccepted: scopeAccepted ?? this.scopeAccepted,
  );
}
