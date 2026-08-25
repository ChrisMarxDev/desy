// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

import '../../genui_protocol.dart';
import '../../orbit/orbit_theme.dart';
import 'change_impact_loader.dart';

/// A separate, local-first GenUI feature for reviewing repository changes.
///
/// Reports are app-owned typed data. The composer is intentionally local and
/// deterministic in this first experiment: it stands in for an agent choosing
/// a declared component arrangement from a supplied repository snapshot.
class ChangeImpactWorkbench extends StatefulWidget {
  const ChangeImpactWorkbench({
    super.key,
    required this.catalog,
    required this.theme,
  });

  final DesyGenUiCatalog catalog;
  final DesyTheme theme;

  @override
  State<ChangeImpactWorkbench> createState() => _ChangeImpactWorkbenchState();
}

class _ChangeImpactWorkbenchState extends State<ChangeImpactWorkbench> {
  static const _surfaceId = 'change-impact-workbench';

  late final SampleChangeImpactLoader _loader;
  late final SurfaceController _controller;
  late final StreamSubscription<ChatMessage> _events;
  late ChangeImpactReport _report;
  var _loading = false;
  var _lastAction = 'Inspect the current review surface.';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loader = SampleChangeImpactLoader();
    _report = _loader.initial;
    _controller = SurfaceController(catalogs: [widget.catalog.catalog]);
    _events = _controller.onSubmit.listen(_handleInteraction);
    _controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: _surfaceId,
        catalogId: widget.catalog.catalog.catalogId!,
      ),
    );
    _renderReport();
  }

  @override
  void dispose() {
    unawaited(_events.cancel());
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showNextSample() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _loader.loadNext();
      if (!mounted) return;
      setState(() {
        _report = report;
        _lastAction = 'Loaded the ${report.title} repository snapshot.';
      });
      _renderReport();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runFocusedVerification() async {
    if (_loading || _report.focusedVerificationComplete) return;
    setState(() {
      _loading = true;
      _error = null;
      _lastAction = 'Running the app-owned focused verification fixture…';
    });
    try {
      final report = await _loader.runFocusedVerification(_report);
      if (!mounted) return;
      setState(() {
        _report = report;
        _lastAction = 'Focused verification completed for ${report.title}.';
      });
      _renderReport();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _acceptScope() {
    if (_report.scopeAccepted) return;
    setState(() {
      _report = _report.copyWith(scopeAccepted: true);
      _lastAction = 'Review scope accepted locally. No repository change ran.';
    });
    _renderReport();
  }

  void _handleInteraction(ChatMessage message) {
    final interaction = message.parts.first.asUiInteractionPart?.interaction;
    if (interaction == null) return;
    try {
      final action = GenUiAction.fromInteraction(interaction);
      switch (action.name) {
        case 'run_focused_verification':
          unawaited(_runFocusedVerification());
        case 'accept_review_scope':
          _acceptScope();
        case 'request_follow_up':
          setState(
            () => _lastAction =
                'Follow-up requested. Choose another local change snapshot.',
          );
        default:
          setState(
            () => _lastAction = 'Ignored unsupported action ${action.name}.',
          );
      }
    } on FormatException catch (error) {
      setState(
        () => _error = 'The generated action was invalid: ${error.message}',
      );
    }
  }

  void _renderReport() {
    _controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: _surfaceId,
        components: [
          for (final component in composeChangeImpactSurface(_report))
            Map<String, dynamic>.from(component),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _ChangeImpactIntroduction(),
              const SizedBox(height: OrbitTokens.spaceXl),
              OrbitSurface(
                tone: OrbitSurfaceTone.muted,
                child: Row(
                  children: [
                    const OrbitGlyph(OrbitGlyphs.database, size: 18),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Expanded(
                      child: Text(
                        'APP-OWNED SNAPSHOT · ${_report.id}',
                        style: OrbitType.label(context),
                      ),
                    ),
                    OrbitButton(
                      label: _loading ? 'Inspecting…' : 'Inspect next change',
                      onPressed: _loading ? null : _showNextSample,
                      compact: true,
                      variant: OrbitButtonVariant.secondary,
                      leading: const OrbitGlyph(OrbitGlyphs.activity, size: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: OrbitTokens.spaceXl),
              Row(
                children: [
                  const OrbitBadge(
                    label: 'LOCAL COMPOSER',
                    tone: OrbitBadgeTone.neutral,
                    glyph: OrbitGlyphs.sparkle,
                  ),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Text('REVIEW COMPOSER', style: OrbitType.label(context)),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'local fixture · declared Orbit catalog',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OrbitType.small(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: OrbitTokens.spaceMd),
              if (_loading) const _ChangeImpactLoading(),
              if (_loading) const SizedBox(height: OrbitTokens.spaceMd),
              if (_error case final error?)
                OrbitSurface(
                  child: Text(
                    error,
                    style: OrbitType.body(context).copyWith(
                      color: OrbitTheme.of(context).colors.destructive,
                    ),
                  ),
                )
              else
                DesyGenUiSurface(
                  controller: _controller,
                  surfaceId: _surfaceId,
                  theme: widget.theme,
                ),
              const SizedBox(height: OrbitTokens.spaceMd),
              OrbitSurface(
                tone: OrbitSurfaceTone.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: OrbitTokens.spaceMd,
                  vertical: OrbitTokens.spaceSm,
                ),
                child: Row(
                  children: [
                    OrbitGlyph(
                      OrbitGlyphs.activity,
                      color: OrbitTheme.of(context).colors.warning,
                      size: 15,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Text(
                      'LAST LOCAL ACTION',
                      style: OrbitType.overline(context),
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    Expanded(
                      child: Text(
                        _lastAction,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OrbitType.small(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ChangeImpactIntroduction extends StatelessWidget {
  const _ChangeImpactIntroduction();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const OrbitBadge(
        label: 'GENUI VALUE EXPERIMENT',
        tone: OrbitBadgeTone.info,
        glyph: OrbitGlyphs.sparkle,
      ),
      const SizedBox(height: OrbitTokens.spaceLg),
      Text(
        'Review a change, not a chat reply.',
        style: OrbitType.display(context),
      ),
      const SizedBox(height: OrbitTokens.spaceSm),
      Text(
        'Orbit owns the repository snapshot and every action. The GenUI composer only chooses the temporary review surface needed for that change.',
        style: OrbitType.body(
          context,
        ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
      ),
    ],
  );
}

class _ChangeImpactLoading extends StatelessWidget {
  const _ChangeImpactLoading();

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: OrbitTokens.spaceMd,
      vertical: OrbitTokens.spaceSm,
    ),
    child: Row(
      children: [
        OrbitSpinner(size: 16, color: OrbitTheme.of(context).colors.info),
        const SizedBox(width: OrbitTokens.spaceSm),
        Text(
          'Refreshing the app-owned change snapshot…',
          style: OrbitType.small(context),
        ),
      ],
    ),
  );
}

List<Map<String, Object?>> composeChangeImpactSurface(
  ChangeImpactReport report,
) {
  final childIds = <String>[
    'summary',
    'metrics',
    'next-step',
    'checks',
    'files',
    if (report.changedFiles.length >= 3) 'impact-chart',
    'evidence',
  ];
  return [
    {'id': 'root', 'component': 'orbit.component.stack', 'children': childIds},
    {
      'id': 'summary',
      'component': 'orbit.component.insight',
      'eyebrow': '${_riskLabel(report.risk)} RISK · CHANGE IMPACT',
      'title': report.title,
      'detail': report.summary,
      'metric': '${report.changedFiles.length} files',
      'change':
          '${report.completedChecks}/${report.checks.length} checks complete',
      'tone': _riskTone(report.risk),
    },
    {
      'id': 'metrics',
      'component': 'orbit.component.metric-grid',
      'tiles': ['files-metric', 'packages-metric', 'risk-metric'],
    },
    {
      'id': 'files-metric',
      'component': 'orbit.component.metric-tile',
      'label': 'Changed files',
      'value': '${report.changedFiles.length}',
      'change': report.changedFiles.first,
      'tone': 'info',
    },
    {
      'id': 'packages-metric',
      'component': 'orbit.component.metric-tile',
      'label': 'Affected packages',
      'value': '${report.affectedPackages.length}',
      'change': report.affectedPackages.join(' · '),
      'tone': 'success',
    },
    {
      'id': 'risk-metric',
      'component': 'orbit.component.metric-tile',
      'label': 'Review risk',
      'value': _riskLabel(report.risk),
      'change': report.scopeAccepted ? 'Scope accepted' : 'Decision required',
      'tone': _riskTone(report.risk),
    },
    {
      'id': 'files',
      'component': 'orbit.component.markdown',
      'title': 'Changed material',
      'markdown': _filesMarkdown(report),
    },
    if (report.changedFiles.length >= 3)
      {
        'id': 'impact-chart',
        'component': 'orbit.component.bar-chart',
        'title': 'Review attention by signal',
        'labels': ['Files', 'Packages', 'Open checks'],
        'values': [
          report.changedFiles.length,
          report.affectedPackages.length,
          report.checks.length - report.completedChecks,
        ],
      },
    {
      'id': 'checks',
      'component': 'orbit.component.task-list',
      'title': 'Verification evidence',
      'rows': [
        for (var index = 0; index < report.checks.length; index++)
          'check-$index',
      ],
    },
    for (var index = 0; index < report.checks.length; index++)
      {
        'id': 'check-$index',
        'component': 'orbit.component.task-row',
        'title': report.checks[index].title,
        'detail': report.checks[index].detail,
        'state': report.checks[index].complete ? 'done' : 'queued',
      },
    if (!report.focusedVerificationComplete)
      {
        'id': 'next-step',
        'component': 'orbit.component.recommendation',
        'title': 'Run the focused verification',
        'detail': report.recommendation,
        'confidence': 0.88,
        'actionLabel': 'Run focused verification',
        'onAction': {
          'event': {
            'name': 'run_focused_verification',
            'context': {'reportId': report.id},
          },
        },
      }
    else
      {
        'id': 'next-step',
        'component': 'orbit.component.approval',
        'title': report.scopeAccepted
            ? 'Review scope accepted'
            : 'Decision required',
        'detail': report.scopeAccepted
            ? 'The local fixture recorded the acceptance. No repository command or change was executed.'
            : report.decision,
        'approveLabel': report.scopeAccepted ? 'Accepted' : 'Accept scope',
        'rejectLabel': 'Request follow-up',
        'onApprove': {
          'event': {
            'name': 'accept_review_scope',
            'context': {'reportId': report.id},
          },
        },
        'onReject': {
          'event': {
            'name': 'request_follow_up',
            'context': {'reportId': report.id},
          },
        },
      },
    {
      'id': 'evidence',
      'component': 'orbit.component.source',
      'title': 'Review evidence',
      'detail': report.evidence,
      'meta': 'Local sample provider · no command execution · no model call',
    },
  ];
}

String _filesMarkdown(ChangeImpactReport report) =>
    '## Files in scope\n\n${report.changedFiles.map((file) => '- `$file`').join('\n')}\n\n'
    '> ${report.decision}';

String _riskLabel(ChangeImpactRisk risk) => switch (risk) {
  ChangeImpactRisk.low => 'LOW',
  ChangeImpactRisk.medium => 'MEDIUM',
  ChangeImpactRisk.high => 'HIGH',
};

String _riskTone(ChangeImpactRisk risk) => switch (risk) {
  ChangeImpactRisk.low => 'success',
  ChangeImpactRisk.medium => 'warning',
  ChangeImpactRisk.high => 'danger',
};
