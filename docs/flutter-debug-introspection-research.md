# Flutter debug introspection for Desy Workbench

**Question.** Can Desy Bench use Flutter debug tooling to inspect the runtime
widget and render stacks of the real consumer components it previews?

**Answer.** Yes. Flutter's Inspector/DevTools is the complete, supported option
for this job when the sample runs in debug mode. It provides selection from the
running app, widget and render-object trees, property/constraint inspection,
and visual layout diagnostics. Flutter also exposes an on-device selection
overlay and console dump helpers that can be useful as small, debug-only
adjuncts to the Workbench. A Desy-owned full inspector UI should *not* be the
first implementation: the framework service behind DevTools is designed to be
driven through the VM service, rather than as a consumer-facing in-app API.

This note uses only Flutter/Dart first-party documentation and API references.
It was researched on 2026-08-06.

## What Flutter already provides

| Need | First-party capability | Suitability |
| --- | --- | --- |
| Select a visible component and see its runtime widget stack | The Flutter Inspector places the running app into select-widget mode; selecting a widget synchronizes the selection and tree. | Best default. |
| Inspect properties, size, constraints, and render-object state | DevTools' Widget Explorer has property and render-object tabs. | Best default for layout diagnosis. |
| See framework implementation nodes too | DevTools can show implementation widgets, which are otherwise hidden/collapsed. | Essential when inspecting actual component composition. |
| Diagnose `Row`/`Column` layout | The Flex explorer exposes constraints, overflow, alignment, fit, and flex factor. | Useful, but it is a DevTools feature rather than a Desy contract. |
| See layout, baselines, repainting, or large images | Inspector visual-debug flags provide these overlays. | Useful opt-in developer controls. |
| Produce a textual artifact | `debugDumpApp`, `debugDumpRenderTree`, `debugDumpLayerTree`, `debugDumpFocusTree`, and `debugDumpSemanticsTree` write diagnostic trees to logs. | Good for a temporary “copy/dump diagnostics” action, not a browsable inspector. |

