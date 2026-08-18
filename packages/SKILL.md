---
name: desy-packages
description: Work safely in the Desy Flutter package workspace.
---

# Desy packages

Use this guidance for work under `packages/`.

## Package ownership

- `desy_bench` owns the public registry contracts and reusable workbench.
- `desy_design_system` owns Desy's private, Forui-backed scaffold UI.
- `desy_design_system/example` is the maintained dogfood executable and the
  public-contract integration proof.
- `extensions/` contains optional experiments; do not make them a required
  dependency of the core workbench path.

## Registry and preview rules

- The consuming repository's immutable `DesyRegistry` is the only source of
  truth. Do not create copied component lists, parallel trees, or JSON widget
  inventories.
- Registered artifacts always render the consumer's actual Flutter widget
  under the consumer's declared `DesyTheme` wrapper.
- Components remain one flat registry list organized by validated slash paths.
  Use typed atom lanes for foundations; Custom atoms are named, knobless widget
  instances in Desy's one built-in `Atoms / Custom` lane.
- Keep advanced features opt-in and local-first. Do not add hosted state,
  embedded coding-agent requirements, or production code generation to core.

## Dependency boundary

- Only `desy_design_system` imports Forui directly.
- `desy_bench` consumes Desy-owned controls from `desy_design_system`; its
  public API must not expose Forui types.
- The Git distribution path is `packages/desy_bench`; its private scaffold
  dependency resolves from the same Git repository at `packages/desy_design_system`.

## Verification

- Run the narrowest relevant package tests while working.
- `task check` is the final workspace verification command.
- For dogfood changes, run `task dogfood:test`.
- Preserve existing user changes in this shared workspace; do not revert or
  reformat unrelated work.
