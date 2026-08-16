import 'package:flutter/material.dart';

/// How a Desy motion timeline behaves when it reaches an endpoint.
enum DesyMotionLoopMode {
  /// Restart from the beginning after reaching the end.
  loop,

  /// Alternate between forward and reverse playback.
  pingPong,

  /// Stop after one forward pass.
  once,
}

/// Ephemeral playback state shared by Desy motion preview surfaces.
///
/// The controller owns only the normalized preview timeline. Registered motion
/// entries remain immutable and consumer-owned.
class DesyMotionPlaybackController extends ChangeNotifier {
  /// Default duration used when no motion-specific or global value is present.
  static const defaultDuration = Duration(milliseconds: 300);

  /// Creates a preview timeline, optionally beginning in a paused state.
  DesyMotionPlaybackController({
    required TickerProvider vsync,
    required Duration duration,
    Curve curve = Curves.linear,
    this.loopMode = DesyMotionLoopMode.pingPong,
    this.autoplay = true,
  }) : assert(duration > Duration.zero),
       _duration = duration,
       _timeline = AnimationController(vsync: vsync, duration: duration) {
    _progress = CurvedAnimation(parent: _timeline, curve: curve);
    _timeline
      ..addListener(notifyListeners)
      ..addStatusListener(_handleStatus);
    if (autoplay) {
      _timeline.forward();
    } else {
      _isPlaying = false;
    }
  }

  /// The uncurved zero-to-one clock used by synchronized galleries.
  Animation<double> get timeline => _timeline;

  /// The curved zero-to-one progress used by a single motion detail.
  Animation<double> get progress => _progress;

  /// The declared duration of one forward pass at 1× speed.
  Duration get duration => _duration;

  /// The current repeat behavior.
  DesyMotionLoopMode loopMode;

  /// Whether the preview begins playing immediately.
  final bool autoplay;

  /// Whether the timeline is currently advancing.
  bool get isPlaying => _isPlaying;

  /// The current playback rate.
  double get speed => _speed;

  /// Current uncurved normalized playhead position.
  double get value => _timeline.value;

  final AnimationController _timeline;
  Duration _duration;
  late final CurvedAnimation _progress;
  var _isPlaying = true;
  var _speed = 1.0;
  var _isScrubbing = false;
  var _resumeAfterScrub = false;

  void _handleStatus(AnimationStatus status) {
    if (!_isPlaying) return;
    switch ((status, loopMode)) {
      case (AnimationStatus.completed, DesyMotionLoopMode.loop):
        _timeline.forward(from: 0);
      case (AnimationStatus.completed, DesyMotionLoopMode.pingPong):
        _timeline.reverse();
      case (AnimationStatus.dismissed, DesyMotionLoopMode.pingPong):
        _timeline.forward();
      case (AnimationStatus.completed, DesyMotionLoopMode.once):
        _isPlaying = false;
        notifyListeners();
      default:
        break;
    }
  }

  /// Starts or pauses playback without changing the current playhead.
  void togglePlayback() {
    _isPlaying = !_isPlaying;
    notifyListeners();
    if (_isPlaying) {
      _resume();
    } else {
      _timeline.stop();
    }
  }

  /// Cycles through ping-pong, once, and loop playback.
  void cycleLoopMode() {
    loopMode = switch (loopMode) {
      DesyMotionLoopMode.loop => DesyMotionLoopMode.pingPong,
      DesyMotionLoopMode.pingPong => DesyMotionLoopMode.once,
      DesyMotionLoopMode.once => DesyMotionLoopMode.loop,
    };
    notifyListeners();
    if (_isPlaying) {
      _timeline.stop();
      _resume();
    }
  }

  /// Changes the playback rate while preserving normalized progress.
  void setSpeed(double speed) {
    if (speed <= 0) {
      throw ArgumentError.value(speed, 'speed', 'Must be greater than zero.');
    }
    if (_speed == speed) return;
    _speed = speed;
    _updateEffectiveDuration();
    notifyListeners();
  }

