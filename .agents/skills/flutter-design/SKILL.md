---
name: flutter-design
description: Design or reshape clear, cohesive, accessible Flutter interfaces using simple native primitives. Use when creating or reviewing Flutter screens, widgets, settings panels, forms, controls, responsive arrangements, typography, spacing, colour, or interaction states. Apply for reusable Flutter UI work; do not assume Desy, a registry, or any particular component library.
---

# Flutter Design

Create interfaces that are readable before they are decorative. Use the app's real theme and real widgets; preserve the user's visual direction and platform conventions.

## Workflow

1. Identify the screen's single job, primary action, audience, and constraints. Read an existing theme or design system before inventing a visual language.
2. Start with simple Flutter primitives: `Padding`, `SizedBox`, `Column`, `Row`, `Wrap`, `Expanded`, `ConstrainedBox`, `Divider`, `Material`, and semantic controls. Add a custom component only when the structure or behaviour repeats.
3. Establish hierarchy before visual polish: stable title and context first, then grouped controls or content, then secondary detail. Use spacing and alignment as the primary grouping tools; add a surface only when it creates a meaningful container.
4. Use the accepted rules in [references/rules.md](references/rules.md). Apply the relevant groups rather than turning every rule into a checklist.
5. Build states deliberately: default, selected, disabled, focus, error, empty, long-text, and system text-scale states. Keep keyboard focus visible and controls operable without colour alone.
6. Verify the real widget under the app's real `ThemeData`. For a reusable component, compare focused alternatives in a small Flutter prototype before committing a public API.

## Flutter translation

- Use semantic roles from `ThemeData`, `ColorScheme`, and `TextTheme`; centralise shared decisions instead of recreating local near-matches.
- Use a compact spacing scale with `SizedBox` and `EdgeInsets`; use a visibly larger spacing step to separate unrelated groups.
- Keep explanatory text within a readable maximum width using `ConstrainedBox`.
- Preserve a component's intended constraints in a demo or preview. Do not make it appear compact by passing unrealistic constraints.
- Use `Semantics`, visible labels, 44×44 logical-pixel touch targets where practical, and Flutter's focus/action system for custom interactive controls.

## Boundaries

- Keep this skill Flutter-general. Do not require Desy, a registry, Forui, or a specific design-system package.
- Do not replace an app's established brand, type scale, colour roles, or interaction patterns without a requested redesign.
- Do not blindly port CSS. Translate the visual intent into Flutter layout, theming, and semantics.
