import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import 'prototypes/annotation_inbox_prototype.dart';
import 'prototypes/knob_controls_prototype.dart';

final _lightTheme = DesyDesignSystemFoundation.themeData(
  DesyDesignSystemTheme.light,
);
final _darkTheme = DesyDesignSystemFoundation.themeData(
  DesyDesignSystemTheme.dark,
);

const _badgeDefaultInstanceId = 'desy.component.badge.default';
const _cardDefaultInstanceId = 'desy.component.card.default';
const _chatComposerReadyInstanceId = 'desy.component.chat-composer.ready';
const _chatMessageAgentInstanceId = 'desy.component.chat-message.agent';
const _chatMessageUserInstanceId = 'desy.component.chat-message.user';
const _shortcutSingleKeyInstanceId = 'desy.component.shortcut-label.single-key';
const _missingTileSuffixInstanceId =
    'desy.component.unregistered-tile-suffix.missing';

/// The single declared source of truth for Desy's own design system.
///
/// Every exported visible component family is registered here using its real
/// production widget. Variants are component instances rather than a parallel
/// gallery or inventory model.
final DesyRegistry desyDesignSystemRegistry = DesyRegistry(
  name: 'Desy Design System',
  catalogConfig: const DesyCatalogConfig(
    id: 'desy.design-system',
    version: '0.2-experimental',
    description:
        'Workbench controls and foundations available to agent-built Desy surfaces.',
  ),
  themes: [
    DesyTheme(
      id: 'desy.theme.light',
      name: 'Workbench light',
      description: 'High-clarity neutral chrome for normal working contexts.',
      previewBackgroundColor: _lightTheme.colors.background,
      wrap: (context, child) => DesyDesignSystemThemeScope(
        theme: DesyDesignSystemTheme.light,
        child: child,
      ),
    ),
    DesyTheme(
      id: 'desy.theme.dark',
      name: 'Workbench dark',
      description: 'Low-glare neutral chrome for dark preview contexts.',
      previewBackgroundColor: _darkTheme.colors.background,
      isDark: true,
      wrap: (context, child) => DesyDesignSystemThemeScope(
        theme: DesyDesignSystemTheme.dark,
        child: child,
      ),
    ),
  ],
  colors: [
    DesyColorEntry(
      id: 'desy.color.background',
      name: 'Background',
      color: _lightTheme.colors.background,
      description: 'The workbench document and canvas foundation.',
    ),
    DesyColorEntry(
      id: 'desy.color.foreground',
      name: 'Foreground',
      color: _lightTheme.colors.foreground,
      description: 'Primary readable content and icon color.',
    ),
    DesyColorEntry(
      id: 'desy.color.primary',
      name: 'Primary action',
      color: _lightTheme.colors.primary,
      description: 'Black, high-emphasis workbench actions.',
    ),
    DesyColorEntry(
      id: 'desy.color.signal',
      name: 'Signal pink',
      color: _lightTheme.colors.desy.signal,
      description:
          'Reserved for inspection, selection, annotations, and focus.',
    ),
    DesyColorEntry(
      id: 'desy.color.signal-surface',
      name: 'Signal surface',
      color: _lightTheme.colors.desy.signalSurface,
      description: 'Quiet selected-row and annotation-context fill.',
    ),
    DesyColorEntry(
      id: 'desy.color.positive',
      name: 'Runtime positive',
      color: _lightTheme.colors.desy.positive,
      description: 'Hot reload, connected, and successful runtime state.',
    ),
    DesyColorEntry(
      id: 'desy.color.card',
      name: 'Card',
      color: _lightTheme.colors.card,
      description: 'Contained workbench panels and specimens.',
    ),
    DesyColorEntry(
      id: 'desy.color.border',
      name: 'Border',
      color: _lightTheme.colors.border,
      description: 'Quiet separation between adjacent surfaces.',
    ),
    DesyColorEntry(
      id: 'desy.color.muted-foreground',
      name: 'Muted foreground',
      color: _lightTheme.colors.mutedForeground,
      description: 'Secondary labels and low-emphasis metadata.',
    ),
  ],
  fonts: [
    DesyTypographyEntry(
      id: 'desy.type.display',
      name: 'Display',
      value: 'displaySmall',
      description: 'Names the primary idea of a workbench surface.',
      sample: 'Inspect the real component',
      builder: (context, text) =>
          Text(text, style: Theme.of(context).textTheme.displaySmall),
    ),
    DesyTypographyEntry(
      id: 'desy.type.title',
      name: 'Title',
      value: 'titleLarge',
      description: 'Introduces a related panel or inspector section.',
      sample: 'Component contract',
      builder: (context, text) =>
          Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
    DesyTypographyEntry(
      id: 'desy.type.body',
      name: 'Body',
      value: 'bodyMedium',
      description: 'Default readable guidance and supporting content.',
      sample: 'The registry remains the declared source of truth.',
      builder: (context, text) =>
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ),
    DesyTypographyEntry(
      id: 'desy.type.label',
      name: 'Label',
      value: 'labelSmall',
      description: 'Compact workbench metadata and section labels.',
      sample: 'CATALOGUE',
      builder: (context, text) =>
          Text(text, style: Theme.of(context).textTheme.labelSmall),
    ),
  ],
  icons: _desyIcons,
  measurements: const [
    DesyNumericEntry.spacing(
      id: 'desy.space.xs',
      name: 'Extra-small spacing',
      value: DesyDesignSystemTokens.spaceXs,
      description: 'Tight inline separation and keycap spacing.',
    ),
    DesyNumericEntry.spacing(
      id: 'desy.space.sm',
      name: 'Small spacing',
      value: DesyDesignSystemTokens.spaceSm,
      description: 'Related control and label separation.',
    ),
    DesyNumericEntry.spacing(
      id: 'desy.space.md',
      name: 'Medium spacing',
      value: DesyDesignSystemTokens.spaceMd,
      description: 'Default compact panel rhythm.',
    ),
    DesyNumericEntry.spacing(
      id: 'desy.space.base',
      name: 'Base spacing',
      value: DesyDesignSystemTokens.spaceBase,
      description: 'Default content and toolbar separation.',
    ),
    DesyNumericEntry.spacing(
      id: 'desy.space.lg',
      name: 'Large spacing',
      value: DesyDesignSystemTokens.spaceLg,
      description: 'Panel padding and major section separation.',
    ),
    DesyNumericEntry.spacing(
      id: 'desy.space.xl',
      name: 'Extra-large spacing',
      value: DesyDesignSystemTokens.spaceXl,
      description: 'Separates major workspace regions.',
    ),
    DesyNumericEntry.radius(
      id: 'desy.radius.sm',
      name: 'Small radius',
      value: DesyDesignSystemTokens.radiusSm,
      description: 'Keycaps and compact controls.',
    ),
    DesyNumericEntry.radius(
      id: 'desy.radius.md',
      name: 'Medium radius',
      value: DesyDesignSystemTokens.radiusMd,
      description: 'Cards and contained workbench panels.',
    ),
    DesyNumericEntry.breakpoint(
      id: 'desy.breakpoint.compact',
      name: 'Compact workbench threshold',
      value: DesyDesignSystemTokens.compactBreakpoint,
      description: 'Switches desktop sidebar chrome to compact navigation.',
    ),
  ],
  motion: [
    DesyMotionEntry(
      id: 'desy.motion.sidebar-reveal',
      name: 'Sidebar reveal',
      duration: DesyDesignSystemTokens.navigationMotion,
      curve: Curves.easeOutCubic,
      description: 'Fades and eases a persistent sidebar into its workspace.',
      builder: _buildSidebarReveal,
      child: const DesyMotionChild.widget(
        id: 'signal-square',
        name: 'Signal square',
        builder: _buildSignalSquare,
      ),
    ),
    DesyMotionEntry(
      id: 'desy.motion.navigation',
      name: 'Navigation reveal',
      duration: DesyDesignSystemTokens.navigationMotion,
      curve: Curves.easeOutCubic,
      description: 'Sidebar width and similar spatial navigation changes.',
      builder: _buildMotionSpecimen,
      transitionBuilder: _buildMotionTransition,
      child: const DesyMotionChild.widget(
        id: 'signal-square',
        name: 'Signal square',
        builder: _buildSignalSquare,
      ),
      alternatives: const [
        DesyMotionChild.instance(
          id: 'primary-button',
          name: 'Primary button',
          instanceId: DesyInstanceId('desy.component.button.primary'),
        ),
        DesyMotionChild.instance(
          id: 'outline-badge',
          name: 'Outline badge',
          instanceId: DesyInstanceId('desy.component.badge.outline'),
        ),
      ],
    ),
    DesyMotionEntry(
      id: 'desy.motion.content-swap',
      name: 'Content swap',
      duration: DesyDesignSystemTokens.feedbackMotion,
      curve: Curves.easeInOutCubic,
      description: 'Crossfades two elements in one stable view without travel.',
      builder: _buildMotionSpecimen,
      transitionBuilder: _buildContentSwapTransition,
      child: const DesyMotionChild.widget(
        id: 'signal-square',
        name: 'Signal square',
        builder: _buildSignalSquare,
      ),
      alternatives: const [
        DesyMotionChild.instance(
          id: 'primary-button',
          name: 'Primary button',
          instanceId: DesyInstanceId('desy.component.button.primary'),
        ),
        DesyMotionChild.instance(
          id: 'outline-badge',
          name: 'Outline badge',
          instanceId: DesyInstanceId('desy.component.badge.outline'),
        ),
      ],
    ),
    DesyMotionEntry(
      id: 'desy.motion.screen-navigation',
      name: 'Screen navigation',
      duration: DesyDesignSystemTokens.navigationMotion,
      curve: Curves.easeOutCubic,
      description:
          'Fades and slides between destination screens while keeping the shell stable.',
      builder: _buildScreenReveal,
      transitionBuilder: _buildScreenNavigationTransition,
      child: const DesyMotionChild.widget(
        id: 'signal-square',
        name: 'Signal square',
        builder: _buildSignalSquare,
      ),
      alternatives: const [
        DesyMotionChild.instance(
          id: 'primary-button',
          name: 'Primary button',
          instanceId: DesyInstanceId('desy.component.button.primary'),
        ),
        DesyMotionChild.instance(
          id: 'outline-badge',
          name: 'Outline badge',
          instanceId: DesyInstanceId('desy.component.badge.outline'),
        ),
      ],
    ),
    DesyMotionEntry(
      id: 'desy.motion.feedback',
      name: 'Feedback emphasis',
      duration: DesyDesignSystemTokens.feedbackMotion,
      curve: Curves.easeOutCubic,
      description: 'A concise confirmation or newly revealed state.',
      builder: _buildMotionSpecimen,
      transitionBuilder: _buildMotionTransition,
      child: const DesyMotionChild.widget(
        id: 'signal-square',
        name: 'Signal square',
        builder: _buildSignalSquare,
      ),
      alternatives: const [
        DesyMotionChild.instance(
          id: 'outline-badge',
          name: 'Outline badge',
          instanceId: DesyInstanceId('desy.component.badge.outline'),
        ),
        DesyMotionChild.instance(
          id: 'primary-button',
          name: 'Primary button',
          instanceId: DesyInstanceId('desy.component.button.primary'),
        ),
      ],
    ),
  ],
  effects: [
    DesyEffectEntry.boxShadow(
      id: 'desy.effect.floating',
      name: 'Floating surface',
      description: 'Temporary surfaces above the workbench document.',
      shadows: const [
        BoxShadow(
          color: Color(0x2410201D),
          offset: Offset(0, 10),
          blurRadius: 28,
          spreadRadius: -10,
        ),
      ],
    ),
  ],
  customAtoms: [
    DesyCustomAtom(
      id: 'desy.atom.gradient.ribbon',
      name: 'Signal ribbon',
      description:
          'A branded directional gradient used to introduce live workbench moments.',
      instances: {
        'default': (_) => const _SignalRibbon(),
        'quiet': (_) => const _SignalRibbon(quiet: true),
      },
    ),
  ],
  prototypes: [
    buildAnnotationInboxPrototypeSession(),
    buildKnobControlsPrototypeSession(),
  ],
  components: [
    _sampleComponent,
    _allKnobsComponent,
    _buttonComponent,
    _badgeComponent,
    _chatMessageComponent,
    _chatComposerComponent,
    _chatThreadComponent,
    _dialogComponent,
    _selectComponent,
    _switchComponent,
    _numericKnobComponent,
    _booleanKnobComponent,
    _textKnobComponent,
    _choiceKnobComponent,
    _dateTimeKnobComponent,
    _colorKnobComponent,
    _instanceKnobComponent,
    _textFieldComponent,
    _accordionComponent,
    _tabsComponent,
    _resizeDividerComponent,
    _tileComponent,
    _sidebarComponent,
    _sidebarSectionComponent,
    _sidebarItemComponent,
    _cardComponent,
    _knobSheetComponent,
    _catalogueCardComponent,
    _progressTrailComponent,
    _scaffoldComponent,
    _shortcutComponent,
  ],
);

final _sampleComponent = DesyComponent(
  id: 'desy.component.sample',
  name: 'Button',
  path: '/',
  icon: DesyIcons.component,
  knobs: (k) => (
    label1: k.string('label1', name: 'Label', initial: 'This is a'),
    label2: k.string('label2', name: 'Label', initial: 'Test'),
  ),
  build: (context, knobs) => Row(
    children: [
      Expanded(child: Text(knobs.label1.value)),
      Expanded(child: Text(knobs.label2.value)),
    ],
  ),
);

final _allKnobsComponent = DesyComponent(
  id: 'desy.component.all-knobs',
  name: 'All knobs',
  path: '/examples',
  icon: DesyIcons.component,
  description:
      'A release-review specimen exercising every knob contract through one real component.',
  source:
      'package:desy_design_system_example/src/desy_design_system_registry.dart',
  defaultSize: const Size(640, 440),
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Release review'),
    status: k.choice(
      'status',
      name: 'Status',
      options: const ['Automatic', 'Ready', 'Blocked'],
    ),
    inset: k.number(
      'inset',
      name: 'Content inset',
      initial: 20,
      unit: 'px',
      step: 4,
      minimum: 8,
      maximum: 40,
    ),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    scheduledAt: k.dateTime(
      'scheduledAt',
      name: 'Scheduled at',
      initial: DateTime.utc(2026, 8, 24, 9, 30),
    ),
    accent: k.color('accent', name: 'Accent', initial: const Color(0xFFFF2871)),
    leading: k.widgetInstance(
      'leading',
      name: 'Leading instance',
      initial: _badgeDefaultInstanceId,
      options: const [
        _badgeDefaultInstanceId,
        'desy.component.badge.outline',
        _shortcutSingleKeyInstanceId,
      ],
    ),
    supporting: k.widgetInstances(
      'supporting',
      name: 'Supporting instances',
      initial: const [
        'desy.component.badge.outline',
        _shortcutSingleKeyInstanceId,
      ],
      options: const [
        _badgeDefaultInstanceId,
        'desy.component.badge.outline',
        _shortcutSingleKeyInstanceId,
      ],
    ),
    onActivate: k.event(
      'onActivate',
      name: 'Activate event',
      description: 'Emits the visible release-review values.',
    ),
  ),
  build: (context, knobs) => _buildAllKnobsSpecimen(
    context,
    title: knobs.title.value,
    status: knobs.status.value,
    inset: knobs.inset.value,
    enabled: knobs.enabled.value,
    scheduledAt: knobs.scheduledAt.value,
    accent: knobs.accent.value,
    leading: knobs.leading.widget,
    supporting: knobs.supporting.widgets,
    onActivate: knobs.enabled.value
        ? () => knobs.onActivate.emit({
            'title': knobs.title.value,
            'status': knobs.status.value,
            'scheduledAt': knobs.scheduledAt.value.toIso8601String(),
            'accent': knobs.accent.value.toARGB32(),
          })
        : null,
  ),
  instances: (knobs) => {
    'default': [knobs.status('Automatic')],
    'ready': [
      knobs.title('Release candidate ready'),
      knobs.status('Ready'),
      knobs.inset(16),
      knobs.scheduledAt(DateTime.utc(2026, 8, 24, 14)),
      knobs.accent(const Color(0xFF16A34A)),
      knobs.leading('desy.component.badge.outline'),
      knobs.supporting(const [_shortcutSingleKeyInstanceId]),
    ],
    'blocked': [
      knobs.title('Release candidate blocked'),
      knobs.status('Blocked'),
      knobs.enabled(false),
      knobs.accent(const Color(0xFFDC2626)),
      knobs.supporting(const ['desy.component.badge.outline']),
    ],
  },
);

