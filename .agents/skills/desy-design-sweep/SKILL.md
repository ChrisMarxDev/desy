---
name: desy-design-sweep
description: Run a review-only, evidence-backed design-system audit of a Desy consumer. Use when asked to sweep, audit, critique, or assess spacing, typography, colors, radii, semantic tokens, components, states, accessibility, responsiveness, registry quality, preview fidelity, or duplicated and unused declarations.
---

# Desy Design Sweep

Produce a small set of reproducible, issue-sized findings. Default to review
only; do not modify code, update goldens, or create issues unless explicitly
authorized.

Read [references/report-schema.md](references/report-schema.md) before writing
the report. Use the `desy` skill alongside this skill when available.

## Establish the audit surface

1. Read project instructions and find the consumer’s `DesyRegistry`.
2. Record the themes, folders, measurements, typography, colors, components,
   named instances, scenarios, contracts, knobs, extensions, and source paths.
3. Select the themes, scenarios, states, and viewport widths actually covered.
4. State exclusions and unavailable evidence before reporting findings.

## Collect deterministic evidence first

- Search typed declarations for repeated raw spacing, radius, color, and type
  values; verify each candidate at its production use site.
- Validate stable IDs, recursive folder placement, source paths, descriptions,
  contracts, knob options, scenario coverage, and unused declarations.
- Confirm previews build real widgets under real themes at intended logical
  dimensions.
- Inspect tests for loading, empty, error, disabled, selected, hover/focus, text
  scale, semantics, keyboard order, and narrow/wide layouts.
- Run focused existing checks when read-only execution is safe. Never update
  snapshots or goldens during review-only mode.

Use screenshots or runtime inspection only for questions source cannot settle.
Label visual conclusions as hypotheses until reproduced through code, semantics,
or a deterministic test.

## Review categories

- Semantic token coverage and duplicated raw values.
- Spacing, typography, color, radius, stroke, and elevation consistency.
- Component API clarity, legal slots, meaningful instances, and contracts.
- Loading, empty, error, disabled, selected, focus, and responsive states.
- Semantics, labels, roles, actions, focus order, target size, contrast, and text
  scaling.
- Visual hierarchy, density, alignment, overflow, and viewport behavior.
- Registry IDs, folder placement, descriptions, source links, and dead entries.
- Fake previews, artificial compact constraints, parallel inventories, or direct
  Desy-owned Forui usage.

## Triage rigorously

- Report only findings with a concrete user or maintenance consequence.
- Consolidate repeated symptoms under one root cause.
- Use severity from the report schema; do not inflate cosmetic differences.
- Separate `Verified` findings from `Hypothesis` and `Coverage gap` items.
- Cite stable registry IDs, paths, lines when known, theme/scenario/viewport,
  and the command or observation that reproduces the issue.
- Recommend the smallest fix that preserves the consumer registry as the source
  of truth. Keep each recommendation suitable for one issue or focused PR.

Finish with the highest-value next action and the exact check that would prove
it complete.
