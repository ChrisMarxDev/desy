import 'package:desy_bench/desy_bench.dart';
import 'package:desy_brand_guide/desy_brand_guide.dart';
import 'package:desy_screenshot_builder/desy_screenshot_builder.dart';

import 'desy_design_system_example.dart';

/// Launches the catalogue for Desy's own workbench design system.
Future<void> main() => runDesyBenchApp(
  registry: desyDesignSystemRegistry,
  extensions: [
    DesyBrandGuideExtension(
      config: DesyBrandGuideConfig(
        logoAssetIds: [
          'desy.asset.workspace.signature.primary',
          'desy.asset.workspace.signature.signal',
        ],
        voice: [
          DesyVoicePrinciple(
            id: 'desy.voice.direct',
            title: 'Direct, never inflated',
            guidance:
                'Name the useful fact, the action, and the consequence in plain language.',
            doExamples: ['Preview the registered component.'],
            dontExamples: ['Unlock a revolutionary component experience.'],
          ),
        ],
        imagery: DesyImageryGuidance(
          summary:
              'Show real interface work with structure, contrast, and one precise signal accent.',
          assetIds: ['desy.asset.workspace.system-map'],
        ),
      ),
    ),
    const DesyScreenshotBuilderExtension(),
  ],
);
