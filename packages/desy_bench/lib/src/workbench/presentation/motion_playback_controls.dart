// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

import '../../motion_playback.dart';

class DesyMotionPlaybackControls extends StatelessWidget {
  const DesyMotionPlaybackControls({
    super.key,
    required this.controller,
    this.compact = false,
    this.globalDuration,
    this.onGlobalDurationChanged,
  });

  final DesyMotionPlaybackController controller;
  final bool compact;
  final Duration? globalDuration;
  final ValueChanged<Duration>? onGlobalDurationChanged;

  static const _speeds = [0.5, 1.0, 2.0];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => compact
        ? _CompactMotionPlaybackControls(
            controller: controller,
            globalDuration: globalDuration,
            onGlobalDurationChanged: onGlobalDurationChanged,
          )
        : _PanelMotionPlaybackControls(controller: controller),
  );
}

class _PanelMotionPlaybackControls extends StatelessWidget {
  const _PanelMotionPlaybackControls({required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('motion-playback-controls'),
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _PlaybackButtons(controller: controller),
      const SizedBox(height: 18),
      _PlayheadLabel(controller: controller),
      const SizedBox(height: 8),
      _PlaybackSlider(controller: controller),
      const SizedBox(height: 18),
      Text('Playback speed', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      _SpeedButtons(controller: controller),
    ],
  );
}

class _CompactMotionPlaybackControls extends StatelessWidget {
  const _CompactMotionPlaybackControls({
    required this.controller,
    required this.globalDuration,
    required this.onGlobalDurationChanged,
  });

  final DesyMotionPlaybackController controller;
  final Duration? globalDuration;
  final ValueChanged<Duration>? onGlobalDurationChanged;

  @override
  Widget build(BuildContext context) => DesyCard(
    key: const ValueKey('motion-global-playback-controls'),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => _CompactDockControls(
              controller: controller,
              globalDuration: globalDuration,
              onGlobalDurationChanged: onGlobalDurationChanged,
              stack: constraints.maxWidth < 620,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'TIMELINE',
                        style: context.theme.typography.body.xs.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                      const Spacer(),
                      _PlayheadLabel(controller: controller, inline: true),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _PlaybackThermometer(
                    key: const ValueKey('motion-playhead-thermometer'),
                    controller: controller,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SpeedButtons(
            controller: controller,
            size: DesyButtonSize.sm,
            dockHeight: 40,
          ),
        ],
      ),
    ),
  );
}

class _CompactDockControls extends StatelessWidget {
  const _CompactDockControls({
    required this.controller,
    required this.globalDuration,
    required this.onGlobalDurationChanged,
    required this.stack,
  });

  final DesyMotionPlaybackController controller;
  final Duration? globalDuration;
  final ValueChanged<Duration>? onGlobalDurationChanged;
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final play = _DockControl(
      child: _PlayPauseButton(
        controller: controller,
        iconOnly: true,
        size: DesyButtonSize.sm,
      ),
    );
    final duration = globalDuration == null
        ? null
        : _DockControl(
            child: _GlobalDurationField(
              duration: globalDuration!,
              onChanged: onGlobalDurationChanged,
              compact: true,
            ),
          );
    final playbackType = _DockControl(
      child: _LoopModeButton(controller: controller, size: DesyButtonSize.sm),
    );
    if (stack) {
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [play, ?duration, playbackType],
      );
    }
    return Row(
      children: [
        play,
        if (duration != null) ...[const SizedBox(width: 10), duration],
        const SizedBox(width: 18),
        playbackType,
      ],
    );
  }
}

