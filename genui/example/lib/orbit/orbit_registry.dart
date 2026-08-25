import 'package:desy_core/desy_core.dart';
import 'package:flutter/widgets.dart';

import 'orbit_components.dart';
import 'orbit_theme.dart';

const _insightDefault = 'orbit.component.insight.default';
const _taskListDefault = 'orbit.component.task-list.default';
const _taskRowProgress = 'orbit.component.task-row.progress';
const _taskRowReady = 'orbit.component.task-row.ready';
const _recommendationDefault = 'orbit.component.recommendation.default';
const _approvalDefault = 'orbit.component.approval.default';
const _toolActivityDefault = 'orbit.component.tool-activity.default';
const _metricGridDefault = 'orbit.component.metric-grid.default';
const _metricTileDefault = 'orbit.component.metric-tile.default';
const _sourceDefault = 'orbit.component.source.default';

/// The GenUI consumer registry. Every catalogue item builds the exact Orbit
/// widget shown in the app, under one of its real themes.
final DesyRegistry orbitRegistry = DesyRegistry(
  name: 'Orbit GenUI',
  identity: const DesyRegistryIdentity(
    id: 'demo.orbit-genui',
    version: '0.2.0',
  ),
  themes: [
    DesyTheme(
      id: OrbitThemeData.midnight.id,
      name: OrbitThemeData.midnight.name,
      description: 'Neutral dark desktop workspace based on Shadcn defaults.',
      previewBackgroundColor: OrbitPalettes.midnight.background,
      isDark: true,
      wrap: (context, child) =>
          OrbitTheme(data: OrbitThemeData.midnight, child: child),
    ),
    DesyTheme(
      id: OrbitThemeData.daylight.id,
      name: OrbitThemeData.daylight.name,
      description: 'Neutral light desktop workspace based on Shadcn defaults.',
      previewBackgroundColor: OrbitPalettes.daylight.background,
      isDark: false,
      wrap: (context, child) =>
          OrbitTheme(data: OrbitThemeData.daylight, child: child),
    ),
  ],
  colors: [
    DesyColorEntry(
      id: 'orbit.color.background',
      name: 'Background',
      color: OrbitPalettes.midnight.background,
      description: 'Application canvas and the lowest visual layer.',
    ),
    DesyColorEntry(
      id: 'orbit.color.card',
      name: 'Card',
      color: OrbitPalettes.midnight.card,
      description: 'Generated content and standard elevated surfaces.',
    ),
    DesyColorEntry(
      id: 'orbit.color.primary',
      name: 'Primary',
      color: OrbitPalettes.midnight.primary,
      description: 'The highest-priority user action.',
    ),
    DesyColorEntry(
      id: 'orbit.color.success',
      name: 'Success',
      color: OrbitPalettes.midnight.success,
      description: 'Completed work and high-confidence recommendation state.',
    ),
    DesyColorEntry(
      id: 'orbit.color.warning',
      name: 'Warning',
      color: OrbitPalettes.midnight.warning,
      description: 'Approval, queued, and attention-needed state.',
    ),
  ],
  measurements: const [
    DesyNumericEntry.spacing(
      id: 'orbit.space.content',
      name: 'Content gap',
      value: OrbitTokens.spaceMd,
      description: 'Standard spacing between generated response blocks.',
    ),
    DesyNumericEntry.radius(
      id: 'orbit.radius.surface',
      name: 'Surface radius',
      value: OrbitTokens.radiusLg,
      description: 'Base radius for cards, prompts, and generated content.',
    ),
    DesyNumericEntry.spacing(
      id: 'orbit.space.control-height',
      name: 'Control height',
      value: OrbitTokens.controlHeight,
      description:
          'Compact desktop control height before pointer target padding.',
    ),
  ],
  components: [
    _buttonComponent,
    _iconButtonComponent,
    _stackComponent,
    _insightComponent,
    _taskListComponent,
    _taskRowComponent,
    _recommendationComponent,
    _approvalComponent,
    _toolActivityComponent,
    _metricGridComponent,
    _metricTileComponent,
    _sourceComponent,
  ],
);