Widget _buildAllKnobsSpecimen(
  BuildContext context, {
  required String title,
  required String status,
  required double inset,
  required bool enabled,
  required DateTime scheduledAt,
  required Color accent,
  required Widget leading,
  required List<Widget> supporting,
  required VoidCallback? onActivate,
}) => DesyCard(
  child: Container(
    width: 560,
    padding: EdgeInsets.all(inset),
    decoration: BoxDecoration(
      color: Color.lerp(Theme.of(context).colorScheme.surface, accent, 0.08),
      border: Border(left: BorderSide(color: accent, width: 4)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            leading,
            const SizedBox(width: DesyDesignSystemTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                  Text(
                    'Scheduled ${_knobSheetDateLabel(scheduledAt)} UTC',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceMd),
            DesyBadge(
              variant: status == 'Blocked'
                  ? DesyBadgeVariant.destructive
                  : DesyBadgeVariant.outline,
              child: Text(status),
            ),
          ],
        ),
        const SizedBox(height: DesyDesignSystemTokens.spaceLg),
        Wrap(
          spacing: DesyDesignSystemTokens.spaceSm,
          runSpacing: DesyDesignSystemTokens.spaceSm,
          children: supporting,
        ),
        const SizedBox(height: DesyDesignSystemTokens.spaceLg),
        DesyButton(
          size: DesyButtonSize.sm,
          mainAxisSize: MainAxisSize.min,
          onPress: onActivate,
          child: Text(enabled ? 'Open release' : 'Release unavailable'),
        ),
      ],
    ),
  ),
);

