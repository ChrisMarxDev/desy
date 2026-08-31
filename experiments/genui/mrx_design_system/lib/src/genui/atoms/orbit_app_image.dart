// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppImage extends StatelessWidget {
  const OrbitAppImage({
    super.key,
    required this.source,
    required this.alt,
    this.presentation = OrbitImagePresentation.content,
    this.caption,
  });

  final String source;
  final String alt;
  final OrbitImagePresentation presentation;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final height = switch (presentation) {
      OrbitImagePresentation.hero => 220.0,
      OrbitImagePresentation.content => 160.0,
      OrbitImagePresentation.thumbnail => 72.0,
    };
    final image = source.isEmpty
        ? _ImageFallback(label: alt)
        : Image.network(
            source,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: alt,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: OrbitAppSpinner()),
            errorBuilder: (context, error, stackTrace) =>
                _ImageFallback(label: alt),
          );
    return Semantics(
      image: true,
      label: alt,
      child: OrbitAppStack(
        gap: OrbitTokens.spaceXs,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(OrbitTokens.radiusMd),
            child: image,
          ),
          if (caption != null)
            OrbitAppText(caption!, role: OrbitTextRole.caption),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 120,
    child: OrbitSurface(
      tone: OrbitSurfaceTone.muted,
      child: Center(
        child: OrbitAppText(
          label,
          role: OrbitTextRole.caption,
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
