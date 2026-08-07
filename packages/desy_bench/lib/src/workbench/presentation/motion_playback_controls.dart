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
  Widget build(BuildContext context) => Wrap(
    key: const ValueKey('motion-global-playback-controls'),
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      _PlaybackButtons(controller: controller),
      if (globalDuration case final duration?)
        _GlobalDurationField(
          duration: duration,
          onChanged: onGlobalDurationChanged,
        ),
      SizedBox(width: 190, child: _PlaybackSlider(controller: controller)),
      _PlayheadLabel(controller: controller, inline: true),
      _SpeedButtons(controller: controller),
    ],
  );
}

class _GlobalDurationField extends StatefulWidget {
  const _GlobalDurationField({required this.duration, this.onChanged});

  final Duration duration;
  final ValueChanged<Duration>? onChanged;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Duration', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(width: 6),
        DesyCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            child: SizedBox(
              width: 76,
              child: DesyTextField(
                key: const ValueKey('motion-global-duration'),
                label: 'Global duration in milliseconds',
                value: _value,
                errorText: isValid
                    ? null
                    : 'Enter a duration greater than zero.',
                enabled: widget.onChanged != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                  signed: false,
                ),
                textInputAction: TextInputAction.done,
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'ms',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                onChanged: (value) {
                  setState(() => _value = value);
                  final next = int.tryParse(value.trim());
                  if (next == null || next <= 0) return;
                  widget.onChanged?.call(Duration(milliseconds: next));
                },
              ),
            ),
          ),
        ),
      ],
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
      DesyButton(
        key: const ValueKey('motion-play-pause'),
        size: DesyButtonSize.xs,
        variant: DesyButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        prefix: Icon(controller.isPlaying ? DesyIcons.pause : DesyIcons.play),
        onPress: controller.togglePlayback,
        child: Text(controller.isPlaying ? 'Pause' : 'Play'),
      ),
      DesyButton(
        key: const ValueKey('motion-loop-mode'),
        size: DesyButtonSize.xs,
        variant: DesyButtonVariant.outline,
        mainAxisSize: MainAxisSize.min,
        onPress: controller.cycleLoopMode,
        child: Text(controller.loopMode.label),
      ),
    ],
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
  const _SpeedButtons({required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final option in DesyMotionPlaybackControls._speeds)
        DesyButton(
          key: ValueKey('motion-speed-$option'),
          size: DesyButtonSize.xs,
          mainAxisSize: MainAxisSize.min,
          variant: controller.speed == option
              ? DesyButtonVariant.primary
              : DesyButtonVariant.outline,
          onPress: () => controller.setSpeed(option),
          child: Text('$option×'),
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
