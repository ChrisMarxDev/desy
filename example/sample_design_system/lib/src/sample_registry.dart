import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'sample_components.dart';
import 'sample_theme.dart';

final _cardTrailingInstances = [
  DesyComponentInstance.widget(
    id: 'status.clear',
    name: 'Clear status',
    icon: FLucideIcons.badgeCheck,
    description: 'Confirmed operational state.',
    builder: (context) => const SampleStatusBadge(
      label: 'On schedule',
      tone: SampleStatusTone.success,
    ),
  ),
  DesyComponentInstance.widget(
    id: 'status.review',
    name: 'Review status',
    icon: FLucideIcons.triangleAlert,
    description: 'State that needs follow-up before publishing.',
    builder: (context) => const SampleStatusBadge(
      label: 'Review needed',
      tone: SampleStatusTone.warning,
    ),
  ),
  DesyComponentInstance.widget(
    id: 'status.delayed',
    name: 'Delayed status',
    icon: FLucideIcons.octagonAlert,
    description: 'State that blocks the expected plan.',
    builder: (context) => const SampleStatusBadge(
      label: 'Delayed',
      tone: SampleStatusTone.critical,
    ),
  ),
];

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

final _sampleTokens = [
  DesyToken(
    id: 'token.color.brand.lagoon',
    name: 'Brand lagoon token',
    builder: _tokenSpecimen,
    value: '#006B63',
    group: 'Color',
    description: 'Primary actions and confirmed states.',
  ),
  DesyToken(
    id: 'token.color.brand.iris',
    name: 'Brand iris token',
    builder: _tokenSpecimen,
    value: '#6750A4',
    group: 'Color',
    description: 'Informative emphasis and system notices.',
  ),
  DesyToken(
    id: 'token.color.signal.sun',
    name: 'Signal sun token',
    builder: _tokenSpecimen,
    value: '#8D5700',
    group: 'Color',
    description: 'Warnings that need review.',
  ),
  DesyToken(
    id: 'token.color.signal.coral',
    name: 'Signal coral token',
    builder: _tokenSpecimen,
    value: '#B42318',
    group: 'Color',
    description: 'Errors and destructive actions.',
  ),
  DesyToken(
    id: 'token.color.surface.mist',
    name: 'Surface mist token',
    builder: _tokenSpecimen,
    value: '#EDF5F2',
    group: 'Color',
    description: 'Quiet light canvas and grouped surfaces.',
  ),
  DesyToken(
    id: 'token.color.text.ink',
    name: 'Text ink token',
    builder: _tokenSpecimen,
    value: '#17201F',
    group: 'Color',
    description: 'Default high-emphasis content.',
  ),
  DesyToken(
    id: 'token.type.title',
    name: 'Section title token',
    builder: _tokenSpecimen,
    value: '22 sp / medium',
    group: 'Typography',
  ),
  DesyToken(
    id: 'token.type.body',
    name: 'Body copy token',
    builder: _tokenSpecimen,
    value: '14 sp / regular',
    group: 'Typography',
  ),
];

final _colorTokens = [
  _sampleTokens[0],
  _sampleTokens[1],
  _sampleTokens[2],
  _sampleTokens[3],
  _sampleTokens[4],
  _sampleTokens[5],
];

final _fontTokens = [_sampleTokens[6], _sampleTokens[7]];

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
    style: (context) => Theme.of(context).textTheme.displaySmall!,
    sample: 'Berths and tides',
  ),
  DesyTypographyEntry(
    id: 'type.section-title',
    name: 'Section title',
    value: 'titleLarge',
    description: 'Introduces a related group of operational details.',
    style: (context) => Theme.of(context).textTheme.titleLarge!,
    sample: 'Today’s berth plan',
  ),
  DesyTypographyEntry(
    id: 'type.body',
    name: 'Body',
    value: 'bodyLarge',
    description: 'The default style for guidance and readable detail.',
    style: (context) => Theme.of(context).textTheme.bodyLarge!,
    sample: 'The north quay opens after the morning inspection.',
  ),
  DesyTypographyEntry(
    id: 'type.label',
    name: 'Label',
    value: 'labelLarge',
    description: 'Names controls and compact interface metadata.',
    style: (context) => Theme.of(context).textTheme.labelLarge!,
    sample: 'PUBLISHED SCHEDULE',
  ),
];

