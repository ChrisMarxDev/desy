# Claude Code → Flutter widget preview: what Wings appears to do

Date: 2026-08-10

## Executive conclusion

The demo is by **Tom Gilder** and is now presented as **Wings for Flutter**. The two public demos are [“Gave Claude the ability to preview my Flutter widgets”](https://x.com/tomgilder/status/2027489639934624190) and [“More fun with Claude + Flutter widget preview”](https://x.com/tomgilder/status/2029889685632245882). In a reply, Gilder described it as a “Flutter macOS app rendering Claude Code + MCP + headless Flutter engine”; the current Wings site confirms a macOS Flutter app, Claude and Codex support, interactive in-chat widget previews, and hot reload. ([author reply](https://x.com/tomgilder/status/2027736619378262211), [Wings](https://flutterwings.dev/))

The current app is private beta and its source is not public. Its exact 2026 internals therefore cannot be confirmed. However, an older public Wings VS Code extension and its published `flutter_wings` package reveal a highly plausible predecessor architecture:

1. Run the consumer widget in a separate **headless `flutter_test` / `flutter_tester` process**.
2. Replace the normal test binding with a custom binding that keeps the widget tree live.
3. Capture the Flutter layer as pixels and stream frames over a local WebSocket.
4. Draw those frames in the host UI and forward mouse, scroll, keyboard, and text-input events back to the test process.
5. Attach to the Dart VM service / Flutter debug session for reload, errors, and tooling.
6. Give Claude Code an MCP tool that asks this preview controller to render a widget.

That is feasible for Desy. It is materially smaller than writing a compiler or embedding arbitrary Dart in the Desy isolate. It is also more experimental than simply running a second ordinary Flutter preview app because it relies on `flutter_test` and some debug-only rendering APIs.

## Evidence: identity and current product

The original video shows Claude Code 2.1.62 working in a project worktree. Claude reads and edits ordinary Dart files, calls a widget-preview tool, and an interactive Flutter surface appears inline. The follow-up video shows selection/annotation callouts anchored to widgets, two targeted instructions, source edits, and the live preview updating. These observations come directly from the two author-posted videos linked above.

The current Wings product page makes the product identity clear:

- “An agent builds a widget and Wings renders the real one right there in the chat.”
- The preview supports tapping and scrolling, and subsequent edits hot-reload into the same surface.
- Wings supports Claude and Codex in the same workspace.
- Wings itself is a macOS Flutter application.
- The product is still a private beta. ([Wings](https://flutterwings.dev/))

There is no public repository for the current app. The implementation details below are consequently divided into **confirmed historical implementation** and **inference about the current app**.

## Confirmed historical implementation

### Public artifacts inspected

- VS Marketplace extension `cheeky-pixel.flutter-wings`, version 0.1.46. The extension describes itself as previewing Flutter widgets and tests in VS Code with hot reload. ([Marketplace listing](https://marketplace.visualstudio.com/items?itemName=cheeky-pixel.flutter-wings), [published VSIX](https://marketplace.visualstudio.com/_apis/public/gallery/publishers/cheeky-pixel/vsextensions/flutter-wings/latest/vspackage))
- Unlisted `flutter_wings` package, version 0.1.19. It depends directly on Flutter and `flutter_test`; its API exposes `WingsTestBinding`, `WingsMode`, and `testWidgetsShim`. ([package](https://pub.dev/packages/flutter_wings/versions), [API](https://pub.dev/documentation/flutter_wings/latest/flutter_wings/), [archive](https://pub.dev/api/archives/flutter_wings-0.1.19.tar.gz))

The former GitHub URL in the package metadata is no longer public, but the shipped VSIX contains the relevant Dart package source.

### 1. The “headless engine” is a customized Flutter widget-test runtime

In the shipped source, `WingsTestBinding` extends `TestWidgetsFlutterBinding` and implements `LiveTestWidgetsFlutterBinding`. The newer VSIX copy explicitly overrides `sendFramesToEngine` to `false`, keeps the preview in `fullyLive` frame policy, and captures frames itself.

That matches Flutter's own description of `flutter test`: it runs a headless Flutter implementation named `flutter_tester`, with a software renderer and fake/stubbed platform services. Flutter documents `TestWidgetsFlutterBinding` as the base binding for widget tests and `LiveTestWidgetsFlutterBinding` as the interactive-device variant. ([Flutter team background on `flutter_tester`](https://github.com/flutter/flutter/issues/148028), [`TestWidgetsFlutterBinding`](https://api.flutter.dev/flutter/flutter_test/TestWidgetsFlutterBinding-class.html), [`LiveTestWidgetsFlutterBinding`](https://api.flutter.dev/flutter/flutter_test/LiveTestWidgetsFlutterBinding-class.html))

This is an important distinction: the public Wings implementation is not evidence that the macOS host creates an Objective-C `FlutterEngine` and attaches a nested `FlutterViewController`. Flutter does provide a macOS `FlutterEngine` initializer that allows headless execution, but Wings' shipped preview code demonstrates the `flutter_test` route instead. ([macOS `FlutterEngine`](https://api.flutter.dev/macos-embedder/interface_flutter_engine.html))

### 2. The host receives pixels, not a native nested Flutter view

The shipped `RpcServer.sendFrame` implementation:

- Gets the root `RenderView` and its `OffsetLayer`.
- Calls `OffsetLayer.toImageSync` at the requested device-pixel ratio.
- Converts the image with `ImageByteFormat.rawRgba`.
- Sends the byte buffer over a WebSocket.

The binding starts a local HTTP/WebSocket server, publishes its session URI to the Wings daemon, and connects to the Dart VM service. The VSIX also bundles a Flutter web UI used inside the VS Code webview. Together these artifacts show a renderer/client split rather than an embedded native child engine. ([published VSIX](https://marketplace.visualstudio.com/_apis/public/gallery/publishers/cheeky-pixel/vsextensions/flutter-wings/latest/vspackage))

### 3. Interactivity is event forwarding

The preview process registers JSON-RPC handlers for:

- Pointer hover, move, down, and up.
- Scroll events.
- Keyboard and text entry.
- Preview size, text scale, and brightness changes.
- Restart and hot-restart requests.

Those handlers construct Flutter `PointerEvent`s or test input events and dispatch them through the live test binding. Flutter's testing APIs explicitly support pumping a real widget tree, hit testing, taps, drags, text entry, and other interactions. ([`WidgetTester`](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html))

The “live preview” is therefore not merely a periodically generated screenshot: it is a remoted Flutter surface whose input travels back to the headless process.

### 4. Preview code is generated around the user's ordinary widget

The VSIX exposes commands to preview a widget class or top-level preview method. Its packaged scaffolding wraps the resulting real widgets in a configurable `configBuildPreview` wrapper, which is how an application theme or providers can be applied. The Marketplace docs tell users to create a preview configuration for their theme and allow top-level preview methods to return one widget or a list. ([Marketplace listing](https://marketplace.visualstudio.com/items?itemName=cheeky-pixel.flutter-wings))

This is compatible with Desy's requirement: the renderer compiles ordinary consumer Dart files and returns the real widgets; the only generated code is the harness that imports, selects, and wraps them.

### 5. Reload is owned by the Flutter debug toolchain

The historical extension launches/attaches to a Dart test debug session, passes `ENABLE_WINGS=true`, receives the VM-service URI, and sends file-save and restart events through a separate daemon. The target-side package starts the VM service and registers service extensions. The Marketplace promises hot reload, while source shows an explicit hot-restart request routed back to the editor/debugger.

The exact current Wings reload orchestration is private, but it does not need a custom Dart compiler: it can rely on the existing Flutter debug frontend and VM service. Flutter's official Dart/Flutter MCP server now exposes running-app inspection, screenshots, interaction, runtime errors, and hot reload to both Claude Code and Codex. ([Dart and Flutter MCP server](https://docs.flutter.dev/ai/mcp-server))

## What is confirmed versus inferred for the 2026 app

| Claim | Confidence | Basis |
|---|---:|---|
| The app is Wings by Tom Gilder | High | Author demos/reply and Wings product copy align exactly. |
| The outer shell is a Flutter macOS app | Confirmed | Author reply and Wings page. |
| Claude Code is connected through MCP | Confirmed | Author reply; the demo visibly invokes a widget-preview tool. |
| Preview widgets are real, live, interactive, and hot-reloaded | Confirmed | Author videos and Wings page. |
| The current preview uses a descendant of the old `flutter_test` frame-streaming implementation | Likely, not confirmed | Same author/product and capability; old shipped artifacts implement exactly this loop. |
| Claude Code is hosted in a PTY terminal view | Likely, not confirmed | The demo displays the real Claude Code interactive TUI, banner, controls, and prompt bar. No source confirms PTY use. |
| The preview is a second in-process macOS `FlutterEngine` view | Unsupported | The historical Wings implementation instead streams frames from `flutter_tester`. |
| The preview uses MCP Apps | Unlikely | MCP Apps render web content in a sandboxed frame; the author explicitly says headless Flutter engine, and the historical implementation uses a Flutter test process. |

## Likely current data flow

```text
Flutter macOS Wings shell
  ├─ Claude Code process (probably PTY-hosted)
  │    └─ MCP client → widget-preview MCP server/tool
  ├─ Preview controller / daemon
  │    ├─ generates a small Flutter test/preview harness
  │    ├─ starts or attaches to flutter_tester + VM service
  │    └─ requests reload/restart and collects diagnostics
  └─ Preview surface
       ├─ receives RGBA/encoded frames
       └─ sends pointer, scroll, keyboard, and sizing events back
```

The MCP direction matters: Claude Code is the MCP **client**; the preview integration is the MCP **server/tool**. The tool asks the preview controller to render a named widget or source location. The controller then reports success/errors to Claude and updates the user-facing surface independently.

Claude Code can also be driven programmatically via `claude -p` and structured `stream-json`, but the author's video looks like the interactive TUI rather than a custom rendering of headless output. A PTY is therefore the closest reproduction of the visible experience. ([Claude Code programmatic mode](https://code.claude.com/docs/en/headless), [CLI output formats](https://code.claude.com/docs/en/cli-usage))

## Feasibility for Desy

### Feasible product boundary

A standalone developer-only macOS Desy Workshop app could contain:

1. A terminal/agent pane that launches `claude` or `codex` in the selected repository/worktree.
2. A journey/feedback pane owned by Desy.
3. A preview pane backed by a separate headless Flutter test process.
4. A local MCP server shared with the agent.

This does **not** require Desy to evaluate source code inside its own Flutter isolate. It requires Flutter SDK availability on the user's Mac and compiles the consumer project through the normal Flutter toolchain.

### Desy preview harness

For a selected component or workshop candidate, Desy can generate a temporary test entrypoint similar to:

```dart
void main() {
  DesyPreviewBinding.ensureInitialized();

  testWidgets('workshop preview', (tester) async {
    await tester.pumpWidget(
      registry.themeById(themeId).wrap(
        const CandidateHomepageA(),
      ),
    );

    await previewSessionUntilStopped();
  });
}
```

The exact API can differ, but the invariants should be:

- Import the real consumer file.
- Obtain the real widget from the existing `DesyRegistry` path.
- Apply the same real `DesyTheme.wrap` as every other Desy preview.
- Keep workshop manifests limited to IDs and values; do not create a second component catalogue.
- Generate harness files outside the consumer's production source tree where possible.

### MCP surface

A small initial server would be enough:

- `desy_preview_widget(component_id, theme_id, scenario_id)`
- `desy_preview_file(file, symbol)` for workshop-only generated widgets
- `desy_hot_reload()`
- `desy_get_preview_errors()`
- `desy_capture_preview()`
- Later: `desy_selected_widget()` for annotation mode

Claude and Codex can both use the same tools. The current Wings site explicitly claims both agents, and Flutter's official MCP documentation provides configuration examples for each. ([Wings](https://flutterwings.dev/), [Dart and Flutter MCP server](https://docs.flutter.dev/ai/mcp-server))

## Tradeoffs and risks

### Advantages

- Real consumer Flutter code and dependencies.
- Very fast debug compilation after initial startup.
- The agent can see errors and request reload without a bespoke compiler.
- Broken prototype code is isolated from the Desy shell process.
- Frame remoting makes a single continuous app layout possible.
- The same binding can expose widget/semantics metadata for annotation and agent feedback.

### Risks

- The old Wings implementation uses `flutter_test`, `debugLayer`, and custom binding behavior. Some of these are not stable public product-extension points and will require maintenance across Flutter releases.
- `flutter_tester` stubs native platform services and is not representative for plugins. Flutter documents this limitation; for Desy's UI-only workshop it is likely acceptable. ([Flutter team background](https://github.com/flutter/flutter/issues/148028))
- Raw RGBA is expensive. A 780×1600 frame is roughly 5 MB before overhead. Sending only dirty frames helps; a production-quality implementation might later use shared memory, IOSurface/Metal textures, or video/image encoding.
- Text input, IME, drag-and-drop, cursors, accessibility, and platform views are harder than pointer forwarding.
- Hosting an unrestricted agent terminal gives the agent the same repository/shell capabilities as running it normally. Desy must make the working directory and permission mode explicit rather than implying the preview is a security sandbox.
- The current Wings implementation is private, so Desy cannot copy it. The historical source is a proof of feasibility and an architectural reference, not a maintained dependency.

## Recommended experiment

Do not begin with a polished agent IDE. Prove the renderer seam first:

1. Generate one temporary preview test that imports an existing Desy dogfood component and uses the real active theme wrapper.
2. Run it in `flutter_tester` with a custom live binding.
3. Stream dirty frames to a separate small macOS Flutter host.
4. Forward hover, click, scroll, and text input.
5. Edit the component and trigger hot reload through the existing Flutter debug session.
6. Preserve the last successful frame and show compilation errors separately.
7. Only after that works, add a PTY pane and expose `preview_widget` through MCP to Claude Code and Codex.

This experiment answers the important unknown—whether the headless preview loop feels fast and reliable enough in Desy's real design-system repositories—without first building an agent UI.

## Recommendation

The Wings pattern is a credible alternative to both the in-process hot-reload prototype and the hosted DartPad concept. For Desy, the best near-term architecture is:

> **Separate local Flutter preview process + ordinary Flutter source + normal hot reload + a Desy-owned UI and MCP bridge.**

Use the `flutter_test` frame-streaming technique if keeping the widget visually inside the same continuous Workshop screen is essential. If the first spike shows too much fragility, keep the same agent/MCP/workshop workflow but render an ordinary second Flutter desktop or web process in a separate preview surface. The product workflow survives either renderer implementation.

