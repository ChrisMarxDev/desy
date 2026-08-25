# Component image export

Component details expose one `Export image` action for the currently active
component variant. The action renders the consumer's real widget to a PNG at
2× its logical size under the active consumer theme and current preview
environment.

## Product opportunity: production design beyond the app team

This feature opens a broader collaboration surface than image export alone.
Production design elements are normally trapped inside source repositories and
running applications, so non-technical collaborators must work from screenshots
or recreate approximations in separate design files. Those copies drift from
the app and make feedback less precise.

Desy makes the real, registered widget usable by people outside engineering.
A marketer can export the exact component, variant, theme, and configured state
that the app renders, then use it in campaign artwork, launch documents,
presentations, or social media without rebuilding it. The same access also
makes critique concrete: feedback can refer to a stable component and state
rather than an approximation or a loosely annotated screenshot.

This suggests an under-served product wedge for Desy. Its audience is not only
developers and design-system maintainers, but anyone who needs to use or discuss
the product's visual language. Giving marketing, product, design, and
engineering one production-accurate reference shortens handoffs and reduces the
distance between how the app is built, presented, and discussed.

The collaboration loop is:

1. Engineering registers and ships the real widget.
2. A collaborator exports or reviews its exact live state.
3. They use the asset or give feedback against that named state.
4. The app team updates the real widget.
5. Every later export reflects the current production design.

The PNG is a collaboration artifact, not a second source of truth. Stable
component identity and the consumer's real widget remain authoritative, so this
new audience does not introduce a parallel asset library that can silently
diverge from the application.

## Capture boundary

The capture boundary contains the real consumer widget after its theme,
direction, text scale, bold-text, high-contrast, and reduced-motion values are
applied. It deliberately sits inside the Desy accessibility overlay and canvas
presentation layers. The exported PNG therefore excludes:

- the Desy canvas color and dot grid;
- selection borders, resize handles, and labels;
- accessibility labels and hit-target overlays;
- canvas zoom and fit transforms; and
- device bezels and device-screen background paint.

The boundary has no Desy-owned background. Pixels the consumer widget does not
paint remain transparent. A background intentionally painted by the consumer
widget remains part of the exported component.

## Selection and naming

Only registered components expose the action. Clicking any default, named
instance, or scenario viewer makes that viewer the export target. The current
theme and typed knob values are already part of that live preview; export does
not create another component configuration.

Filenames are derived from stable entry, variant, and theme IDs, normalized for
filesystem safety, and include the fixed scale. For example:

```text
button-primary-dark@2x.png
```

## Platform behavior

- macOS, Windows, and Linux open the platform save-location dialog.
- Web starts a browser PNG download.
- Mobile builds remain supported, but this first slice reports that local image
  saving is unavailable. A future mobile share-sheet flow should be added only
  through a narrowly scoped platform boundary.

Export is local-only. It adds no registry declaration, hosted service, upload,
recipe persistence, golden baseline, or public rendering URL. The internal
typed capture operation can be reused later by a separately designed local CLI
or screenshot-recipe workflow.
