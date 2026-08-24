import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_visual_tokens.dart';

/// Shared square-line backdrop for Desy-owned canvas surfaces.
class DesyCanvasGridBackground extends StatelessWidget {
  /// Creates a canvas grid backdrop.
  const DesyCanvasGridBackground({
    super.key,
    this.cellSize = 24,
    this.backgroundColor,
    this.lineColor,
    this.majorEvery,
    this.majorLineColor,
    this.lineWidth = 1,
    this.majorLineWidth = 1,
    this.child,
  }) : assert(cellSize > 0),
       assert(majorEvery == null || majorEvery > 0),
       assert(lineWidth > 0),
       assert(majorLineWidth > 0);

  /// Logical size of one grid cell.
  final double cellSize;

  /// Surface painted before grid lines.
  final Color? backgroundColor;

  /// One-pixel grid line color.
  final Color? lineColor;

  /// Paints every nth line with [majorLineColor] when supplied.
  final int? majorEvery;

  /// Optional stronger line color for every [majorEvery] grid line.
  final Color? majorLineColor;

  /// Minor grid line stroke width.
  final double lineWidth;

  /// Major grid line stroke width.
  final double majorLineWidth;

  /// Optional content painted above the grid.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return CustomPaint(
      painter: _CanvasGridPainter(
        cellSize: cellSize,
        backgroundColor: backgroundColor ?? colors.desy.canvas,
        lineColor: lineColor ?? colors.border.withValues(alpha: .45),
        majorEvery: majorEvery,
        majorLineColor: majorLineColor,
        lineWidth: lineWidth,
        majorLineWidth: majorLineWidth,
      ),
      child: child,
    );
  }
}

/// Shared checkerboard backdrop for transparent canvas content.
class DesyCheckerboardBackground extends StatelessWidget {
  /// Creates a checkerboard background.
  const DesyCheckerboardBackground({
    super.key,
    this.cellSize = 12,
    this.lightColor,
    this.darkColor,
    this.child,
  }) : assert(cellSize > 0);

  /// Logical size of one checkerboard square.
  final double cellSize;

  /// First square color.
  final Color? lightColor;

  /// Alternating square color.
  final Color? darkColor;

  /// Optional content painted above the checkerboard.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return CustomPaint(
      painter: _CheckerboardPainter(
        cellSize: cellSize,
        lightColor: lightColor ?? colors.desy.panel,
        darkColor: darkColor ?? colors.desy.panelSubtle,
      ),
      child: child,
    );
  }
}

class _CanvasGridPainter extends CustomPainter {
  const _CanvasGridPainter({
    required this.cellSize,
    required this.backgroundColor,
    required this.lineColor,
    required this.majorEvery,
    required this.majorLineColor,
    required this.lineWidth,
    required this.majorLineWidth,
  });

  final double cellSize;
  final Color backgroundColor;
  final Color lineColor;
  final int? majorEvery;
  final Color? majorLineColor;
  final double lineWidth;
  final double majorLineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(backgroundColor, BlendMode.src);
    final minorPaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;
    final majorPaint = Paint()
      ..color = majorLineColor ?? lineColor
      ..strokeWidth = majorLineWidth;
    for (var index = 0, x = 0.0; x <= size.width; index++, x += cellSize) {
      final paint = _isMajor(index) ? majorPaint : minorPaint;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var index = 0, y = 0.0; y <= size.height; index++, y += cellSize) {
      final paint = _isMajor(index) ? majorPaint : minorPaint;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  bool _isMajor(int index) {
    final every = majorEvery;
    return every != null && index % every == 0;
  }

  @override
  bool shouldRepaint(covariant _CanvasGridPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.majorEvery != majorEvery ||
      oldDelegate.majorLineColor != majorLineColor ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.majorLineWidth != majorLineWidth;
}

class _CheckerboardPainter extends CustomPainter {
  const _CheckerboardPainter({
    required this.cellSize,
    required this.lightColor,
    required this.darkColor,
  });

  final double cellSize;
  final Color lightColor;
  final Color darkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        paint.color = ((x / cellSize).floor() + (y / cellSize).floor()).isEven
            ? lightColor
            : darkColor;
        canvas.drawRect(Rect.fromLTWH(x, y, cellSize, cellSize), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CheckerboardPainter oldDelegate) =>
      oldDelegate.cellSize != cellSize ||
      oldDelegate.lightColor != lightColor ||
      oldDelegate.darkColor != darkColor;
}
