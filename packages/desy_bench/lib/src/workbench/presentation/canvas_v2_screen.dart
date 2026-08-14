// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../workbench_session.dart';
import 'collection_canvas.dart';
import 'component_knob_panel.dart';

/// The beta collection canvas for exploring every registered component at once.
///
/// The shared canvas owns scene interaction. This screen owns the component
/// domain: registry resolution, temporary knob values, and component controls.
class DesyCanvasV2Screen extends StatefulWidget {
  const DesyCanvasV2Screen({super.key, required this.session});

  final DesyWorkbenchSession session;

  @override
  State<DesyCanvasV2Screen> createState() => _DesyCanvasV2ScreenState();
}

class _DesyCanvasV2ScreenState extends State<DesyCanvasV2Screen> {
  final _valuesByComponentId = <String, Map<String, Object>>{};

  @override
  Widget build(BuildContext context) {
    final themeIndex = widget.session.activeThemeIndex.watch(context);
    final theme = widget.session.registry.themes[themeIndex];
    final components = widget.session.registry.allComponents;
    return DesyCollectionCanvas<DesyRegistryComponent>(
      theme: theme,
      title: 'Canvas',
      badgeLabel: 'Beta',
      itemNoun: 'components',
      keyPrefix: 'canvas-v2',
      items: [
        for (final component in components)
          DesyCanvasSceneItem(
            id: component.id,
            name: component.name,
            value: component,
            initialSize: component.defaultSize ?? const Size(320, 240),
            previewBuilder: (context, component) => component.buildWithValues(
              context,
              _valuesFor(component),
              widgets: widget.session.registry.widgetBuilder,
            ),
          ),
      ],
      detailsBuilder: (context, item) => _CanvasV2Inspector(
        registry: widget.session.registry,
        component: item.value,
        values: _valuesFor(item.value),
        onChanged: (definition, value) =>
            _setKnob(item.value, definition, value),
      ),
    );
  }

  Map<String, Object> _valuesFor(DesyRegistryComponent component) =>
      _valuesByComponentId.putIfAbsent(
        component.id,
        () => _initialValues(component),
      );

  void _setKnob(
    DesyRegistryComponent component,
    KnobDefinition<Object> definition,
    Object value,
  ) {
    setState(() {
      _valuesByComponentId[component.id] = {
        ..._valuesFor(component),
        definition.id: value,
      };
    });
  }
}

Map<String, Object> _initialValues(DesyRegistryComponent component) => {
  for (final definition in component.knobDefinitions)
    definition.id: switch (definition.kind) {
      DesyKnobKind.widgetInstance =>
        (definition.initial as DesyInstanceId).value,
      DesyKnobKind.widgetInstances => [
        for (final id in (definition.initial as DesyInstanceIds).values)
          id.value,
      ],
      DesyKnobKind.event => const <String, Object?>{},
      _ => definition.initial,
    },
};

class _CanvasV2Inspector extends StatelessWidget {
  const _CanvasV2Inspector({
    required this.registry,
    required this.component,
    required this.values,
    required this.onChanged,
  });

  final DesyRegistry registry;
  final DesyRegistryComponent component;
  final Map<String, Object> values;
  final void Function(KnobDefinition<Object> definition, Object value)
  onChanged;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('canvas-v2-inspector'),
    padding: const EdgeInsets.all(16),
    children: [
      if (component.knobDefinitions.isEmpty)
        DesyKnobSheet(
          title: 'Controls',
          subtitle: component.name,
          sections: const [
            DesyKnobSection(
              label: 'COMPONENT',
              children: [
                DesyKnobRow(
                  label: 'Properties',
                  control: Text('No knobs declared'),
                ),
              ],
            ),
          ],
        )
      else
        DesyComponentKnobPanel(
          registry: registry,
          knobs: component.knobDefinitions,
          values: values,
          onChanged: onChanged,
          title: 'Controls',
          subtitle: component.name,
        ),
    ],
  );
}
