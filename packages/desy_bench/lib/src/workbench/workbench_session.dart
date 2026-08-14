// Internal workbench session state; it is not consumer-facing package API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:state_beacon/state_beacon.dart';

import '../device_preview.dart';
import '../detail_extension.dart';
import '../registry.dart';
import '../workspace_extension.dart';
import 'workbench_annotation.dart';
import 'annotation_workspace.dart';

/// Ephemeral interaction state for one open Desy workbench.
///
/// The registry remains immutable consumer data. Routes own navigation; this
/// controller only holds preview geometry and the values a person is trying.
class DesyWorkbenchSession {
  DesyWorkbenchSession({
    required this.registry,
    List<DesyWorkspaceExtension> extensions = const [],
    List<DesyDetailExtension> detailExtensions = const [],
    DesyAnnotationWorkspace? annotations,
  }) : extensions = List.unmodifiable(extensions),
       detailExtensions = List.unmodifiable(detailExtensions),
       annotations = annotations ?? DesyAnnotationWorkspace();

  final DesyRegistry registry;
  final List<DesyWorkspaceExtension> extensions;
  final List<DesyDetailExtension> detailExtensions;
  final DesyAnnotationWorkspace annotations;

  final activeThemeIndex = Beacon.writable(0);
  final selectedScenario = Beacon.writable<DesyComponentScenario?>(null);
  final selectedComponentInstance =
      Beacon.writable<DesyRegisteredComponentInstance?>(null);
  final previewDevice = Beacon.writable<DesyDevicePreset?>(null);
  final knobValues = Beacon.writable<Map<String, Object>>({});
  final atlasQuery = Beacon.writable('');
  final sidebarQuery = Beacon.writable('');
  final previewAccessibility = Beacon.writable(
    const DesyPreviewAccessibilitySettings(),
  );
  final fontSampleText = Beacon.writable(
    'The quick brown fox jumps over the lazy dog.',
  );
  final stage = Beacon.writable(const DesyPreviewStage());
  final workbenchAnnotations = Beacon.writable<List<DesyWorkbenchAnnotation>>(
    const [],
  );
  final pendingAgentRequest = Beacon.writable('');

  DesyTheme get activeTheme => registry.themes[activeThemeIndex.value];

  DesyWorkspaceExtensionContext get extensionContext =>
      DesyWorkspaceExtensionContext(
        registry: registry,
        activeTheme: registry.themes[activeThemeIndex.value],
        workbenchAnnotations: workbenchAnnotations.value,
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

  void selectPreviewDevice(DesyDevicePreset? device) {
    stage.value = stage.value.copyWith(
      size: device?.screenSize ?? const DesyPreviewStage().size,
    );
    previewDevice.value = device;
  }

  void updateStage(DesyPreviewStage next) => stage.value = next;

  /// Updates the preview-only environment without mutating consumer widgets.
  void setPreviewAccessibility(DesyPreviewAccessibilitySettings settings) {
    previewAccessibility.value = settings;
  }

  /// Commits one source-aware note without mutating consumer registry data.
  void addWorkbenchAnnotation({
    required DesyWorkbenchWidgetTarget target,
    required String comment,
  }) {
    final text = comment.trim();
    if (text.isEmpty) return;
    workbenchAnnotations.value = List.unmodifiable([
      ...workbenchAnnotations.value,
      DesyWorkbenchAnnotation(
        id: workbenchAnnotations.value.length + 1,
        target: target,
        comment: text,
        createdAt: DateTime.now(),
      ),
    ]);
    unawaited(annotations.store.save(workbenchAnnotations.value));
  }

  /// Removes the selected local review notes and persists the remaining inbox.
  void removeWorkbenchAnnotations(Iterable<int> ids) {
    final removed = ids.toSet();
    if (removed.isEmpty) return;
    workbenchAnnotations.value = List.unmodifiable([
      for (final annotation in workbenchAnnotations.value)
        if (!removed.contains(annotation.id)) annotation,
    ]);
    unawaited(annotations.store.save(workbenchAnnotations.value));
  }

  /// Restores persisted review notes without making persistence a core concern.
  Future<void> hydrateAnnotations() async {
    final restored = await annotations.store.load();
    workbenchAnnotations.value = List.unmodifiable(restored);
  }

  /// Conservatively detaches visible targets after hot reload.
  ///
  /// Flutter may preserve an element, replace it, or relocate it after an
  /// edit. Keeping source evidence is useful, but reusing the former bounds
  /// would suggest certainty Desy does not have.
  void detachWorkbenchAnnotationsAfterReload() {
    if (workbenchAnnotations.value.isEmpty) return;
    workbenchAnnotations.value = List.unmodifiable([
      for (final annotation in workbenchAnnotations.value)
        if (annotation.attachment == DesyWorkbenchAnnotationAttachment.detached)
          annotation
        else
          annotation.copyWithAttachment(
            DesyWorkbenchAnnotationAttachment.detached,
          ),
    ]);
  }

  /// Carries a home-screen request into the next local agent workspace.
  ///
  /// The value is intentionally ephemeral: it exists only to preserve the
  /// user's first sentence while moving from the Registry Spine home state to
  /// the resumable Workshop conversation.
  void startAgentRequest(String value) {
    pendingAgentRequest.value = value.trim();
  }

  /// Clears the request once its destination workspace has adopted it.
  void consumePendingAgentRequest() => pendingAgentRequest.value = '';

  void dispose() {
    activeThemeIndex.dispose();
    selectedScenario.dispose();
    selectedComponentInstance.dispose();
    previewDevice.dispose();
    knobValues.dispose();
    atlasQuery.dispose();
    sidebarQuery.dispose();
    previewAccessibility.dispose();
    fontSampleText.dispose();
    stage.dispose();
    workbenchAnnotations.dispose();
    pendingAgentRequest.dispose();
  }
}

/// Media-query overrides applied only inside the inspected consumer preview.
///
/// These settings deliberately live beside the other ephemeral preview state:
/// they are test conditions, not consumer theme or registry declarations.
class DesyPreviewAccessibilitySettings {
  const DesyPreviewAccessibilitySettings({
    this.textScale = 1,
    this.textDirection = TextDirection.ltr,
    this.boldText = false,
    this.highContrast = false,
    this.disableAnimations = false,
    this.showSemantics = false,
    this.showHitTargets = false,
  });

  final double textScale;
  final TextDirection textDirection;
  final bool boldText;
  final bool highContrast;
  final bool disableAnimations;
  final bool showSemantics;
  final bool showHitTargets;

  DesyPreviewAccessibilitySettings copyWith({
    double? textScale,
    TextDirection? textDirection,
    bool? boldText,
    bool? highContrast,
    bool? disableAnimations,
    bool? showSemantics,
    bool? showHitTargets,
  }) => DesyPreviewAccessibilitySettings(
    textScale: textScale ?? this.textScale,
    textDirection: textDirection ?? this.textDirection,
    boldText: boldText ?? this.boldText,
    highContrast: highContrast ?? this.highContrast,
    disableAnimations: disableAnimations ?? this.disableAnimations,
    showSemantics: showSemantics ?? this.showSemantics,
    showHitTargets: showHitTargets ?? this.showHitTargets,
  );
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