final _sampleNumbers = [
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
  DesyAssetEntry(
    id: 'icon.anchor',
    name: 'Anchor',
    group: 'Icons',
    value: 'FLucideIcons.anchor',
    description: 'Navigation destination for berth availability.',
    builder: (context) => Icon(
      FLucideIcons.anchor,
      size: 36,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
  DesyAssetEntry(
    id: 'icon.schedule',
    name: 'Schedule',
    group: 'Icons',
    value: 'FLucideIcons.calendar',
    description: 'Represents a planned operating window or timetable.',
    builder: (context) => Icon(
      FLucideIcons.calendar,
      size: 36,
      color: Theme.of(context).colorScheme.primary,
    ),
  ),
];

final _sampleComponents = [
  DesyComponent(
    id: 'harbor.button.primary',
    name: 'Primary button',
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
    buildWithKnobs: (context, values) => SampleButton(
      label: values.string('label'),
      onPressed: values.boolean('enabled') ? () {} : null,
    ),
    instances: [
      DesyComponentInstance.preset(
        id: 'publish-schedule',
        name: 'Publish schedule',
        description: 'Enabled primary action for a final review step.',
        knobValues: DesyKnobValues({'label': 'Publish schedule'}),
      ),
      DesyComponentInstance.preset(
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
    buildWithKnobs: (context, values) => SampleSecondaryButton(
      label: values.string('label'),
      onPressed: values.boolean('enabled') ? () {} : null,
    ),
    instances: [
      DesyComponentInstance.preset(
        id: 'adjust-filters',
        name: 'Adjust filters',
        knobValues: DesyKnobValues({'label': 'Adjust filters'}),
      ),
      DesyComponentInstance.preset(
        id: 'view-berths',
        name: 'View berths',
        knobValues: DesyKnobValues({'label': 'View berths'}),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.badge.status',
    name: 'Status badge',
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
    instances: _cardTrailingInstances.take(2).toList(),
  ),
  DesyComponent(
    id: 'harbor.notice.info',
    name: 'Information notice',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'tide-forecast-updated',
        name: 'Tide forecast updated',
        builder: _tideForecastNotice,
      ),
      DesyComponentInstance.widget(
        id: 'inspection-planned',
        name: 'Inspection planned',
        builder: _inspectionNotice,
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.field.text',
    name: 'Text field',
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
    buildWithKnobs: (context, values) => SizedBox(
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
      DesyComponentInstance.preset(
        id: 'vessel-reference',
        name: 'Vessel reference',
        knobValues: DesyKnobValues({
          'label': 'Vessel reference',
          'hint': 'e.g. HB-2048',
        }),
      ),
      DesyComponentInstance.preset(
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
        initial: _cardTrailingInstances.first,
        options: _cardTrailingInstances,
      ),
    ],
    buildWithKnobs: (context, values) => SizedBox(
      width: 340,
      child: SampleCard(
        title: values.string('title'),
        body: 'Berth 04 opens at 14:30 after a routine inspection.',
        trailing: values.component('trailing').build(context),
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
      DesyComponentInstance.preset(
        id: 'north-quay-clear',
        name: 'North quay · clear',
        knobValues: DesyKnobValues({
          'title': 'North quay',
          'trailing': _cardTrailingInstances.first,
        }),
      ),
      DesyComponentInstance.preset(
        id: 'north-quay-delayed',
        name: 'North quay · delayed',
        knobValues: DesyKnobValues({
          'title': 'North quay delayed',
          'trailing': _cardTrailingInstances.last,
        }),
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.row.navigation',
    name: 'Navigation row',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'berth-availability',
        name: 'Berth availability',
        builder: _berthAvailabilityRow,
      ),
      DesyComponentInstance.widget(
        id: 'today-schedule',
        name: 'Today’s schedule',
        builder: _todayScheduleRow,
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.metric.operational',
    name: 'Operational metric',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'available-berths',
        name: 'Available berths',
        builder: _availableBerthsMetric,
      ),
      DesyComponentInstance.widget(
        id: 'arrivals-today',
        name: 'Arrivals today',
        builder: _arrivalsTodayMetric,
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.capacity.indicator',
    name: 'Capacity indicator',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'berth-capacity',
        name: 'Berth capacity',
        builder: _berthCapacity,
      ),
      DesyComponentInstance.widget(
        id: 'inspection-capacity',
        name: 'Inspection capacity',
        builder: _inspectionCapacity,
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.schedule.item',
    name: 'Schedule item',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'north-quay-inspection',
        name: 'North quay inspection',
        builder: _northQuayInspection,
      ),
      DesyComponentInstance.widget(
        id: 'tug-arrival',
        name: 'Tug arrival',
        builder: _tugArrival,
      ),
    ],
  ),
  DesyComponent(
    id: 'harbor.empty-state',
    name: 'Empty state',
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
    instances: [
      DesyComponentInstance.widget(
        id: 'no-arrivals',
        name: 'No arrivals',
        builder: _noArrivalsEmptyState,
      ),
      DesyComponentInstance.widget(
        id: 'no-search-results',
        name: 'No search results',
        builder: _noSearchResultsEmptyState,
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
        DesyFolder(
          id: 'atoms.colors',
          name: 'Colors',
          tokens: _colorTokens,
          colors: _sampleColors,
        ),
        DesyFolder(
          id: 'atoms.fonts',
          name: 'Fonts',
          tokens: _fontTokens,
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

Widget _tokenSpecimen(BuildContext context) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    borderRadius: BorderRadius.circular(8),
  ),
  child: const Text('Consumer token specimen'),
);
