// Internal workbench session state; it is not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:state_beacon/state_beacon.dart';

import '../device_preview.dart';
import '../detail_extension.dart';
import '../registry.dart';
import '../workspace_extension.dart';

/// Ephemeral interaction state for one open Desy workbench.
///
/// The registry remains immutable consumer data. Routes own navigation; this
/// controller only holds preview geometry and the values a person is trying.
class DesyWorkbenchSession {
  DesyWorkbenchSession({
    required this.registry,
    List<DesyWorkspaceExtension> extensions = const [],
    List<DesyDetailExtension> detailExtensions = const [],
  }) : extensions = List.unmodifiable(extensions),
       detailExtensions = List.unmodifiable(detailExtensions);

  final DesyRegistry registry;
  final List<DesyWorkspaceExtension> extensions;
  final List<DesyDetailExtension> detailExtensions;

  final activeThemeIndex = Beacon.writable(0);
  final selectedScenario = Beacon.writable<DesyComponentScenario?>(null);
  final selectedComponentInstance =
      Beacon.writable<DesyRegisteredComponentInstance?>(null);
  final previewDevice = Beacon.writable<DesyDevicePreset?>(null);
  final knobValues = Beacon.writable<Map<String, Object>>({});
  final atlasQuery = Beacon.writable('');
  final fontSampleText = Beacon.writable(
    'The quick brown fox jumps over the lazy dog.',
  );
  final stage = Beacon.writable(const DesyPreviewStage());

  DesyTheme get activeTheme => registry.themes[activeThemeIndex.value];

  DesyWorkspaceExtensionContext get extensionContext =>
      DesyWorkspaceExtensionContext(
        registry: registry,
        activeTheme: registry.themes[activeThemeIndex.value],
      );

  DesyDetailExtensionContext detailExtensionContext(DesyRegistryEntry entry) {
    return DesyDetailExtensionContext(
      registry: registry,
      activeTheme: registry.themes[activeThemeIndex.value],
      entry: entry,
    );
  }

  /// Starts a fresh inspection for the entry currently addressed by a route.
  void prepareEntry(DesyRegistryEntry entry) {
    selectedScenario.value = null;
    selectedComponentInstance.value = null;
    previewDevice.value = null;
    knobValues.value = _defaults(entry.component);
    stage.value = const DesyPreviewStage();
  }

  void selectTheme(int index) {
    activeThemeIndex.value = index;
  }

  void selectScenario(DesyComponentScenario? scenario) {
    selectedScenario.value = scenario;
    selectedComponentInstance.value = null;
  }

  /// Starts editing one declared component variant in the detail inspector.
  ///
  /// The mutable knob map is derived from the component defaults and optional
  /// instance preset. The consumer-owned declaration remains immutable.
  void editComponentVariant({
    required DesyRegistryComponent component,
    DesyRegisteredComponentInstance? instance,
  }) {
    knobValues.value = instance == null
        ? _defaults(component)
        : component.valuesFor(instance.instanceId);
    selectedScenario.value = null;
    selectedComponentInstance.value = instance;
  }

  void setKnob(KnobDefinition<Object> definition, Object value) {
    knobValues.value = {...knobValues.value, definition.id: value};
    selectedScenario.value = null;
  }

  Map<String, Object> _defaults(DesyRegistryComponent? component) => {
    for (final definition in component?.knobDefinitions ?? const [])
      definition.id: definition.kind == DesyKnobKind.widgetInstance
          ? (definition.initial as DesyInstanceId).value
          : definition.initial,
  };

  void selectPreviewDevice(DesyDevicePreset? device) {
    stage.value = stage.value.copyWith(
      size: device?.frameSize ?? const DesyPreviewStage().size,
    );
    previewDevice.value = device;
  }

  void updateStage(DesyPreviewStage next) => stage.value = next;

  void dispose() {
    activeThemeIndex.dispose();
    selectedScenario.dispose();
    selectedComponentInstance.dispose();
    previewDevice.dispose();
    knobValues.dispose();
    atlasQuery.dispose();
    fontSampleText.dispose();
    stage.dispose();
  }
}

/// Geometry of the movable, resizable preview artboard in a detail canvas.
class DesyPreviewStage {
  const DesyPreviewStage({
    this.offset = const Offset(88, 72),
    this.size = const Size(320, 240),
  });

  final Offset offset;
  final Size size;

  DesyPreviewStage copyWith({Offset? offset, Size? size}) =>
      DesyPreviewStage(offset: offset ?? this.offset, size: size ?? this.size);
}
