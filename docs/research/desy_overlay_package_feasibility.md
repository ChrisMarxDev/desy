# Desy overlay package feasibility

Research date: 2026-08-10

## Verdict

**Feasible, with one essential boundary:** Desy can ship a reusable Flutter
package that an existing application explicitly wraps around its real app. That
package can render an in-app overlay, turn Flutter's debug inspector on and off,
select render objects and their creating elements, draw bounds, collect design
requests, preserve an in-memory session across hot reload, and expose a small
debug VM-service protocol.

It cannot be a self-sufficient in-app IDE. A trusted process on the developer's
machine must own repository access, agent execution, compilation, and the hot
reload request. The recommended product is therefore:

```text
consumer debug app
  └─ desy_overlay (Flutter package)
       ├─ inspect/select/highlight real widgets
       ├─ annotation and prompt UI
       ├─ ephemeral session state
       └─ debug VM-service bridge
                    ⇅
developer workstation
  └─ desy_overlay_host (CLI, then optional DevTools extension/MCP adapter)
       ├─ project files and analysis
       ├─ agent process and permissions
       ├─ session persistence
       └─ resident Flutter tool / hot reload
```

This remains local-first, renders the consumer's actual application, introduces
no second component catalogue, and does not require a backend or production code
generation.

## What can live in an ordinary package