  /// Changes the duration while preserving normalized progress and speed.
  void setDuration(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Must be greater than zero.',
      );
    }
    if (_duration == duration) return;
    _duration = duration;
    _updateEffectiveDuration();
    notifyListeners();
  }

  Duration get _effectiveDuration {
    final microseconds = (_duration.inMicroseconds / _speed).round();
    return Duration(microseconds: microseconds < 1 ? 1 : microseconds);
  }

  void _updateEffectiveDuration() {
    final resume = _isPlaying && !_isScrubbing;
    final wasReversing = _timeline.status == AnimationStatus.reverse;
    if (resume) _timeline.stop();
    _timeline.duration = _effectiveDuration;
    if (!resume) return;
    if (wasReversing && loopMode == DesyMotionLoopMode.pingPong) {
      _timeline.reverse();
    } else {
      _resume();
    }
  }

  /// Pauses playback on the first seek update and moves the playhead.
  void scrub(double value) {
    if (!_isScrubbing) {
      _isScrubbing = true;
      _resumeAfterScrub = _isPlaying;
      _timeline.stop();
    }
    _timeline.value = value;
  }

  /// Completes a seek gesture and resumes when it began during playback.
  void finishScrub(double value) {
    _timeline.value = value;
    _isScrubbing = false;
    if (_resumeAfterScrub) _resume();
  }

  void _resume() {
    if (loopMode == DesyMotionLoopMode.once && _timeline.isCompleted) {
      _timeline.forward(from: 0);
    } else if (loopMode == DesyMotionLoopMode.pingPong &&
        _timeline.status == AnimationStatus.reverse) {
      _timeline.reverse();
    } else {
      _timeline.forward();
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _timeline
      ..removeListener(notifyListeners)
      ..removeStatusListener(_handleStatus)
      ..dispose();
    super.dispose();
  }
}

/// Makes the workbench-owned motion timeline available to a registered
/// consumer specimen.
///
/// Motion entries remain normal consumer widget builders. A specimen can opt
/// into Desy's shared timeline with [maybeOf], then render its real animation
/// from the supplied zero-to-one progress value. Desy owns playback state;
/// the consumer continues to own the visual result.
class DesyMotionPlaybackScope extends InheritedNotifier<Animation<double>> {
  /// Creates a playback scope for one motion preview.
  const DesyMotionPlaybackScope({
    required this.progress,
    required super.child,
    super.key,
  }) : super(notifier: progress);

  /// The consumer motion's curved progress from zero to one.
  final Animation<double> progress;

  /// Returns the nearest workbench timeline, or `null` outside a motion
  /// preview.
  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<DesyMotionPlaybackScope>()
      ?.progress;
}

/// A scrub-friendly transition between two real widgets.
///
/// The outgoing widget leaves slightly toward the leading edge while the
/// incoming widget enters from the trailing edge. Consumers can supply an
/// explicit [progress] or rely on the nearest [DesyMotionPlaybackScope].
class DesyMotionWidgetTransition extends StatelessWidget {
  /// Creates a two-widget motion transition.
  const DesyMotionWidgetTransition({
    required this.first,
    required this.second,
    this.progress,
    this.distance = 24,
    super.key,
  });

  /// Widget displayed at the start of the timeline.
  final Widget first;

  /// Widget displayed at the end of the timeline.
  final Widget second;

  /// Optional zero-to-one timeline. Defaults to the nearest motion scope.
  final Animation<double>? progress;

  /// Horizontal offset applied to each widget at its hidden endpoint.
  final double distance;

  @override
  Widget build(BuildContext context) {
    final animation =
        progress ??
        DesyMotionPlaybackScope.maybeOf(context) ??
        kAlwaysCompleteAnimation;
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value.clamp(0.0, 1.0).toDouble();
        return Stack(
          alignment: Alignment.center,
          children: [
            ExcludeSemantics(
              excluding: value >= .5,
              child: IgnorePointer(
                ignoring: value >= .5,
                child: Opacity(
                  opacity: 1 - value,
                  child: Transform.translate(
                    offset: Offset(-distance * value, 0),
                    child: first,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              excluding: value < .5,
              child: IgnorePointer(
                ignoring: value < .5,
                child: Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(distance * (1 - value), 0),
                    child: second,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