final _buttonComponent = DesyComponent(
  id: 'orbit.component.button',
  name: 'Button',
  path: '/actions/buttons',
  description:
      'A labelled action with semantic priority, native keyboard activation, and Mix state motion.',
  accessibility:
      'Use a concise outcome label. Disabled buttons remain visibly and semantically unavailable.',
  source: 'lib/orbit/orbit_theme.dart',
  defaultSize: const Size(320, 96),
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Continue to review'),
    variant: k.choice(
      'variant',
      name: 'Variant',
      options: const ['primary', 'secondary', 'ghost', 'destructive'],
    ),
    compact: k.boolean('compact', name: 'Compact', initial: false),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    onPress: k.event(
      'onPress',
      name: 'Press event',
      description: 'Emitted when the enabled button is activated.',
    ),
  ),
  build: (context, knobs) => OrbitButton(
    label: knobs.label.value,
    variant: _buttonVariant(knobs.variant.value),
    compact: knobs.compact.value,
    onPressed: knobs.enabled.value
        ? () => knobs.onPress.emit({
            'label': knobs.label.value,
            'variant': knobs.variant.value,
          })
        : null,
  ),
  instances: (knobs) => {
    'primary': const [],
    'secondary': [knobs.label('Save draft'), knobs.variant('secondary')],
    'destructive': [
      knobs.label('Discard changes'),
      knobs.variant('destructive'),
    ],
    'disabled': [knobs.label('Waiting for access'), knobs.enabled(false)],
  },
);

final _iconButtonComponent = DesyComponent(
  id: 'orbit.component.icon-button',
  name: 'Icon button',
  path: '/actions/buttons',
  description: 'A compact labelled action whose visible affordance is a glyph.',
  accessibility: 'The label names the action because the glyph is decorative.',
  source: 'lib/orbit/orbit_theme.dart',
  defaultSize: const Size(104, 88),
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Add source'),
    glyph: k.choice(
      'glyph',
      name: 'Glyph',
      options: const ['add', 'search', 'more', 'close'],
    ),
    variant: k.choice(
      'variant',
      name: 'Variant',
      options: const ['primary', 'secondary', 'ghost', 'destructive'],
      initial: 'ghost',
    ),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    onPress: k.event(
      'onPress',
      name: 'Press event',
      description: 'Emitted when the enabled icon button is activated.',
    ),
  ),
  build: (context, knobs) => OrbitIconButton(
    label: knobs.label.value,
    glyph: _glyph(knobs.glyph.value),
    variant: _buttonVariant(knobs.variant.value),
    onPressed: knobs.enabled.value
        ? () => knobs.onPress.emit({
            'label': knobs.label.value,
            'glyph': knobs.glyph.value,
          })
        : null,
  ),
  instances: (knobs) => {
    'add': const [],
    'search': [knobs.label('Search workspace'), knobs.glyph('search')],
    'disabled': [knobs.label('Unavailable'), knobs.enabled(false)],
  },
);

final _stackComponent = DesyComponent(
  id: 'orbit.component.stack',
  name: 'Response stack',
  path: '/layout',
  description: 'A full-width, vertically spaced sequence of generated blocks.',
  source: 'lib/orbit/orbit_components.dart',
  defaultSize: const Size(640, 760),
  knobs: (k) => (
    children: k.widgetInstances(
      'children',
      name: 'Blocks',
      description: 'The ordered cards that make up an agent response.',
      options: const [
        _insightDefault,
        _metricGridDefault,
        _recommendationDefault,
        _approvalDefault,
        _taskListDefault,
        _toolActivityDefault,
        _sourceDefault,
      ],
    ),
  ),
  build: (context, knobs) => OrbitStack(children: knobs.children.widgets),
  instances: (knobs) => {
    'default': [
      knobs.children(const [
        _insightDefault,
        _metricGridDefault,
        _recommendationDefault,
        _taskListDefault,
      ]),
    ],
    'approval-flow': [
      knobs.children(const [_insightDefault, _approvalDefault, _sourceDefault]),
    ],
  },
);

final _insightComponent = DesyComponent(
  id: 'orbit.component.insight',
  name: 'Insight',
  path: '/conversation/insights',
  description: 'A concise agent finding with context, metric, and comparison.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    eyebrow: k.string('eyebrow', initial: 'LIVE SIGNAL'),
    title: k.string('title', initial: 'Activation is trending above plan'),
    detail: k.string(
      'detail',
      initial: 'New workspace teams are returning after their first prompt.',
    ),
    metric: k.string('metric', initial: '18.4%'),
    change: k.string('change', initial: '+4.2 pts'),
    tone: k.choice(
      'tone',
      options: const ['neutral', 'info', 'success', 'warning', 'danger'],
    ),
  ),
  build: (context, knobs) => OrbitInsightCard(
    eyebrow: knobs.eyebrow.value,
    title: knobs.title.value,
    detail: knobs.detail.value,
    metric: knobs.metric.value,
    change: knobs.change.value,
    tone: _tone(knobs.tone.value),
  ),
  instances: (knobs) => {
    'default': [knobs.tone('info')],
    'attention': [
      knobs.eyebrow('SIGNAL DETECTED'),
      knobs.title('Review the three accounts with a sudden usage drop'),
      knobs.detail('The pattern began after the workspace invitation change.'),
      knobs.metric('3 accounts'),
      knobs.change('Needs review'),
      knobs.tone('warning'),
    ],
  },
);