class _SignalRibbon extends StatelessWidget {
  const _SignalRibbon({this.quiet = false});

  final bool quiet;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: quiet
            ? const [Color(0xFFFFE7F0), Color(0xFFF8F5FF)]
            : const [Color(0xFFFF2871), Color(0xFF8133F1)],
      ),
    ),
    child: const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text('Signal ribbon'),
      ),
    ),
  );
}

final _buttonComponent = DesyComponent(
  id: 'desy.component.button',
  name: 'Button',
  path: '/actions',
  icon: DesyIcons.component,
  description: 'Triggers a workbench action with a clear semantic priority.',
  accessibility: 'Use a visible outcome label and preserve disabled semantics.',
  source: 'package:desy_design_system/src/desy_button.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Inspect component'),
    outline: k.boolean('outline', name: 'Outline', initial: false),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    onPress: k.event(
      'onPress',
      name: 'Press event',
      description: 'Action emitted when the enabled button is activated.',
    ),
  ),
  build: (context, knobs) => DesyButton(
    variant: knobs.outline.value
        ? DesyButtonVariant.outline
        : DesyButtonVariant.primary,
    mainAxisSize: MainAxisSize.min,
    onPress: knobs.enabled.value
        ? () => knobs.onPress.emit({'label': knobs.label.value})
        : null,
    child: Text(knobs.label.value),
  ),
  instances: (knobs) => {
    'primary': [knobs.label('Inspect component')],
    'outline': [knobs.label('Open settings'), knobs.outline(true)],
    'disabled': [knobs.label('Unavailable'), knobs.enabled(false)],
  },
);

final _chatMessageComponent = DesyComponent(
  id: 'desy.component.chat-message',
  name: 'Chat message',
  path: '/agents/chat',
  icon: DesyIcons.messageSquare,
  description:
      'Distinguishes a workbench prompt from agent-produced widget content.',
  accessibility:
      'Preserve the author label and announce pending agent output as a live region.',
  source: 'package:desy_design_system/src/desy_chat.dart',
  knobs: (k) => (
    label: k.string(
      'label',
      name: 'Author label',
      description: 'Short visible author or agent name.',
      initial: 'GENUI AGENT',
    ),
    fromUser: k.boolean(
      'fromUser',
      name: 'From user',
      description: 'Whether this is a user command rather than agent output.',
      initial: false,
    ),
    pending: k.boolean(
      'pending',
      name: 'Pending',
      description: 'Whether agent output is still being generated.',
      initial: false,
    ),
    body: k.widgetInstance(
      'body',
      name: 'Message body',
      description: 'Registered content rendered inside the message.',
      initial: _cardDefaultInstanceId,
      options: const [
        _cardDefaultInstanceId,
        'desy.component.catalogue-card.default',
        'desy.component.progress-trail.active',
      ],
    ),
  ),
  build: (context, knobs) => DesyChatMessage(
    role: knobs.fromUser.value ? DesyChatRole.user : DesyChatRole.agent,
    label: knobs.label.value,
    pending: knobs.pending.value,
    child: knobs.body.widget,
  ),
  instances: (knobs) => {
    'agent': [
      knobs.label('GENUI AGENT'),
      knobs.fromUser(false),
      knobs.body(_cardDefaultInstanceId),
    ],
    'user': [
      knobs.label('YOU'),
      knobs.fromUser(true),
      knobs.body(_cardDefaultInstanceId),
    ],
    'pending': [
      knobs.label('GENUI AGENT'),
      knobs.pending(true),
      knobs.body(_cardDefaultInstanceId),
    ],
  },
  contract: DesyComponentContract(
    guidance:
        'Use agent messages for generated surfaces and user messages for prompts.',
    properties: [
      DesyContractProperty(name: 'label', type: 'String'),
      DesyContractProperty(name: 'role', type: 'DesyChatRole', required: true),
      DesyContractProperty(name: 'pending', type: 'bool'),
    ],
    slots: [
      DesyComponentSlot(
        name: 'body',
        accepts: 'Registered message content',
        required: true,
      ),
    ],
  ),
);

final _chatComposerComponent = DesyComponent(
  id: 'desy.component.chat-composer',
  name: 'Chat composer',
  path: '/agents/chat',
  icon: DesyIcons.send,
  description:
      'Collects a native text prompt and emits one semantic agent request.',
  accessibility:
      'Keeps native editing behavior and exposes a labelled keyboard-operable action.',
  source: 'package:desy_design_system/src/desy_chat.dart',
  knobs: (k) => (
    value: k.string(
      'value',
      name: 'Prompt',
      description: 'Current editable agent prompt.',
      initial: '',
    ),
    hint: k.string(
      'hint',
      name: 'Hint',
      description: 'Guidance shown while the prompt is empty.',
      initial: 'Describe the interface you need',
    ),
    submitLabel: k.string(
      'submitLabel',
      name: 'Action label',
      description: 'Visible label describing the generated outcome.',
      initial: 'Generate UI',
    ),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    loading: k.boolean('loading', name: 'Loading', initial: false),
    onSubmit: k.event(
      'onSubmit',
      name: 'Submit event',
      description: 'Action emitted with the entered text as its payload.',
    ),
  ),
  build: (context, knobs) => DesyChatComposer(
    value: knobs.value.value,
    hintText: knobs.hint.value,
    submitLabel: knobs.submitLabel.value,
    enabled: knobs.enabled.value,
    loading: knobs.loading.value,
    onSubmit: (value) => knobs.onSubmit.emit({'text': value}),
  ),
  instances: (knobs) => {
    'ready': [
      knobs.value('Create an inspection summary card.'),
      knobs.loading(false),
    ],
    'empty': [knobs.value('')],
    'loading': [
      knobs.value('Create a component comparison.'),
      knobs.loading(true),
    ],
  },
  contract: DesyComponentContract(
    guidance:
        'Keep business logic outside the component; emit the entered prompt through the event host.',
    properties: [
      DesyContractProperty(name: 'value', type: 'String'),
      DesyContractProperty(name: 'enabled', type: 'bool'),
      DesyContractProperty(name: 'loading', type: 'bool'),
    ],
  ),
);