Sources: [Flutter Inspector documentation](https://docs.flutter.dev/tools/devtools/inspector), [Flutter code-debugging documentation](https://docs.flutter.dev/testing/code-debugging).

## Compatibility with this repository

The sample application's `main.dart` already starts
`simdeck_flutter_inspector` only when `kDebugMode` is true, and the root
Taskfile has `task simdeck`, `task simdeck:describe:flutter`, and related
commands. The Desy package renders its UI in `MaterialApp.router`, while each
preview is a real consumer widget under the selected consumer theme. That means
the standard Inspector will observe the real runtime stack, including both
Desy's surrounding chrome and the themed preview—no registry duplication or
component-specific instrumentation is needed.

Flutter's inspector tree is source-location-aware when widget-creation tracking
is enabled (it is the default for `flutter run`). Without tracking, the runtime
tree is deeper and harder to relate to source. This is especially relevant to
Desy because the preview is composed through both package and example-app
widgets. [Flutter documents the tracking behaviour and its default](https://docs.flutter.dev/tools/devtools/inspector#track-widget-creation).

DevTools initially treats only the launch project's root directory as project
code. For this workspace, developers inspecting a package widget should either
enable **Show implementation widgets** or add the workspace/package parent in
Inspector **Package Directories**. Flutter documents both behaviours and the
package-directory configuration. [Inspector package-directory documentation](https://docs.flutter.dev/tools/devtools/inspector#package-directories).

## Recommended approach

1. **Make the official Inspector/DevTools the primary tree explorer.** Run the
   sample with `task sample:run` (or `task sample:run_mac`) in debug
   configuration and attach DevTools from the
   IDE or with `dart devtools`. This is the supported path for selected-widget
   navigation, widget stacks, render details, constraints, and Flex debugging.
   [DevTools connection guidance](https://docs.flutter.dev/learn/pathway/tutorial/devtools), [Inspector capabilities](https://docs.flutter.dev/tools/devtools/inspector).

2. **Keep SimDeck as the existing automation-friendly companion.** After the
   debug sample is running, use `task simdeck` to open the port-4310 service or
   `task simdeck:describe:flutter` in a second terminal for an agent-readable
   widget description. It is already debug-gated and useful for CLI/agent
   inspection, but it is not a
   replacement for the official DevTools graphical inspector. This conclusion
   is based on the repository wiring; SimDeck itself is outside the
   first-party-source scope of this research.

3. **Optionally add a very small debug-only “Inspect” affordance later.**
   Flutter's `WidgetsApp.debugShowWidgetInspector` enables an on-device overlay
   that lets a person select a location and see the matching widget/render
   object. The selected outline and terse summary are on-device; detailed data
   remains in DevTools/IDE. The property has no effect in release mode. If
   added, it should be an explicit debug-only toggle and should remain off by
   default because selection changes ordinary pointer interaction.
   [WidgetsApp API](https://api.flutter.dev/flutter/widgets/WidgetsApp/debugShowWidgetInspector.html), [WidgetInspector API](https://api.flutter.dev/flutter/widgets/WidgetInspector-class.html), [binding override API](https://api.flutter.dev/flutter/widgets/WidgetsBinding/debugShowWidgetInspectorOverride.html).

4. **Optionally add narrow diagnostics actions, not a second tree viewer.** A
   debug-gated action can call the appropriate `debugDump…` helper from an
   event handler (never during build; render dumps must also avoid layout/paint)
   and direct the developer to DevTools logs. In particular, `debugDumpApp()`
   recursively formats the widget tree; the render, layer, focus, and semantics
   dump APIs target their respective layers. Flutter states that `debug…`
   framework APIs work only in debug mode. [Dump API guidance and constraints](https://docs.flutter.dev/testing/code-debugging#debug-app-layers-using-flags).

## Why not build Desy's own full Inspector now?

Flutter does expose `WidgetInspectorService`, but its API documentation says it
is a service for GUI tools and that calls are normally issued through the Dart
VM Service by evaluating expressions on `WidgetInspectorService.instance`. It
manages inspector object IDs and groups itself. The service extensions can
return roots, children, properties, selections, layout data, and screenshots;
some additionally depend on widget-creation tracking. This makes a custom tool
technically possible, but coupling product UI to those debugger protocols would
duplicate DevTools and create a version-sensitive maintenance surface.

That recommendation is an inference from the intended API boundary, not a
claim that custom tooling is impossible. If a future Desy feature needs
machine-readable, external inspection, use a separate developer tool that
speaks the VM service/inspector protocol rather than exposing it as a normal
consumer runtime API.

Sources: [WidgetInspectorService API](https://api.flutter.dev/flutter/widgets/WidgetInspectorService-mixin.html), [Inspector service-extension catalogue](https://api.flutter.dev/flutter/widgets/WidgetInspectorServiceExtensions.html), [screenshot API (protected)](https://api.flutter.dev/flutter/widgets/WidgetInspectorService/screenshot.html).

## Guardrails

- Gate any Desy-owned introspection UI with `kDebugMode` (or `assert`) so it is
  absent from profile/release products. Flutter's own documentation states that
  `debug...` framework APIs operate only in debug mode. [Flutter debugging
  modes guidance](https://docs.flutter.dev/testing/code-debugging#debug-app-layers-using-flags)
- Do not make runtime inspection part of `DesyRegistry`: it observes the
  rendered tree; it does not describe a consumer component contract. Keeping
  it separate preserves the registry as the declared source of truth.
- Do not rely on an on-device overlay as the sole debugging interface. Its
  detailed information belongs in DevTools/IDE, and it changes interaction
  while selection is active. [WidgetInspector behaviour](https://api.flutter.dev/flutter/widgets/WidgetInspector-class.html)
- Treat all visual debug flags as temporary diagnostics. Repaint highlighting,
  guidelines, and slowed animations change what developers see and, in the
  case of animation timing, what they experience. [Inspector visual-debug
  options](https://docs.flutter.dev/tools/devtools/inspector#visual-debugging)

## Decision

Adopt **debug-run + official DevTools Inspector** as the canonical widget-stack
inspection workflow for Desy Bench. Retain the current debug-only SimDeck path
for agent/CLI use. Only add a debug-only on-device Inspector toggle or dump
buttons after validating that developers need the convenience; neither requires
new registry fields or a bespoke inspector implementation.
