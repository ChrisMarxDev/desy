/// Optional brand-specific narrative layered over registry-owned facts.
final class DesyBrandGuideConfig {
  /// Creates immutable guide guidance.
  DesyBrandGuideConfig({
    List<DesyVoicePrinciple> voice = const [],
    List<String> logoAssetIds = const [],
    this.imagery,
  }) : voice = List.unmodifiable(voice),
       logoAssetIds = List.unmodifiable(logoAssetIds) {
    final ids = voice.map((principle) => principle.id).toSet();
    if (ids.length != voice.length) {
      throw ArgumentError.value(
        voice,
        'voice',
        'Voice principle IDs must be unique.',
      );
    }
    if (logoAssetIds.toSet().length != logoAssetIds.length) {
      throw ArgumentError.value(
        logoAssetIds,
        'logoAssetIds',
        'Logo asset IDs must be unique.',
      );
    }
  }

  /// Optional voice and tone rules.
  final List<DesyVoicePrinciple> voice;

  /// Optional logo examples explicitly selected from registered assets.
  final List<String> logoAssetIds;

  /// Optional imagery direction referencing registered assets.
  final DesyImageryGuidance? imagery;
}

/// One typed voice rule with concrete positive and negative examples.
final class DesyVoicePrinciple {
  /// Creates immutable voice guidance.
  DesyVoicePrinciple({
    required this.id,
    required this.title,
    required this.guidance,
    List<String> doExamples = const [],
    List<String> dontExamples = const [],
  }) : doExamples = List.unmodifiable(doExamples),
       dontExamples = List.unmodifiable(dontExamples);

  /// Stable principle identity within the guide.
  final String id;

  /// Concise voice rule.
  final String title;

  /// Operational explanation of the rule.
  final String guidance;

  /// Approved copy examples.
  final List<String> doExamples;

  /// Copy patterns to avoid.
  final List<String> dontExamples;
}

/// Curated imagery direction over existing registry asset IDs.
final class DesyImageryGuidance {
  /// Creates immutable imagery guidance.
  DesyImageryGuidance({required this.summary, required List<String> assetIds})
    : assetIds = List.unmodifiable(assetIds) {
    if (assetIds.toSet().length != assetIds.length) {
      throw ArgumentError.value(
        assetIds,
        'assetIds',
        'Imagery asset IDs must be unique.',
      );
    }
  }

  /// The visual world the approved examples should establish.
  final String summary;

  /// Stable IDs resolved from the active registry.
  final List<String> assetIds;
}
