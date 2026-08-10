# desy_overlay

`desy_overlay` adds a small widget-review loop to an ordinary Flutter app:

1. Press the crosshair.
2. Select a rendered component.
3. Type feedback in the draggable annotation card.
4. Send the typed annotation through a consumer-owned callback.

Selection stays active after choosing a component and after sending feedback,
so another click immediately targets something else. Close the annotation card
with its × action or press the crosshair again to leave selection mode. Desy
does not execute an agent, write repository files, or choose a transport.

## Add it to an app

```dart
MaterialApp(
  builder: DesyOverlay.builder(
    onAnnotationSubmitted: (annotation) async {
      await myAgentBridge.send(annotation);
    },
  ),
  home: const HomeScreen(),
);
```

The callback receives widget and State types, ancestry, RenderObject geometry,
layout constraints, bounded diagnostics, keys, semantics, visible content, the
user's comment, and—when Flutter provides it—the Dart creation location.

## Release builds

The safe default is `DesyOverlayMode.debugOnly`, which returns the consumer app
unchanged in profile and release builds. A consumer can deliberately enable the
review surface in every build mode:

```dart
builder: DesyOverlay.builder(
  mode: DesyOverlayMode.always,
  onAnnotationSubmitted: forwardAnnotation,
),
```

Flutter removes `RenderObject.debugCreator` and Dart creation locations from
release builds. Runtime type strings may also be minified or otherwise unstable.
Release annotations therefore prioritize values that survive compilation:

- `ValueKey` and `ObjectKey` values;
- `Semantics.identifier`, label, value, and hint;
- visible text and tooltips;
- widget ancestry and RenderObject geometry as supporting context.

For an important component, a stable semantic identifier is the strongest
release-mode agent signal and also improves accessibility automation:

```dart
Semantics(
  identifier: 'checkout.primaryAction',
  child: CheckoutButton(onPressed: submitOrder),
)
```

The overlay UI contains no platform-specific code and can run on Flutter web,
mobile, and desktop. The consumer remains responsible for authenticating and
securing any forwarding integration exposed to users.

See [`example`](example/) for a complete app.
