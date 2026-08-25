# Flutter Widget Previewer evaluation result

**Status: parked.** Evaluated on 2026-08-13 against Flutter 3.44.7 and the
Desy dogfood design system.

## Result

- Flutter's Widget Previewer launched successfully for real Desy production
  widgets in their real light and dark themes. The local harness remains at
  `packages/desy_design_system/widget_previewer/` and starts with
  `task widget_previewer:start`.
- The installed SDK provides the command and annotation API. Flutter documents
  the Previewer as stable from 3.47; no Flutter 4.7 SDK target was identified.
- The Previewer is a generated, separate Flutter Web application. Its public
  `@Preview` API is an authoring marker, not a runtime widget-piping API.
- Desy cannot supportably embed or reuse Flutter's generated Previewer in its
  own widget tree. The tool's discovery, generated scaffold, and DTD/LSP
  control plane are private Flutter-tool implementation details.

## Decision

Do not add `@DesyPreview`, annotation discovery, or a Previewer embedding
integration. They would create duplicated authoring surface without improving
Desy's existing direct-registry preview path.

If revisited, build only Previewer-inspired affordances directly from the
existing `DesyRegistry`: source-based narrowing, typed configuration matrices,
and preview-local reset. This preserves one declared inventory and renders the
consumer's real widget in its real Flutter runtime.

## Evidence

- [Flutter Widget Previewer guide](https://docs.flutter.dev/tools/widget-previewer)
- [Comparison findings](flutter_widget_previewer_desy_comparison.md)
- [Embedding feasibility](flutter_widget_previewer_embedding_feasibility.md)