final _chatThreadComponent = DesyComponent(
  id: 'desy.component.chat-thread',
  name: 'Chat thread',
  path: '/agents/chat',
  icon: DesyIcons.sparkles,
  description:
      'Frames ordered agent messages and one prompt composer as a workbench conversation.',
  accessibility:
      'Keep messages in reading order and place the composer after the transcript.',
  source: 'package:desy_design_system/src/desy_chat.dart',
  defaultSize: const Size(680, 620),
  knobs: (k) => (
    title: k.string(
      'title',
      name: 'Title',
      description: 'Stable agent or workflow name.',
      initial: 'GENUI AGENT',
    ),
    detail: k.string(
      'detail',
      name: 'Detail',
      description: 'Provider, model, or catalog context.',
      initial: 'desy.design-system',
    ),
    messages: k.widgetInstances(
      'messages',
      name: 'Messages',
      description: 'Messages in transcript reading order.',
      options: const [_chatMessageAgentInstanceId, _chatMessageUserInstanceId],
    ),
    composer: k.widgetInstance(
      'composer',
      name: 'Composer',
      description: 'The registered prompt composer shown after the transcript.',
      initial: _chatComposerReadyInstanceId,
      options: const [_chatComposerReadyInstanceId],
    ),
  ),
  build: (context, knobs) => DesyChatThread(
    title: knobs.title.value,
    detail: knobs.detail.value,
    messages: knobs.messages.widgets,
    composer: knobs.composer.widget,
  ),
  instances: (knobs) => {
    'default': [
      knobs.messages([_chatMessageUserInstanceId, _chatMessageAgentInstanceId]),
      knobs.composer(_chatComposerReadyInstanceId),
    ],
  },
  contract: DesyComponentContract(
    guidance:
        'Compose the conversation from registered messages and one registered composer.',
    slots: [
      DesyComponentSlot(
        name: 'messages',
        accepts: 'DesyChatMessage instances',
        required: true,
      ),
      DesyComponentSlot(
        name: 'composer',
        accepts: 'DesyChatComposer instance',
        required: true,
      ),
    ],
  ),
);

final _badgeComponent = _component(
  id: 'desy.component.badge',
  name: 'Badge',
  path: '/feedback',
  description: 'A compact non-interactive label for concise metadata.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_badge.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'EXPERIMENTAL'),
    outline: k.boolean('outline', name: 'Outline', initial: false),
  ),
  build: (context, knobs) => _buildBadge(
    context,
    label: knobs.label.value,
    outline: knobs.outline.value,
  ),
  instances: (knobs) => {
    'default': [knobs.label('EXPERIMENTAL'), knobs.outline(false)],
    'outline': [knobs.label('STABLE'), knobs.outline(true)],
  },
);

Widget _buildBadge(
  BuildContext context, {
  required String label,
  required bool outline,
}) => DesyBadge(
  variant: outline ? DesyBadgeVariant.outline : DesyBadgeVariant.primary,
  child: Text(label),
);

final _cardComponent = _component(
  id: 'desy.component.card',
  name: 'Card',
  path: '/surfaces',
  description: 'Contains a related workbench specimen or inspector section.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_card.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Registry source'),
    body: k.string(
      'body',
      name: 'Body',
      initial: 'One declared system drives every workbench surface.',
    ),
    showBody: k.boolean('showBody', name: 'Show body', initial: true),
  ),
  build: (context, knobs) => _buildCard(
    context,
    title: knobs.title.value,
    body: knobs.body.value,
    showBody: knobs.showBody.value,
  ),
  instances: (knobs) => {
    'default': [knobs.title('Registry source'), knobs.showBody(true)],
  },
);

Widget _buildCard(
  BuildContext context, {
  required String title,
  required String body,
  required bool showBody,
}) => DesyCard(
  child: Padding(
    padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (showBody) ...[
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          Text(body),
        ],
      ],
    ),
  ),
);

final _catalogueCardComponent = _component(
  id: 'desy.component.catalogue-card',
  name: 'Catalogue card',
  path: '/molecules/surfaces',
  description:
      'Separates a real component specimen from its durable registry identity.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_catalogue_card.dart',
  knobs: (k) => (
    path: k.string('path', name: 'Path', initial: 'Actions'),
    identifier: k.string(
      'identifier',
      name: 'Identifier',
      initial: 'desy.component.button',
    ),
    actionLabel: k.string(
      'actionLabel',
      name: 'Preview label',
      initial: 'Inspect',
    ),
    showAction: k.boolean(
      'showAction',
      name: 'Show preview action',
      initial: true,
    ),
  ),
  build: (context, knobs) => _buildCatalogueCard(
    context,
    path: knobs.path.value,
    identifier: knobs.identifier.value,
    actionLabel: knobs.actionLabel.value,
    showAction: knobs.showAction.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.path('Actions'),
      knobs.identifier('desy.component.button'),
      knobs.actionLabel('Inspect'),
      knobs.showAction(true),
    ],
  },
);

final _progressTrailComponent = _component(
  id: 'desy.component.progress-trail',
  name: 'Progress trail',
  path: '/molecules/feedback',
  description:
      'Connects completed work to the current task in a quiet, scannable list.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_progress_trail.dart',
  knobs: (k) => (
    current: k.boolean('current', name: 'Show current work', initial: true),
    metadata: k.boolean('metadata', name: 'Show metadata', initial: true),
  ),
  build: (context, knobs) => DesyProgressTrail(
    items: [
      DesyProgressTrailItem(
        title: 'Mapped the prototype surface',
        detail: 'Located the prototype builder and production component panel.',
        metadata: knobs.metadata.value ? '12s' : null,
        state: DesyProgressTrailItemState.complete,
        icon: Icons.search_rounded,
      ),
      DesyProgressTrailItem(
        title: 'Built the progress trail',
        detail: 'Reused Desy tokens, theme, and typed component state.',
        metadata: knobs.metadata.value ? '1 file' : null,
        state: DesyProgressTrailItemState.complete,
        icon: Icons.edit_rounded,
      ),
      DesyProgressTrailItem(
        title: knobs.current.value ? 'Running focused checks' : 'Checks passed',
        detail: 'Formatting and focused component tests.',
        metadata: knobs.metadata.value
            ? knobs.current.value
                  ? 'Running'
                  : 'Passed'
            : null,
        state: knobs.current.value
            ? DesyProgressTrailItemState.current
            : DesyProgressTrailItemState.complete,
        icon: Icons.check_rounded,
      ),
    ],
  ),
  instances: (knobs) => {
    'active': [knobs.current(true), knobs.metadata(true)],
    'complete': [knobs.current(false), knobs.metadata(true)],
  },
);

Widget _buildCatalogueCard(
  BuildContext context, {
  required String path,
  required String identifier,
  required String actionLabel,
  required bool showAction,
}) => DesyCatalogueCard(
  path: path,
  identifier: identifier,
  preview: Center(
    child: showAction
        ? DesyButton(
            size: DesyButtonSize.sm,
            mainAxisSize: MainAxisSize.min,
            onPress: () {},
            child: Text(actionLabel),
          )
        : const Text('Component preview'),
  ),
);

final _dialogComponent = _component(
  id: 'desy.component.dialog',
  name: 'Dialog',
  path: '/molecules/feedback',
  description: 'A focused modal decision or bounded selection surface.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Swap instance'),
    body: k.string(
      'body',
      name: 'Body',
      initial: 'Choose one legal component instance from the registry.',
    ),
    showBody: k.boolean('showBody', name: 'Show body', initial: true),
  ),
  build: (context, knobs) => _buildDialog(
    context,
    title: knobs.title.value,
    body: knobs.body.value,
    showBody: knobs.showBody.value,
  ),
  instances: (knobs) => {
    'default': [knobs.title('Swap instance'), knobs.showBody(true)],
  },
);

Widget _buildDialog(
  BuildContext context, {
  required String title,
  required String body,
  required bool showBody,
}) => DesyDialog(
  semanticsLabel: 'Example dialog',
  constraints: const BoxConstraints(maxWidth: 360),
  builder: (context, style) => Padding(
    padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: style.titleTextStyle),
        if (showBody) ...[
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          Text(body, style: style.bodyTextStyle),
        ],
      ],
    ),
  ),
);

final _selectComponent = _component(
  id: 'desy.component.select',
  name: 'Select',
  path: '/inputs',
  description: 'Chooses one typed value from a bounded option set.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    theme: k.choice(
      'theme',
      name: 'Theme',
      options: const ['Workbench light', 'Workbench dark', 'Follow system'],
    ),
    showDescriptions: k.boolean(
      'showDescriptions',
      name: 'Show descriptions',
      initial: false,
    ),
  ),
  build: (context, knobs) => _buildSelect(
    context,
    theme: knobs.theme.value,
    showDescriptions: knobs.showDescriptions.value,
  ),
  instances: (knobs) => {
    'light': [knobs.theme('Workbench light')],
    'dark': [knobs.theme('Workbench dark')],
    'system': [knobs.theme('Follow system')],
    'described': [knobs.showDescriptions(true)],
  },
);

