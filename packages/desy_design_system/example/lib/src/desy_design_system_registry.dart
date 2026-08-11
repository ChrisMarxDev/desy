import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

final _lightTheme = DesyDesignSystemFoundation.themeData(
  DesyDesignSystemTheme.light,
);
final _darkTheme = DesyDesignSystemFoundation.themeData(
  DesyDesignSystemTheme.dark,
);

const _badgeDefaultInstanceId = 'desy.component.badge.default';
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
      id: 'desy.motion.navigation',
      name: 'Navigation reveal',
      duration: DesyDesignSystemTokens.navigationMotion,
      curve: Curves.easeOutCubic,
      description: 'Sidebar width and similar spatial navigation changes.',
      builder: (context) => const _MotionSpecimen(),
    ),
    DesyMotionEntry(
      id: 'desy.motion.feedback',
      name: 'Feedback emphasis',
      duration: DesyDesignSystemTokens.feedbackMotion,
      curve: Curves.easeOutCubic,
      description: 'A concise confirmation or newly revealed state.',
      builder: (context) => const _MotionSpecimen(),
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
  components: [
    _buttonComponent,
    _badgeComponent,
    _dialogComponent,
    _selectComponent,
    _switchComponent,
    _numericKnobComponent,
    _booleanKnobComponent,
    _textKnobComponent,
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

class _SignalRibbon extends StatelessWidget {
  const _SignalRibbon({this.quiet = false});

  final bool quiet;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 280,
    height: 112,
    child: DecoratedBox(
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
  ),
  build: (context, knobs) => DesyButton(
    variant: knobs.outline.value
        ? DesyButtonVariant.outline
        : DesyButtonVariant.primary,
    mainAxisSize: MainAxisSize.min,
    onPress: knobs.enabled.value ? () {} : null,
    child: Text(knobs.label.value),
  ),
  instances: (knobs) => {
    'primary': [knobs.label('Inspect component')],
    'outline': [knobs.label('Open settings'), knobs.outline(true)],
    'disabled': [knobs.label('Unavailable'), knobs.enabled(false)],
  },
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
  build: (context, knobs) => SizedBox(
    width: 360,
    child: DesyProgressTrail(
      items: [
        DesyProgressTrailItem(
          title: 'Mapped the prototype surface',
          detail:
              'Located the prototype builder and production component panel.',
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
          title: knobs.current.value
              ? 'Running focused checks'
              : 'Checks passed',
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
}) => SizedBox(
  width: 280,
  height: 236,
  child: DesyCatalogueCard(
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
    dark: k.boolean('dark', name: 'Select dark theme', initial: false),
    showDescriptions: k.boolean(
      'showDescriptions',
      name: 'Show descriptions',
      initial: false,
    ),
  ),
  build: (context, knobs) => _buildSelect(
    context,
    dark: knobs.dark.value,
    showDescriptions: knobs.showDescriptions.value,
  ),
  instances: (knobs) => {
    'default': [knobs.dark(false), knobs.showDescriptions(false)],
  },
);

Widget _buildSelect(
  BuildContext context, {
  required bool dark,
  required bool showDescriptions,
}) => SizedBox(
  width: 280,
  child: DesySelect<String>.rich(
    control: DesySelectControl.lifted(
      value: dark ? 'dark' : 'light',
      onChange: (_) {},
    ),
    format: (value) => value == 'light' ? 'Workbench light' : 'Workbench dark',
    children: [
      DesySelectItem.item(
        value: 'light',
        title: const Text('Workbench light'),
        subtitle: showDescriptions
            ? const Text('High-clarity neutral chrome')
            : null,
      ),
      DesySelectItem.item(
        value: 'dark',
        title: const Text('Workbench dark'),
        subtitle: showDescriptions
            ? const Text('Low-glare preview context')
            : null,
      ),
    ],
  ),
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
}) => SizedBox(
  width: 160,
  child: DesySwitch(
    label: Text(label),
    value: value,
    onChange: enabled ? (_) {} : null,
  ),
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
  build: (context, knobs) => SizedBox(
    width: 320,
    child: DesyNumericKnobRow(
      label: knobs.label.value,
      value: 320,
      unit: 'px',
      step: 8,
      onChanged: knobs.enabled.value ? (_) {} : null,
    ),
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
  build: (context, knobs) => SizedBox(
    width: 320,
    child: DesyBooleanKnobRow(
      label: knobs.label.value,
      value: knobs.value.value,
      onChanged: knobs.enabled.value ? (_) {} : null,
    ),
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
  build: (context, knobs) => SizedBox(
    width: 360,
    child: DesyTextKnobRow(
      label: knobs.label.value,
      value: knobs.value.value,
      enabled: knobs.enabled.value,
      onChanged: (_) {},
    ),
  ),
  instances: (knobs) => {
    'default': [knobs.value('Precision sheet'), knobs.enabled(true)],
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
  build: (context, knobs) => SizedBox(
    width: 320,
    child: DesyColorKnobRow(
      label: knobs.label.value,
      value: knobs.color.value,
      onChanged: knobs.enabled.value ? (_) {} : null,
    ),
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
  build: (context, knobs) => SizedBox(
    width: 380,
    child: DesyInstanceKnobRow(
      label: knobs.label.value,
      instanceName: _knobSheetInstanceLabel(knobs.instance.value),
      prefix: const Icon(DesyIcons.component),
      onPress: knobs.enabled.value ? () {} : null,
    ),
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
    width: k.number(
      'width',
      name: 'Width',
      initial: 320,
      unit: 'px',
      step: 8,
      minimum: 160,
      maximum: 640,
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
    showLabel: k.boolean('showLabel', name: 'Show label', initial: false),
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
  build: (context, knobs) => SizedBox(
    width: knobs.width.value,
    child: DesyKnobSheet(
      title: knobs.title.value,
      sections: [
        DesyKnobSection(
          label: 'LAYOUT',
          children: [
            DesyNumericKnobRow(
              label: 'Width',
              value: knobs.width.value,
              unit: 'px',
              step: 8,
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
        DesyKnobSection(
          label: 'BEHAVIOR',
          children: [
            DesyBooleanKnobRow(
              label: 'Clip content',
              value: knobs.clipContent.value,
              onChanged: (_) {},
            ),
            DesyBooleanKnobRow(
              label: 'Show label',
              value: knobs.showLabel.value,
              onChanged: (_) {},
            ),
          ],
        ),
        DesyKnobSection(
          label: 'CONTENT',
          children: [
            DesyTextKnobRow(
              label: 'Caption',
              value: knobs.caption.value,
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
  ),
  instances: (knobs) => {
    'default': [knobs.title('Knobs')],
    'roomy': [knobs.width(400), knobs.cornerRadius(12)],
    'labels': [knobs.caption('Live controls'), knobs.showLabel(true)],
    'signal-surface': [knobs.surfaceColor(const Color(0xFFFFF0F6))],
    'outline-instance': [knobs.instance('desy.component.badge.outline')],
  },
);

String _knobSheetInstanceLabel(DesyInstanceId id) => id.value
    .replaceFirst('desy.component.', '')
    .split('.')
    .map((segment) => '${segment[0].toUpperCase()}${segment.substring(1)}')
    .join(' · ');

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
  build: (context, knobs) => _TextFieldFrame(
    child: DesyTextField(
      label: knobs.label.value,
      hintText: knobs.hint.value,
      value: knobs.value.value,
      enabled: knobs.enabled.value,
      minLines: knobs.multiline.value ? 3 : null,
      maxLines: knobs.multiline.value ? 5 : 1,
    ),
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
}) => SizedBox(
  width: 320,
  child: DesyAccordion(
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
  ),
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
  ),
  build: (context, knobs) => _buildSidebarSection(
    context,
    label: knobs.label.value,
    showCount: knobs.showCount.value,
    showAction: knobs.showAction.value,
    previewGrid: knobs.previewGrid.value,
    opensAtlas: knobs.opensAtlas.value,
  ),
  instances: (knobs) => {
    'default': [
      knobs.label('Components'),
      knobs.showCount(true),
      knobs.showAction(true),
      knobs.previewGrid(false),
      knobs.opensAtlas(true),
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
}) => SizedBox(
  width: 248,
  height: 150,
  child: DesySidebar(
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
        children: const [
          DesySidebarItem(icon: Icon(DesyIcons.folder), label: Text('Actions')),
        ],
      ),
    ],
  ),
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
}) => SizedBox(
  width: 248,
  height: 110,
  child: DesySidebar(
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
  ),
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
}) => SizedBox(
  width: 360,
  height: 180,
  child: DesyTabs(
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
  ),
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
    SizedBox(
      width: 340,
      child: DesyTile(
        prefix: const Icon(DesyIcons.component),
        title: Text(title),
        subtitle: const Text('Registry-backed suffix'),
        suffix: suffix,
        onPress: () {},
      ),
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
}) => SizedBox(
  width: 380,
  height: 220,
  child: DesyScaffold(
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
  ),
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
  Widget build(BuildContext context) => SizedBox(
    width: 248,
    height: 560,
    child: DesySidebar(
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
    ),
  );
}

class _TextFieldFrame extends StatelessWidget {
  const _TextFieldFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(width: 300, child: child);
}

class _MotionSpecimen extends StatelessWidget {
  const _MotionSpecimen();

  @override
  Widget build(BuildContext context) {
    final progress =
        DesyMotionPlaybackScope.maybeOf(context) ?? kAlwaysDismissedAnimation;
    final colors = context.theme.colors;
    return AnimatedBuilder(
      animation: progress,
      builder: (context, child) => Container(
        key: const ValueKey('dogfood-motion-specimen'),
        width: 120 + (100 * progress.value),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        ),
        child: child,
      ),
      child: Text(
        'Motion preview',
        style: TextStyle(color: colors.primaryForeground),
      ),
    );
  }
}