A Flutter package can contain reusable Dart/Flutter libraries under `lib`, a
public CLI under `bin`, and a bundled DevTools extension under
`extension/devtools`. Merely adding a dependency does not execute it or inject a
widget; the consumer must import a library, use an alternate entrypoint, or open
the extension. ([Dart package layout](https://dart.dev/tools/pub/package-layout),
[Flutter package development](https://docs.flutter.dev/packages-and-plugins/developing-packages),
[DevTools custom-tool guide](https://docs.flutter.dev/tools/devtools/custom-tool))

The in-app half can be pure Flutter. It needs no native plugin for the first
version:

- a `DesyOverlay` widget or `TransitionBuilder` that preserves the consumer's
  real root subtree;
- inspector-mode controls and a selection listener;
- highlight, pin, comment, prompt, progress, and cancel UI;
- immutable annotation/session DTOs containing runtime types, transformed
  bounds, widget ancestry, route/viewport context, and host-enriched source
  location when available;
- an `assert`-guarded custom service extension and extension-stream events for
  communication with a host;
- conditional platform adapters so the UI library never imports `dart:io` on
  web.

It should use Flutter's public barrel libraries, not import Flutter's
`lib/src` implementation files. Dart explicitly treats another package's
`lib/src` as unsupported implementation detail. ([Dart package layout](https://dart.dev/tools/pub/package-layout#implementation-files))

### Dependency and entrypoint consequence

If `lib/main.dart` imports `package:desy_overlay/desy_overlay.dart`, Dart's
official dependency rule says `desy_overlay` must be a regular dependency,
because code under `lib` imports it. A `kDebugMode` branch can remove the
runtime code from profile/release output, but it does not change the pubspec
classification. ([Dart pub dependencies](https://dart.dev/tools/pub/dependencies#dev-dependencies),
[`depend_on_referenced_packages`](https://dart.dev/tools/linter-rules/depend_on_referenced_packages))

For a true `dev_dependency`, use a private development entrypoint, for example
`tool/desy_main.dart`, that imports the consumer's public app root and wraps it:

```dart
void main() => runApp(DesyOverlay(child: const ConsumerApp()));
```

The host launches that target instead of changing the production entrypoint.
This requires the application to expose its root/bootstrap cleanly, but it gives
the strongest guarantee that Desy is not in the production library graph.

## Inspection and target mapping

Flutter already exposes the core selection model. `WidgetInspector` selects the
render objects at a pointer location and displays an outline; its shared
`InspectorSelection` exposes candidate render objects, the current render
object, and the corresponding `Element`. `WidgetsBinding` can force the root
`WidgetsApp` inspector on, and also provides an escape hatch for tools that want
to inject a scoped inspector themselves. ([`WidgetInspector`](https://api.flutter.dev/flutter/widgets/WidgetInspector-class.html),
[`InspectorSelection`](https://api.flutter.dev/flutter/widgets/InspectorSelection-class.html),
[`debugShowWidgetInspectorOverride`](https://api.flutter.dev/flutter/widgets/WidgetsBinding/debugShowWidgetInspectorOverride.html),
[`debugExcludeRootWidgetInspector`](https://api.flutter.dev/flutter/widgets/WidgetsBinding/debugExcludeRootWidgetInspector.html))

The mapping is:

```text
pointer position
  → matching RenderObject candidates
  → RenderObject.debugCreator
  → DebugCreator.element
  → widget plus ancestor Element chain
```

`DebugCreator` is public and wraps the `Element` that created a render object.
However, Flutter assigns `renderObject.debugCreator = DebugCreator(this)` inside
an assertion. That assignment is absent when assertions are disabled. This is
the decisive reason that source-aware inspection is a **debug-mode feature**,
not a profile-mode feature. ([`DebugCreator`](https://api.flutter.dev/flutter/widgets/DebugCreator-class.html),
[`RenderObject.debugCreator`](https://api.flutter.dev/flutter/rendering/RenderObject/debugCreator.html),
[Flutter 3.44.6 framework source](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter/lib/src/widgets/framework.dart#L6805-L6821))

The visual leaf is not always the meaningful consumer widget. Stateless,
stateful, proxy, and composition widgets can build lower-level
`RenderObjectWidget`s without owning a render object themselves. Desy should
therefore retain both identities:

- the exact selected render object and its bounds;
- the closest project-created widget/element in the ancestor chain.

Flutter's `WidgetInspectorService` already implements project-summary trees,
object groups, source-creation metadata, and VM-service serialization for GUI
tools. Its inspector service extensions are registered inside an assertion, and
some convenient in-process methods such as `getSelectedWidget` are `@protected`.
The package UI should use the public selection state rather than call protected
methods or copy Flutter's private serializer; the external host can use the
inspector VM-service endpoints to enrich the selected target with file, line,
and column. ([`WidgetInspectorService`](https://api.flutter.dev/flutter/widgets/WidgetInspectorService-mixin.html),
[`getSelectedWidget`](https://api.flutter.dev/flutter/widgets/WidgetInspectorService/getSelectedWidget.html),
[Flutter 3.44.6 binding source](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter/lib/src/widgets/binding.dart#L798-L814))

Widget-creation tracking must remain enabled for the best source mapping. The
inspector can still show a runtime tree without it, but creation locations and
the project-summary tree are degraded. ([Flutter Inspector](https://docs.flutter.dev/tools/devtools/inspector#track-widget-creation))

### Annotation identity is not automatically durable

An `Element`, render-object reference, inspector object ID, and screen-space
rectangle are runtime identities. Elements can be replaced on rebuild; inspector
object IDs are grouped explicitly because VM-service IDs expire; source lines
move after edits. A persisted annotation therefore cannot treat any one of
these as a permanent primary key. ([`WidgetInspectorService`](https://api.flutter.dev/flutter/widgets/WidgetInspectorService-mixin.html))

For the spike, annotations should be session-scoped snapshots. A later
reattachment heuristic can combine source URI/line/column, widget and render
types, ancestor signature, route, semantic label, and approximate bounds, and
must visibly mark ambiguous or stale matches. An optional explicit
`DesyAnnotationAnchor(id: ..., child: ...)` can provide durable identity for
teams that need it, without making metadata mandatory for ordinary inspection.

## Overlay integration in an existing app

`MaterialApp.builder` is an official app-wide insertion point above the
Navigator/Router and below `Directionality`, `Localizations`, `DefaultTextStyle`,
and `MediaQuery`. The returned subtree must retain the supplied routing `child`.
`WidgetsApp` and `CupertinoApp` have the same general builder seam, so Desy need
not require Material. ([`MaterialApp.builder`](https://api.flutter.dev/flutter/material/MaterialApp/builder.html))

Recommended integration order:

1. Offer `DesyOverlay.builder(existingBuilder: ...)` that composes with an
   existing app builder and returns `Stack(children: [child, overlayChrome])`.
   This is predictable across route changes and keeps inherited app context.
2. Offer a root `DesyOverlay(child: ConsumerApp())` for the alternate dev
   entrypoint. It must supply its own minimal directionality/theme for its
   chrome and never alter the consumer subtree's media or theme.
3. Use an `OverlayEntry` only when the consumer provides a descendant context
   or `navigatorKey`. The builder's own context is above the Navigator, so
   `Overlay.of` there cannot discover the Navigator's descendant overlay.

`Overlay.of` documents that a MaterialApp, CupertinoApp, or Navigator is the
usual provider. `NavigatorState.overlay` is also public when a navigator key is
available. ([`Overlay.of`](https://api.flutter.dev/flutter/widgets/Overlay/of.html),
[`NavigatorState.overlay`](https://api.flutter.dev/flutter/widgets/NavigatorState/overlay.html),
[`MaterialApp.navigatorKey`](https://api.flutter.dev/flutter/material/MaterialApp/navigatorKey.html))

The overlay should not add `MaterialApp`, Navigator, scrolling, `SafeArea`, or
synthetic constraints around the consumer app. It draws its own chrome above
the already-laid-out application. Selection outlines should use the selected
render object's transformed bounds in the common render tree and respect clips;
they are diagnostic geometry, not a promise of exact painted pixels.

## Build-mode contract

| Mode | Overlay UI | RenderObject → Element mapping | VM/DevTools bridge | Hot reload |
| --- | --- | --- | --- | --- |
| Debug | Supported | Supported through `DebugCreator` | Supported | Supported |
| Profile | Do not enable | `debugCreator` assignment is absent | Some VM/service facilities exist, but inspector extensions are debug-only | Not supported |
| Release | Must be absent | Not available | VM service and service extensions disabled | Not supported |

Flutter documents that hot reload works only in debug mode. Release strips
debugging information and disables service extensions; profile keeps selected
profiling service support, but it is not a substitute for the assert-only widget
inspector. ([Flutter build modes](https://docs.flutter.dev/testing/build-modes),
[Flutter hot reload](https://docs.flutter.dev/tools/hot-reload))

Use a compile-time `kDebugMode` branch or an `assert` closure at the consumer
bootstrap and around every service-extension registration. Flutter documents
that these constant guards allow the tree shaker to remove unreachable debug
code. A release verification test should build representative Android, iOS,
desktop, and web consumers and check both behavior and artifact symbols/assets.
([`kDebugMode`](https://api.flutter.dev/flutter/foundation/kDebugMode-constant.html),
[`BindingBase.initServiceExtensions`](https://api.flutter.dev/flutter/foundation/BindingBase/initServiceExtensions.html))

Inspection is intentionally not performance-neutral. Flutter's own inspector
source describes its overlay approach as unsuitable for production and limits
it to debug mode. Desy should inspect on click/drag, avoid continuous whole-tree
hover traversal by default, bound diagnostics depth, and measure large trees.
([Flutter 3.44.6 inspector source](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter/lib/src/widgets/widget_inspector.dart#L3470-L3483))

## Hot reload ownership

The in-app package can observe `State.reassemble` and rebuild its own caches,
but it cannot compile edited Dart source. Flutter's resident hot runner first
updates/compiles DevFS, then calls VM `reloadSources`, evicts dirty assets, and
finally reassembles Flutter views. Calling `reloadSources` without the tool's
new incremental kernel does not perform that pipeline. ([Flutter hot reload](https://docs.flutter.dev/tools/hot-reload),
[`State.reassemble`](https://api.flutter.dev/flutter/widgets/State/reassemble.html),
[Flutter hot-runner source: compile and reassemble](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter_tools/lib/src/run_hot.dart#L1011-L1095),
[Flutter hot-runner source: VM reload](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter_tools/lib/src/run_hot.dart#L1284-L1381))

The host must therefore either:

- launch and retain the `flutter run` process and request reload through that
  resident tool;
- integrate with the user's IDE/Dart tooling session; or
- reuse the official Dart and Flutter MCP server, which can discover running
  apps through DTD and expose widget-tree inspection, runtime errors, input,
  and hot reload.

The official MCP path is particularly attractive for agent clients and already
supports widget tree, errors, and hot reload in normal web debug sessions.
([Dart and Flutter MCP server](https://docs.flutter.dev/ai/mcp-server))

The local prototype's PID-file/`SIGUSR1` path is a valid first CLI adapter:
Flutter's `run --pid-file` help explicitly declares `SIGUSR1` for reload and
`SIGUSR2` for restart. It is not portable to a separately launched IDE session,
Windows, or a mobile/web app process, so it must remain behind a replaceable
host interface. ([Flutter 3.44.6 run command source](https://github.com/flutter/flutter/blob/ee80f08bbf97172ec030b8751ceab557177a34a6/packages/flutter_tools/lib/src/commands/run.dart#L470-L489))

## VM service and DevTools possibilities

The runtime package may register `ext.desy_overlay.*` methods with
`dart:developer.registerExtension`; registration is per isolate, names must use
an `ext.<package>.<command>` namespace, and clients include the isolate ID.
Flutter recommends assertion or `!kReleaseMode` guards because the VM service
exists only in debug/profile and unguarded handler code can otherwise increase
release size. ([`registerExtension`](https://api.dart.dev/dart-developer/registerExtension.html),
[`BindingBase.registerServiceExtension`](https://api.flutter.dev/flutter/foundation/BindingBase/registerServiceExtension.html))

A small protocol is enough:

```text
runtime → host: ready, selectionChanged, annotationSubmitted,
                promptSubmitted, cancelRequested, reassembled
host → runtime: sessionSnapshot, agentEvent, compileError,
                reloadStarted, reloadFinished, hostDisconnected
```

Runtime-to-host notifications can use the VM Extension event stream;
`dart:developer` documents that VM-service clients can listen to it. Commands
back into the app use service-extension RPCs. Events need acknowledgements or a
drainable queue because an event posted with no listener is dropped.
([`extensionStreamHasListener`](https://api.dart.dev/dart-developer/extensionStreamHasListener.html),
[`postEvent`](https://api.dart.dev/dart-developer/postEvent.html))

A bundled DevTools extension is a supported second UI/transport. DevTools
extensions are Flutter web apps distributed in a pub package, discovered from
the application's dependencies, manually enabled by the user, and able to use
the connected VM service, DTD, project files, and analysis server. It is a good
home for a rich session timeline and source navigation. It does not remove the
need for the small in-app layer when the product goal is direct on-canvas
selection and annotation, and agent/process execution still belongs in a
trusted host rather than the extension iframe. ([DevTools extensions](https://docs.flutter.dev/tools/devtools/extensions),
[DevTools custom-tool guide](https://docs.flutter.dev/tools/devtools/custom-tool))

## Process and platform constraints

`dart:io` is unavailable to browser applications. It is available to Flutter
mobile and desktop code, but `Process.start` starts a program on the runtime's
own operating system; it is not a bridge from a phone or browser to the
developer workstation. The repository and agent binary live on the workstation,
so orchestration belongs in a Dart CLI/IDE host even when the inspected app runs
on Android or iOS. ([`dart:io`](https://api.dart.dev/dart-io/),
[`Process.start`](https://api.dart.dev/dart-io/Process/start.html),
[Flutter web FAQ](https://docs.flutter.dev/platform-integration/web/faq#can-i-use-dartio-with-a-web-app))

Expected first-version support:

- **macOS/Linux/Windows desktop debug app:** full overlay; host runs locally.
- **Android/iOS debug app or simulator:** full overlay; host runs on the
  workstation and uses the existing Flutter/VM-service connection.
- **Flutter web debug app:** overlay and VM-service/DTD flow; no `dart:io`
  or in-browser agent process. The official MCP docs confirm widget tree,
  errors, and reload work for web, while `flutter_driver` finder interactions
  do not.
- **profile/release on every platform:** overlay disabled; no supported
  source-aware workflow.

The overlay must also handle multiple Flutter views/windows deliberately. The
first spike should declare one implicit root view; do not silently draw bounds
from one render tree into another.

## Evidence from the existing Desy prototype

The current [`packages/desy_ide` prototype](../../packages/desy_ide/README.md)
already proves the main feasibility points on Flutter 3.44.6/macOS:

- [`hot_reload_ide_main.dart`](../../packages/desy_ide/lib/hot_reload_ide_main.dart)
  renders real candidates in the same process, starts Codex, asks the owning
  Flutter tool to reload, and preserves compatible host/preview state;
- its picker traverses render objects, reads `DebugCreator.element`, walks to a
  locally created widget, transforms bounds, and draws the selection;
- [`workshop_runtime_io.dart`](../../packages/extensions/desy_widget_workshop/lib/src/workshop_runtime_io.dart)
  places process execution and PID signalling behind a platform interface,
  while the non-IO stub keeps the UI buildable elsewhere.

It also exposes the exact reasons to split the product. The app currently runs
the agent with `Process.start`, depends on a known project directory and PID
file, supports only selected desktop hosts, and shares a failure domain with
edited widget code. Those are acceptable spike choices, not a reusable runtime
package contract. The prototype's copied hit traversal should be replaced by
Flutter's public inspector selection where possible.

## Safety and proposed packaging

Recommended packages:

1. **`desy_overlay_protocol`** — pure Dart immutable DTOs, protocol versions,
   capability negotiation, and JSON codecs; no Flutter, IO, agent, or VM URI.
2. **`desy_overlay`** — thin Flutter runtime UI and debug inspector bridge;
   public APIs only, `kDebugMode`/assert guarded, conditional platform imports,
   no file writes, shell, credentials, or arbitrary network listener.
3. **`desy_overlay_host`** — opt-in Dart CLI and later MCP/DevTools adapter;
   owns project root, session files under `.dart_tool/desy_overlay`, agent
   subprocesses, Flutter runner attachment, and reload/restart policy.

The consumer should experience this as one setup command even if the internals
remain split.

Security defaults:

- require explicit debug launch/attachment and show a persistent connected
  indicator;
- bind any host socket to loopback, use an unguessable per-session token, and
  never print the VM-service authentication URI;
- do not use a shell for agent execution; pass an executable and arguments
  separately, fix the working directory, drain stdout/stderr, and expose stop;
- make the host's repository scope and edit authorization visible before
  sending a prompt;
- keep annotations and source snippets local by default; redact secrets from
  logs and require explicit export;
- version/capability-negotiate every runtime/host connection;
- make host disconnect, rejected reload, stale target, and compile error normal
  recoverable states;
- test that release builds contain neither service extensions, overlay assets,
  session data, nor a reachable activation path.

## Smallest decisive spike

Build the spike against one ordinary consumer app, not inside the Desy Bench
shell:

1. Add `desy_overlay` as a path `dev_dependency` and create
   `tool/desy_main.dart` that wraps the app root.
2. Inject a package-owned `Stack` through the app builder. Toggle Flutter's
   built-in inspector, listen to `InspectorSelection`, outline the selected
   render object, and show widget/render types plus transformed bounds.
3. Create one annotation containing a comment, viewport/route, widget and
   render types, ancestor signature, and screenshot-free bounds. Have a small
   host enrich it with the inspector service's source location.
4. Register an assert-only `ext.desy_overlay.*` bridge. Run an echo/fake agent
   first, then one constrained real agent request; stream progress and support
   cancellation.
5. Launch the debug target through the host, edit one Dart file, request hot
   reload through the resident Flutter tool, and verify that the overlay
   session survives while stale target identity is detected.
6. Introduce a syntax error and a reload-rejected change; verify the app and
   annotation remain usable and the host reports recovery actions.
7. Run the same UI on Chrome and an Android/iOS simulator using the workstation
   host. Finally build release artifacts and prove that the overlay and custom
   service extensions are absent.

Success criteria:

- selection identifies the expected project widget in at least 20 varied
  layouts, including transforms, clips, scrolling, overlays, and routes;
- annotation-to-source enrichment works with widget creation tracking enabled
  and degrades clearly when unavailable;
- 30 consecutive compatible reloads preserve the prompt/session state;
- compile and reload failures never grant new file/process authority and have a
  clear retry/restart path;
- idle mode does no render-tree traversal and selection latency remains usable
  on a large real screen;
- release verification finds no activation route or VM extension.

If that spike succeeds, the architecture is viable. The next risk to retire is
target reattachment after source edits—not drawing the overlay or sending an
agent prompt.

## Principal risks

| Risk | Consequence | Mitigation |
| --- | --- | --- |
| Debug Flutter internals evolve | Inspector serialization or source mapping breaks across SDK releases | Use public selection APIs in-app; isolate VM inspector adapter; pin/test a Flutter version matrix |
| Runtime identity is ephemeral | Annotations drift or attach to the wrong widget after rebuild/reload | Snapshot identity, use multi-signal reattachment, expose stale/ambiguous state, offer optional stable anchors |
| Inspector overhead on large trees | Jank and interaction interception | Explicit inspect mode, click/drag not constant hover, bounded diagnostics, profiling tests |
| App and edited widget share a process | Bad code can freeze/crash the whole target | Keep last host session externally, report disconnect, offer restart; consider isolated preview only for untrusted candidates |
| Existing app builders/navigation differ | Overlay hidden, duplicated, or lacks inherited context | Composable builder API plus root-wrapper fallback; tests for Material/Cupertino/Router/custom Navigator |
| Host discovery differs by IDE/platform | Reload works only when Desy launched the app | Capability adapters: owned resident runner first, official MCP/DTD/IDE attachment second; never expose the transport as product API |
| Debug tool leaks into release | Size, security, or store-policy problem | Alternate dev entrypoint, constant guards, release artifact tests |
| Agent has excessive repository authority | Unintended edits or secret exposure | Trusted external host, explicit scope/approval, no in-app shell, cancellable process, local logs |
| Mobile/web cannot spawn workstation tools | In-app prompt appears connected but cannot act | Treat UI as a client; require and visibly show an authenticated workstation host |

## Decision

Proceed with the spike, but name and design it as a **debug overlay client plus
host**, not a package that owns hot reload or embeds an agent in every Flutter
app. The runtime package is straightforward; the product-defining work is the
safe host connection, source-aware target identity, and failure recovery across
real IDE/CLI launch modes.
