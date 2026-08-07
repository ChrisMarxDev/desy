import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'sample_components.dart';
import 'sample_theme.dart';

final _cardTrailingInstances = [
  DesyComponentInstance(
    id: 'clear',
    name: 'Clear status',
    icon: FLucideIcons.badgeCheck,
    description: 'Confirmed operational state.',
    knobValues: DesyKnobValues({'label': 'On schedule', 'tone': 'success'}),
  ),
  DesyComponentInstance(
    id: 'review',
    name: 'Review status',
    icon: FLucideIcons.triangleAlert,
    description: 'State that needs follow-up before publishing.',
    knobValues: DesyKnobValues({'label': 'Review needed', 'tone': 'warning'}),
  ),
  DesyComponentInstance(
    id: 'delayed',
    name: 'Delayed status',
    icon: FLucideIcons.octagonAlert,
    description: 'State that blocks the expected plan.',
    knobValues: DesyKnobValues({'label': 'Delayed', 'tone': 'critical'}),
  ),
];

const _clearStatusId = 'harbor.badge.status.clear';
const _reviewStatusId = 'harbor.badge.status.review';
const _delayedStatusId = 'harbor.badge.status.delayed';

final _sampleThemes = [
  DesyTheme(
    id: 'harbor.daylight',
    name: 'Daylight',
    description: 'High-clarity surfaces for the primary working environment.',
    previewBackgroundColor: SampleColors.mist,
    wrap: (context, child) => Theme(data: sampleLightTheme, child: child),
  ),
  DesyTheme(
    id: 'harbor.midnight',
    name: 'Midnight',
    description: 'Low-glare treatment for monitoring after dark.',
    previewBackgroundColor: const Color(0xff17211f),
    isDark: true,
    wrap: (context, child) => Theme(data: sampleDarkTheme, child: child),
  ),
];

final _sampleColors = [
  DesyColorEntry.swatch(
    id: 'color.brand.lagoon',
    name: 'Lagoon',
    color: SampleColors.lagoon,
    description: 'Primary actions and confirmed states.',
  ),
  DesyColorEntry.swatch(
    id: 'color.brand.iris',
    name: 'Iris',
    color: SampleColors.iris,
    description: 'Informative emphasis and system notices.',
  ),
  DesyColorEntry.swatch(
    id: 'color.signal.sun',
    name: 'Signal sun',
    color: SampleColors.sun,
    description: 'Warnings that need review.',
  ),
  DesyColorEntry.swatch(
    id: 'color.signal.coral',
    name: 'Signal coral',
    color: SampleColors.coral,
    description: 'Errors and destructive actions.',
  ),
  DesyColorEntry.gradient(
    id: 'treatment.tide-line',
    name: 'Tide line',
    value: 'Lagoon → Iris',
    gradient: const LinearGradient(
      colors: [SampleColors.lagoon, SampleColors.iris],
    ),
    description: 'A directional treatment for status overviews and maps.',
  ),
  DesyColorEntry(
    id: 'treatment.status-set',
    name: 'Operational status set',
    value: 'Consumer widget preview',
    description:
        'A custom treatment can show a real system widget, not only pigment.',
    builder: (context) => SizedBox(
      width: 240,
      height: 140,
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              SampleStatusBadge(label: 'Clear', tone: SampleStatusTone.success),
              SampleStatusBadge(
                label: 'Review',
                tone: SampleStatusTone.warning,
              ),
            ],
          ),
        ),
      ),
    ),
  ),
];

final _sampleTypography = [
  DesyTypographyEntry(
    id: 'type.display',
    name: 'Display',
    value: 'displaySmall',
    description: 'Use for a page’s single, primary idea.',
    builder: (context, text) =>
        Text(text, style: Theme.of(context).textTheme.displaySmall),
    sample: 'Berths and tides',
  ),
  DesyTypographyEntry(
    id: 'type.section-title',
    name: 'Section title',
    value: 'titleLarge',
    description: 'Introduces a related group of operational details.',
    builder: (context, text) =>
        Text(text, style: Theme.of(context).textTheme.titleLarge),
    sample: 'Today’s berth plan',
  ),
  DesyTypographyEntry(
    id: 'type.body',
    name: 'Body',
    value: 'bodyLarge',
    description: 'The default style for guidance and readable detail.',
    builder: (context, text) =>
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
    sample: 'The north quay opens after the morning inspection.',
  ),
  DesyTypographyEntry(
    id: 'type.label',
    name: 'Label',
    value: 'labelLarge',
    description: 'Names controls and compact interface metadata.',
    builder: (context, text) =>
        Text(text, style: Theme.of(context).textTheme.labelLarge),
    sample: 'PUBLISHED SCHEDULE',
  ),
];

