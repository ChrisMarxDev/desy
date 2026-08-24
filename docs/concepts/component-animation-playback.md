# Component animation playback

Animated demonstrations are ordinary `DesyRegistryComponent` declarations.
They live in the same component tree and may sit beside any other component;
there is no Motion atom lane or separate animation inventory.

A `DesyAnimationComponent` carries its duration, curve, and a dedicated
builder that receives the current `Animation<double>` playhead. Desy creates
the controller and also exposes that progress through `DesyMotionPlaybackScope`
for nested widgets, with play and scrub controls in that component's Details
inspector. Playback starts in one-shot mode; the inspector can switch the
ephemeral controller between Once and Loop without changing registry data.

The component's own normal builder supplies the entire specimen tree. Desy
does not model a second collection of animation children. When a demonstration
needs a swappable child, it uses the existing widget-instance knob on that
component just like any other consumer widget.

The component atlas stays browse-first and does not synchronize animation
playback. Component scenarios remain appropriate for discrete real states;
animation playback is only for a component that explicitly opts in.
