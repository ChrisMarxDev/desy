# Screenshot builder

The experimental `desy_screenshot_builder` workspace extension is an
ephemeral image-composition surface. It lets a user arrange real registered
Flutter widget instances, local images, and registry-styled text on one
custom-size canvas and export that canvas as a PNG.

## Ownership and data flow

- The active consumer `DesyRegistry` remains the only component, typography,
  color, and theme inventory.
- Widget layers store a registered instance ID and an independent local knob
  value map. They resolve the consumer's real widget on every build.
- Image bytes, text content, geometry, z-order, visibility, and page settings
  live only in an extension-owned controller for the current mounted session.
- No scene value is written to disk or treated as a future persistence format.
- The selected consumer theme wraps the logical canvas before capture.

## V1 workflow

The standalone extension owns a resizable sidebar with three views:

1. **Elements** lists registry-derived component instances and the built-in
   Text and Image additions. Widgets and text may be clicked or dragged onto
   the canvas; image files may be picked or dropped from the host platform.
2. **Scene** selects layers and shows their stack order and visibility. A
   dedicated, resizable inspector beside the tabbed sidebar changes the
   selected layer's order and visibility, deletes it, and edits widget knobs or
   text content, typography, and color without hiding the scene or page tools.
3. **Page** sets exact custom width and height, consumer theme, background or
   transparency, and starts PNG export.

Canvas zoom and pan affect only workbench presentation. Element rectangles and
page dimensions remain logical Flutter pixels. Resizing a widget changes the
real constraints supplied to it. A separate `0.1×`–`2×` widget scale changes
its visual footprint while retaining those logical constraints.

The export boundary contains the page background and visible scene layers,
but not selection frames, resize handles, canvas chrome, or the transparent
checkerboard. V1 produces one PNG pixel for each logical canvas pixel.

## Deliberate non-goals

- Projects, multiple pages, persistence, autosave, history, or collaboration.
- Undo/redo, grouping, rotation, rulers, manual guides, or arbitrary effects.
- Rich text, generated production widgets, or a serialized Flutter widget
  language.

Those capabilities need separate evidence and contracts; this experimental
surface must not make its in-memory scene model a de facto file format.