final _sampleNumbers = [
  DesyNumericEntry.spacing(
    id: 'space.tight',
    name: 'Tight',
    value: 8,
    description: 'Keeps controls and compact status details closely related.',
  ),
  DesyNumericEntry.spacing(
    id: 'space.default',
    name: 'Default',
    value: 16,
    description: 'The default gap between related Harbor interface elements.',
  ),
  DesyNumericEntry.spacing(
    id: 'space.section',
    name: 'Section',
    value: 24,
    description: 'Separates distinct groups within one operational surface.',
  ),
  DesyNumericEntry.spacing(
    id: 'space.page',
    name: 'Page',
    value: 32,
    description: 'Provides breathing room around major page regions.',
  ),
  DesyNumericEntry.breakpoint(
    id: 'layout.compact',
    name: 'Compact threshold',
    value: 720,
    description:
        'The workspace changes from split to stacked below this width.',
  ),
];

final _sampleMotion = [
  DesyMotionEntry(
    id: 'motion.feedback',
    name: 'Feedback emphasis',
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeOutCubic,
    description: 'Use for a small confirmation or newly revealed status.',
    builder: (context) => const SizedBox(
      width: 180,
      height: 52,
      child: SampleMotionSpecimen(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      ),
    ),
  ),
];

final _sampleEffects = [
  DesyEffectEntry.boxShadow(
    id: 'effect.surface.lifted',
    name: 'Lifted surface',
    description: 'Use for a contained surface that needs a quiet separation.',
    shadows: [
      BoxShadow(
        color: Color(0x240f2420),
        offset: Offset(0, 6),
        blurRadius: 18,
        spreadRadius: -6,
      ),
    ],
  ),
  DesyEffectEntry.boxShadow(
    id: 'effect.surface.floating',
    name: 'Floating surface',
    description: 'Reserve for temporary surfaces above a working canvas.',
    shadows: [
      BoxShadow(
        color: Color(0x3317201f),
        offset: Offset(0, 14),
        blurRadius: 32,
        spreadRadius: -10,
      ),
    ],
  ),
];

final _sampleAssets = [
  DesyAssetEntry.image(
    id: 'asset.app-mark.small',
    name: 'Application mark',
    image: AssetImage('web/icons/Icon-192.png'),
    group: 'Logos',
    value: 'web/icons/Icon-192.png',
    description: 'Compact square application mark for small placements.',
    semanticLabel: 'Harbor Operations application mark',
  ),
  DesyAssetEntry.image(
    id: 'asset.app-mark.large',
    name: 'Application mark · large',
    image: AssetImage('web/icons/Icon-512.png'),
    group: 'Logos',
    value: 'web/icons/Icon-512.png',
    description: 'High-resolution application mark for larger placements.',
    semanticLabel: 'Harbor Operations application mark',
  ),
];

