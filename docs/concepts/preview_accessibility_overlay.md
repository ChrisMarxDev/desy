# Preview accessibility overlay

Desy’s detail view provides opt-in visual accessibility aids for the selected
consumer preview. They are local session state, never registry data or a
consumer-widget modification.

## Boundary and controls

`DesyPreviewAccessibilityOverlay` creates an explicit Flutter semantics
boundary around the real preview child. When enabled from the Accessibility
card, it collects the debug semantics below that boundary and paints over the
same artboard. Desy navigation, knobs, and other workbench chrome are outside
the boundary.

The two visual controls are independent:

- **Semantic labels** draws Flutter semantic labels (or tooltips when a label
  is absent).
- **Hit targets** draws actionable semantic regions: green for targets at least
  44 logical pixels in both dimensions, red for smaller labelled targets, and
  pink for actionable targets without a label.

The media-query controls in that card remain preview-only environmental test
conditions: text scale, text direction, bold text, high contrast, and reduced
motion.

## Limits

The overlay uses Flutter debug semantics and is therefore a local visual review
aid in debug/profile builds, not a release feature or a pass/fail audit. It
does not determine text contrast, focus traversal, platform-specific minimum
targets, or conformance. Those checks belong in Flutter widget tests using
`meetsGuideline` and focused semantic assertions.

This intentionally avoids wrapping the application in `accessibility_tools`:
that package’s collection and controls are application-wide, whereas a Desy
detail panel needs to remain scoped to one preview artboard.
