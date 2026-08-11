import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Resolved geometry for Desy's consumer-embedded annotation chrome.
///
/// Consumer content keeps its original geometry. Only Desy's launcher, prompt,
/// and annotation card are inset around system UI and the software keyboard.
@immutable
class DesyOverlayLayout {
  const DesyOverlayLayout._({
    required this.cardWidth,
    required this.cardMaxHeight,
    required this.cardOffset,
    required this.launcherBottom,
    required this.promptBottom,
    required this.chromeRight,
    required Offset minimumCardOffset,
    required Offset maximumCardOffset,
  }) : _minimumCardOffset = minimumCardOffset,
       _maximumCardOffset = maximumCardOffset;

  static const double _edgeInset = 8;
  static const double _cardWidthLimit = 360;
  static const double _estimatedCardHeight = 300;

  /// Resolves overlay geometry for one viewport and current system insets.
  factory DesyOverlayLayout.resolve({
    required Size viewport,
    required EdgeInsets padding,
    required EdgeInsets viewInsets,
    required Offset? requestedCardOffset,
    required bool touchMode,
  }) {
    final obstructedBottom = math.max(padding.bottom, viewInsets.bottom);
    final safeTop = padding.top + _edgeInset;
    final safeBottom = math.max(
      safeTop,
      viewport.height - obstructedBottom - _edgeInset,
    );
    final cardWidth = math.min(
      _cardWidthLimit,
      math.max(0.0, viewport.width - padding.left - padding.right - 24),
    );
    final cardMaxHeight = math.max(0.0, safeBottom - safeTop);
    final estimatedCardHeight = math.min(_estimatedCardHeight, cardMaxHeight);
    final minimumCardOffset = Offset(padding.left + _edgeInset, safeTop);
    final maximumCardOffset = Offset(
      math.max(
        minimumCardOffset.dx,
        viewport.width - padding.right - cardWidth - _edgeInset,
      ),
      math.max(safeTop, safeBottom - estimatedCardHeight),
    );
    final launcherBottom = obstructedBottom + 16;
    final promptBottom = launcherBottom + (touchMode ? 62 : 46);
    final fallback = Offset(
      maximumCardOffset.dx - 8,
      (viewport.height -
              promptBottom -
              estimatedCardHeight -
              DesyOverlayLayout._edgeInset)
          .clamp(minimumCardOffset.dy, maximumCardOffset.dy),
    );

    Offset clamp(Offset offset) => Offset(
      offset.dx.clamp(minimumCardOffset.dx, maximumCardOffset.dx),
      offset.dy.clamp(minimumCardOffset.dy, maximumCardOffset.dy),
    );

    return DesyOverlayLayout._(
      cardWidth: cardWidth,
      cardMaxHeight: cardMaxHeight,
      cardOffset: clamp(requestedCardOffset ?? fallback),
      launcherBottom: launcherBottom,
      promptBottom: promptBottom,
      chromeRight: padding.right + 16,
      minimumCardOffset: minimumCardOffset,
      maximumCardOffset: maximumCardOffset,
    );
  }

  /// Width of the annotation card after horizontal safe-area insets.
  final double cardWidth;

  /// Maximum space available above system UI and the software keyboard.
  final double cardMaxHeight;

  /// Current clamped card position.
  final Offset cardOffset;

  /// Distance from the physical bottom to the launcher.
  final double launcherBottom;

  /// Distance from the physical bottom to the selection prompt.
  final double promptBottom;

  /// Distance from the physical right edge to floating chrome.
  final double chromeRight;

  final Offset _minimumCardOffset;
  final Offset _maximumCardOffset;

  /// Keeps a dragged card within the safe, keyboard-free viewport.
  Offset clampCardOffset(Offset offset) => Offset(
    offset.dx.clamp(_minimumCardOffset.dx, _maximumCardOffset.dx),
    offset.dy.clamp(_minimumCardOffset.dy, _maximumCardOffset.dy),
  );
}
