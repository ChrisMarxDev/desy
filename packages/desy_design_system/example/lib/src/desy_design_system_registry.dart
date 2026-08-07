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
  folders: [
    DesyFolder(
      id: 'desy.atoms',
      name: 'Atoms',
      children: [
        DesyFolder(
          id: 'desy.atoms.colors',
          name: 'Colors',
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
        ),
        DesyFolder(
          id: 'desy.atoms.fonts',
          name: 'Fonts',
          typography: [
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
        ),
        DesyFolder(id: 'desy.atoms.icons', name: 'Icons', icons: _desyIcons),
        DesyFolder(
          id: 'desy.atoms.measurements',
          name: 'Measurements',
          numbers: const [
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
              description:
                  'Switches desktop sidebar chrome to compact navigation.',
            ),
          ],
        ),
        DesyFolder(
          id: 'desy.atoms.motion',
          name: 'Motion',
          motion: [
            DesyMotionEntry(
              id: 'desy.motion.navigation',
              name: 'Navigation reveal',
              duration: DesyDesignSystemTokens.navigationMotion,
              curve: Curves.easeOutCubic,
              description:
                  'Sidebar width and similar spatial navigation changes.',
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
        ),
        DesyFolder(
          id: 'desy.atoms.effects',
          name: 'Effects',
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
        ),
      ],
    ),
    DesyFolder(
      id: 'desy.components',
      name: 'Components',
      children: [
        DesyFolder(
          id: 'desy.components.actions',
          name: 'Actions',
          components: [_buttonComponent],
        ),
        DesyFolder(
          id: 'desy.components.feedback',
          name: 'Feedback',
          components: [_badgeComponent, _dialogComponent],
        ),
        DesyFolder(
          id: 'desy.components.inputs',
          name: 'Inputs',
          components: [_selectComponent, _switchComponent, _textFieldComponent],
        ),
        DesyFolder(
          id: 'desy.components.navigation',
          name: 'Navigation',
          components: [
            _accordionComponent,
            _sidebarComponent,
            _tabsComponent,
            _tileComponent,
          ],
        ),
        DesyFolder(
          id: 'desy.components.surfaces',
          name: 'Surfaces',
          components: [_cardComponent, _scaffoldComponent],
        ),
        DesyFolder(
          id: 'desy.components.utilities',
          name: 'Utilities',
          components: [_shortcutComponent],
        ),
      ],
    ),
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
  icon: DesyIcons.component,
  description: 'Triggers a workbench action with a clear semantic priority.',
  accessibility: 'Use a visible outcome label and preserve disabled semantics.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  preview: (context) => DesyButton(
    mainAxisSize: MainAxisSize.min,
    onPress: () {},
    child: const Text('Inspect component'),
  ),
  knobs: const [
    DesyStringKnob(id: 'label', name: 'Label', initial: 'Inspect component'),
    DesyBooleanKnob(id: 'outline', name: 'Outline', initial: false),
    DesyBooleanKnob(id: 'enabled', name: 'Enabled', initial: true),
  ],
  buildWithKnobs: (context, values, _) => DesyButton(
    variant: values.boolean('outline')
        ? DesyButtonVariant.outline
        : DesyButtonVariant.primary,
    mainAxisSize: MainAxisSize.min,
    onPress: values.boolean('enabled') ? () {} : null,
    child: Text(values.string('label')),
  ),
  instances: [
    DesyComponentInstance(
      id: 'primary',
      name: 'Primary',
      knobValues: DesyKnobValues({'label': 'Inspect component'}),
    ),
    DesyComponentInstance(
      id: 'outline',
      name: 'Outline',
      knobValues: DesyKnobValues({'label': 'Open settings', 'outline': true}),
    ),
    DesyComponentInstance(
      id: 'disabled',
      name: 'Disabled',
      knobValues: DesyKnobValues({'label': 'Unavailable', 'enabled': false}),
    ),
  ],
);

final _badgeComponent = _component(
  id: 'desy.component.badge',
  name: 'Badge',
  description: 'A compact non-interactive label for concise metadata.',
  preview: (context) => DesyBadge(child: const Text('EXPERIMENTAL')),
);

final _cardComponent = _component(
  id: 'desy.component.card',
  name: 'Card',
  description: 'Contains a related workbench specimen or inspector section.',
  preview: (context) => DesyCard(
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registry source',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          const Text('One declared system drives every workbench surface.'),
        ],
      ),
    ),
  ),
);