Widget _buildSelect(
  BuildContext context, {
  required String theme,
  required bool showDescriptions,
}) => DesySelect<String>.rich(
  control: DesySelectControl.lifted(value: theme, onChange: (_) {}),
  format: (value) => value,
  children: [
    DesySelectItem.item(
      value: 'Workbench light',
      title: const Text('Workbench light'),
      subtitle: showDescriptions
          ? const Text('High-clarity neutral chrome')
          : null,
    ),
    DesySelectItem.item(
      value: 'Workbench dark',
      title: const Text('Workbench dark'),
      subtitle: showDescriptions
          ? const Text('Low-glare preview context')
          : null,
    ),
    DesySelectItem.item(
      value: 'Follow system',
      title: const Text('Follow system'),
      subtitle: showDescriptions
          ? const Text('Use the host platform brightness preference')
          : null,
    ),
  ],
);

final _switchComponent = DesyComponent(
  id: 'desy.component.switch',
  name: 'Switch',
  path: '/inputs',
  icon: DesyIcons.component,
  description: 'Changes one immediate boolean workbench preference.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Show grid'),
    value: k.boolean('value', name: 'Value', initial: true),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => _switchSpecimen(
    label: knobs.label.value,
    value: knobs.value.value,
    enabled: knobs.enabled.value,
  ),
  instances: (knobs) => {
    'on': [knobs.value(true)],
    'off': [knobs.value(false)],
    'disabled': [knobs.enabled(false)],
  },
);

Widget _switchSpecimen({
  required String label,
  required bool value,
  required bool enabled,
}) => DesySwitch(
  label: Text(label),
  value: value,
  onChange: enabled ? (_) {} : null,
);

final _numericKnobComponent = _component(
  id: 'desy.component.numeric-knob-row',
  name: 'Numeric knob row',
  path: '/inputs/knobs',
  description:
      'Edits a bounded numeric property through compact accessible step actions.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Width'),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyNumericKnobRow(
    label: knobs.label.value,
    value: 320,
    unit: 'px',
    step: 8,
    onChanged: knobs.enabled.value ? (_) {} : null,
  ),
  instances: (knobs) => {
    'default': [knobs.label('Width'), knobs.enabled(true)],
    'disabled': [knobs.label('Width'), knobs.enabled(false)],
  },
);

final _booleanKnobComponent = _component(
  id: 'desy.component.boolean-knob-row',
  name: 'Boolean knob row',
  path: '/inputs/knobs',
  description:
      'Aligns a boolean property with the real Desy switch without duplicating switch behavior.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Clip content'),
    value: k.boolean('value', name: 'Value', initial: true),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyBooleanKnobRow(
    label: knobs.label.value,
    value: knobs.value.value,
    onChanged: knobs.enabled.value ? (_) {} : null,
  ),
  instances: (knobs) => {
    'on': [knobs.value(true), knobs.enabled(true)],
    'off': [knobs.value(false), knobs.enabled(true)],
    'disabled': [knobs.enabled(false)],
  },
);

final _textKnobComponent = _component(
  id: 'desy.component.text-knob-row',
  name: 'Text knob row',
  path: '/inputs/knobs',
  description:
      'Aligns a named string property with Desy’s native editable field.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Title'),
    value: k.string('value', name: 'Value', initial: 'Precision sheet'),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyTextKnobRow(
    label: knobs.label.value,
    value: knobs.value.value,
    enabled: knobs.enabled.value,
    onChanged: (_) {},
  ),
  instances: (knobs) => {
    'default': [knobs.value('Precision sheet'), knobs.enabled(true)],
    'disabled': [knobs.enabled(false)],
  },
);

final _choiceKnobComponent = _component(
  id: 'desy.component.choice-knob-row',
  name: 'Choice knob row',
  path: '/inputs/knobs',
  description: 'Chooses one legal string through a compact Desy dropdown.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Visibility'),
    value: k.choice(
      'value',
      name: 'Value',
      options: const ['Automatic', 'Enabled', 'Disabled'],
    ),
    interactive: k.boolean('interactive', name: 'Interactive', initial: true),
  ),
  build: (context, knobs) => DesyChoiceKnobRow(
    label: knobs.label.value,
    value: knobs.value.value,
    options: knobs.value.definition.options,
    onChanged: knobs.interactive.value ? (_) {} : null,
  ),
  instances: (knobs) => {
    'automatic': [knobs.value('Automatic')],
    'enabled': [knobs.value('Enabled')],
    'disabled': [knobs.value('Disabled')],
    'read-only': [knobs.interactive(false)],
  },
);

final _dateTimeKnobComponent = _component(
  id: 'desy.component.date-time-knob-row',
  name: 'Date-time knob row',
  path: '/inputs/knobs',
  description:
      'Edits one typed Flutter DateTime through separate date and time fields.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Starts at'),
    value: k.dateTime(
      'value',
      name: 'Value',
      initial: DateTime.utc(2026, 8, 15, 9, 30),
    ),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyDateTimeKnobRow(
    label: knobs.label.value,
    value: knobs.value.value,
    onChanged: knobs.enabled.value ? (_) {} : null,
  ),
  instances: (knobs) => {
    'default': [knobs.value(DateTime.utc(2026, 8, 15, 9, 30))],
    'evening': [knobs.value(DateTime.utc(2026, 8, 15, 18, 45))],
    'disabled': [knobs.enabled(false)],
  },
);

final _colorKnobComponent = _component(
  id: 'desy.component.color-knob-row',
  name: 'Color knob row',
  path: '/inputs/knobs',
  description:
      'Edits a literal ARGB color while preserving the typed Flutter Color value.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Surface color'),
    color: k.color('color', name: 'Color', initial: const Color(0xFFFFF0F6)),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyColorKnobRow(
    label: knobs.label.value,
    value: knobs.color.value,
    onChanged: knobs.enabled.value ? (_) {} : null,
  ),
  instances: (knobs) => {
    'signal-surface': [
      knobs.label('Surface color'),
      knobs.color(const Color(0xFFFFF0F6)),
    ],
    'positive': [
      knobs.label('Status color'),
      knobs.color(const Color(0xFF16A34A)),
    ],
    'custom-translucent': [
      knobs.label('Overlay tint'),
      knobs.color(const Color(0x80336699)),
    ],
    'disabled': [knobs.enabled(false)],
  },
);

final _instanceKnobComponent = _component(
  id: 'desy.component.instance-knob-row',
  name: 'Instance knob row',
  path: '/inputs/knobs',
  description:
      'Shows the selected registered component instance and delegates picker ownership to the caller.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Suffix'),
    instance: k.widgetInstance(
      'instance',
      name: 'Instance',
      initial: _badgeDefaultInstanceId,
      options: const [
        _badgeDefaultInstanceId,
        'desy.component.badge.outline',
        _shortcutSingleKeyInstanceId,
      ],
    ),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => DesyInstanceKnobRow(
    label: knobs.label.value,
    instanceName: _knobSheetInstanceLabel(knobs.instance.value),
    prefix: const Icon(DesyIcons.component),
    onPress: knobs.enabled.value ? () {} : null,
  ),
  instances: (knobs) => {
    'badge': [knobs.instance(_badgeDefaultInstanceId), knobs.enabled(true)],
    'shortcut': [knobs.instance(_shortcutSingleKeyInstanceId)],
    'disabled': [knobs.enabled(false)],
  },
);

