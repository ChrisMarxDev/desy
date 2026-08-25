// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../motion_playback.dart';

class DesyMotionPlaybackControls extends StatelessWidget {
  const DesyMotionPlaybackControls({
    super.key,
    required this.controller,
    this.compact = false,
    this.stacked = false,
    this.globalDuration,
    this.onGlobalDurationChanged,
  });

  final DesyMotionPlaybackController controller;
  final bool compact;

  /// Arranges the compact toolbar as a small vertical panel.
  ///
  /// This lets the detail inspector retain the Atlas control language while
  /// giving its timeline the full panel width.
  final bool stacked;
  final Duration? globalDuration;
  final ValueChanged<Duration>? onGlobalDurationChanged;

  /// The fixed visual height shared by every compact playback control.
  ///
  /// Keep this in sync with the workbench's compact form controls. The button
  /// size matters here: a surrounding [SizedBox] cannot make a larger button
  /// render at this height.
  static const _compactControlHeight = 36.0;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) => compact
        ? _CompactMotionPlaybackControls(
            controller: controller,
            stacked: stacked,
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
    ],
  );
}

class _CompactMotionPlaybackControls extends StatelessWidget {
  const _CompactMotionPlaybackControls({
    required this.controller,
    required this.stacked,
    required this.globalDuration,
    required this.onGlobalDurationChanged,
  });

  final DesyMotionPlaybackController controller;
  final bool stacked;
  final Duration? globalDuration;
  final ValueChanged<Duration>? onGlobalDurationChanged;

  @override
  Widget build(BuildContext context) => DesyCard(
    key: ValueKey(
      stacked ? 'motion-playback-controls' : 'motion-global-playback-controls',
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: stacked ? _buildStacked() : _buildToolbar(),
    ),
  );

  Widget _buildToolbar() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: DesyMotionPlaybackControls._compactControlHeight,
          child: _PlayPauseButton(
            controller: controller,
            iconOnly: true,
            size: DesyButtonSize.md,
          ),
        ),
        if (globalDuration case final duration?) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: _GlobalDurationField(
              duration: duration,
              onChanged: onGlobalDurationChanged,
              compact: true,
              width: 80,
            ),
          ),
        ],
        const SizedBox(width: 10),
        SizedBox(
          height: DesyMotionPlaybackControls._compactControlHeight,
          child: _LoopModeButton(
            controller: controller,
            size: DesyButtonSize.md,
            iconOnly: true,
          ),
        ),
        const SizedBox(width: 18),
        SizedBox(
          width: 250,
          child: _PlaybackSlider(
            key: const ValueKey('motion-playhead-thermometer'),
            controller: controller,
          ),
        ),
      ],
    ),
  );

  Widget _buildStacked() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        key: const ValueKey('motion-playback-toolbar'),
        height: DesyMotionPlaybackControls._compactControlHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _PlayPauseButton(
                controller: controller,
                iconOnly: true,
                size: DesyButtonSize.md,
              ),
            ),
            if (globalDuration case final duration?) ...[
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _GlobalDurationField(
                  duration: duration,
                  onChanged: onGlobalDurationChanged,
                  compact: true,
                ),
              ),
            ],
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _LoopModeButton(
                controller: controller,
                size: DesyButtonSize.md,
                iconOnly: true,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      _PlaybackSlider(
        key: const ValueKey('motion-playhead-thermometer'),
        controller: controller,
      ),
    ],
  );
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
    this.width,
  });

  final Duration duration;
  final ValueChanged<Duration>? onChanged;
  final bool compact;
  final double? width;

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
      width: widget.width ?? (widget.compact ? null : 76),
      child: DesyTextField(
        key: const ValueKey('motion-global-duration'),
        label: 'Global duration in milliseconds',
        suffix: Text('ms', style: Theme.of(context).textTheme.bodySmall),
        value: _value,
        errorText: widget.compact || isValid
            ? null
            : 'Enter a duration greater than zero.',
        enabled: widget.onChanged != null,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: false,
          signed: false,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textInputAction: TextInputAction.done,
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
    this.iconOnly = false,
  });

  final DesyMotionPlaybackController controller;
  final DesyButtonSize size;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final current = controller.loopMode;
    final next = DesyMotionLoopMode
        .values[(current.index + 1) % DesyMotionLoopMode.values.length];
    final semanticsLabel =
        '${current.label} playback; activate to use ${next.label.toLowerCase()} playback';
    if (iconOnly) {
      return DesyButton.icon(
        key: const ValueKey('motion-loop-mode'),
        size: size,
        variant: DesyButtonVariant.outline,
        semanticsLabel: semanticsLabel,
        onPress: () => controller.setLoopMode(next),
        child: Icon(current.icon),
      );
    }
    return DesyButton(
      key: const ValueKey('motion-loop-mode'),
      size: size,
      variant: DesyButtonVariant.outline,
      mainAxisSize: MainAxisSize.min,
      prefixIcon: Icon(current.icon),
      semanticsLabel: semanticsLabel,
      onPress: () => controller.setLoopMode(next),
      child: Text(current.label),
    );
  }
}

class _PlayheadLabel extends StatelessWidget {
  const _PlayheadLabel({required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) {
    final elapsed = (controller.duration.inMilliseconds * controller.value)
        .round();
    final value = Text(
      '$elapsed / ${controller.duration.inMilliseconds} ms',
      key: const ValueKey('motion-playhead-label'),
      style: Theme.of(context).textTheme.bodySmall,
    );
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
  const _PlaybackSlider({super.key, required this.controller});

  final DesyMotionPlaybackController controller;

  @override
  Widget build(BuildContext context) => DesyAnimationScrubber(
    key: const ValueKey('motion-playhead'),
    progress: controller.value,
    duration: controller.duration,
    onChanged: controller.scrub,
    onChangeEnd: controller.finishScrub,
  );
}

extension on DesyMotionLoopMode {
  String get label => switch (this) {
    DesyMotionLoopMode.once => 'Once',
    DesyMotionLoopMode.loop => 'Loop',
    DesyMotionLoopMode.pingPong => 'Ping-pong',
  };

  IconData get icon => switch (this) {
    DesyMotionLoopMode.once => DesyIcons.repeatOnce,
    DesyMotionLoopMode.loop => DesyIcons.repeat,
    DesyMotionLoopMode.pingPong => DesyIcons.arrowLeftRight,
  };
}
