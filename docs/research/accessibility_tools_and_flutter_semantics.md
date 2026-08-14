# Flutter semantics and accessibility-tooling options for Desy

Research date: 2026-08-12  
Flutter SDK reviewed: 3.44.7  
Package snapshot reviewed: `accessibility_tools` 2.8.0

## Executive finding

Desy now has a useful **scoped visual accessibility overlay**: the preview-only
Accessibility card gives the real consumer preview an explicit semantics
boundary, draws its semantic labels, and colours actionable hit targets. This
is a good exploration tool, but it is not an accessibility inspector or a
pass/fail checker.

`accessibility_tools` would add valuable diagnostics (missing semantic labels,
missing input/image labels, small tap targets, and experimental large-text
overflow checks). It should **not** be mounted directly around an individual
Desy preview: its checkers observe the application's root semantics/rendering
state and paint global-coordinate issue rectangles in the wrapper's local
overlay. In a scaled, movable Desy artboard, that makes the findings and
overlay scope unreliable. It is a possible opt-in, debug-only *app-root*
diagnostic for the dogfood app, not the foundation for Desy's scoped preview
tooling.

The recommended direction is a three-part toolset:

1. keep the existing preview environment controls and scoped overlay for
   visual exploration;
2. introduce a Desy-owned, explicitly scoped **issue list + highlight overlay**
   for preview diagnostics, using a stable contract rather than a global
   package wrapper; and
3. make the checks enforceable in widget tests with Flutter's built-in
   accessibility guidelines, plus consumer-owned semantic assertions for cases
   generic rules cannot judge.

This is evidence and option analysis, not an implementation commitment.

## What is present today

The workbench's `DesyPreviewAccessibilityPanel` has independent *Semantic
labels* and *Hit targets* toggles. Its preview scope applies MediaQuery and
Directionality overrides only to the consumer preview. The Desy-owned overlay
then traverses that preview's explicit debug-semantics boundary: labels are
painted in place; actionable regions are green when at least 44 logical pixels
in both dimensions, red when smaller, and pink when they have no label. The
source is `packages/desy_bench/lib/src/workbench/presentation/detail_screen.dart`,
`packages/desy_bench/lib/src/workbench/presentation/preview_accessibility_panel.dart`,
and `packages/desy_bench/lib/src/workbench/presentation/preview_accessibility_overlay.dart`.