final _knobSheetComponent = _component(
  id: 'desy.component.knob-sheet',
  name: 'Knob sheet',
  path: '/molecules/inputs/knobs',
  description:
      'Groups related property controls and derives its visible count from the real rows.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_knob_sheet.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Knobs'),
    caption: k.string('caption', name: 'Caption', initial: 'Precision sheet'),
    density: k.choice(
      'density',
      name: 'Density',
      options: const ['Compact', 'Comfortable', 'Spacious'],
      initial: 'Comfortable',
    ),
    cornerRadius: k.number(
      'cornerRadius',
      name: 'Corner radius',
      initial: 8,
      unit: 'px',
      step: 1,
      minimum: 0,
      maximum: 48,
    ),
    clipContent: k.boolean('clipContent', name: 'Clip content', initial: true),
    scheduledAt: k.dateTime(
      'scheduledAt',
      name: 'Scheduled at',
      initial: DateTime.utc(2026, 8, 18, 9, 30),
    ),
    surfaceColor: k.color(
      'surfaceColor',
      name: 'Surface color',
      initial: const Color(0xFFFFF0F6),
    ),
    instance: k.widgetInstance(
      'instance',
      name: 'Instance',
      initial: 'desy.component.badge.default',
      options: const [
        'desy.component.badge.default',
        'desy.component.badge.outline',
      ],
    ),
  ),
  build: (context, knobs) => DesyKnobSheet(
    segments: [
      DesyKnobSegment(
        title: 'LAYOUT',
        children: [
          DesyChoiceKnobRow(
            label: 'Density',
            value: knobs.density.value,
            options: knobs.density.definition.options,
            onChanged: (_) {},
          ),
          DesyNumericKnobRow(
            label: 'Corner radius',
            value: knobs.cornerRadius.value,
            unit: 'px',
            step: 1,
            onChanged: (_) {},
          ),
        ],
      ),
      DesyKnobSegment(
        title: 'BEHAVIOR',
        children: [
          DesyBooleanKnobRow(
            label: 'Clip content',
            value: knobs.clipContent.value,
            onChanged: (_) {},
          ),
        ],
      ),
      DesyKnobSegment(
        title: 'CONTENT',
        children: [
          DesyTextKnobRow(
            label: 'Caption',
            value:
                '${knobs.caption.value} · '
                '${_knobSheetDateLabel(knobs.scheduledAt.value)}',
            onChanged: (_) {},
          ),
          DesyColorKnobRow(
            label: 'Surface color',
            value: knobs.surfaceColor.value,
            onChanged: (_) {},
          ),
          DesyInstanceKnobRow(
            label: 'Instance',
            instanceName: _knobSheetInstanceLabel(knobs.instance.value),
            prefix: const Icon(DesyIcons.component),
            onPress: () {},
          ),
        ],
      ),
    ],
  ),
  instances: (knobs) => {
    'default': [knobs.title('Knobs')],
    'roomy': [knobs.density('Spacious'), knobs.cornerRadius(12)],
    'labels': [knobs.caption('Live controls')],
    'signal-surface': [knobs.surfaceColor(const Color(0xFFFFF0F6))],
    'scheduled-evening': [
      knobs.caption('Evening review'),
      knobs.scheduledAt(DateTime.utc(2026, 8, 18, 18, 45)),
      knobs.surfaceColor(const Color(0xFFFFF0F6)),
    ],
    'scheduled-custom': [
      knobs.caption('Custom overlay review'),
      knobs.scheduledAt(DateTime.utc(2026, 8, 21, 14, 15)),
      knobs.surfaceColor(const Color(0x80336699)),
    ],
    'outline-instance': [knobs.instance('desy.component.badge.outline')],
  },
);

String _knobSheetInstanceLabel(DesyInstanceId id) => id.value
    .replaceFirst('desy.component.', '')
    .split('.')
    .map((segment) => '${segment[0].toUpperCase()}${segment.substring(1)}')
    .join(' · ');

String _knobSheetDateLabel(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-'
    '${value.month.toString().padLeft(2, '0')}-'
    '${value.day.toString().padLeft(2, '0')} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

final _textFieldComponent = DesyComponent(
  id: 'desy.component.text-field',
  name: 'Text field',
  path: '/inputs',
  icon: DesyIcons.component,
  description: 'Native Flutter text editing styled by the Desy theme bridge.',
  accessibility:
      'Preserve native selection, caret, keyboard, and context menus.',
  source: 'package:desy_design_system/src/desy_text_field.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Search'),
    hint: k.string('hint', name: 'Hint', initial: 'Search components'),
    value: k.string('value', name: 'Value', initial: ''),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
    multiline: k.boolean('multiline', name: 'Multiline', initial: false),
  ),
  build: (context, knobs) => DesyTextField(
    label: knobs.label.value,
    hintText: knobs.hint.value,
    value: knobs.value.value,
    enabled: knobs.enabled.value,
    minLines: knobs.multiline.value ? 3 : null,
    maxLines: knobs.multiline.value ? 5 : 1,
  ),
  instances: (knobs) => {
    'empty': [knobs.label('Search'), knobs.value('')],
    'disabled': [
      knobs.label('Search'),
      knobs.value('Atlas'),
      knobs.enabled(false),
    ],
    'multiline': [
      knobs.label('Notes'),
      knobs.hint('Add usage guidance'),
      knobs.multiline(true),
    ],
  },
);

final _accordionComponent = _component(
  id: 'desy.component.accordion',
  name: 'Accordion',
  path: '/molecules/navigation',
  description: 'Progressively discloses nested registry structure.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Components'),
    content: k.string(
      'content',
      name: 'Content',
      initial: 'Actions · Feedback · Inputs · Navigation',
    ),
    expanded: k.boolean('expanded', name: 'Initially expanded', initial: true),
  ),
  build: (context, knobs) => _buildAccordion(
    context,
    title: knobs.title.value,
    content: knobs.content.value,
    expanded: knobs.expanded.value,
  ),
  instances: (knobs) => {
    'default': [knobs.expanded(true)],
  },
);

Widget _buildAccordion(
  BuildContext context, {
  required String title,
  required String content,
  required bool expanded,
}) => DesyAccordion(
  children: [
    DesyAccordionItem(
      key: ValueKey('accordion-$expanded'),
      initiallyExpanded: expanded,
      title: Text(title),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text(content),
      ),
    ),
  ],
);

final _sidebarComponent = _component(
  id: 'desy.component.sidebar',
  name: 'Sidebar',
  path: '/molecules/navigation/sidebar',
  description: 'The complete section-and-item workbench navigation pattern.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_sidebar.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Product title', initial: 'DESY BENCH'),
    showAtoms: k.boolean('showAtoms', name: 'Show Atoms', initial: true),
    previewGrid: k.boolean(
      'previewGrid',
      name: 'Component preview grid',
      initial: false,
    ),
  ),
  build: (context, knobs) => _SidebarSpecimen(
    title: knobs.title.value,
    showAtoms: knobs.showAtoms.value,
    previewGrid: knobs.previewGrid.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.title('DESY BENCH'),
      knobs.showAtoms(true),
      knobs.previewGrid(false),
    ],
  },
);

final _sidebarSectionComponent = _component(
  id: 'desy.component.sidebar-section',
  name: 'Sidebar section',
  path: '/molecules/navigation/sidebar',
  description:
      'A navigation heading with an optional root destination and local setting.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_sidebar.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Components'),
    showCount: k.boolean('showCount', name: 'Show count', initial: true),
    showAction: k.boolean(
      'showAction',
      name: 'Show view action',
      initial: true,
    ),
    previewGrid: k.boolean(
      'previewGrid',
      name: 'Preview grid mode',
      initial: false,
    ),
    opensAtlas: k.boolean(
      'opensAtlas',
      name: 'Label opens Atlas',
      initial: true,
    ),
    collapsible: k.boolean('collapsible', name: 'Collapsible', initial: true),
  ),
  build: (context, knobs) => _buildSidebarSection(
    context,
    label: knobs.label.value,
    showCount: knobs.showCount.value,
    showAction: knobs.showAction.value,
    previewGrid: knobs.previewGrid.value,
    opensAtlas: knobs.opensAtlas.value,
    collapsible: knobs.collapsible.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.label('Components'),
      knobs.showCount(true),
      knobs.showAction(true),
      knobs.previewGrid(false),
      knobs.opensAtlas(true),
      knobs.collapsible(true),
    ],
  },
);

Widget _buildSidebarSection(
  BuildContext context, {
  required String label,
  required bool showCount,
  required bool showAction,
  required bool previewGrid,
  required bool opensAtlas,
  required bool collapsible,
}) => DesySidebar(
  children: [
    DesySidebarSection(
      label: label,
      count: showCount ? 16 : null,
      action: showAction
          ? Icon(
              previewGrid ? DesyIcons.folderTree : DesyIcons.layoutGrid,
              size: 15,
            )
          : null,
      actionSemanticsLabel: previewGrid
          ? 'Use component file tree'
          : 'Use component preview grid',
      onActionPress: showAction ? () {} : null,
      onLabelPress: opensAtlas ? () {} : null,
      collapsible: collapsible,
      children: const [
        DesySidebarItem(icon: Icon(DesyIcons.folder), label: Text('Actions')),
      ],
    ),
  ],
);

