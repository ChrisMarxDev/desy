// Internal workbench session state; it is not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:device_preview/device_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:state_beacon/state_beacon.dart';

import '../detail_extension.dart';
import '../registry.dart';
import '../workspace_extension.dart';

/// The small initial set of preview-frame profiles.
///
/// This is local workbench state and never changes the consumer registry.
enum DesyPreviewBezel { iPhone15Pro, iPadPro11 }

extension DesyPreviewBezelDevice on DesyPreviewBezel {
  DeviceInfo get device => switch (this) {
    DesyPreviewBezel.iPhone15Pro => Devices.ios.iPhone15Pro,
    DesyPreviewBezel.iPadPro11 => Devices.ios.iPadPro11Inches,
  };
}

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
  final selectedComponentInstance = Beacon.writable<DesyComponentInstance?>(
    null,
  );
  final previewBezel = Beacon.writable<DesyPreviewBezel?>(null);
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
    previewBezel.value = null;
    knobValues.value = {
      for (final knob in entry.component?.knobs ?? const <DesyKnob<Object>>[])
        knob.id: knob.initial,
    };
    stage.value = const DesyPreviewStage();
  }

  void selectTheme(int index) {
    activeThemeIndex.value = index;
  }

  void selectScenario(DesyComponentScenario? scenario) {
    selectedScenario.value = scenario;
    selectedComponentInstance.value = null;
  }

  /// Applies a named component preset without making a separate mutable copy
  /// of the consumer's instance declaration.
  void applyInstance(DesyComponentInstance instance) {
    knobValues.value = {...knobValues.value, ...instance.knobValues.entries};
    selectedScenario.value = null;
    selectedComponentInstance.value = instance;
  }

  void setKnob(DesyKnob<Object> knob, Object value) {
    if (!_isLegalKnobValue(knob, value)) {
      throw ArgumentError.value(
        value,
        knob.id,
        'The value must be one of the component knob\'s declared options.',
      );
    }
    knobValues.value = {...knobValues.value, knob.id: value};
    selectedScenario.value = null;
    selectedComponentInstance.value = null;
  }

  bool _isLegalKnobValue(DesyKnob<Object> knob, Object value) => switch (knob) {
    DesyBooleanKnob() => value is bool,
    DesyStringKnob() => value is String,
    DesyComponentKnob() =>
      value is DesyComponentInstance &&
          knob.options.any((option) => identical(option, value)),
    _ => false,
  };

  void selectPreviewBezel(DesyPreviewBezel? bezel) {
    stage.value = stage.value.copyWith(
      size: bezel?.device.frameSize ?? const DesyPreviewStage().size,
    );
    previewBezel.value = bezel;
  }

  void updateStage(DesyPreviewStage next) => stage.value = next;

  void dispose() {
    activeThemeIndex.dispose();
    selectedScenario.dispose();
    selectedComponentInstance.dispose();
    previewBezel.dispose();
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