Flutter defines `SemanticsDebugger` as a widget that “visualizes the semantics
for the child” to help understand how an app presents itself to accessibility
technology ([API](https://api.flutter.dev/flutter/widgets/SemanticsDebugger-class.html),
[framework source](https://github.com/flutter/flutter/blob/3.44.7/packages/flutter/lib/src/widgets/semantics_debugger.dart)). Its painter shows:

- the semantics-node rectangle;
- label and tooltip text, when available;
- annotations such as `button`, `textfield`, `checked`, `scrollable`,
  `adjustable`, and `disabled`.

Flutter's implementation remains a useful reference for label and region
visualization. Desy's overlay directly serves the immediate goal: showing a
widget's semantic label and basic target status in one preview. It does not
select a node, expose a structured tree, judge whether a label is appropriate,
or report an audit result.

### Important scope limitation

`SemanticsDebugger` obtains the view's `PipelineOwner` and paints from its
root semantics node ([source](https://github.com/flutter/flutter/blob/3.44.7/packages/flutter/lib/src/widgets/semantics_debugger.dart)). Inference: even when the widget is mounted inside a Desy preview, the semantics data comes from the view-wide pipeline, rather than an explicit preview-root tree. Its `CustomPaint` clips to its own bounds, so it is still an effective visual aid for the artboard, but it is not a robust ownership boundary for an eventual inspector or issue counter. Scaling and positioning the artboard also need deliberate coordinate handling before promising exact hit selection or a tree view.

## Flutter-native checks and testing

Flutter's `flutter_test` exposes `AccessibilityGuideline` and the
`meetsGuideline` matcher ([API](https://api.flutter.dev/flutter/flutter_test/AccessibilityGuideline-class.html),
[matcher source](https://github.com/flutter/flutter/blob/3.44.7/packages/flutter_test/lib/src/matchers.dart)). Built-in guidelines cover:

- Android 48×48 tap targets;
- iOS 44×44 tap targets;
- text contrast; and
- labels on nodes with a tap or long-press action.

The test needs `tester.ensureSemantics()` before awaiting the matcher
([Flutter source](https://github.com/flutter/flutter/blob/3.44.7/packages/flutter_test/lib/src/accessibility.dart)). These are deterministic test checks, not a live workbench overlay. They are the strongest initial enforcement layer for a design system: run them against each registered component scenario and keep failures in CI.

They do not replace manual screen-reader verification, design review, or
component-specific expectations. Flutter's own release checklist also calls
out intelligible TalkBack/VoiceOver descriptions, contrast, target size,
color-vision modes, and large text scales
([Flutter accessibility checklist](https://docs.flutter.dev/ui/accessibility)).

## `accessibility_tools` assessment

[`accessibility_tools` 2.8.0](https://pub.dev/packages/accessibility_tools)
is an MIT Flutter package supporting Android, iOS, Linux, macOS, web, and
Windows. Its released SDK constraint is Flutter `>=3.38.0` and Dart `>=3.9.0`
([package manifest](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/pubspec.yaml)),
which is compatible with this workspace's Flutter 3.44.7.

It is designed to wrap an app's `MaterialApp`/`CupertinoApp` builder with
`AccessibilityTools(child: child)`. It compiles its UI out of release builds;
widget tests also skip checkers unless its test-only static flag is enabled
([public implementation](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/src/accessibility_tools.dart)).

### Useful capabilities

| Capability | Package behavior | Relevance to Desy |
| --- | --- | --- |
| Semantic label checks | Reports tappable semantics without labels/tooltips. | Useful baseline diagnostic. |
| Input and image label checks | Checks common fields, choice controls, and images. | Useful for real component previews. |
| Tap-area checks | Checks a platform-specific minimum size; individual exceptions can use the package's ignore wrapper. | Useful but policy needs to match Desy's supported platforms. |
| Large-font overflow | Experimental; temporarily changes text scale while checking flex overflow. | Valuable test concept, poor first live-workbench check. |
| Environment simulation | Offers text scale, direction, locale, platform, density, bold text, colour-vision modes, and a semantics-debugger mode. | Most overlaps Desy's existing panel; colour-vision modes are a possible addition. |

The package documents these checkers and simulations on its
[pub.dev readme](https://pub.dev/packages/accessibility_tools), and its public
entry point exposes the configuration types
([library source](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/accessibility_tools.dart)).

### Why not wrap each Desy artboard directly?

This is the key integration boundary:

- Its checkers update from the framework's semantics lifecycle and collect
  issue data from the app rather than accepting a supplied preview root
  ([implementation](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/src/accessibility_tools.dart)).
- The checker manager and issue overlay operate in global coordinates
  ([checker manager](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/src/checker_manager.dart),
  [overlay implementation](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/src/accessibility_tools.dart)).
  Inference: mounting it inside a translated/scaled preview could include
  workbench chrome in the results and offset or clip issue boxes incorrectly.
- The package owns floating buttons, an overlay, and an optional draggable tools
  panel. Even with its panel disabled, findings create its own UI. That conflicts
  with a clean, stable Desy canvas and screenshot output.
- Its experimental overflow checker temporarily changes error handling and text
  scaling ([source](https://raw.githubusercontent.com/rebelappstudio/accessibility_tools/v2.8.0/lib/src/checkers/flex_overflow_checker.dart)).
  It should not be run concurrently for multiple previews or treated as a
  passive visual overlay.

## Integration options

| Option | Scope | Value | Main limitation | Recommendation |
| --- | --- | --- | --- | --- |
| Keep Flutter `SemanticsDebugger` | Individual preview | Immediate visual labels, roles, regions | No structured inspection or diagnostics; view-wide semantics source | Keep as the first tool. |
| Add `accessibility_tools` at the dogfood app root | Entire workbench, debug only | Fast exploratory warnings and colour-vision simulation | Audits Desy chrome and all open content; duplicate controls/UI; unsuitable for screenshots | Consider only as a separate developer-only experiment. |
| Mount `accessibility_tools` inside each preview | Intended individual preview | Reuses off-the-shelf checks | Global semantic collection and global geometry defeat scoped accuracy | Do not do this without a maintained fork/extraction. |
| Desy-owned preview audit adapter | Individual preview | Can match artboard transforms, presentation, issue policy, and Desy controls | Requires deliberate design and test investment | Recommended production direction. |
| Flutter guideline tests + semantic assertions | Component scenario/CI | Deterministic regression prevention | Not a live visual tool; generic checks cannot know product intent | Add alongside visual tooling. |

## Proposed implementation plan

### Phase 0 — validate the existing visual overlay

1. Keep `SemanticsDebugger` explicitly labelled as **Visualize semantics**, not
   as a checker or inspector.
2. Add a component fixture with labels, values, hints, actions, merged
   semantics, and an intentionally unlabelled tappable node. Verify the overlay
   is understandable at normal and scaled preview sizes.
3. Decide whether the visual overlay should cover only the selected artboard or
   the whole preview canvas. The latter is more faithful to the framework's
   view-wide data; the former is better for focus but requires a clear clipped
   behavior contract.

### Phase 1 — testable baseline

1. Define an opt-in `DesyAccessibilityScenario`/test harness for registered
   real component widgets. It must not introduce a parallel registry or ask
   consumers to duplicate ordinary component data.
2. Run Flutter's labelled-target and platform tap-target guidelines in the
   harness. Keep target platform explicit.
3. Add consumer-supplied semantic assertions only where product meaning cannot
   be derived: expected label/value/hint, checked state, disabled behavior,
   and merged-node intent.
4. Publish the result as normal test failures first. Do not present flaky pixel
   or inference-based findings as CI gates.

### Phase 2 — Desy-owned preview audit panel

1. Establish one explicit `DesyPreviewAuditBoundary` at the unscaled logical
   consumer preview. It must know the artboard's global transform and clipping
   rect.
2. Define a small typed `DesyAccessibilityFinding` contract: rule ID,
   severity, concise message, affected global/logical rect, and optional
   documentation/fix link. Findings are ephemeral diagnostics, never registry
   declarations.
3. Build an **Issues** section under the existing Accessibility card: count by
   severity, rule toggles, a selected finding, and a matching artboard overlay.
   Maintain keyboard navigation and ensure the tooling itself does not obscure
   or mutate the consumer widget.
4. Begin with rules that have trustworthy scope and geometry. Label presence
   and minimum target size are candidates; contrast and text-overflow need
   clearly documented limitations before being shown as findings.

### Phase 3 — optional external-package experiment

1. Add `accessibility_tools` only to the dogfood application's debug entry
   point, never to `desy_bench`'s public dependency surface.
2. Disable its testing panel and draggable buttons; keep the experiment outside
   screenshot/golden paths.
3. Compare findings with Phase 1 tests and a manual screen-reader pass on a
   small representative set. Record false positives/negatives and performance.
4. If its rule implementations prove useful, either retain the root-only tool
   as a local developer aid or fork/extract a narrow, explicitly-scoped checker
   adapter. Do not couple the Desy workbench UX to its floating-overlay UI.

## Decisions needed before implementation

- Which platforms does Desy certify by default? Tap-target policy needs that
  answer; mobile and desktop expectations differ.
- Is the intended live experience visual education, actionable diagnostics, or
  an accessibility conformance report? Each needs a different level of
  precision and interaction design.
- Which checks may be CI gates versus advisory warnings? Start with framework
  guideline tests; do not gate on experimental overflow or rendered-pixel
  heuristics without stable fixtures.
- Do consumer components need optional semantic-contract metadata, or should
  first-party components provide focused test scenarios beside their real
  registry declarations? The latter preserves the registry as the single
  inventory and keeps product-specific expectations close to the widget.