final _taskListComponent = DesyComponent(
  id: 'orbit.component.task-list',
  name: 'Task list',
  path: '/agent/work',
  description: 'Visible work coordinated by an agent.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    title: k.string('title', initial: 'Agent work'),
    rows: k.widgetInstances(
      'rows',
      name: 'Tasks',
      description: 'Ordered task rows shown to the user.',
      options: const [_taskRowProgress, _taskRowReady],
    ),
  ),
  build: (context, knobs) =>
      OrbitTaskList(title: knobs.title.value, rows: knobs.rows.widgets),
  instances: (knobs) => {
    'default': [
      knobs.rows(const [_taskRowProgress, _taskRowReady]),
    ],
  },
);

final _taskRowComponent = DesyComponent(
  id: 'orbit.component.task-row',
  name: 'Task row',
  path: '/agent/work',
  description: 'One transparent agent task with an execution state.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    title: k.string('title', initial: 'Map the customer feedback themes'),
    detail: k.string('detail', initial: '18 comments · 2 sources'),
    state: k.choice(
      'state',
      options: const ['queued', 'working', 'done', 'blocked'],
    ),
  ),
  build: (context, knobs) => OrbitTaskRow(
    title: knobs.title.value,
    detail: knobs.detail.value,
    state: _taskState(knobs.state.value),
  ),
  instances: (knobs) => {
    'progress': [knobs.state('working')],
    'ready': [
      knobs.title('Draft the release note'),
      knobs.detail('Waiting for approval'),
      knobs.state('queued'),
    ],
  },
);

final _recommendationComponent = DesyComponent(
  id: 'orbit.component.recommendation',
  name: 'Recommendation',
  path: '/conversation/decisions',
  description: 'An agent proposal with confidence and an explicit next action.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    title: k.string('title', initial: 'Prioritize the mobile onboarding fix'),
    detail: k.string(
      'detail',
      initial:
          'It affects the highest-volume drop-off and has a clear experiment path.',
    ),
    confidence: k.number(
      'confidence',
      initial: 0.84,
      unit: 'ratio',
      minimum: 0,
      maximum: 1,
      step: 0.01,
    ),
    actionLabel: k.string('actionLabel', initial: 'Review recommendation'),
    onAction: k.event(
      'onAction',
      description:
          'Emitted when the user asks the agent to continue this recommendation.',
    ),
  ),
  build: (context, knobs) => OrbitRecommendationCard(
    title: knobs.title.value,
    detail: knobs.detail.value,
    confidence: knobs.confidence.value,
    actionLabel: knobs.actionLabel.value,
    onAction: () => knobs.onAction.emit({'title': knobs.title.value}),
  ),
  instances: (knobs) => {
    'default': const [],
    'high-confidence': [
      knobs.confidence(0.96),
      knobs.actionLabel('Prepare the experiment'),
    ],
  },
);

final _approvalComponent = DesyComponent(
  id: 'orbit.component.approval',
  name: 'Approval request',
  path: '/agent/approval',
  description: 'A user-owned decision point before an agent continues.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    title: k.string('title', initial: 'Send this experiment for review?'),
    detail: k.string(
      'detail',
      initial:
          'The agent will share the brief and task plan with the project owners.',
    ),
    approveLabel: k.string('approveLabel', initial: 'Approve and continue'),
    rejectLabel: k.string('rejectLabel', initial: 'Keep editing'),
    onApprove: k.event(
      'onApprove',
      description: 'Emitted when the user approves the work.',
    ),
    onReject: k.event(
      'onReject',
      description: 'Emitted when the user asks the agent to revise.',
    ),
  ),
  build: (context, knobs) => OrbitApprovalCard(
    title: knobs.title.value,
    detail: knobs.detail.value,
    approveLabel: knobs.approveLabel.value,
    rejectLabel: knobs.rejectLabel.value,
    onApprove: () => knobs.onApprove.emit({'decision': 'approved'}),
    onReject: () => knobs.onReject.emit({'decision': 'revision_requested'}),
  ),
  instances: (knobs) => {'default': const []},
);

