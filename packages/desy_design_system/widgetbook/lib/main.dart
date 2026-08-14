import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

void main() => runApp(const DesyWidgetbook());

/// A local Widgetbook workbench for comparing Widgetbook and Desy.
///
/// It deliberately uses the public, production Desy widgets with the real
/// Desy theme. The Widgetbook node and knob declarations are hand-authored
/// evaluation configuration; they are not a replacement for the Desy registry.
class DesyWidgetbook extends StatelessWidget {
  /// Creates the local Widgetbook comparison application.
  const DesyWidgetbook({super.key});

  @override
  Widget build(BuildContext context) => Widgetbook.material(
    header: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('DESY × WIDGETBOOK'),
    ),
    directories: [
      _actionsDirectory(),
      _inputsDirectory(),
      _feedbackDirectory(),
      _navigationDirectory(),
      _surfacesDirectory(),
      _agentDirectory(),
      _utilitiesDirectory(),
    ],
    addons: [
      ViewportAddon([Viewports.none, ...Viewports.all]),
      ThemeAddon<DesyDesignSystemTheme>(
        themes: const [
          WidgetbookTheme(
            name: 'Workbench light',
            data: DesyDesignSystemTheme.light,
          ),
          WidgetbookTheme(
            name: 'Workbench dark',
            data: DesyDesignSystemTheme.dark,
          ),
        ],
        themeBuilder: (context, theme, child) =>
            DesyDesignSystemScope(theme: theme, child: child),
      ),
      TextScaleAddon(initialScale: 1, min: .8, max: 2, divisions: 6),
      AlignmentAddon(),
      GridAddon(8),
      ZoomAddon(),
      InspectorAddon(),
      // Widgetbook marks its semantics debugger experimental; it is included
      // here specifically to evaluate that capability against Desy's contract.
      // ignore: experimental_member_use
      SemanticsAddon(),
    ],
  );
}

