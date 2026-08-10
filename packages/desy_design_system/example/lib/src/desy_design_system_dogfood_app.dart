import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:desy_widget_workshop/desy_widget_workshop.dart';
import 'package:flutter/widgets.dart';

import 'desy_design_system_registry.dart';
import 'desy_workshop_candidates.dart';
import 'dogfood_annotations/dogfood_annotation_sink.dart';

const _workshopProjectDirectory = String.fromEnvironment(
  'DESY_WORKSHOP_PROJECT_DIR',
  defaultValue: '.',
);

/// Builds Desy's maintained dogfood catalogue with its optional extensions.
Widget buildDesyDesignSystemDogfoodApp({DesyAgentAnnotationSubmit? onSubmit}) =>
    DesyBenchApp(
      registry: desyDesignSystemRegistry,
      extensions: [
        DesyWidgetWorkshopExtension(
          configuration: DesyWidgetWorkshopConfiguration(
            projectDirectory: _workshopProjectDirectory,
            candidateSourcePath:
                'packages/desy_design_system/example/lib/src/'
                'desy_workshop_candidates.dart',
            flutterPidFile:
                'packages/desy_design_system/example/build/'
                'desy_workshop_hot_reload.pid',
            candidates: buildDesyWorkshopCandidates,
          ),
        ),
      ],
      detailExtensions: [
        DesyAgentAnnotationsExtension(
          onSubmit: onSubmit ?? createDesyDogfoodAnnotationSubmit(),
        ),
      ],
    );