final _dialogComponent = _component(
  id: 'desy.component.dialog',
  name: 'Dialog',
  description: 'A focused modal decision or bounded selection surface.',
  preview: (context) => DesyDialog(
    semanticsLabel: 'Example dialog',
    constraints: const BoxConstraints(maxWidth: 360),
    builder: (context, style) => Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Swap instance', style: style.titleTextStyle),
          const SizedBox(height: DesyDesignSystemTokens.spaceSm),
          Text(
            'Choose one legal component instance from the registry.',
            style: style.bodyTextStyle,
          ),
        ],
      ),
    ),
  ),
);

final _selectComponent = _component(
  id: 'desy.component.select',
  name: 'Select',
  description: 'Chooses one typed value from a bounded option set.',
  preview: (context) => SizedBox(
    width: 280,
    child: DesySelect<String>.rich(
      control: DesySelectControl.lifted(value: 'light', onChange: (_) {}),
      format: (value) =>
          value == 'light' ? 'Workbench light' : 'Workbench dark',
      children: const [
        DesySelectItem.item(value: 'light', title: Text('Workbench light')),
        DesySelectItem.item(value: 'dark', title: Text('Workbench dark')),
      ],
    ),
  ),
);

final _switchComponent = DesyComponent(
  id: 'desy.component.switch',
  name: 'Switch',
  description: 'Changes one immediate boolean workbench preference.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  preview: (context) =>
      DesySwitch(label: const Text('Show grid'), value: true, onChange: (_) {}),
  knobs: const [DesyBooleanKnob(id: 'value', name: 'Value', initial: true)],
  buildWithKnobs: (context, values, _) => DesySwitch(
    label: const Text('Show grid'),
    value: values.boolean('value'),
    onChange: (_) {},
  ),
  instances: [
    DesyComponentInstance(
      id: 'on',
      name: 'On',
      knobValues: DesyKnobValues({'value': true}),
    ),
    DesyComponentInstance(
      id: 'off',
      name: 'Off',
      knobValues: DesyKnobValues({'value': false}),
    ),
  ],
);

final _textFieldComponent = DesyComponent(
  id: 'desy.component.text-field',
  name: 'Text field',
  icon: DesyIcons.component,
  description: 'Native Flutter text editing styled by the Desy theme bridge.',
  accessibility:
      'Preserve native selection, caret, keyboard, and context menus.',
  source: 'package:desy_design_system/src/desy_text_field.dart',
  preview: (context) => const _TextFieldFrame(
    child: DesyTextField(label: 'Search', hintText: 'Search components'),
  ),
  knobs: const [
    DesyStringKnob(id: 'variant', name: 'Variant', initial: 'empty'),
  ],
  buildWithKnobs: (context, values, _) => switch (values.string('variant')) {
    'disabled' => const _TextFieldFrame(
      child: DesyTextField(label: 'Search', value: 'Atlas', enabled: false),
    ),
    'multiline' => const _TextFieldFrame(
      child: DesyTextField(
        label: 'Notes',
        hintText: 'Add usage guidance',
        minLines: 3,
        maxLines: 5,
      ),
    ),
    _ => const _TextFieldFrame(
      child: DesyTextField(label: 'Search', hintText: 'Search components'),
    ),
  },
  instances: [
    DesyComponentInstance(
      id: 'empty',
      name: 'Empty',
      knobValues: DesyKnobValues({'variant': 'empty'}),
    ),
    DesyComponentInstance(
      id: 'disabled',
      name: 'Disabled',
      knobValues: DesyKnobValues({'variant': 'disabled'}),
    ),
    DesyComponentInstance(
      id: 'multiline',
      name: 'Multiline',
      knobValues: DesyKnobValues({'variant': 'multiline'}),
    ),
  ],
);

final _accordionComponent = _component(
  id: 'desy.component.accordion',
  name: 'Accordion',
  description: 'Progressively discloses nested registry structure.',
  preview: (context) => SizedBox(
    width: 320,
    child: DesyAccordion(
      children: const [
        DesyAccordionItem(
          initiallyExpanded: true,
          title: Text('Components'),
          child: Padding(
            padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Text('Actions · Feedback · Inputs · Navigation'),
          ),
        ),
      ],
    ),
  ),
);

final _sidebarComponent = _component(
  id: 'desy.component.sidebar',
  name: 'Sidebar',
  description:
      'Persistent workbench navigation derived from the registry tree.',
  preview: (context) => SizedBox(
    width: 248,
    height: 320,
    child: DesySidebar(
      header: const Padding(
        padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text('DESY BENCH'),
      ),
      children: const [
        DesySidebarItem(
          icon: Icon(DesyIcons.layoutGrid),
          label: Text('Atlas'),
          selected: true,
        ),
        DesySidebarItem(icon: Icon(DesyIcons.boxes), label: Text('Components')),
      ],
    ),
  ),
);

