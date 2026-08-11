# desy_overlay

`desy_overlay` adds a small widget-review loop to an ordinary Flutter app:

1. Press the crosshair.
2. Select a rendered component.
3. Type feedback in the draggable annotation card.
4. Send the typed annotation through a consumer-owned callback.

Selection stays active while the annotation card is open, so another click can
retarget the feedback. Sending feedback exits selection mode and removes the
prompt, highlight, and card. Close the card with its × action or press the
crosshair again to leave without sending. Desy does not execute an agent, write
repository files, or choose a transport.

## Add it to an app

Use the `builder` exposed by the consumer's application shell. This works with
`WidgetsApp`, `MaterialApp`, `CupertinoApp`, and design-system-specific shells:

```dart
CupertinoApp(
  builder: DesyOverlay.builder(
    onAnnotationSubmitted: (annotation) async {
      await myAgentBridge.send(annotation);
    },
  ),
  home: const HomeScreen(),
);
```

The overlay library inspects framework-level widgets, keys, semantics, and
render objects. It does not require a Material application or branch on
Material component types.

The callback receives widget and State types, ancestry, RenderObject geometry,
layout constraints, bounded diagnostics, keys, semantics, visible content, the
user's comment, and—when Flutter provides it—the Dart creation location.

## Mobile behavior

On Android and iOS, the overlay uses larger touch controls and keeps its
launcher, prompt, and draggable annotation card inside system safe areas. When
the software keyboard opens, the floating chrome moves above `viewInsets`
without inserting `SafeArea` into or resizing the consumer application.

The feedback editor uses fewer initial lines on touch platforms so the card
remains usable on phone viewports. Selection and whole-card dragging use the
same pointer and gesture path on touch, mouse, and trackpad devices.

## Source structure

- `desy_overlay.dart` owns the public integration and ephemeral workflow state.
- `overlay/widget_target_inspector.dart` owns element traversal and metadata.
- `overlay/overlay_layout.dart` owns safe-area, keyboard, and drag geometry.
- `overlay/overlay_widgets.dart` owns the self-contained Desy chrome.

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
- visible text;
- widget ancestry and RenderObject geometry as supporting context.

For an important component, a stable semantic identifier is the strongest
release-mode agent signal and also improves accessibility automation:

```dart
Semantics(
  identifier: 'checkout.primaryAction',
  child: CheckoutButton(onPressed: submitOrder),
)
```

The overlay UI runs on Flutter web, mobile, and desktop. The consumer remains
responsible for authenticating and securing any forwarding integration exposed
to users.

See [`example`](example/) for a complete app.
