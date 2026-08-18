import 'package:desy_bench/desy_bench.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

import 'brand_guide_config.dart';

/// A polished, read-only guideline assembled from one live [DesyRegistry].
final class DesyBrandGuideExtension extends DesyWorkspaceExtension {
  /// Creates the optional Brand Guide extension.
  DesyBrandGuideExtension({DesyBrandGuideConfig? config})
    : config = config ?? DesyBrandGuideConfig();

  /// Brand-specific narrative that cannot be derived from the registry.
  final DesyBrandGuideConfig config;

  @override
  String get id => 'brand-guide';

  @override
  String get name => 'Brand guide';

  @override
  IconData get icon => DesyIcons.layers;

  @override
  String get description =>
      'Read the active design system as one living brand guideline.';

  @override
  Widget build(BuildContext context, DesyWorkspaceExtensionContext extension) =>
      _BrandGuideScreen(extension: extension, config: config);
}

class _BrandGuideScreen extends StatelessWidget {
  const _BrandGuideScreen({required this.extension, required this.config});

  final DesyWorkspaceExtensionContext extension;
  final DesyBrandGuideConfig config;

  @override
  Widget build(BuildContext context) {
    final registry = extension.registry;
    final profile = registry.systemProfile;
    final logos = <DesyAssetEntry>[
      for (final id in config.logoAssetIds) ?registry.asset(id),
    ];
    final imagery = <DesyAssetEntry>[
      for (final id in config.imagery?.assetIds ?? const <String>[])
        ?registry.asset(id),
    ];
    final missingImagery =
        (config.imagery?.assetIds.length ?? 0) - imagery.length;
    final sections = <String>[
      if (profile != null) 'Introduction',
      if (logos.isNotEmpty) 'Logo',
      if (registry.allColors.isNotEmpty) 'Color',
      if (registry.allFonts.isNotEmpty) 'Typography',
      if (registry.allMotion.isNotEmpty) 'Motion',
      if (config.voice.isNotEmpty) 'Voice and tone',
      if (config.imagery != null) 'Imagery',
      if (registry.allAssets.isNotEmpty) 'Assets',
    ];

    return ListView(
      key: const ValueKey('brand-guide-screen'),
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 72),
      children: [
        Text('BRAND GUIDE', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Text(
            registry.name,
            key: const ValueKey('brand-guide-title'),
            style: Theme.of(context).textTheme.displaySmall,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            profile?.summary ??
                'The foundations and approved resources in the active registry.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        if (sections.isNotEmpty) ...[
          const SizedBox(height: 22),
          Wrap(
            key: const ValueKey('brand-guide-contents'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (index, section) in sections.indexed)
                DesyBadge(
                  variant: DesyBadgeVariant.outline,
                  child: Text('${index + 1} · $section'),
                ),
            ],
          ),
        ],
        if (registry.systemHeroAsset case final hero?) ...[
          const SizedBox(height: 30),
          DesyCard(
            key: const ValueKey('brand-guide-hero'),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(
              height: 300,
              child: extension.preview(
                (context) => ColoredBox(
                  color:
                      extension.activeTheme.previewBackgroundColor ??
                      Theme.of(context).colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: hero.build(context),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (profile != null) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-introduction'),
            number: _numberOf(sections, 'Introduction'),
            eyebrow: 'INTRODUCTION',
            title: profile.purpose == null
                ? 'The system'
                : 'Why this system exists',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profile.purpose case final purpose?)
                  Text(purpose, style: Theme.of(context).textTheme.bodyLarge),
                if (profile.principles.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  _PrincipleGrid(principles: profile.principles),
                ],
              ],
            ),
          ),
        ],
        if (logos.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-logo'),
            number: _numberOf(sections, 'Logo'),
            eyebrow: 'LOGO',
            title: 'Approved signatures',
            child: _AssetGrid(extension: extension, assets: logos),
          ),
        ],
        if (registry.allColors.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-color'),
            number: _numberOf(sections, 'Color'),
            eyebrow: 'COLOR',
            title: 'The system palette',
            child: _ColorGrid(colors: registry.allColors),
          ),
        ],
        if (registry.allFonts.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-typography'),
            number: _numberOf(sections, 'Typography'),
            eyebrow: 'TYPOGRAPHY',
            title: 'How the system speaks visually',
            child: Column(
              children: [
                for (final type in registry.allFonts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DesyCard(
                      key: ValueKey('brand-type-${type.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              type.name,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 12),
                            extension.preview(
                              (context) => type.builder(context, type.sample),
                            ),
                            if (type.description case final description?) ...[
                              const SizedBox(height: 10),
                              Text(description),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (registry.allMotion.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-motion'),
            number: _numberOf(sections, 'Motion'),
            eyebrow: 'MOTION',
            title: 'How the system moves',
            child: _PreviewGrid(
              children: [
                for (final motion in registry.allMotion)
                  DesyCard(
                    key: ValueKey('brand-motion-${motion.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            motion.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(motion.displayValue),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 150,
                            child: extension.preview(motion.buildDefault),
                          ),
                          if (motion.description case final description?) ...[
                            const SizedBox(height: 10),
                            Text(description),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (config.voice.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-voice'),
            number: _numberOf(sections, 'Voice and tone'),
            eyebrow: 'VOICE AND TONE',
            title: 'How the brand sounds',
            child: _VoiceGrid(principles: config.voice),
          ),
        ],
        if (config.imagery case final guidance?) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-imagery'),
            number: _numberOf(sections, 'Imagery'),
            eyebrow: 'IMAGERY',
            title: 'The world around the system',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Text(
                    guidance.summary,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                if (missingImagery > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '$missingImagery imagery reference${missingImagery == 1 ? '' : 's'} could not be resolved.',
                    key: const ValueKey('brand-guide-missing-imagery'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (imagery.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _AssetGrid(extension: extension, assets: imagery),
                ],
              ],
            ),
          ),
        ],
        if (registry.allAssets.isNotEmpty) ...[
          _GuideGap(),
          _GuideSection(
            key: const ValueKey('brand-guide-assets'),
            number: _numberOf(sections, 'Assets'),
            eyebrow: 'ASSETS',
            title: 'Approved working resources',
            child: _AssetLedger(assets: registry.allAssets),
          ),
        ],
      ],
    );
  }

  int _numberOf(List<String> sections, String section) =>
      sections.indexOf(section) + 1;
}

class _GuideGap extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(height: 56);
}

class _GuideSection extends StatelessWidget {
  const _GuideSection({
    super.key,
    required this.number,
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  final int number;
  final String eyebrow;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$number · $eyebrow', style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: 5),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 18),
      child,
    ],
  );
}

class _PrincipleGrid extends StatelessWidget {
  const _PrincipleGrid({required this.principles});

  final List<DesySystemPrinciple> principles;

  @override
  Widget build(BuildContext context) => _PreviewGrid(
    children: [
      for (final principle in principles)
        DesyCard(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principle.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(principle.guidance),
              ],
            ),
          ),
        ),
    ],
  );
}

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors});