final _sidebarItemComponent = _component(
  id: 'desy.component.sidebar-item',
  name: 'Sidebar item',
  path: '/navigation/sidebar',
  description:
      'A simple icon-and-label row, with a screen form for major destinations.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_sidebar.dart',
  knobs: (k) => (
    label: k.string('label', name: 'Label', initial: 'Atlas'),
    opensScreen: k.boolean(
      'opensScreen',
      name: 'Opens a screen',
      initial: true,
    ),
    selected: k.boolean('selected', name: 'Selected', initial: false),
    enabled: k.boolean('enabled', name: 'Enabled', initial: true),
  ),
  build: (context, knobs) => _buildSidebarItem(
    context,
    label: knobs.label.value,
    opensScreen: knobs.opensScreen.value,
    selected: knobs.selected.value,
    enabled: knobs.enabled.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.label('Atlas'),
      knobs.opensScreen(true),
      knobs.selected(false),
      knobs.enabled(true),
    ],
  },
);

Widget _buildSidebarItem(
  BuildContext context, {
  required String label,
  required bool opensScreen,
  required bool selected,
  required bool enabled,
}) => DesySidebar(
  children: [
    DesySidebarSection(
      label: 'Workspace',
      children: [
        if (opensScreen)
          DesySidebarItem.screen(
            icon: const Icon(DesyIcons.layoutGrid),
            label: Text(label),
            selected: selected,
            onPress: enabled ? () {} : null,
          )
        else
          DesySidebarItem(
            icon: const Icon(DesyIcons.layoutGrid),
            label: Text(label),
            selected: selected,
            onPress: enabled ? () {} : null,
          ),
      ],
    ),
  ],
);

final _tabsComponent = _component(
  id: 'desy.component.tabs',
  name: 'Tabs',
  path: '/molecules/navigation',
  description: 'Switches between peer views without changing route ownership.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    firstLabel: k.string('firstLabel', name: 'First label', initial: 'Assets'),
    secondLabel: k.string(
      'secondLabel',
      name: 'Second label',
      initial: 'Layers',
    ),
    scrollable: k.boolean(
      'scrollable',
      name: 'Scrollable tabs',
      initial: false,
    ),
    expandContent: k.boolean(
      'expandContent',
      name: 'Expand content',
      initial: true,
    ),
  ),
  build: (context, knobs) => _buildTabs(
    context,
    firstLabel: knobs.firstLabel.value,
    secondLabel: knobs.secondLabel.value,
    scrollable: knobs.scrollable.value,
    expandContent: knobs.expandContent.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.firstLabel('Assets'),
      knobs.secondLabel('Layers'),
      knobs.scrollable(false),
      knobs.expandContent(true),
    ],
  },
);

Widget _buildTabs(
  BuildContext context, {
  required String firstLabel,
  required String secondLabel,
  required bool scrollable,
  required bool expandContent,
}) => DesyTabs(
  scrollable: scrollable,
  expands: expandContent,
  children: [
    DesyTabEntry(
      label: Text(firstLabel),
      child: Center(child: Text(firstLabel)),
    ),
    DesyTabEntry(
      label: Text(secondLabel),
      child: Center(child: Text(secondLabel)),
    ),
  ],
);

final _tileComponent = DesyComponent(
  id: 'desy.component.tile',
  name: 'Tile',
  path: '/molecules/navigation',
  icon: DesyIcons.component,
  description: 'A compact interactive row for navigation and selection.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Release channel'),
    suffix: k.widgetInstance(
      'suffix',
      name: 'Suffix instance',
      initial: _badgeDefaultInstanceId,
      options: const [_badgeDefaultInstanceId, _shortcutSingleKeyInstanceId],
    ),
  ),
  build: (context, knobs) =>
      _buildTileField(title: knobs.title.value, suffix: knobs.suffix.widget),
  instances: (knobs) => {
    'with-badge': [
      knobs.title('Release channel'),
      knobs.suffix(_badgeDefaultInstanceId),
    ],
    'with-shortcut': [
      knobs.title('Open command menu'),
      knobs.suffix(_shortcutSingleKeyInstanceId),
    ],
  },
  contract: DesyComponentContract(
    guidance:
        'Resolve the suffix from the registry so compositions retain stable '
        'instance IDs instead of widget callbacks.',
    properties: [
      DesyContractProperty(name: 'title', type: 'String', required: true),
    ],
    slots: [
      DesyComponentSlot(
        name: 'suffix',
        accepts: 'Widget / registered compact component instance',
        description:
            'A legal registry-backed instance such as a badge or shortcut.',
      ),
    ],
  ),
  scenarios: [
    DesyComponentScenario(
      id: 'missing-suffix-instance',
      name: 'Missing suffix instance',
      description:
          'Exercises the clickable diagnostic rendered for an unresolved '
          'registry ID.',
      builder: (context) => _buildTileField(
        title: 'Unresolved registry link',
        suffix: desyDesignSystemRegistry.widgetBuilder.build(
          context,
          _missingTileSuffixInstanceId,
        ),
      ),
    ),
  ],
);

Widget _buildTileField({required String title, required Widget suffix}) =>
    DesyTile(
      prefix: const Icon(DesyIcons.component),
      title: Text(title),
      subtitle: const Text('Registry-backed suffix'),
      suffix: suffix,
      onPress: () {},
    );

final _scaffoldComponent = _component(
  id: 'desy.component.scaffold',
  name: 'Scaffold',
  path: '/molecules/surfaces',
  description: 'The neutral structural surface around one workbench route.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    header: k.string('header', name: 'Header', initial: 'Workbench header'),
    content: k.string('content', name: 'Content', initial: 'Route content'),
    showHeader: k.boolean('showHeader', name: 'Show header', initial: true),
    showFooter: k.boolean('showFooter', name: 'Show footer', initial: false),
    padContent: k.boolean('padContent', name: 'Pad content', initial: true),
  ),
  build: (context, knobs) => _buildScaffold(
    context,
    header: knobs.header.value,
    content: knobs.content.value,
    showHeader: knobs.showHeader.value,
    showFooter: knobs.showFooter.value,
    padContent: knobs.padContent.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.header('Workbench header'),
      knobs.content('Route content'),
      knobs.showHeader(true),
      knobs.showFooter(false),
      knobs.padContent(true),
    ],
  },
);

final _resizeDividerComponent = _component(
  id: 'desy.component.resize-divider',
  name: 'Resize divider',
  path: '/layout',
  description:
      'Owns one structural hairline and its complete pointer, keyboard, and semantic resize interaction.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/desy_resize_divider.dart',
  knobs: (k) => (
    vertical: k.boolean('vertical', name: 'Vertical', initial: true),
    label: k.string('label', name: 'Accessible label', initial: 'Resize panel'),
  ),
  build: (context, knobs) => _ResizeDividerSpecimen(
    axis: knobs.vertical.value ? Axis.vertical : Axis.horizontal,
    semanticsLabel: knobs.label.value,
  ),
  instances: (knobs) => {
    'vertical': [knobs.vertical(true), knobs.label('Resize sidebar')],
    'horizontal': [knobs.vertical(false), knobs.label('Resize lower panel')],
  },
);

Widget _buildScaffold(
  BuildContext context, {
  required String header,
  required String content,
  required bool showHeader,
  required bool showFooter,
  required bool padContent,
}) => DesyScaffold(
  childPad: padContent,
  header: showHeader
      ? Padding(
          padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
          child: Text(header),
        )
      : null,
  footer: showFooter
      ? const Padding(
          padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
          child: Text('Workbench footer'),
        )
      : null,
  child: Center(child: Text(content)),
);

final _desyIcons = [
  _desyIcon('layout-grid', 'Layout grid', DesyIcons.layoutGrid),
  _desyIcon('boxes', 'Boxes', DesyIcons.boxes),
  _desyIcon('component', 'Component', DesyIcons.component),
  _desyIcon('folder', 'Folder', DesyIcons.folder),
  _desyIcon('folder-tree', 'Folder tree', DesyIcons.folderTree),
  _desyIcon('palette', 'Palette', DesyIcons.palette),
  _desyIcon('type', 'Type', DesyIcons.type),
  _desyIcon('ruler', 'Ruler', DesyIcons.ruler),
  _desyIcon('send', 'Send', DesyIcons.send),
  _desyIcon('shapes', 'Shapes', DesyIcons.shapes),
  _desyIcon('layers', 'Layers', DesyIcons.layers),
  _desyIcon('image', 'Image', DesyIcons.image),
  _desyIcon('smartphone', 'Smartphone', DesyIcons.smartphone),
  _desyIcon('tablet', 'Tablet', DesyIcons.tablet),
  _desyIcon('triangle-alert', 'Triangle alert', DesyIcons.triangleAlert),
  _desyIcon('sparkles', 'Sparkles', DesyIcons.sparkles),
  _desyIcon('camera', 'Camera', DesyIcons.camera),
  _desyIcon('panel-left-open', 'Panel left open', DesyIcons.panelLeftOpen),
  _desyIcon('panel-left-close', 'Panel left close', DesyIcons.panelLeftClose),
  _desyIcon('chevron-right', 'Chevron right', DesyIcons.chevronRight),
  _desyIcon('chevron-down', 'Chevron down', DesyIcons.chevronDown),
  _desyIcon('chevron-up', 'Chevron up', DesyIcons.chevronUp),
  _desyIcon('chevrons-up-down', 'Chevrons up down', DesyIcons.chevronsUpDown),
  _desyIcon('check', 'Check', DesyIcons.check),
  _desyIcon('arrow-left', 'Arrow left', DesyIcons.arrowLeft),
  _desyIcon('minus', 'Minus', DesyIcons.minus),
  _desyIcon('plus', 'Plus', DesyIcons.plus),
  _desyIcon('play', 'Play', DesyIcons.play),
  _desyIcon('pause', 'Pause', DesyIcons.pause),
];