final _toolActivityComponent = DesyComponent(
  id: 'orbit.component.tool-activity',
  name: 'Tool activity',
  path: '/agent/activity',
  description: 'A legible record of a tool an agent is running or has run.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    tool: k.string('tool', initial: 'Analyze workspace activity'),
    detail: k.string(
      'detail',
      initial: 'Grouping 1,842 events into useful signals.',
    ),
    state: k.choice(
      'state',
      options: const ['queued', 'working', 'done', 'blocked'],
    ),
    progress: k.number(
      'progress',
      initial: 0.62,
      unit: 'ratio',
      minimum: 0,
      maximum: 1,
      step: 0.01,
    ),
  ),
  build: (context, knobs) => OrbitToolActivity(
    tool: knobs.tool.value,
    detail: knobs.detail.value,
    state: _taskState(knobs.state.value),
    progress: knobs.progress.value,
  ),
  instances: (knobs) => {
    'default': [knobs.state('working')],
    'complete': [knobs.state('done'), knobs.progress(1)],
  },
);

final _metricGridComponent = DesyComponent(
  id: 'orbit.component.metric-grid',
  name: 'Metric grid',
  path: '/data/metrics',
  description: 'A compact responsive group of metric tiles.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    tiles: k.widgetInstances(
      'tiles',
      name: 'Metrics',
      description: 'Metric tiles shown side by side when space permits.',
      options: const [_metricTileDefault],
    ),
  ),
  build: (context, knobs) => OrbitMetricGrid(tiles: knobs.tiles.widgets),
  instances: (knobs) => {
    'default': [
      knobs.tiles(const [_metricTileDefault, _metricTileDefault]),
    ],
  },
);

final _metricTileComponent = DesyComponent(
  id: 'orbit.component.metric-tile',
  name: 'Metric tile',
  path: '/data/metrics',
  description: 'One concise metric with a direction or state label.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    label: k.string('label', initial: 'Active projects'),
    value: k.string('value', initial: '24'),
    change: k.string('change', initial: '+18% this week'),
    tone: k.choice(
      'tone',
      options: const ['neutral', 'info', 'success', 'warning', 'danger'],
    ),
  ),
  build: (context, knobs) => OrbitMetricTile(
    label: knobs.label.value,
    value: knobs.value.value,
    change: knobs.change.value,
    tone: _tone(knobs.tone.value),
  ),
  instances: (knobs) => {
    'default': [knobs.tone('success')],
    'sources': [
      knobs.label('Sources connected'),
      knobs.value('12'),
      knobs.change('+3 this week'),
      knobs.tone('info'),
    ],
  },
);

final _sourceComponent = DesyComponent(
  id: 'orbit.component.source',
  name: 'Source card',
  path: '/data/sources',
  description: 'Traceable evidence supporting an agent conclusion.',
  source: 'lib/orbit/orbit_components.dart',
  knobs: (k) => (
    title: k.string('title', initial: 'Workspace activation report'),
    detail: k.string(
      'detail',
      initial: 'The source used for the recommendation.',
    ),
    meta: k.string('meta', initial: 'Updated 4 min ago · 1,842 records'),
  ),
  build: (context, knobs) => OrbitSourceCard(
    title: knobs.title.value,
    detail: knobs.detail.value,
    meta: knobs.meta.value,
  ),
  instances: (knobs) => {'default': const []},
);

OrbitBadgeTone _tone(String value) => switch (value) {
  'info' => OrbitBadgeTone.info,
  'success' => OrbitBadgeTone.success,
  'warning' => OrbitBadgeTone.warning,
  'danger' => OrbitBadgeTone.danger,
  _ => OrbitBadgeTone.neutral,
};

OrbitButtonVariant _buttonVariant(String value) => switch (value) {
  'secondary' => OrbitButtonVariant.secondary,
  'ghost' => OrbitButtonVariant.ghost,
  'destructive' => OrbitButtonVariant.destructive,
  _ => OrbitButtonVariant.primary,
};

String _glyph(String value) => switch (value) {
  'search' => OrbitGlyphs.search,
  'more' => OrbitGlyphs.more,
  'close' => OrbitGlyphs.close,
  _ => OrbitGlyphs.add,
};

OrbitTaskState _taskState(String value) => switch (value) {
  'working' => OrbitTaskState.working,
  'done' => OrbitTaskState.done,
  'blocked' => OrbitTaskState.blocked,
  _ => OrbitTaskState.queued,
};
