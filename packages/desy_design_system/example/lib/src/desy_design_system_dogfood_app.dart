import 'package:desy_agent_annotations/desy_agent_annotations.dart';
import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';

import 'desy_design_system_registry.dart';
import 'dogfood_annotations/dogfood_annotation_sink.dart';

/// Builds Desy's maintained dogfood catalogue with its optional extensions.
Widget buildDesyDesignSystemDogfoodApp({DesyAgentAnnotationSubmit? onSubmit}) =>
    DesyBenchApp(
      registry: desyDesignSystemRegistry,
      detailExtensions: [
        DesyAgentAnnotationsExtension(
          onSubmit: onSubmit ?? createDesyDogfoodAnnotationSubmit(),
        ),
      ],
    );
