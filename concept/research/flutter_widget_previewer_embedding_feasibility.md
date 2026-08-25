# Can Desy render Flutter Widget Previewer previews?

Research date: 2026-08-13. This is an implementation-feasibility note, not a
proposal to add a second component inventory. It uses Flutter's public docs and
the Flutter 3.44.7 SDK source installed for this workspace at commit
[`84fc5cbb`](https://github.com/flutter/flutter/tree/84fc5cbb223bc12f83d65b647ff8a56caf779ffd).

## Decision

**Not as a supported embed or library integration.** Flutter does not ship the
Widget Previewer scaffold, discovery service, or generated preview catalogue
as a public package that a Flutter application can add and render inside its
own widget tree.

**Yes, technically, by owning a forked integration.** Desy could copy/adapt
the Previewer scaffold and its generated-catalogue protocol, then render the
result in a Desy-owned screen. That would make Desy responsible for tracking
Flutter-tool, analyzer/LSP, Dart Tooling Daemon (DTD), and web-runtime changes.
It is a substantial and fragile toolchain integration, not a normal Flutter
dependency. It should therefore be treated as a time-boxed workspace extension
experiment rather than a replacement for the `DesyRegistry`.

The recommended product direction is narrower: borrow Previewer's *runtime
affordances* (not its hidden discovery runtime) for Desy's registry-rendered
previews, and retain the official Previewer as a complementary source-local
tool.

## What Flutter actually runs

The public command, `flutter widget-preview start`, creates a separate,
generated Flutter **web** application under the host project's preview state.
The command's implementation creates the `widget_preview_scaffold` project,
generates a `generated_preview.dart` file, and launches that project with a
`ResidentWebRunner`. It is not adding a screen to the host application.
[Command source](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/lib/src/commands/widget_preview.dart),
[code generator](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/lib/src/widget_preview/preview_code_generator.dart).

```text
@Preview declarations in packages
        |
        | Dart analysis server / LSP through DTD (private tool protocol)
        v
Flutter tool generates imports + List<WidgetPreview>
        |
        v
generated widget_preview_scaffold Flutter web app
        |
        +-- Material previewer chrome and individual preview cards
        +-- DTD: selected editor file, preferences, full restart, DevTools URI
        +-- DevTools Widget Inspector rendered in a WebView
```

The generated scaffold imports each discovered preview library and calls its
public zero-argument function/constructor. That static generated import is how
the Previewer obtains executable `Widget` builders; it does not enumerate Dart
annotations at application runtime. The scaffold's own `mainImpl()` creates a
custom inspector service before binding initialization, runs a `MaterialApp`,
and injects an inspector around each preview.
[Generated-preview model](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/templates/widget_preview_scaffold/lib/src/widget_preview.dart.tmpl),
[scaffold entry and rendering](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/templates/widget_preview_scaffold/lib/src/widget_preview_rendering.dart.tmpl).

## Public surface versus private machinery

| Part | Status | Consequence for Desy |
| --- | --- | --- |
| `@Preview`, `MultiPreview`, `PreviewThemeData`, and annotation callbacks in `package:flutter/widget_previews.dart` | Framework API, but `Preview` and `PreviewThemeData` explicitly say they are unstable and will change. | Safe enough for the standalone comparison harness; not a durable core-Desy contract. |
| `flutter widget-preview start` | Public CLI workflow. Officially stable from Flutter 3.47. | Starts a separate web previewer; it has no option/API to mount into an existing Flutter app. |
| Annotation discovery | Flutter tool uses an analysis-server/LSP request through DTD. | No documented application-facing Dart API returns the discovered previews. Depending on its payload couples Desy to private tooling. |
| `PreviewCodeGenerator`, `WidgetPreviewDtdServices`, `WidgetPreviewScaffold`, and the scaffold template | `flutter_tools` implementation/template source, not published app-library API. | Importing these from Desy is unsupported; copying them creates a maintained fork. |
| Per-preview soft restart | Ordinary Flutter widget-tree technique: remove the child for one frame, then reinsert it. | Straightforward to implement directly for a registry-built Desy preview; no Previewer coupling needed. |

The official guide documents only annotation authoring and starting/using the
environment; it does not describe an embedding API. It also records the
web-only limitations: native plugins, `dart:io`, and `dart:ffi` are not
supported in a preview, and a single IDE session supports one Flutter
project/Pub workspace. [Official Widget Previewer guide](https://docs.flutter.dev/tools/widget-previewer).

## Integration choices

| Choice | Can render in Desy? | Cost and limitation | Recommendation |
| --- | --- | --- | --- |
| Use Desy's existing registry builders; independently run Flutter Previewer | Yes, but as two complementary views | No shared control/data channel required. Keeps real cross-platform Dogfood preview behavior. | **Adopt now.** |
| Recreate select Previewer affordances in Desy | Yes | Implement search/source narrowing, configuration matrices, and per-preview reset against the registry. | **Best next experiment.** |
| Add `@Preview` declarations in a sidecar package and hand-maintain a registry bridge | Yes | The bridge is a second list unless it is generated from the registry; annotations remain unstable. | Accept only as a disposable comparison fixture. |
| Generate a Desy screen/catalogue from discovered annotations | Yes, after code generation | Requires a custom analyzer/LSP/DTD client or copied Flutter-tool internals. Generated imports still must compile into the dogfood app. | Possible, but do not productize before evidence justifies maintenance cost. |
| Fork Flutter's scaffold into Desy | Yes, with extensive adaptation | Must track templates, generated DTD connection data, analyzer protocol, Inspector service setup, web-only packages, and Flutter SDK revisions. Its Material chrome also conflicts with Desy's Forui-only scaffold rule. | Only a time-boxed prototype in `packages/extensions/`; never a core dependency. |
| Load the running Previewer web page inside Desy | Web-only, at best | Requires an iframe/WebView; it is a separate Flutter app and widget tree, cannot share inherited context/state/inspector, and is not a cross-platform Flutter surface. | Do not pursue as a Desy workbench feature. |

## Concrete blockers to a true in-app embed

1. **There is no runtime preview catalogue.** Annotations are compile-time
   metadata. The Previewer receives resolved preview details from the analysis
   server, then writes static imports into `generated_preview.dart`. An app
   cannot reflect over every annotation and invoke an arbitrary top-level
   declaration at runtime.

2. **The control plane belongs to developer tooling.** The scaffold connects
   to DTD for editor selection, preference persistence, restart requests, URI
   resolution, and a DevTools server address. The corresponding Flutter-tool
   services have comments requiring the tool and scaffold constants to remain
   synchronized, which is direct evidence of a private protocol boundary.
   [Tool-side DTD service](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/lib/src/widget_preview/dtd_services.dart),
   [scaffold-side DTD service](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter_tools/templates/widget_preview_scaffold/lib/src/dtd/dtd_services.dart.tmpl).

3. **The generated scaffold owns application-global debug behavior.** It sets
   a custom `WidgetInspectorService` before `WidgetsFlutterBinding` is
   initialized and configures inspector exclusion at its root. That is
   appropriate for a purpose-built preview application, but cannot simply be
   dropped into an already running Desy app without changing its own inspector
   and binding assumptions.

4. **The rendering contracts differ.** Previewer's `size` is an artificial
   constraint; unconstrained widgets are bounded by approximately half of the
   Previewer viewport. Desy's declared contract instead gives responsive
   previews a real logical artboard and scales after layout, while named
   devices retain fixed screen/media geometry. [Previewer sizing behavior](https://docs.flutter.dev/tools/widget-previewer#restrictions-and-limitations).

5. **Embedding a web page is not embedding widgets.** An iframe/WebView route
   can show the Previewer UI, but it cannot make Previewer-rendered widgets
   children of Desy's theme, registry, keyboard model, or accessibility tree.

## Desy-aligned recommendation

Keep the `DesyRegistry` as the only declared inventory and make an optional
**Previewer-inspired registry extension** that accepts only already-declared
component IDs and scenarios. It can provide:

- preview-local reset by temporarily replacing the selected registry preview
  subtree for one frame, mirroring Flutter's simple soft-restart mechanism;
- source filtering derived from optional registry source metadata, with no
  annotation scan and no second catalogue;
- a typed configuration matrix that composes current theme, scenario,
  device, text scale, direction, and accessibility settings;
- optional links that open the consumer's source file through an explicit
  IDE/tool integration, instead of depending on Previewer's private DTD
  editor protocol.

This directly preserves Desy's declared principles: one registry, real widgets
in real context, platform-compatible Dogfood, explicit typed extension
boundaries, and Desy-owned Forui scaffolding. It also copies the useful parts
of Widget Previewer without inheriting its artificial sizing, web-only runtime,
or unstable source-discovery contract.

If the team wants a proof rather than a decision, the bounded experiment is:

1. Add a temporary extension screen that takes the app-wide `DesyRegistry`.
2. Implement only a configuration matrix and preview-local reset for one
   existing component; do not add `@Preview` discovery.
3. Compare authoring speed and recovery ergonomics with the already-running
   official Previewer harness.
4. Keep it only if it materially improves the registry workflow; otherwise
   retain the official Previewer as an external, source-local companion.

## Source notes

- Flutter's guide says the Widget Previewer is stable as of Flutter 3.47 and
  documents its command, supported annotations, controls, search, limits, and
  web runtime. [Flutter documentation](https://docs.flutter.dev/tools/widget-previewer)
- The framework API itself labels `Preview` and `PreviewThemeData` unstable.
  [Framework source](https://github.com/flutter/flutter/blob/84fc5cbb223bc12f83d65b647ff8a56caf779ffd/packages/flutter/lib/src/widget_previews/widget_previews.dart)
- The installed SDK source was used to examine the exact 3.44.7 tool behavior;
  Flutter's `main` branch may differ, which reinforces why private-template
  coupling should not be promoted to a Desy contract.