final _tabsComponent = _component(
  id: 'desy.component.tabs',
  name: 'Tabs',
  description: 'Switches between peer views without changing route ownership.',
  preview: (context) => SizedBox(
    width: 360,
    height: 180,
    child: DesyTabs(
      children: const [
        DesyTabEntry(
          label: Text('Assets'),
          child: Center(child: Text('Assets')),
        ),
        DesyTabEntry(
          label: Text('Layers'),
          child: Center(child: Text('Layers')),
        ),
      ],
    ),
  ),
);

final _tileComponent = DesyComponent(
  id: 'desy.component.tile',
  name: 'Tile',
  icon: DesyIcons.component,
  description: 'A compact interactive row for navigation and selection.',
  source: 'package:desy_design_system/src/control_aliases.dart',
  preview: (context) => _buildTile(
    context,
    DesyKnobValues({
      'title': 'Release channel',
      'suffix': _badgeDefaultInstanceId,
    }),
    desyDesignSystemRegistry.widgetBuilder,
  ),
  knobs: [
    const DesyStringKnob(
      id: 'title',
      name: 'Title',
      initial: 'Release channel',
    ),
    DesyComponentKnob(
      id: 'suffix',
      name: 'Suffix instance',
      initial: _badgeDefaultInstanceId,
      options: const [_badgeDefaultInstanceId, _shortcutSingleKeyInstanceId],
    ),
  ],
  buildWithKnobs: _buildTile,
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
      builder: (context) => _buildTile(
        context,
        DesyKnobValues({
          'title': 'Unresolved registry link',
          'suffix': _missingTileSuffixInstanceId,
        }),
        desyDesignSystemRegistry.widgetBuilder,
      ),
    ),
  ],
  instances: [
    DesyComponentInstance(
      id: 'with-badge',
      name: 'Metadata badge',
      knobValues: DesyKnobValues({
        'title': 'Release channel',
        'suffix': _badgeDefaultInstanceId,
      }),
    ),
    DesyComponentInstance(
      id: 'with-shortcut',
      name: 'Keyboard shortcut',
      knobValues: DesyKnobValues({
        'title': 'Open command menu',
        'suffix': _shortcutSingleKeyInstanceId,
      }),
    ),
  ],
);

Widget _buildTile(
  BuildContext context,
  DesyKnobValues values,
  DesyRegistryWidgetBuilder widgets,
) => SizedBox(
  width: 340,
  child: DesyTile(
    prefix: const Icon(DesyIcons.component),
    title: Text(values.string('title')),
    subtitle: const Text('Registry-backed suffix'),
    suffix: widgets.build(context, values.component('suffix')),
    onPress: () {},
  ),
);

final _scaffoldComponent = _component(
  id: 'desy.component.scaffold',
  name: 'Scaffold',
  description: 'The neutral structural surface around one workbench route.',
  preview: (context) => const SizedBox(
    width: 380,
    height: 220,
    child: DesyScaffold(
      header: Padding(
        padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text('Workbench header'),
      ),
      child: Center(child: Text('Route content')),
    ),
  ),
);

final _desyIcons = [
  _desyIcon('layout-grid', 'Layout grid', DesyIcons.layoutGrid),
  _desyIcon('boxes', 'Boxes', DesyIcons.boxes),
  _desyIcon('component', 'Component', DesyIcons.component),
  _desyIcon('folder', 'Folder', DesyIcons.folder),
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
  icon: DesyIcons.component,
  description:
      'A compact semantic keycap treatment for discoverable shortcuts.',
  accessibility:
      'Announce the complete chord rather than individual decoration.',
  source: 'package:desy_design_system/src/keyboard_shortcut_label.dart',
  preview: (context) => const DesyKeyboardShortcutLabel(keys: ['⌘', 'K']),
  knobs: const [DesyBooleanKnob(id: 'chord', name: 'Chord', initial: true)],
  buildWithKnobs: (context, values, _) => DesyKeyboardShortcutLabel(
    keys: values.boolean('chord') ? const ['⌘', 'K'] : const ['Esc'],
  ),
  instances: [
    DesyComponentInstance(
      id: 'single-key',
      name: 'Single key',
      knobValues: DesyKnobValues({'chord': false}),
    ),
    DesyComponentInstance(
      id: 'chord',
      name: 'Chord',
      knobValues: DesyKnobValues({'chord': true}),
    ),
  ],
);

DesyComponent _component({
  required String id,
  required String name,
  required String description,
  required DesyPreviewBuilder preview,
}) => DesyComponent(
  id: id,
  name: name,
  icon: DesyIcons.component,
  description: description,
  source: 'package:desy_design_system/src/control_aliases.dart',
  preview: preview,
  instances: [DesyComponentInstance(id: 'default', name: 'Default')],
);

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
