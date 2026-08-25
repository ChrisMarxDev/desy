# Orbit GenUI design system

Orbit is a consumer-owned, desktop-first design system in the standalone GenUI
exploration. Its optional `desy_genui` adapter demonstrates one integration:
the consumer retains ownership of its visual language, real widgets, theme,
input, and product policy.

## Foundation

Orbit adopts Shadcn's semantic token model rather than naming colors after
their hue. Each mode supplies background/foreground, card, popover, primary,
secondary, muted, accent, border, input, ring, destructive, and semantic
success/warning/info roles. Midnight and Daylight are equal first-class themes
in the consumer registry.

The base radius is 10 logical pixels, derived sizes are 6/8/10/14, and spacing
uses a compact 4/6/8/12/16/24/32 scale. System font fallbacks keep the sample
portable. Motion is short and respects `MediaQuery.disableAnimationsOf`.

Mix is used for reusable surface and pill treatment. The implementation does
not take a dependency on Material's visual controls.

## Interaction and accessibility

Orbit controls are built from Flutter's documented focus, actions, shortcuts,
semantics, pointer-cursor, and editable text primitives.

| Contract | Orbit behavior |
| --- | --- |
| Button state | Default, hover, focus, disabled, keyboard activation, pointer cursor, and semantic button state are explicit. |
| Text entry | The composer wraps native `EditableText`; text selection, IME, undo, and assistive technology remain Flutter/platform behavior. |
| Keyboard | `Ctrl/⌘ + K` focuses the composer; `Ctrl/⌘ + Enter` submits. |
| Status | Agent response changes use a live semantic region. Task, tool, and approval state are conveyed in text as well as color. |
| Motion | Spinner and state transitions stop when reduced motion is requested. |
| Resilience | Response stacks, metric groups, action groups, long labels, and content panes wrap or truncate intentionally rather than relying on fixed text length. |

Orbit does not add a custom gesture coordinator, compatibility input layer, or
bespoke selection implementation. Native Flutter behavior remains the source
of truth for those platform-sensitive concerns.

## Generated component boundary

The registry in
`genui/example/lib/orbit/orbit_registry.dart` declares
stable component IDs and slash paths. It exposes this component vocabulary:

- layout: response stack;
- conversation: insight, recommendation;
- agent: task list, task row, approval request, tool activity;
- data: metric grid, metric tile, source card.

Generated surfaces can set declared values, select declared example instances,
nest into legal slots, and emit typed actions. They do not receive callbacks,
navigation, database access, secret values, or ownership of the chat composer.
The app decides whether to forward a typed action to the backend.

## Verification

The sample's tests verify the catalog identity, both themes, the full
component set, native composer rendering and keyboard focus, prompt-to-A2UI
replacement, action forwarding, and local action policy. `flutter analyze`,
the example test suite, and a web build validate the executable boundary.