class _DockControl extends StatelessWidget {
  const _DockControl({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(height: 40, child: child);
}

class _MotionControlGroup extends StatelessWidget {
  const _MotionControlGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: .8,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: style),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _GlobalDurationField extends StatefulWidget {
  const _GlobalDurationField({
    required this.duration,
    this.onChanged,
    this.compact = false,
  });

  final Duration duration;
  final ValueChanged<Duration>? onChanged;
  final bool compact;

  @override
  State<_GlobalDurationField> createState() => _GlobalDurationFieldState();
}

class _GlobalDurationFieldState extends State<_GlobalDurationField> {
  late String _value = widget.duration.inMilliseconds.toString();

  @override
  void didUpdateWidget(covariant _GlobalDurationField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration == widget.duration) return;
    _value = widget.duration.inMilliseconds.toString();
  }

  @override
  Widget build(BuildContext context) {
    final milliseconds = int.tryParse(_value.trim());
    final isValid = milliseconds != null && milliseconds > 0;
    final field = SizedBox(
      width: widget.compact ? 104 : 76,
      child: DesyTextField(
        key: const ValueKey('motion-global-duration'),
        label: 'Global duration in milliseconds',
        value: _value,
        errorText: isValid ? null : 'Enter a duration greater than zero.',
        enabled: widget.onChanged != null,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
        textInputAction: TextInputAction.done,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('ms', style: Theme.of(context).textTheme.labelSmall),
        ),
        onChanged: (value) {
          setState(() => _value = value);
          final next = int.tryParse(value.trim());
          if (next == null || next <= 0) return;
          widget.onChanged?.call(Duration(milliseconds: next));
        },
      ),
    );
    if (widget.compact) return field;
    return _MotionControlGroup(
      label: 'DURATION',
      child: DesyCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          child: field,
        ),
      ),
    );
  }
}

class _PlaybackButtons extends StatelessWidget {
  const _PlaybackButtons({required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      _PlayPauseButton(controller: controller),
      _LoopModeButton(controller: controller),
    ],
  );
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({
    required this.controller,
    this.iconOnly = false,
    this.size = DesyButtonSize.xs,
  });

  final DesyMotionPlaybackController controller;
  final bool iconOnly;
  final DesyButtonSize size;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(controller.isPlaying ? DesyIcons.pause : DesyIcons.play);
    if (iconOnly) {
      return DesyButton.icon(
        key: const ValueKey('motion-play-pause'),
        size: size,
        variant: DesyButtonVariant.primary,
        semanticsLabel: controller.isPlaying ? 'Pause playback' : 'Play',
        onPress: controller.togglePlayback,
        child: icon,
      );
    }
    return DesyButton(
      key: const ValueKey('motion-play-pause'),
      size: size,
      variant: DesyButtonVariant.outline,
      mainAxisSize: MainAxisSize.min,
      prefix: icon,
      onPress: controller.togglePlayback,
      child: Text(controller.isPlaying ? 'Pause' : 'Play'),
    );
  }
}

class _LoopModeButton extends StatelessWidget {
  const _LoopModeButton({
    required this.controller,
    this.size = DesyButtonSize.xs,
  });

  final DesyMotionPlaybackController controller;
  final DesyButtonSize size;

  @override
  Widget build(BuildContext context) => DesyButton(
    key: const ValueKey('motion-loop-mode'),
    size: size,
    variant: DesyButtonVariant.outline,
    mainAxisSize: MainAxisSize.min,
    onPress: controller.cycleLoopMode,
    child: Text(controller.loopMode.label),
  );
}

class _PlayheadLabel extends StatelessWidget {
  const _PlayheadLabel({required this.controller, this.inline = false});

  final DesyMotionPlaybackController controller;
  final bool inline;

  @override
  Widget build(BuildContext context) {
    final elapsed = (controller.duration.inMilliseconds * controller.value)
        .round();
    final value = Text(
      '$elapsed / ${controller.duration.inMilliseconds} ms',
      key: const ValueKey('motion-playhead-label'),
      style: Theme.of(context).textTheme.bodySmall,
    );
    if (inline) return value;
    return Row(
      children: [
        Text('Timeline', style: Theme.of(context).textTheme.labelLarge),
        const Spacer(),
        value,
      ],
    );
  }
}

class _PlaybackThermometer extends StatelessWidget {
  const _PlaybackThermometer({super.key, required this.controller});

  static const _sections = 20;

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final duration = controller.duration.inMilliseconds;
    final current = controller.value;
    final increment = 1 / _sections;

    String timeAt(double value) =>
        '${(duration * value).round()} of $duration milliseconds';

    void seek(double value) {
      controller.scrub(value);
      controller.finishScrub(value);
    }