DesyIconEntry _desyIcon(String id, String name, IconData icon) =>
    DesyIconEntry(id: 'desy.icon.$id', name: name, icon: icon);

final _shortcutComponent = DesyComponent(
  id: 'desy.component.shortcut-label',
  name: 'Keyboard shortcut label',
  path: '/utilities',
  icon: DesyIcons.component,
  description:
      'A compact semantic keycap treatment for discoverable shortcuts.',
  accessibility:
      'Announce the complete chord rather than individual decoration.',
  source: 'package:desy_design_system/src/keyboard_shortcut_label.dart',
  knobs: (k) => (
    key: k.string('key', name: 'Key', initial: 'K'),
    chord: k.boolean('chord', name: 'Include modifier', initial: true),
  ),
  build: (context, knobs) => DesyKeyboardShortcutLabel(
    keys: knobs.chord.value ? ['⌘', knobs.key.value] : [knobs.key.value],
  ),
  instances: (knobs) => {
    'single-key': [knobs.key('Esc'), knobs.chord(false)],
    'chord': [knobs.chord(true)],
  },
);

DesyComponent<K> _component<K>({
  required String id,
  required String name,
  required String path,
  required String description,
  required IconData icon,
  required String source,
  required K Function(KnobScope k) knobs,
  required Widget Function(BuildContext context, K knobs) build,
  required Map<String, Iterable<KnobSettingBase>> Function(K knobs) instances,
}) => DesyComponent<K>(
  id: id,
  name: name,
  path: path,
  icon: icon,
  description: description,
  source: source,
  knobs: knobs,
  build: build,
  instances: instances,
);

class _ResizeDividerSpecimen extends StatefulWidget {
  const _ResizeDividerSpecimen({
    required this.axis,
    required this.semanticsLabel,
  });

  final Axis axis;
  final String semanticsLabel;

  @override
  State<_ResizeDividerSpecimen> createState() => _ResizeDividerSpecimenState();
}

class _ResizeDividerSpecimenState extends State<_ResizeDividerSpecimen> {
  var _leadingSize = 112.0;

  void _resize(double delta) {
    final maximum = widget.axis == Axis.vertical ? 240.0 : 120.0;
    setState(() {
      _leadingSize = (_leadingSize + delta).clamp(64.0, maximum);
    });
  }

  @override
  Widget build(BuildContext context) {
    final leading = ColoredBox(
      color: context.theme.colors.desy.panelSubtle,
      child: const Center(child: Text('Resizable region')),
    );
    final trailing = ColoredBox(
      color: context.theme.colors.background,
      child: const Center(child: Text('Content')),
    );
    final divider = DesyResizeDivider(
      axis: widget.axis,
      value: _leadingSize,
      semanticsLabel: widget.semanticsLabel,
      onResize: _resize,
    );

    return SizedBox(
      width: 320,
      height: 180,
      child: widget.axis == Axis.vertical
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: _leadingSize, child: leading),
                divider,
                Expanded(child: trailing),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: _leadingSize, child: leading),
                divider,
                Expanded(child: trailing),
              ],
            ),
    );
  }
}

class _SidebarSpecimen extends StatelessWidget {
  const _SidebarSpecimen({
    required this.title,
    required this.showAtoms,
    required this.previewGrid,
  });

  final String title;
  final bool showAtoms;
  final bool previewGrid;

  @override
  Widget build(BuildContext context) => DesySidebar(
    header: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Text(title),
    ),
    children: [
      const DesySidebarSection(
        label: 'Workspace',
        children: [
          DesySidebarItem.screen(
            icon: Icon(DesyIcons.layoutGrid),
            label: Text('Atlas'),
            selected: true,
          ),
          DesySidebarItem.screen(
            icon: Icon(DesyIcons.boxes),
            label: Text('Sketch'),
          ),
          DesySidebarItem.screen(
            icon: Icon(DesyIcons.sparkles),
            label: Text('AI prompts'),
          ),
        ],
      ),
      if (showAtoms)
        const DesySidebarSection(
          label: 'Atoms',
          children: [
            DesySidebarItem(
              icon: Icon(DesyIcons.palette),
              label: Text('Colors'),
            ),
            DesySidebarItem(icon: Icon(DesyIcons.type), label: Text('Fonts')),
          ],
        ),
      DesySidebarSection(
        label: 'Components',
        count: 16,
        action: Icon(
          previewGrid ? DesyIcons.folderTree : DesyIcons.layoutGrid,
          size: 15,
        ),
        actionSemanticsLabel: previewGrid
            ? 'Use component file tree'
            : 'Use component preview grid',
        onActionPress: () {},
        children: const [
          DesySidebarItem(
            icon: Icon(DesyIcons.folder),
            label: Text('Actions'),
            initiallyExpanded: true,
            children: [
              DesySidebarItem(
                icon: Icon(DesyIcons.component),
                label: Text('Button'),
              ),
            ],
          ),
          DesySidebarItem(
            icon: Icon(DesyIcons.folder),
            label: Text('Feedback'),
          ),
        ],
      ),
    ],
  );
}

Widget _buildMotionSpecimen(
  BuildContext context,
  Widget child,
  Duration duration,
) => _MotionSpecimen(child: child);

Widget _buildSidebarReveal(
  BuildContext context,
  Widget child,
  Duration duration,
) => DesyMotionReveal(beginOffset: const Offset(-24, 0), child: child);

Widget _buildScreenReveal(
  BuildContext context,
  Widget child,
  Duration duration,
) => DesyMotionReveal(beginOffset: const Offset(20, 0), child: child);

Widget _buildMotionTransition(
  BuildContext context,
  Widget first,
  Widget second,
  Duration duration,
) => _MotionSpecimen(
  child: DesyMotionWidgetTransition(first: first, second: second),
);

Widget _buildContentSwapTransition(
  BuildContext context,
  Widget first,
  Widget second,
  Duration duration,
) => DesyMotionWidgetTransition(first: first, second: second, distance: 0);

Widget _buildScreenNavigationTransition(
  BuildContext context,
  Widget first,
  Widget second,
  Duration duration,
) => DesyMotionWidgetTransition(first: first, second: second, distance: 32);

Widget _buildSignalSquare(BuildContext context) => const _SignalSquare();

class _MotionSpecimen extends StatelessWidget {
  const _MotionSpecimen({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress =
        DesyMotionPlaybackScope.maybeOf(context) ?? kAlwaysDismissedAnimation;
    return AnimatedBuilder(
      animation: progress,
      child: child,
      builder: (context, child) => SingleMotionBuilder(
        motion: const MaterialSpringMotion.expressiveSpatialDefault(),
        from: 0,
        value: progress.value,
        child: child,
        builder: (context, value, child) {
          final visible = value.clamp(0.0, 1.0).toDouble();
          return Opacity(
            opacity: visible,
            child: Transform.translate(
              offset: Offset(96 * (1 - visible), 0),
              child: Transform.rotate(
                angle: .075 * (1 - visible),
                child: Transform.scale(
                  scale: .82 + (.18 * visible),
                  child: child,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignalSquare extends StatelessWidget {
  const _SignalSquare();

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      key: const ValueKey('dogfood-motion-specimen'),
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.desy.signal,
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332B1020),
            offset: Offset(0, 12),
            blurRadius: 24,
            spreadRadius: -12,
          ),
        ],
      ),
      child: Icon(DesyIcons.sparkles, color: colors.primaryForeground),
    );
  }
}
