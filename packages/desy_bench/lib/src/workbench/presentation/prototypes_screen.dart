// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../workbench_annotation.dart';
import '../workbench_session.dart';
import 'collection_canvas.dart';

/// A canvas comparison surface for consumer-owned visual experiments.
///
/// Prototypes share the collection canvas interaction model with registered
/// components, but retain prototype-specific preview context and direction
/// details through the canvas's typed builders.
class DesyPrototypesScreen extends StatelessWidget {
  const DesyPrototypesScreen({
    super.key,
    required this.session,
    required this.prototypeSession,
  });

  final DesyWorkbenchSession session;
  final DesyPrototypeSession prototypeSession;

  @override
  Widget build(BuildContext context) {
    final themeIndex = session.activeThemeIndex.watch(context);
    final theme = session.registry.themes[themeIndex];
    return DesyCollectionCanvas<DesyPrototype>(
      theme: theme,
      title: prototypeSession.name,
      description: prototypeSession.description,
      badgeLabel: 'Prototypes',
      itemNoun: 'directions',
      keyPrefix: 'prototypes-canvas-${prototypeSession.id}',
      items: [
        for (final prototype in prototypeSession.prototypes)
          DesyCanvasSceneItem(
            id: prototype.id,
            name: prototype.name,
            value: prototype,
            initialSize:
                prototype.canvasPlacement?.size ?? const Size(380, 620),
            initialRect: prototype.canvasPlacement?.rect,
            previewBuilder: (context, prototype) => SizedBox(
              key: ValueKey('prototype-fill-${prototype.id}'),
              width: double.infinity,
              child: DesyWorkbenchInspectionScope(
                key: ValueKey('prototype-scope-${prototype.id}'),
                context: DesyWorkbenchInspectionContext(
                  artifactId: prototype.id,
                  kind: 'Prototype',
                  label: prototype.name,
                ),
                child: Builder(builder: prototype.builder),
              ),
            ),
          ),
      ],
      detailsBuilder: (context, item) =>
          _PrototypeCanvasDetails(prototype: item.value),
    );
  }
}

class _PrototypeCanvasDetails extends StatelessWidget {
  const _PrototypeCanvasDetails({required this.prototype});

  final DesyPrototype prototype;

  @override
  Widget build(BuildContext context) => ListView(
    key: const ValueKey('prototypes-canvas-inspector'),
    padding: EdgeInsets.zero,
    children: [
      DesyKnobSheet(
        segments: [
          DesyKnobSegment(
            title: 'DIRECTION',
            description: 'The selected prototype direction.',
            children: [
              DesyTextValueKnobRow(label: 'Name', value: prototype.name),
              DesyTextValueKnobRow(label: 'Prototype ID', value: prototype.id),
              if (prototype.description case final description?)
                DesyTextValueKnobRow(label: 'Notes', value: description),
            ],
          ),
        ],
      ),
    ],
  );
}
