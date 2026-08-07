---
name: desy
description: Understand, explain, implement, or review a Flutter project that uses Desy Bench. Use when working with DesyRegistry, typed atoms, component paths, themes, primitive entries, components, contracts, scenarios, knobs, extensions, real widget previews, sketch layouts, or registry validation without creating a parallel catalogue.
---

# Desy

Treat the consumer-owned `DesyRegistry` as the declared source of truth. Work
from real Dart declarations and production widget builders, not an inferred
JSON schema, screenshot inventory, or copied list.

## Explore safely

1. Read the nearest `AGENTS.md`, `CORE_PRINCIPLES.md`, and maintained Desy docs.
2. Locate the app that constructs `DesyRegistry` and passes it to
   `DesyBenchApp`. Use `rg` before reading broad directories.
3. Trace the requested theme, folder, entry, component, instance, or extension
   by stable ID into its real widget and source path.
4. Read [references/registry-contracts.md](references/registry-contracts.md)
   when changing declarations, composition, or validation.
5. Distinguish consumer code from Desy-owned workbench chrome before editing.

Useful focused queries:

```sh
rg -n "DesyRegistry\(|DesyBenchApp\(" -g '*.dart'
rg -n "DesyComponent\(|DesyNumericEntry|path:" -g '*.dart'
rg -n "id: ['\"]<stable-id>['\"]|source: ['\"]<path>" -g '*.dart'
rg -n "DesyComponentScenario|DesyComponentKnob|Desy.*Extension" -g '*.dart'
```

## Apply the decision gates

- Preserve one immutable registry, its optional typed atom lanes, and its flat
  component list with validated component paths.
- Keep every theme, artifact, showcase, instance, and extension ID
  stable and unique in the shared namespace.
- Make every registered artifact ultimately return the consumer’s real widget.
- Use typed entries, rich domain objects, and semantic names. Do not recover
  meaning from folder labels or stringly typed maps.
- Put numeric values in `DesyNumericEntry`; filter by `kind`, `unit`, and `axis`
  when a workbench feature needs a subset.
- Keep Desy-owned UI on `desy_design_system`; never import Forui directly from
  `desy_bench` or a Desy-owned extension.
- Keep workbench composition state ephemeral unless a separate serializable
  manifest contract is explicitly in scope. Never serialize callbacks.
- Render previews at intended logical dimensions and scale the completed result.
- Ask the consumer only for information Desy cannot derive.

## Explain a registry

Report the registry name, themes, non-empty typed atom lanes, component paths,
components, named instances, scenarios, knobs/contracts, extensions, and source
paths. Mark missing optional declarations as gaps, not errors. Use Desy's
built-in atom taxonomy only for its typed registry lanes; do not invent
additional consumer categories.

## Make a change

1. Identify the smallest public contract and owning package.
2. Preserve immutable collections and existing IDs.
3. Add focused tests for deterministic behavior and failure cases.
4. Run the narrowest package task, then the repository’s canonical check when
   practical. For Desy itself, use `task check`; root `flutter test` is not an
   equivalent workspace verification.
5. Report changed contracts, evidence, limitations, and deferred decisions.
