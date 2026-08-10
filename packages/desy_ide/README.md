# Desy IDE live-widget prototypes

This package keeps two deliberately different rendering experiments side by
side so their behavior can be compared.

## Same-process hot reload with Codex

Run the newer experiment from the repository root:

```sh
task ide:hot_reload
```

This entrypoint renders `lib/hot_reload_widget.dart` directly inside the macOS
app. Its Codex console runs a constrained, non-interactive `codex exec` session
that may edit only that file. After a successful run, the app sends `SIGUSR1`
to the owning `flutter run` process via its PID file. Flutter performs a normal
hot reload, so the new widget appears while compatible host and preview state
remain alive.

The workshop input sits on the left. The right side displays every
`HotReloadCandidate` as a horizontally scrollable card with a stable ID, short
description, selection checkbox, and its real `WidgetBuilder`. Candidate
widgets retain the same `DesyWidgetPreview` theme boundary as the Atlas. This
experimental inspector intentionally omits `DesyFittedPreview`: it draws each
widget at a raw 1:1 logical-pixel scale and scrolls any overflow so render-object
geometry corresponds directly to what is on screen. Selected candidate IDs,
titles, and descriptions are included in the next Codex prompt as explicit
iteration context.

Press **Inspect widgets** to turn each candidate preview into a scoped widget
picker. A click walks the preview's render-object tree, maps the hit back to the
nearest widget created by the candidate source, and draws its bounds inside the
raw Desy preview. The selected widget and render-object types are shown in
the panel header. Inspection is debug-only by design and does not yet persist
annotations or add the selected widget to the Codex prompt.

This is intentionally a console rather than a full terminal emulator: it
captures a single Codex run's output and provides a stop action. The app must be
started through `task ide:hot_reload`; a packaged release has no parent Flutter
tool to reload it. Because preview and host share one process, invalid widget
code can also prevent the entire app from reloading or crash it.

The macOS runner explicitly disables Flutter's experimental merged platform/UI
thread with `FLTEnableMergedPlatformUIThread=false`. With Flutter 3.44.6, the
merged default retained checkbox state but sometimes did not paint it until a
window resize or reload. The separate threads repaint workshop interaction
state immediately.

The end-to-end spike was verified with the installed Codex CLI and Flutter
3.44.6. Codex replaced a three-button selector with responsive prototype cards,
exited successfully, and the app signalled its owning Flutter tool. The preview
updated in place while its selected `Playful` state and the host console state
survived. A second one-line Codex edit proved the filtered JSON event console
and automatic reload path again.

## Isolated flutter_tester renderer

This is a deliberately isolated prototype answering one question:

> Can a normal Flutter desktop app launch a second headless Flutter runtime and
> display that runtime's real, continuously changing widget?

Run it from the repository root:

```sh
task ide:run
```

The macOS host automatically launches `lib/preview_runtime_main.dart` on
Flutter's hidden `flutter-tester` device. The runtime captures completed PNG
frames and announces their paths over stdout; the host reads and displays the
new bytes as a gapless live preview.

The host exposes runtime status, a small log, hot reload, and restart controls.
Edit `_runtimeMarker` in `preview_runtime_main.dart`, save it, and press **Hot
reload** to see the new widget code appear in the running preview.

## Prototype boundaries

- The preview is the real widget under the real Desy theme.
- The host and widget runtime are separate processes.
- Frames are PNG files at approximately 5 FPS. This is intentionally simple,
  not the eventual high-performance transport.
- Pointer, keyboard, text input, semantics, and element selection are not yet
  forwarded to the runtime.
- The macOS app sandbox is disabled for this prototype because it launches the
  developer's local Flutter toolchain.
- `--show-test-device` is an internal Flutter development surface and must stay
  behind a replaceable renderer boundary.

The next decisive seam is input forwarding: translate a host pointer position
through the preview's fit transform, then dispatch it inside the child runtime.

## Verified result

Using Flutter 3.44.6 on macOS, the host displayed continuously changing frames
from the child runtime. During the spike, the visible sequence advanced from
255 to 347 while being inspected. Changing `_runtimeMarker` and pressing **Hot
reload** updated the rendered widget in 380 ms while preserving its runtime tick
at 223. Restarting the runtime reset that state and began a fresh frame stream.
