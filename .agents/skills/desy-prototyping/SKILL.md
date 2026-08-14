---
name: desy-prototyping
description: Explore Desy workbench or design-system UI before committing it as a component or scaffold contract. Use when a Desy user asks for visual directions, prototypes, comparisons, or a design experiment involving controls, workbench chrome, panels, inspectors, navigation, accessibility, previews, or registry presentation.
---

# Desy Prototyping

## Workflow

1. Read `AGENTS.md`, `CORE_PRINCIPLES.md`, and the existing consumer registry.
2. State the single question the session must answer. Keep the answer visual or interaction-focused; use the general `$prototype` skill for an isolated throwaway route when registry comparison is not appropriate.
3. Add one immutable `DesyPrototypeSession` to the consumer registry's `prototypes` list. Use stable IDs in the shared registry namespace and place the Flutter code beside the consumer registry, normally under `example/lib/src/prototypes/`.
4. Build two or three contrasting, interactive `DesyPrototype` directions with real Flutter and Desy-owned controls. Keep state local to each prototype; never add a second component list, callbacks to a manifest, or persistence.
5. Make the question and trade-offs legible in the session and direction descriptions. Ensure each direction demonstrates the same user task.
6. Test the consumer registry validation and run the focused dogfood tests. Treat the selected direction as a decision to fold into real code later; leave the session clearly marked `PROTOTYPE` until then.

## Design gates

- Use the registry's `prototypes` lane, not component paths, Custom atoms, or an unregistered debug route.
- Preserve real consumer themes and Desy-owned workbench controls.
- Keep prototypes local-first, keyboard-operable, and readable at system text scales.
- Prototype scaffold/UI hierarchy only; do not approximate consumer preview widgets when a real registered widget exists.
- Avoid production APIs or serialization while the decision is unresolved.
