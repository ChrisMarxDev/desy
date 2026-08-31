---
name: state-beacon
description: Build clear, local Flutter feature state with state_beacon controllers. Use when adding reactive controller state, provider selection, async request state, or resource lifecycles in this repository.
---

# State Beacon

Use `state_beacon` to give a feature or app boundary one explicit owner for
mutable state. Keep the controller small, typed, and local to the feature.

## Controller pattern

- Create a controller with `with BeaconController`.
- Declare owned reactive values with `late final value = B.writable<T>(initial)`.
- Expose intent methods (`selectProvider`, `respond`, `reset`) instead of
  letting widgets mutate controller beacons ad hoc.
- Widgets subscribe only to the values they render with `beacon.watch(context)`.
  Do not call `watch` in callbacks or long-running async work.
- Keep ordinary ephemeral widget mechanics (a text field controller, focus
  node, animation controller) in the widget when no other surface needs them.

## Async and lifecycle rules

- Model request activity with a typed beacon owned by the controller; guard
  duplicate requests before starting async work and clear it in `finally`.
- A controller that creates a client, stream subscription, process bridge, or
  other resource must dispose it before `super.dispose()`.
- Switching a selected provider or model releases the previous provider client
  before constructing the next one. Reject either change during an active
  request.
- Keep errors useful to the user, but avoid putting transient display-only
  layout state into a global controller.

## GenUI application boundary

`experiments/genui/orbit_app/lib/ai/orbit_ai_controller.dart` is the app-owned
AI routing boundary. It holds the selected provider, selected model, and local
runtime readiness; creates the matching GenUI backend; owns backend lifecycle;
and routes provider-neutral GenUI turns. Do not add `GENUI_DRIVER` flags or
provider-specific backend creation to screens. Add future LLM request families
to this controller or to a typed child controller owned by it.

Codex's streaming app-server transport remains provider-specific behind its
backend. Claude's structured print bridge remains provider-specific behind its
backend. The UI may inspect the selected provider only for provider-specific
workflows, never for backend construction or disposal.

## Verification

- Add controller tests for default state, provider/model switching, runtime
  status refresh, request routing, duplicate-request behavior, and disposal of
  replaced resources.
- Run the focused Flutter tests and `flutter analyze` in the owning package.