  final List<DesyColorEntry> colors;

  @override
  Widget build(BuildContext context) => _PreviewGrid(
    minimumWidth: 190,
    children: [
      for (final color in colors)
        DesyCard(
          key: ValueKey('brand-color-${color.id}'),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: color.color,
                child: const SizedBox(height: 112),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      color.name,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    SelectableText(color.displayValue),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _AssetGrid extends StatelessWidget {
  const _AssetGrid({required this.extension, required this.assets});

  final DesyWorkspaceExtensionContext extension;
  final List<DesyAssetEntry> assets;

  @override
  Widget build(BuildContext context) => _PreviewGrid(
    children: [
      for (final asset in assets)
        DesyCard(
          key: ValueKey('brand-asset-${asset.id}'),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 190,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: extension.preview(asset.build),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      asset.fileName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(asset.description),
                  ],
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _VoiceGrid extends StatelessWidget {
  const _VoiceGrid({required this.principles});

  final List<DesyVoicePrinciple> principles;

  @override
  Widget build(BuildContext context) => _PreviewGrid(
    children: [
      for (final principle in principles)
        DesyCard(
          key: ValueKey('brand-voice-${principle.id}'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  principle.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(principle.guidance),
                if (principle.doExamples.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('DO', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  for (final example in principle.doExamples) Text(example),
                ],
                if (principle.dontExamples.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('DON’T', style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 4),
                  for (final example in principle.dontExamples) Text(example),
                ],
              ],
            ),
          ),
        ),
    ],
  );
}

class _AssetLedger extends StatelessWidget {
  const _AssetLedger({required this.assets});

  final List<DesyAssetEntry> assets;

  @override
  Widget build(BuildContext context) => DesyCard(
    child: Column(
      children: [
        for (final (index, asset) in assets.indexed) ...[
          if (index > 0) const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.fileName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(asset.description),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                DesyBadge(
                  variant: DesyBadgeVariant.outline,
                  child: Text(asset.id),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _PreviewGrid extends StatelessWidget {
  const _PreviewGrid({required this.children, this.minimumWidth = 300});

  final List<Widget> children;
  final double minimumWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = (constraints.maxWidth / minimumWidth).floor().clamp(1, 3);
      final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
      return Wrap(
        spacing: 14,
        runSpacing: 14,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          for (final child in children) SizedBox(width: width, child: child),
        ],
      );
    },
  );
}