WidgetbookFolder _actionsDirectory() => WidgetbookFolder(
  name: 'Actions',
  children: [
    WidgetbookComponent(
      name: 'Button',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Inspect component',
            );
            final variant = context.knobs.object.segmented(
              label: 'Variant',
              options: DesyButtonVariant.values,
              labelBuilder: (value) => value.name,
            );
            final size = context.knobs.object.segmented(
              label: 'Size',
              options: DesyButtonSize.values,
              initialOption: DesyButtonSize.md,
              labelBuilder: (value) => value.name,
            );
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            final selected = context.knobs.boolean(label: 'Selected');
            return DesyButton(
              variant: variant,
              size: size,
              selected: selected,
              mainAxisSize: MainAxisSize.min,
              onPress: enabled ? () {} : null,
              child: Text(label),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Badge',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'EXPERIMENTAL',
            );
            final variant = context.knobs.object.segmented(
              label: 'Variant',
              options: DesyBadgeVariant.values,
              labelBuilder: (value) => value.name,
            );
            return DesyBadge(variant: variant, child: Text(label));
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _inputsDirectory() => WidgetbookFolder(
  name: 'Inputs',
  children: [
    WidgetbookComponent(
      name: 'Checkbox',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Show component details',
            );
            final description = context.knobs.string(
              label: 'Description',
              initialValue: 'Includes the contract panel.',
            );
            final value = context.knobs.boolean(label: 'Value');
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            return DesyCheckbox(
              value: value,
              onChanged: enabled ? (_) {} : null,
              label: Text(label),
              description: description.isEmpty ? null : Text(description),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Switch',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Annotation mode',
            );
            final value = context.knobs.boolean(
              label: 'Value',
              initialValue: true,
            );
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            return DesySwitch(
              label: Text(label),
              value: value,
              onChange: enabled ? (_) {} : null,
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Text field',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final label = context.knobs.string(
              label: 'Label',
              initialValue: 'Search',
            );
            final hint = context.knobs.string(
              label: 'Hint',
              initialValue: 'Search components',
            );
            final value = context.knobs.string(label: 'Value');
            final error = context.knobs.string(label: 'Error text');
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            final multiline = context.knobs.boolean(label: 'Multiline');
            final width = context.knobs.double.slider(
              label: 'Width',
              initialValue: 360,
              min: 200,
              max: 640,
              divisions: 11,
              precision: 0,
            );
            return SizedBox(
              width: width,
              child: DesyTextField(
                label: label,
                hintText: hint,
                value: value,
                errorText: error.isEmpty ? null : error,
                enabled: enabled,
                minLines: multiline ? 3 : null,
                maxLines: multiline ? 5 : 1,
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Select',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final selected = context.knobs.object.segmented(
              label: 'Selected theme',
              options: DesyDesignSystemTheme.values,
              labelBuilder: (value) => value.name,
            );
            final descriptions = context.knobs.boolean(
              label: 'Show descriptions',
            );
            return SizedBox(
              width: 320,
              child: DesySelect<DesyDesignSystemTheme>.rich(
                control: DesySelectControl.lifted(
                  value: selected,
                  onChange: (_) {},
                ),
                format: (value) => 'Workbench ${value.name}',
                children: [
                  for (final theme in DesyDesignSystemTheme.values)
                    DesySelectItem.item(
                      value: theme,
                      title: Text('Workbench ${theme.name}'),
                      subtitle: descriptions
                          ? Text(
                              theme == DesyDesignSystemTheme.light
                                  ? 'High-clarity neutral chrome'
                                  : 'Low-glare preview context',
                            )
                          : null,
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _feedbackDirectory() => WidgetbookFolder(
  name: 'Feedback',
  children: [
    WidgetbookComponent(
      name: 'Progress trail',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final state = context.knobs.object.segmented(
              label: 'Final state',
              options: DesyProgressTrailItemState.values,
              initialOption: DesyProgressTrailItemState.current,
              labelBuilder: (value) => value.name,
            );
            final metadata = context.knobs.boolean(
              label: 'Show metadata',
              initialValue: true,
            );
            return SizedBox(
              width: 420,
              child: DesyProgressTrail(
                items: [
                  _trailItem(
                    'Mapped the component surface',
                    DesyProgressTrailItemState.complete,
                    metadata,
                  ),
                  _trailItem(
                    'Prepared the Widgetbook use case',
                    DesyProgressTrailItemState.complete,
                    metadata,
                  ),
                  _trailItem(
                    'Compare the inspection workflow',
                    state,
                    metadata,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Dialog',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Swap instance',
            );
            final body = context.knobs.string(
              label: 'Body',
              initialValue: 'Choose one legal component instance.',
              maxLines: 3,
            );
            return DesyDialog(
              semanticsLabel: 'Widgetbook dialog specimen',
              constraints: const BoxConstraints(maxWidth: 420),
              builder: (context, style) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: style.titleTextStyle),
                    const SizedBox(height: 8),
                    Text(body, style: style.bodyTextStyle),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _navigationDirectory() => WidgetbookFolder(
  name: 'Navigation',
  children: [
    WidgetbookComponent(
      name: 'Accordion',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Components',
            );
            final content = context.knobs.string(
              label: 'Content',
              initialValue: 'Actions · Feedback · Inputs · Navigation',
            );
            final expanded = context.knobs.boolean(
              label: 'Initially expanded',
              initialValue: true,
            );
            return SizedBox(
              width: 360,
              child: DesyAccordion(
                children: [
                  DesyAccordionItem(
                    key: ValueKey(expanded),
                    initiallyExpanded: expanded,
                    title: Text(title),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(content),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tabs',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final first = context.knobs.string(
              label: 'First label',
              initialValue: 'Assets',
            );
            final second = context.knobs.string(
              label: 'Second label',
              initialValue: 'Layers',
            );
            final scrollable = context.knobs.boolean(label: 'Scrollable');
            final expands = context.knobs.boolean(
              label: 'Expand content',
              initialValue: true,
            );
            return SizedBox(
              width: 440,
              height: 220,
              child: DesyTabs(
                scrollable: scrollable,
                expands: expands,
                children: [
                  DesyTabEntry(
                    label: Text(first),
                    child: Center(child: Text(first)),
                  ),
                  DesyTabEntry(
                    label: Text(second),
                    child: Center(child: Text(second)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Tile',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Release channel',
            );
            final subtitle = context.knobs.string(
              label: 'Subtitle',
              initialValue: 'Registry-backed metadata',
            );
            final selected = context.knobs.boolean(label: 'Selected');
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            return SizedBox(
              width: 380,
              child: DesyTile(
                title: Text(title),
                subtitle: subtitle.isEmpty ? null : Text(subtitle),
                suffix: const DesyBadge(child: Text('BETA')),
                selected: selected,
                onPress: enabled ? () {} : null,
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Sidebar',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final count = context.knobs.int.slider(
              label: 'Component count',
              initialValue: 16,
              min: 0,
              max: 48,
              divisions: 6,
            );
            final selected = context.knobs.boolean(
              label: 'Atlas selected',
              initialValue: true,
            );
            final atoms = context.knobs.boolean(
              label: 'Show atoms',
              initialValue: true,
            );
            return SizedBox(
              width: 280,
              height: 460,
              child: DesySidebar(
                header: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('DESY BENCH'),
                ),
                children: [
                  DesySidebarSection(
                    label: 'Components',
                    count: count,
                    children: [
                      DesySidebarItem.screen(
                        label: const Text('Atlas'),
                        selected: selected,
                        onPress: () {},
                      ),
                      const DesySidebarItem(label: Text('Button')),
                      const DesySidebarItem(label: Text('Text field')),
                    ],
                  ),
                  if (atoms)
                    const DesySidebarSection(
                      label: 'Atoms',
                      children: [
                        DesySidebarItem(label: Text('Colors')),
                        DesySidebarItem(label: Text('Measurements')),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _surfacesDirectory() => WidgetbookFolder(
  name: 'Surfaces',
  children: [
    WidgetbookComponent(
      name: 'Card',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'Registry source',
            );
            final body = context.knobs.string(
              label: 'Body',
              initialValue:
                  'One declared system drives every workbench surface.',
              maxLines: 3,
            );
            final showBody = context.knobs.boolean(
              label: 'Show body',
              initialValue: true,
            );
            return SizedBox(
              width: 380,
              child: DesyCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (showBody) ...[const SizedBox(height: 8), Text(body)],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Catalogue card',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final path = context.knobs.string(
              label: 'Path',
              initialValue: 'Actions',
            );
            final identifier = context.knobs.string(
              label: 'Identifier',
              initialValue: 'desy.component.button',
            );
            final action = context.knobs.string(
              label: 'Action label',
              initialValue: 'Inspect',
            );
            final showAction = context.knobs.boolean(
              label: 'Show action',
              initialValue: true,
            );
            return SizedBox(
              width: 300,
              height: 250,
              child: DesyCatalogueCard(
                path: path,
                identifier: identifier,
                preview: Center(
                  child: showAction
                      ? DesyButton(
                          mainAxisSize: MainAxisSize.min,
                          size: DesyButtonSize.sm,
                          onPress: () {},
                          child: Text(action),
                        )
                      : const Text('Component preview'),
                ),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Scaffold',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final header = context.knobs.string(
              label: 'Header',
              initialValue: 'Workbench header',
            );
            final content = context.knobs.string(
              label: 'Content',
              initialValue: 'Route content',
            );
            final footer = context.knobs.boolean(label: 'Show footer');
            final padded = context.knobs.boolean(
              label: 'Pad content',
              initialValue: true,
            );
            return SizedBox(
              width: 440,
              height: 280,
              child: DesyScaffold(
                childPad: padded,
                header: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(header),
                ),
                footer: footer
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Workbench footer'),
                      )
                    : null,
                child: Center(child: Text(content)),
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _agentDirectory() => WidgetbookFolder(
  name: 'Agent UI',
  children: [
    WidgetbookComponent(
      name: 'Chat message',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final role = context.knobs.object.segmented(
              label: 'Role',
              options: DesyChatRole.values,
              labelBuilder: (value) => value.name,
            );
            final label = context.knobs.string(
              label: 'Author label',
              initialValue: 'GENUI AGENT',
            );
            final body = context.knobs.string(
              label: 'Message',
              initialValue: 'The component preview is ready to inspect.',
              maxLines: 4,
            );
            final pending = context.knobs.boolean(label: 'Pending');
            return SizedBox(
              width: 520,
              child: DesyChatMessage(
                role: role,
                label: label,
                pending: pending,
                child: Text(body),
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Chat composer',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final value = context.knobs.string(
              label: 'Value',
              initialValue: 'Create an inspection summary card.',
              maxLines: 3,
            );
            final hint = context.knobs.string(
              label: 'Hint',
              initialValue: 'Describe the interface you need',
            );
            final action = context.knobs.string(
              label: 'Action label',
              initialValue: 'Generate UI',
            );
            final enabled = context.knobs.boolean(
              label: 'Enabled',
              initialValue: true,
            );
            final loading = context.knobs.boolean(label: 'Loading');
            final error = context.knobs.string(label: 'Error text');
            return SizedBox(
              width: 560,
              child: DesyChatComposer(
                value: value,
                hintText: hint,
                submitLabel: action,
                enabled: enabled,
                loading: loading,
                errorText: error.isEmpty ? null : error,
                onSubmit: (_) {},
              ),
            );
          },
        ),
      ],
    ),
    WidgetbookComponent(
      name: 'Chat thread',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final title = context.knobs.string(
              label: 'Title',
              initialValue: 'GENUI AGENT',
            );
            final detail = context.knobs.string(
              label: 'Detail',
              initialValue: 'desy.design-system',
            );
            final composer = context.knobs.boolean(
              label: 'Show composer',
              initialValue: true,
            );
            return SizedBox(
              width: 680,
              child: DesyChatThread(
                title: title,
                detail: detail.isEmpty ? null : detail,
                messages: const [
                  DesyChatMessage(
                    role: DesyChatRole.user,
                    child: Text('Compare the inspection workflow.'),
                  ),
                  DesyChatMessage(
                    role: DesyChatRole.agent,
                    child: Text('I prepared the real production widgets.'),
                  ),
                ],
                composer: composer ? _threadComposer() : null,
              ),
            );
          },
        ),
      ],
    ),
  ],
);

WidgetbookFolder _utilitiesDirectory() => WidgetbookFolder(
  name: 'Utilities',
  children: [
    WidgetbookComponent(
      name: 'Keyboard shortcut label',
      useCases: [
        WidgetbookUseCase(
          name: 'playground',
          builder: (context) {
            final key = context.knobs.string(label: 'Key', initialValue: 'K');
            final chord = context.knobs.boolean(
              label: 'Include modifier',
              initialValue: true,
            );
            return DesyKeyboardShortcutLabel(keys: chord ? ['⌘', key] : [key]);
          },
        ),
      ],
    ),
  ],
);

DesyProgressTrailItem _trailItem(
  String title,
  DesyProgressTrailItemState state,
  bool metadata,
) => DesyProgressTrailItem(
  title: title,
  detail: 'A real production component state.',
  metadata: metadata ? state.name.toUpperCase() : null,
  state: state,
);

Widget _threadComposer() =>
    DesyChatComposer(value: '', onSubmit: (_) {}, submitLabel: 'Send prompt');
