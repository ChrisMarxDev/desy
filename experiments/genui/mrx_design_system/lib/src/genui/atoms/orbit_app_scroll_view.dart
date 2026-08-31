// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppScrollView extends StatelessWidget {
  const OrbitAppScrollView({
    super.key,
    required this.child,
    this.horizontal = false,
  });
  final Widget child;
  final bool horizontal;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
    child: child,
  );
}

Color _toneColor(OrbitColors colors, OrbitSemanticTone tone) => switch (tone) {
  OrbitSemanticTone.neutral => colors.mutedForeground,
  OrbitSemanticTone.accent => colors.accentForeground,
  OrbitSemanticTone.success => colors.success,
  OrbitSemanticTone.warning => colors.warning,
  OrbitSemanticTone.error => colors.destructive,
  OrbitSemanticTone.info => colors.info,
};

OrbitBadgeTone _badgeTone(OrbitSemanticTone tone) => switch (tone) {
  OrbitSemanticTone.neutral => OrbitBadgeTone.neutral,
  OrbitSemanticTone.accent || OrbitSemanticTone.info => OrbitBadgeTone.info,
  OrbitSemanticTone.success => OrbitBadgeTone.success,
  OrbitSemanticTone.warning => OrbitBadgeTone.warning,
  OrbitSemanticTone.error => OrbitBadgeTone.danger,
};

String _toneIcon(OrbitSemanticTone tone) => switch (tone) {
  OrbitSemanticTone.success => 'check',
  OrbitSemanticTone.warning => 'warning',
  OrbitSemanticTone.error => 'close',
  OrbitSemanticTone.info => 'info',
  _ => 'dot',
};

String _glyphFor(String icon) => switch (icon) {
  'add' => OrbitGlyphs.add,
  'minus' => '−',
  'search' => OrbitGlyphs.search,
  'more' => OrbitGlyphs.more,
  'close' => OrbitGlyphs.close,
  'check' => OrbitGlyphs.check,
  'warning' => '!',
  'info' => 'i',
  'user' => '●',
  'image' => '▧',
  'calendar' => '□',
  'clock' => '◷',
  'code' => '</>',
  'map' => '⌖',
  'play' => '▶',
  _ => icon,
};
