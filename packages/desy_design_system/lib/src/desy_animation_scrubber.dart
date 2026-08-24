import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

import 'desy_visual_tokens.dart';

/// A controlled, accessible playhead for a finite animation timeline.
///
/// [progress] is normalized from `0` at the start of [duration] to `1` at its
/// end. The visible tick rail and signal playhead are Desy-owned, while the
/// full scrubber box directly maps pointer positions to normalized progress.
class DesyAnimationScrubber extends StatefulWidget {
  /// Creates an animation playhead scrubber.
  const DesyAnimationScrubber({
    super.key,
    required this.progress,
    required this.duration,
    this.onChanged,
    this.onChangeEnd,
    this.enabled = true,
  }) : assert(progress >= 0 && progress <= 1);

  /// Current normalized position in the animation timeline.
  final double progress;

  /// Total duration represented by the scrubber.
  final Duration duration;

  /// Receives a normalized playhead position during a scrub gesture.
  final ValueChanged<double>? onChanged;

  /// Receives the final normalized playhead position after a scrub gesture.
  final ValueChanged<double>? onChangeEnd;

  /// Whether user input is available.
  final bool enabled;

  @override
  State<DesyAnimationScrubber> createState() => _DesyAnimationScrubberState();
}

class _DesyAnimationScrubberState extends State<DesyAnimationScrubber> {
  static const _sections = 20;
  static const _height = 40.0;
  static const _step = 1 / _sections;

  final FocusNode _focusNode = FocusNode(debugLabel: 'Desy animation scrubber');
  double? _interactionProgress;

  double get _progress => _interactionProgress ?? widget.progress;

  bool get _interactive => widget.enabled && widget.onChanged != null;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String _format(double value) {
    final elapsed = (widget.duration.inMilliseconds * value).round();
    return '$elapsed milliseconds';
  }

  double _progressAt(BuildContext boxContext, Offset localPosition) {
    final width = boxContext.size?.width ?? 0;
    if (width <= 0) return _progress;
    return (localPosition.dx / width).clamp(0.0, 1.0).toDouble();
  }

  void _seek(BuildContext boxContext, Offset localPosition) {
    final next = _progressAt(boxContext, localPosition);
    setState(() => _interactionProgress = next);
    widget.onChanged?.call(next);
  }

  void _finishInteraction() {
    final finalProgress = _progress;
    setState(() => _interactionProgress = null);
    widget.onChangeEnd?.call(finalProgress);
  }

  void _nudge(double delta) {
    if (!_interactive) return;
    final next = (widget.progress + delta).clamp(0.0, 1.0).toDouble();
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final increased = (_progress + _step).clamp(0.0, 1.0).toDouble();
    final decreased = (_progress - _step).clamp(0.0, 1.0).toDouble();

    return Semantics(
      container: true,
      slider: true,
      enabled: _interactive,
      label: 'Playback position',
      value: _format(_progress),
      increasedValue: _format(increased),
      decreasedValue: _format(decreased),
      onIncrease: _interactive ? () => _nudge(_step) : null,
      onDecrease: _interactive ? () => _nudge(-_step) : null,
      child: FocusableActionDetector(
        enabled: _interactive,
        focusNode: _focusNode,
        mouseCursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowLeft): _ScrubberStepIntent(
            -_step,
          ),
          SingleActivator(LogicalKeyboardKey.arrowDown): _ScrubberStepIntent(
            -_step,
          ),
          SingleActivator(LogicalKeyboardKey.arrowRight): _ScrubberStepIntent(
            _step,
          ),
          SingleActivator(LogicalKeyboardKey.arrowUp): _ScrubberStepIntent(
            _step,
          ),
        },
        actions: {
          _ScrubberStepIntent: CallbackAction<_ScrubberStepIntent>(
            onInvoke: (intent) {
              _nudge(intent.delta);
              return null;
            },
          ),
        },
        child: Builder(
          builder: (boxContext) => GestureDetector(
            key: const ValueKey('desy-animation-scrubber-gesture-box'),
            behavior: HitTestBehavior.opaque,
            onTapUp: _interactive
                ? (details) {
                    _focusNode.requestFocus();
                    _seek(boxContext, details.localPosition);
                    _finishInteraction();
                  }
                : null,
            onHorizontalDragStart: _interactive
                ? (details) {
                    _focusNode.requestFocus();
                    _seek(boxContext, details.localPosition);
                  }
                : null,
            onHorizontalDragUpdate: _interactive
                ? (details) => _seek(boxContext, details.localPosition)
                : null,
            onHorizontalDragEnd: _interactive
                ? (_) => _finishInteraction()
                : null,
            onHorizontalDragCancel: _interactive ? _finishInteraction : null,
            child: SizedBox(
              height: _height,
              width: double.infinity,
              child: CustomPaint(
                key: const ValueKey('desy-animation-scrubber-rail'),
                painter: _AnimationScrubberPainter(
                  progress: _progress,
                  guideColor: colors.border,
                  playheadColor: _interactive
                      ? colors.desy.signal
                      : colors.mutedForeground,
                  sections: _sections,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrubberStepIntent extends Intent {
  const _ScrubberStepIntent(this.delta);

  final double delta;
}

class _AnimationScrubberPainter extends CustomPainter {
  const _AnimationScrubberPainter({
    required this.progress,
    required this.guideColor,
    required this.playheadColor,
    required this.sections,
  });

  final double progress;
  final Color guideColor;
  final Color playheadColor;
  final int sections;

  @override
  void paint(Canvas canvas, Size size) {
    const trackTop = 8.0;
    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    for (var index = 0; index <= sections; index++) {
      final x = size.width * index / sections;
      final major = index % (sections ~/ 4) == 0;
      canvas.drawLine(
        Offset(x, trackTop + 11),
        Offset(x, trackTop + (major ? 21 : 16)),
        guidePaint,
      );
    }
    final playheadX = size.width <= 4
        ? size.width / 2
        : (size.width * progress).clamp(2.0, size.width - 2.0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(playheadX, trackTop + 4),
          width: 4,
          height: 32,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = playheadColor,
    );
  }

  @override
  bool shouldRepaint(_AnimationScrubberPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      guideColor != oldDelegate.guideColor ||
      playheadColor != oldDelegate.playheadColor ||
      sections != oldDelegate.sections;
}
