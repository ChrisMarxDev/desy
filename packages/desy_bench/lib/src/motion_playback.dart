import 'package:flutter/material.dart';

/// Ephemeral playback state shared by Desy motion preview surfaces.
///
/// The controller owns only the normalized preview timeline. Registered motion
/// entries remain immutable and consumer-owned.
class DesyMotionPlaybackController extends ChangeNotifier {
  /// Default duration used when no motion-specific or global value is present.
  static const defaultDuration = Duration(milliseconds: 300);

  /// Creates a preview timeline and immediately plays it forward once.
  DesyMotionPlaybackController({
    required TickerProvider vsync,
    required Duration duration,
    Curve curve = Curves.linear,
  }) : assert(duration > Duration.zero),
       _duration = duration,
       _timeline = AnimationController(vsync: vsync, duration: duration) {
    _progress = CurvedAnimation(parent: _timeline, curve: curve);
    _timeline
      ..addListener(notifyListeners)
      ..addStatusListener(_handleStatus);
    _timeline.forward();
  }

  /// The uncurved zero-to-one clock used by synchronized galleries.
  Animation<double> get timeline => _timeline;

  /// The curved zero-to-one progress used by a single motion detail.
  Animation<double> get progress => _progress;

  /// The declared duration of one forward pass at 1× speed.
  Duration get duration => _duration;

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
    if (_isPlaying && status == AnimationStatus.completed) {
      _isPlaying = false;
      notifyListeners();
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
    if (resume) _timeline.stop();
    _timeline.duration = _effectiveDuration;
    if (!resume) return;
    _resume();
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
    if (_timeline.isCompleted) {
      _timeline.forward(from: 0);
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

/// A scrub-friendly fade and slide reveal for one real widget.
///
/// Consumers can supply an explicit [progress] or rely on the nearest
/// [DesyMotionPlaybackScope]. The widget stays semantically inert until it is
/// mostly visible, which makes it suitable for sidebars and transient panels.
class DesyMotionReveal extends StatelessWidget {
  /// Creates a one-widget reveal.
  const DesyMotionReveal({
    required this.child,
    this.progress,
    this.beginOffset = const Offset(0, 16),
    this.beginScale = 1,
    super.key,
  });

  /// Widget shown at the end of the timeline.
  final Widget child;

  /// Optional zero-to-one timeline. Defaults to the nearest motion scope.
  final Animation<double>? progress;

  /// Pixel offset applied while the widget is hidden.
  final Offset beginOffset;

  /// Scale applied while the widget is hidden.
  final double beginScale;

  @override
  Widget build(BuildContext context) {
    final animation =
        progress ??
        DesyMotionPlaybackScope.maybeOf(context) ??
        kAlwaysCompleteAnimation;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final value = animation.value.clamp(0.0, 1.0).toDouble();
        return ExcludeSemantics(
          excluding: value < .5,
          child: IgnorePointer(
            ignoring: value < .5,
            child: Opacity(
              opacity: value,
              child: Transform.translate(
                offset: beginOffset * (1 - value),
                child: Transform.scale(
                  scale: beginScale + ((1 - beginScale) * value),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reveals or hides a persistent workbench region with fade and travel.
///
/// Unlike [DesyMotionReveal], this owns its short transition and is intended
/// for a region whose visibility is controlled by local UI state.
class DesyMotionVisibilityTransition extends StatelessWidget {
  /// Creates a visibility transition.
  const DesyMotionVisibilityTransition({
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.beginOffset = const Offset(-12, 0),
    super.key,
  });

  /// Whether the region is visible.
  final bool visible;

  /// Region that remains mounted while it transitions.
  final Widget child;

  /// Duration of the visibility transition.
  final Duration duration;

  /// Easing used by the visibility transition.
  final Curve curve;

  /// Pixel offset applied while hidden.
  final Offset beginOffset;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return TweenAnimationBuilder<double>(
      duration: reduceMotion ? Duration.zero : duration,
      curve: curve,
      tween: Tween(end: visible ? 1 : 0),
      child: child,
      builder: (context, value, child) => ExcludeSemantics(
        excluding: value < .5,
        child: IgnorePointer(
          ignoring: value < .5,
          child: Opacity(
            opacity: value,
            child: Transform.translate(
              offset: beginOffset * (1 - value),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animates the incoming content for a keyed workbench screen change.
///
/// Give each destination a stable [transitionKey]. The next screen fades and
/// arrives from [incomingOffset] without retaining the outgoing route subtree.
/// This keeps Flutter router-owned global keys unique during navigation.
class DesyMotionScreenTransition extends StatefulWidget {
  /// Creates a transition between keyed screen children.
  const DesyMotionScreenTransition({
    required this.transitionKey,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
    this.curve = Curves.easeOutCubic,
    this.incomingOffset = const Offset(.025, 0),
    super.key,
  });

  /// Stable identity of the currently visible destination.
  final Key transitionKey;

  /// Current destination content.
  final Widget child;

  /// Duration of each screen replacement.
  final Duration duration;

  /// Easing used for screen replacement.
  final Curve curve;

  /// Fractional offset from which incoming content enters.
  final Offset incomingOffset;

  @override
  State<DesyMotionScreenTransition> createState() =>
      _DesyMotionScreenTransitionState();
}

class _DesyMotionScreenTransitionState extends State<DesyMotionScreenTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant DesyMotionScreenTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.transitionKey == widget.transitionKey) return;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return AnimatedBuilder(
      animation: _controller,
      child: KeyedSubtree(key: widget.transitionKey, child: widget.child),
      builder: (context, child) {
        final value = reduceMotion ? 1.0 : _controller.value;
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: widget.incomingOffset * (1 - value),
            child: child,
          ),
        );
      },
    );
  }
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
    this.axis = Axis.horizontal,
    super.key,
  });

  /// Widget displayed at the start of the timeline.
  final Widget first;

  /// Widget displayed at the end of the timeline.
  final Widget second;

  /// Optional zero-to-one timeline. Defaults to the nearest motion scope.
  final Animation<double>? progress;

  /// Offset applied to each widget at its hidden endpoint.
  final double distance;

  /// Axis along which the widgets exchange places.
  final Axis axis;

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
                    offset: _offset(-distance * value),
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
                    offset: _offset(distance * (1 - value)),
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

  Offset _offset(double value) =>
      axis == Axis.horizontal ? Offset(value, 0) : Offset(0, value);
}