final _sampleComponents = [
  DesyComponent(
    id: 'harbor.button.primary',
    name: 'Primary button',
    icon: FLucideIcons.mousePointerClick,
    category: 'Action',
    description: 'The one dominant action in a focused task.',
    accessibility: 'Use a specific visible label that describes the outcome.',
    source: 'lib/src/sample_components.dart',
    preview: (context) =>
        SampleButton(label: 'Publish schedule', onPressed: () {}),
    knobs: const [
      DesyStringKnob(
        id: 'label',
        name: 'Action label',
        initial: 'Publish schedule',
      ),
      DesyBooleanKnob(id: 'enabled', name: 'Enabled', initial: true),
    ],
    buildWithKnobs: (context, values, _) => SampleButton(
      label: values.string('label'),
      onPressed: values.boolean('enabled') ? () {} : null,
    ),
    instances: [
      DesyComponentInstance(
        id: 'publish-schedule',
        name: 'Publish schedule',
        description: 'Enabled primary action for a final review step.',
        knobValues: DesyKnobValues({'label': 'Publish schedule'}),
      ),
      DesyComponentInstance(
        id: 'save-draft',
        name: 'Save draft',
        description: 'A quieter saved-progress action while editing.',
        knobValues: DesyKnobValues({'label': 'Save draft'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.button.secondary',
    name: 'Secondary button',
    icon: FLucideIcons.slidersHorizontal,
    category: 'Action',
    description: 'A supporting action that stays visually subordinate.',
    accessibility: 'Do not use this styling for destructive actions.',
    source: 'lib/src/sample_components.dart',
    preview: (context) =>
        SampleSecondaryButton(label: 'Adjust filters', onPressed: () {}),
    knobs: const [
      DesyStringKnob(
        id: 'label',
        name: 'Action label',
        initial: 'Adjust filters',
      ),
      DesyBooleanKnob(id: 'enabled', name: 'Enabled', initial: true),
    ],
    buildWithKnobs: (context, values, _) => SampleSecondaryButton(
      label: values.string('label'),
      onPressed: values.boolean('enabled') ? () {} : null,
    ),
    instances: [
      DesyComponentInstance(
        id: 'adjust-filters',
        name: 'Adjust filters',
        knobValues: DesyKnobValues({'label': 'Adjust filters'}),
      ),
      DesyComponentInstance(
        id: 'view-berths',
        name: 'View berths',
        knobValues: DesyKnobValues({'label': 'View berths'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.badge.status',
    name: 'Status badge',
    icon: FLucideIcons.badgeCheck,
    category: 'Feedback',
    description: 'A concise, always-visible state label.',
    accessibility:
        'Include the status meaning in text; color is supplementary.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SampleStatusBadge(label: 'On schedule', tone: SampleStatusTone.success),
        SampleStatusBadge(
          label: 'Review needed',
          tone: SampleStatusTone.warning,
        ),
        SampleStatusBadge(label: 'Delayed', tone: SampleStatusTone.critical),
      ],
    ),
    knobs: const [
      DesyStringKnob(id: 'label', name: 'Label', initial: 'On schedule'),
      DesyStringKnob(id: 'tone', name: 'Tone', initial: 'success'),
    ],
    buildWithKnobs: (context, values, _) => SampleStatusBadge(
      label: values.string('label'),
      tone: _statusTone(values.string('tone')),
    ),
    instances: _cardTrailingInstances,
  ),
  DesyComponent(
    id: 'harbor.notice.info',
    name: 'Information notice',
    icon: FLucideIcons.info,
    category: 'Feedback',
    description: 'Directs attention to a changed condition and the next step.',
    accessibility:
        'Keep the title and guidance actionable without relying on the icon.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 360,
      child: SampleNotice(
        title: 'Tide forecast updated',
        message:
            'Two berth windows changed. Review the schedule before publishing.',
        actionLabel: 'Review schedule',
      ),
    ),
    knobs: const [
      DesyStringKnob(
        id: 'variant',
        name: 'Variant',
        initial: 'tide-forecast-updated',
      ),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'inspection-planned' => _inspectionNotice(context),
      _ => _tideForecastNotice(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'tide-forecast-updated',
        name: 'Tide forecast updated',
        knobValues: DesyKnobValues({'variant': 'tide-forecast-updated'}),
      ),
      DesyComponentInstance(
        id: 'inspection-planned',
        name: 'Inspection planned',
        knobValues: DesyKnobValues({'variant': 'inspection-planned'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.field.text',
    name: 'Text field',
    icon: FLucideIcons.formInput,
    category: 'Input',
    description:
        'Collects one concise piece of information with a persistent label.',
    accessibility:
        'Use label text and present validation guidance next to the field.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 320,
      child: SampleTextField(label: 'Vessel reference', hint: 'e.g. HB-2048'),
    ),
    knobs: const [
      DesyStringKnob(
        id: 'label',
        name: 'Field label',
        initial: 'Vessel reference',
      ),
      DesyStringKnob(id: 'hint', name: 'Hint', initial: 'e.g. HB-2048'),
      DesyBooleanKnob(id: 'showError', name: 'Show validation', initial: false),
    ],
    buildWithKnobs: (context, values, _) => SizedBox(
      width: 320,
      child: SampleTextField(
        label: values.string('label'),
        hint: values.string('hint'),
        errorText: values.boolean('showError')
            ? 'Enter a vessel reference.'
            : null,
      ),
    ),
    instances: [
      DesyComponentInstance(
        id: 'vessel-reference',
        name: 'Vessel reference',
        knobValues: DesyKnobValues({
          'label': 'Vessel reference',
          'hint': 'e.g. HB-2048',
        }),
      ),
      DesyComponentInstance(
        id: 'missing-reference',
        name: 'Missing reference',
        knobValues: DesyKnobValues({
          'label': 'Vessel reference',
          'hint': 'e.g. HB-2048',
          'showError': true,
        }),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.card.content',
    name: 'Content card',
    icon: FLucideIcons.layoutPanelTop,
    category: 'Content',
    description: 'Groups a short update with a visible operational state.',
    accessibility: 'Keep headings meaningful and preserve reading order.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 340,
      child: SampleCard(
        title: 'North quay',
        body: 'Berth 04 opens at 14:30 after a routine inspection.',
        trailing: SampleStatusBadge(
          label: 'On schedule',
          tone: SampleStatusTone.success,
        ),
      ),
    ),
    knobs: [
      const DesyStringKnob(
        id: 'title',
        name: 'Card title',
        initial: 'North quay',
      ),
      DesyComponentKnob(
        id: 'trailing',
        name: 'Operational status',
        initial: _clearStatusId,
        options: const [_clearStatusId, _reviewStatusId, _delayedStatusId],
      ),
    ],
    buildWithKnobs: (context, values, widgets) => SizedBox(
      width: 340,
      child: SampleCard(
        title: values.string('title'),
        body: 'Berth 04 opens at 14:30 after a routine inspection.',
        trailing: widgets.build(context, values.component('trailing')),
      ),
    ),
    contract: DesyComponentContract(
      guidance:
          'Use the trailing slot for a concise state, not a second action.',
      properties: [
        DesyContractProperty(name: 'title', type: 'String', required: true),
        DesyContractProperty(name: 'body', type: 'String', required: true),
      ],
      slots: [
        DesyComponentSlot(
          name: 'trailing',
          accepts: 'Widget / status instance',
          description: 'A compact, non-interactive operational state.',
        ),
      ],
    ),
    scenarios: [
      DesyComponentScenario(
        id: 'delayed',
        name: 'Delayed berth',
        description: 'Critical state with the same card structure.',
        builder: (context) => const SizedBox(
          width: 340,
          child: SampleCard(
            title: 'North quay',
            body: 'Berth 04 is delayed while the inspection is completed.',
            trailing: SampleStatusBadge(
              label: 'Delayed',
              tone: SampleStatusTone.critical,
            ),
          ),
        ),
      ),
    ],
    instances: [
      DesyComponentInstance(
        id: 'north-quay-clear',
        name: 'North quay · clear',
        knobValues: DesyKnobValues({
          'title': 'North quay',
          'trailing': _clearStatusId,
        }),
      ),
      DesyComponentInstance(
        id: 'north-quay-delayed',
        name: 'North quay · delayed',
        knobValues: DesyKnobValues({
          'title': 'North quay delayed',
          'trailing': _delayedStatusId,
        }),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.row.navigation',
    name: 'Navigation row',
    icon: FLucideIcons.navigation,
    category: 'Navigation',
    description: 'Moves someone to a setting or detailed operational view.',
    accessibility:
        'Make the whole row tappable and name the destination plainly.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 360,
      child: SampleNavigationRow(
        icon: FLucideIcons.anchor,
        title: 'Berth availability',
        detail: '12 berths available today',
      ),
    ),
    knobs: const [
      DesyStringKnob(
        id: 'variant',
        name: 'Variant',
        initial: 'berth-availability',
      ),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'today-schedule' => _todayScheduleRow(context),
      _ => _berthAvailabilityRow(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'berth-availability',
        name: 'Berth availability',
        knobValues: DesyKnobValues({'variant': 'berth-availability'}),
      ),
      DesyComponentInstance(
        id: 'today-schedule',
        name: 'Today’s schedule',
        knobValues: DesyKnobValues({'variant': 'today-schedule'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.metric.operational',
    name: 'Operational metric',
    icon: FLucideIcons.chartNoAxesColumnIncreasing,
    category: 'Metrics',
    description: 'Pairs one high-value measure with concise operating context.',
    accessibility: 'Keep the value and its meaning available as text.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 300,
      child: SampleMetricTile(
        label: 'Available berths',
        value: '12',
        detail: '3 more than yesterday',
        icon: FLucideIcons.anchor,
      ),
    ),
    knobs: const [
      DesyStringKnob(
        id: 'variant',
        name: 'Variant',
        initial: 'available-berths',
      ),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'arrivals-today' => _arrivalsTodayMetric(context),
      _ => _availableBerthsMetric(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'available-berths',
        name: 'Available berths',
        knobValues: DesyKnobValues({'variant': 'available-berths'}),
      ),
      DesyComponentInstance(
        id: 'arrivals-today',
        name: 'Arrivals today',
        knobValues: DesyKnobValues({'variant': 'arrivals-today'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.capacity.indicator',
    name: 'Capacity indicator',
    icon: FLucideIcons.gauge,
    category: 'Metrics',
    description:
        'Shows used and total capacity without relying on the bar alone.',
    accessibility:
        'Always pair the visual fill with the used and total values.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 320,
      child: SampleCapacityIndicator(
        label: 'Berth capacity',
        used: 9,
        total: 12,
      ),
    ),
    knobs: const [
      DesyStringKnob(id: 'variant', name: 'Variant', initial: 'berth-capacity'),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'inspection-capacity' => _inspectionCapacity(context),
      _ => _berthCapacity(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'berth-capacity',
        name: 'Berth capacity',
        knobValues: DesyKnobValues({'variant': 'berth-capacity'}),
      ),
      DesyComponentInstance(
        id: 'inspection-capacity',
        name: 'Inspection capacity',
        knobValues: DesyKnobValues({'variant': 'inspection-capacity'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.schedule.item',
    name: 'Schedule item',
    icon: FLucideIcons.calendarClock,
    category: 'Schedule',
    description:
        'Presents one timed event with its supporting detail and state.',
    accessibility:
        'State the event status in text and keep the time unambiguous.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 430,
      child: SampleScheduleItem(
        time: '14:30',
        title: 'North quay inspection',
        detail: 'Berth 04 · Operations team',
        status: 'On schedule',
        tone: SampleStatusTone.success,
      ),
    ),
    knobs: const [
      DesyStringKnob(
        id: 'variant',
        name: 'Variant',
        initial: 'north-quay-inspection',
      ),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'tug-arrival' => _tugArrival(context),
      _ => _northQuayInspection(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'north-quay-inspection',
        name: 'North quay inspection',
        knobValues: DesyKnobValues({'variant': 'north-quay-inspection'}),
      ),
      DesyComponentInstance(
        id: 'tug-arrival',
        name: 'Tug arrival',
        knobValues: DesyKnobValues({'variant': 'tug-arrival'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.empty-state',
    name: 'Empty state',
    icon: FLucideIcons.inbox,
    category: 'Empty states',
    description:
        'Explains why a useful collection is empty and offers recovery.',
    accessibility: 'Use a specific heading and keep the action optional.',
    source: 'lib/src/sample_components.dart',
    preview: (context) => const SizedBox(
      width: 360,
      child: SampleEmptyState(
        title: 'No arrivals scheduled',
        message: 'Add an arrival window when the next vessel is confirmed.',
        icon: FLucideIcons.calendarX,
      ),
    ),
    knobs: const [
      DesyStringKnob(id: 'variant', name: 'Variant', initial: 'no-arrivals'),
    ],
    buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
      'no-search-results' => _noSearchResultsEmptyState(context),
      _ => _noArrivalsEmptyState(context),
    },
    instances: [
      DesyComponentInstance(
        id: 'no-arrivals',
        name: 'No arrivals',
        knobValues: DesyKnobValues({'variant': 'no-arrivals'}),
      ),
      DesyComponentInstance(
        id: 'no-search-results',
        name: 'No search results',
        knobValues: DesyKnobValues({'variant': 'no-search-results'}),
      ),
    ],
  ),
];

// Folder membership is declared alongside the registry structure. Component
// categories remain consumer metadata for display and documentation; they do
// not determine the workbench's hierarchy.
final _actionComponents = [_sampleComponents[0], _sampleComponents[1]];
final _feedbackComponents = [_sampleComponents[2], _sampleComponents[3]];
final _inputComponents = [_sampleComponents[4]];
final _contentComponents = [_sampleComponents[5]];
final _navigationComponents = [_sampleComponents[6]];
final _metricComponents = [_sampleComponents[7], _sampleComponents[8]];
final _scheduleComponents = [_sampleComponents[9]];
final _emptyStateComponents = [_sampleComponents[10]];

/// The single design-system declaration owned by this consumer application.
///
/// Every catalogue leaf belongs to this nested tree. The named lists above
/// only keep the consumer declarations readable; they are not root registry
/// fallbacks.
final sampleRegistry = DesyRegistry(
  name: 'Harbor Operations',
  themes: _sampleThemes,
  folders: [
    DesyFolder(
      id: 'atoms',
      name: 'Atoms',
      children: [
        DesyFolder(id: 'atoms.colors', name: 'Colors', colors: _sampleColors),
        DesyTypographyFolder(
          id: 'atoms.fonts',
          name: 'Fonts',
          typography: _sampleTypography,
        ),
        DesyFolder(
          id: 'atoms.measurements',
          name: 'Measurements',
          numbers: _sampleNumbers,
        ),
        DesyFolder(id: 'atoms.motion', name: 'Motion', motion: _sampleMotion),
        DesyFolder(
          id: 'atoms.effects',
          name: 'Effects',
          effects: _sampleEffects,
        ),
        DesyFolder(id: 'atoms.assets', name: 'Assets', assets: _sampleAssets),
      ],
    ),
    DesyFolder(
      id: 'components',
      name: 'Components',
      children: [
        DesyFolder(
          id: 'components.action',
          name: 'Action',
          components: _actionComponents,
        ),
        DesyFolder(
          id: 'components.feedback',
          name: 'Feedback',
          components: _feedbackComponents,
        ),
        DesyFolder(
          id: 'components.input',
          name: 'Input',
          components: _inputComponents,
        ),
        DesyFolder(
          id: 'components.content',
          name: 'Content',
          components: _contentComponents,
        ),
        DesyFolder(
          id: 'components.navigation',
          name: 'Navigation',
          components: _navigationComponents,
        ),
        DesyFolder(
          id: 'components.operations',
          name: 'Operations',
          description: 'Patterns for day-to-day harbor work.',
          children: [
            DesyFolder(
              id: 'components.operations.overview',
              name: 'Overview',
              children: [
                DesyFolder(
                  id: 'components.operations.overview.metrics',
                  name: 'Metrics',
                  components: _metricComponents,
                ),
              ],
            ),
            DesyFolder(
              id: 'components.operations.planning',
              name: 'Planning',
              children: [
                DesyFolder(
                  id: 'components.operations.planning.schedule',
                  name: 'Schedule',
                  components: _scheduleComponents,
                ),
              ],
            ),
          ],
        ),
        DesyFolder(
          id: 'components.guidance',
          name: 'Guidance',
          description: 'Patterns for quiet, incomplete, or blocked states.',
          children: [
            DesyFolder(
              id: 'components.guidance.states',
              name: 'States',
              children: [
                DesyFolder(
                  id: 'components.guidance.states.empty',
                  name: 'Empty states',
                  components: _emptyStateComponents,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    DesyFolder(
      id: 'examples',
      name: 'Examples',
      children: [
        DesyFolder(
          id: 'examples.showcases',
          name: 'Showcases',
          showcases: [
            DesyShowcase(
              id: 'harbor.berth-brief',
              name: 'Berth brief',
              description:
                  'A compact operational overview composed from declared system widgets.',
              builder: (context) => const SizedBox(
                width: 620,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SampleNotice(
                      title: 'Tide forecast updated',
                      message:
                          'Two berth windows changed. Review the schedule before publishing.',
                      actionLabel: 'Review schedule',
                    ),
                    SizedBox(height: 20),
                    SampleCard(
                      title: 'North quay',
                      body:
                          'Berth 04 opens at 14:30 after a routine inspection.',
                      trailing: SampleStatusBadge(
                        label: 'On schedule',
                        tone: SampleStatusTone.success,
                      ),
                    ),
                    SizedBox(height: 12),
                    SampleNavigationRow(
                      icon: FLucideIcons.calendar,
                      title: 'Today’s schedule',
                      detail: 'Six confirmed arrival windows',
                    ),
                    SizedBox(height: 20),
                    SampleButton(label: 'Publish schedule'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

SampleStatusTone _statusTone(String value) => switch (value) {
  'warning' => SampleStatusTone.warning,
  'critical' => SampleStatusTone.critical,
  _ => SampleStatusTone.success,
};

Widget _tideForecastNotice(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleNotice(
    title: 'Tide forecast updated',
    message:
        'Two berth windows changed. Review the schedule before publishing.',
    actionLabel: 'Review schedule',
  ),
);

Widget _inspectionNotice(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleNotice(
    title: 'Inspection planned',
    message: 'The north quay will reopen once the routine check is complete.',
  ),
);

Widget _berthAvailabilityRow(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleNavigationRow(
    icon: FLucideIcons.anchor,
    title: 'Berth availability',
    detail: '12 berths available today',
  ),
);

Widget _todayScheduleRow(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleNavigationRow(
    icon: FLucideIcons.calendar,
    title: 'Today’s schedule',
    detail: 'Six confirmed arrival windows',
  ),
);

Widget _availableBerthsMetric(BuildContext context) => const SizedBox(
  width: 300,
  child: SampleMetricTile(
    label: 'Available berths',
    value: '12',
    detail: '3 more than yesterday',
    icon: FLucideIcons.anchor,
  ),
);

Widget _arrivalsTodayMetric(BuildContext context) => const SizedBox(
  width: 300,
  child: SampleMetricTile(
    label: 'Arrivals today',
    value: '6',
    detail: 'Next window at 14:30',
    icon: FLucideIcons.ship,
  ),
);

Widget _berthCapacity(BuildContext context) => const SizedBox(
  width: 320,
  child: SampleCapacityIndicator(label: 'Berth capacity', used: 9, total: 12),
);

Widget _inspectionCapacity(BuildContext context) => const SizedBox(
  width: 320,
  child: SampleCapacityIndicator(
    label: 'Inspection capacity',
    used: 3,
    total: 8,
  ),
);

Widget _northQuayInspection(BuildContext context) => const SizedBox(
  width: 430,
  child: SampleScheduleItem(
    time: '14:30',
    title: 'North quay inspection',
    detail: 'Berth 04 · Operations team',
    status: 'On schedule',
    tone: SampleStatusTone.success,
  ),
);

Widget _tugArrival(BuildContext context) => const SizedBox(
  width: 430,
  child: SampleScheduleItem(
    time: '16:10',
    title: 'Tug Marlin arrival',
    detail: 'South channel · Window 3',
    status: 'Review',
    tone: SampleStatusTone.warning,
  ),
);

Widget _noArrivalsEmptyState(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleEmptyState(
    title: 'No arrivals scheduled',
    message: 'Add an arrival window when the next vessel is confirmed.',
    icon: FLucideIcons.calendarX,
    actionLabel: 'Add arrival',
  ),
);

Widget _noSearchResultsEmptyState(BuildContext context) => const SizedBox(
  width: 360,
  child: SampleEmptyState(
    title: 'No matching vessels',
    message: 'Try a different vessel name, reference, or berth number.',
    icon: FLucideIcons.searchX,
  ),
);
