# Desy Design System

`desy_design_system` owns the foundations and reusable UI used by Desy Bench
itself. It is the deliberate home of the Forui dependency, Desy's workbench
theme bridge, icon vocabulary, controls, native text-entry exception, and
shortcut presentation.

The package does not depend on `desy_bench`. That direction matters:
`desy_bench` consumes this package, while the colocated `example/` application
depends on both packages and owns the dogfood `DesyRegistry`.

```text
Forui
  ↓
desy_design_system ← desy_bench
          ↑                ↑
          └─ example app ──┘
```

## Run the catalogue

From the repository root:

```sh
task dogfood:run_mac
# or
task dogfood:web
```

The catalogue declaration lives in
[`example/lib/src/desy_design_system_registry.dart`](example/lib/src/desy_design_system_registry.dart).
It is the single runtime inventory: foundations and real component builders are
declared there once, then the normal Desy workbench derives navigation, Atlas,
details, instances, and showcases from it.

## Complete element inventory

| Desy API | Foundation element | Current use |
| --- | --- | --- |
| `DesyAccordion`, `DesyAccordionItem` | Forui accordion | Recursive component palette and progressive disclosure |
| `DesyBadge` | Forui badge | Experimental/local metadata |
| `DesyButton`, `DesyButtonVariant`, `DesyButtonSize` | Forui button | Primary, outline, ghost, icon, and disabled actions |
| `DesyCard` | Forui card | Atlas specimens, inspectors, measurements, and extension panels |
| `DesyDialog`, `showDesyDialog` | Forui dialog | Compact navigation and component-instance selection |
| `DesyScaffold` | Forui scaffold | Workbench route surfaces |
| `DesySelect`, `DesySelectControl`, `DesySelectItem` | Forui select | Active preview-theme selection |
| `DesySidebar`, `DesySidebarGroup`, `DesySidebarItem` | Forui sidebar | Registry-derived desktop and compact navigation |
| `DesySwitch` | Forui switch | Boolean component knobs and canvas preferences |
| `DesyTabs`, `DesyTabEntry` | Forui tabs | Assets/layers views in the composition surface |
| `DesyTile` | Forui tile | Selection rows, instance swapping, and canvas outline |
| `DesyTextField` | Native Flutter `TextField` | Search, string knobs, and editable workbench values |
| `DesyKeyboardShortcutLabel` | Desy-owned widget | Discoverable keyboard chords |
| `DesyIcons` | Lucide glyphs supplied by Forui | Stable workbench icon vocabulary |
| `DesyDesignSystemScope` | Forui theme/toast/tooltip + Material bridge | One app-wide Desy chrome host |

The public entrypoint currently re-exports Forui support types so the aliases
remain source-compatible while the system boundary settles. Desy-owned packages
must still import `desy_design_system`, never Forui directly. The root
`task check` enforces this boundary.

## Foundations

`DesyDesignSystemTokens` names the spacing, radii, breakpoint, and motion values
that were previously embedded throughout the workbench. The dogfood registry
also declares the actual neutral light/dark colors, typography roles, numeric
measurements, motion specimens, and floating-surface effect.

Consumer previews remain independent. A design system shown inside Desy may use
Material, Cupertino, Forui, or its own widgets; only Desy-owned chrome uses this
package.

## Verify

```sh
task design_system:test
task dogfood:test
task design_system:forui-boundary
task check
```
