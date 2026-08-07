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
    DesyColorEntry.swatch(
      id: 'desy.color.background',
      name: 'Background',
      color: _lightTheme.colors.background,
      description: 'The workbench document and canvas foundation.',
    ),
    DesyColorEntry.swatch(
      id: 'desy.color.foreground',
      name: 'Foreground',
      color: _lightTheme.colors.foreground,
      description: 'Primary readable content and icon color.',
    ),
    DesyColorEntry.swatch(
      id: 'desy.color.primary',
      name: 'Primary',
      color: _lightTheme.colors.primary,
      description: 'Selected controls and primary workbench actions.',
    ),
    DesyColorEntry.swatch(
      id: 'desy.color.card',
      name: 'Card',
      color: _lightTheme.colors.card,
      description: 'Contained workbench panels and specimens.',
    ),
    DesyColorEntry.swatch(
      id: 'desy.color.border',
      name: 'Border',
      color: _lightTheme.colors.border,
      description: 'Quiet separation between adjacent surfaces.',
    ),
    DesyColorEntry.swatch(
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
      id: 'desy.space.lg',
      name: 'Large spacing',
      value: DesyDesignSystemTokens.spaceLg,
      description: 'Panel padding and major section separation.',
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
  components: [
    _buttonComponent,
    _badgeComponent,
    _dialogComponent,
    _selectComponent,
    _switchComponent,
    _textFieldComponent,
    _accordionComponent,
    _tabsComponent,
    _tileComponent,
    _sidebarComponent,
    _sidebarSectionComponent,
    _sidebarItemComponent,
    _cardComponent,
    _catalogueCardComponent,
    _scaffoldComponent,
    _shortcutComponent,
  ],
  showcases: [
    DesyShowcase(
      id: 'desy.showcase.control-stack',
      name: 'Workbench control stack',
      description: 'A small real composition of Desy-owned controls.',
      builder: (context) => const _ControlStackShowcase(),
    ),
  ],
);

final _buttonComponent = DesyComponent(
  id: 'desy.component.button',
  name: 'Button',
  path: '/actions',
  icon: DesyIcons.component,
  description: 'Triggers a workbench action with a clear semantic priority.',
  accessibility: 'Use a visible outcome label and preserve disabled semantics.',
  source: 'package:desy_design_system/src/control_aliases.dart',
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
  source: 'package:desy_design_system/src/control_aliases.dart',
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
  source: 'package:desy_design_system/src/control_aliases.dart',
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
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
  path: '/surfaces',
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
    actionLabel: k.string('actionLabel', name: 'Preview label', initial: 'Inspect'),
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
  path: '/feedback',
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

final _textFieldComponent = DesyComponent(
  id: 'desy.component.text-field',
  name: 'Text field',
  path: '/inputs',
  icon: DesyIcons.component,
  description: 'Native Flutter text editing styled by the Desy theme bridge.',
  accessibility: 'Preserve native selection, caret, keyboard, and context menus.',
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
    'disabled': [knobs.label('Search'), knobs.value('Atlas'), knobs.enabled(false)],
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
  path: '/navigation',
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
  path: '/navigation/sidebar',
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
  path: '/navigation/sidebar',
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
    opensAtlas: k.boolean('opensAtlas', name: 'Label opens Atlas', initial: true),
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
    opensScreen: k.boolean('opensScreen', name: 'Opens a screen', initial: true),
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
  path: '/navigation',
  description: 'Switches between peer views without changing route ownership.',
  icon: DesyIcons.component,
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    firstLabel: k.string('firstLabel', name: 'First label', initial: 'Assets'),
    secondLabel: k.string('secondLabel', name: 'Second label', initial: 'Layers'),
    scrollable: k.boolean('scrollable', name: 'Scrollable tabs', initial: false),
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
  path: '/navigation',
  icon: DesyIcons.component,
  description: 'A compact interactive row for navigation and selection.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  knobs: (k) => (
    title: k.string('title', name: 'Title', initial: 'Release channel'),
    suffix: k.widgetInstance(
      'suffix',
      name: 'Suffix instance',
      initial: _badgeDefaultInstanceId,
      options: const [
        _badgeDefaultInstanceId,
        _shortcutSingleKeyInstanceId,
      ],
    ),
  ),
  build: (context, knobs) => _buildTileField(
    title: knobs.title.value,
    suffix: knobs.suffix.widget,
  ),
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
  path: '/surfaces',
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
  description: 'A compact semantic keycap treatment for discoverable shortcuts.',
  accessibility: 'Announce the complete chord rather than individual decoration.',
  source: 'package:desy_design_system/src/keyboard_shortcut_label.dart',
  knobs: (k) => (
    key: k.string('key', name: 'Key', initial: 'K'),
    chord: k.boolean('chord', name: 'Include modifier', initial: true),
  ),
  build: (context, knobs) => DesyKeyboardShortcutLabel(
    keys: knobs.chord.value
        ? ['⌘', knobs.key.value]
        : [knobs.key.value],
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
        const DesySidebarSection(
          label: 'Showcases',
          count: 1,
          children: [
            DesySidebarItem(
              icon: Icon(DesyIcons.layers),
              label: Text('Overview'),
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
  Widget build(BuildContext context) => SizedBox(
    width: 300,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: context.theme.colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: child,
      ),
    ),
  );
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

class _ControlStackShowcase extends StatelessWidget {
  const _ControlStackShowcase();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 520,
    child: DesyCard(
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Preview settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                DesyBadge(child: const Text('LOCAL')),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            DesyTile(
              prefix: const Icon(DesyIcons.smartphone),
              title: const Text('iPhone 15 Pro'),
              subtitle: const Text('393 × 852 logical pixels'),
              suffix: const Icon(DesyIcons.chevronRight),
              onPress: () {},
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            DesySwitch(
              label: const Text('Show grid'),
              value: true,
              onChange: (_) {},
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            DesyButton(
              mainAxisSize: MainAxisSize.min,
              onPress: () {},
              child: const Text('Apply preview'),
            ),
          ],
        ),
      ),
    ),
  );
}