    return Semantics(
      slider: true,
      label: 'Playback position',
      value: timeAt(current),
      increasedValue: timeAt((current + increment).clamp(0.0, 1.0).toDouble()),
      decreasedValue: timeAt((current - increment).clamp(0.0, 1.0).toDouble()),
      onIncrease: () => seek((current + increment).clamp(0.0, 1.0).toDouble()),
      onDecrease: () => seek((current - increment).clamp(0.0, 1.0).toDouble()),
      child: LayoutBuilder(
        builder: (context, constraints) {
          void scrub(Offset position) {
            if (constraints.maxWidth <= 0) return;
            controller.scrub(
              (position.dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble(),
            );
          }

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: (details) => seek(
              (details.localPosition.dx / constraints.maxWidth)
                  .clamp(0.0, 1.0)
                  .toDouble(),
            ),
            onHorizontalDragUpdate: (details) => scrub(details.localPosition),
            onHorizontalDragEnd: (_) =>
                controller.finishScrub(controller.value),
            onHorizontalDragCancel: () =>
                controller.finishScrub(controller.value),
            child: SizedBox(
              height: 40,
              width: double.infinity,
              child: CustomPaint(
                painter: _PlaybackThermometerPainter(
                  progress: current,
                  baseColor: Colors.transparent,
                  guideColor: colors.border,
                  progressColor: colors.desy.signal,
                  playheadColor: colors.foreground,
                  sections: _sections,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaybackThermometerPainter extends CustomPainter {
  const _PlaybackThermometerPainter({
    required this.progress,
    required this.baseColor,
    required this.guideColor,
    required this.progressColor,
    required this.playheadColor,
    required this.sections,
  });

  final double progress;
  final Color baseColor;
  final Color guideColor;
  final Color progressColor;
  final Color playheadColor;
  final int sections;

  @override
  void paint(Canvas canvas, Size size) {
    const trackTop = 8.0;
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, trackTop, size.width, 8),
      const Radius.circular(99),
    );
    canvas.drawRRect(track, Paint()..color = baseColor);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, trackTop, size.width * progress, 8),
        const Radius.circular(99),
      ),
      Paint()..color = progressColor,
    );
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
    final playheadX = (size.width * progress).clamp(2.0, size.width - 2.0);
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
  bool shouldRepaint(_PlaybackThermometerPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      baseColor != oldDelegate.baseColor ||
      guideColor != oldDelegate.guideColor ||
      progressColor != oldDelegate.progressColor ||
      playheadColor != oldDelegate.playheadColor ||
      sections != oldDelegate.sections;
}

class _PlaybackSlider extends StatelessWidget {
  const _PlaybackSlider({required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) => DesySlider(
    key: const ValueKey('motion-playhead'),
    control: DesySliderControl.liftedContinuous(
      value: DesySliderValue(max: controller.value),
      onChange: (value) => controller.scrub(value.max),
    ),
    semanticValueFormatterCallback: (value) =>
        '${(controller.duration.inMilliseconds * value).round()} milliseconds',
    tooltipBuilder: (tooltip, value) =>
        Text('${(controller.duration.inMilliseconds * value).round()} ms'),
    onEnd: (value) => controller.finishScrub(value.max),
  );
}

class _SpeedButtons extends StatelessWidget {
  const _SpeedButtons({
    required this.controller,
    this.size = DesyButtonSize.xs,
    this.dockHeight,
  });

  final DesyMotionPlaybackController controller;
  final DesyButtonSize size;
  final double? dockHeight;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final option in DesyMotionPlaybackControls._speeds)
        SizedBox(
          height: dockHeight,
          child: DesyButton(
            key: ValueKey('motion-speed-$option'),
            size: size,
            mainAxisSize: MainAxisSize.min,
            variant: controller.speed == option
                ? DesyButtonVariant.primary
                : DesyButtonVariant.outline,
            onPress: () => controller.setSpeed(option),
            child: Text('$option×'),
          ),
        ),
    ],
  );
}

extension on DesyMotionLoopMode {
  String get label => switch (this) {
    DesyMotionLoopMode.loop => 'Loop',
    DesyMotionLoopMode.pingPong => 'Ping-pong',
    DesyMotionLoopMode.once => 'Once',
  };
}
