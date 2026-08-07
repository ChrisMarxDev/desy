# Desy registry contracts

## Declaration map

| Concern | Authoritative declaration | Key rule |
| --- | --- | --- |
| Theme context | `DesyTheme` | Wrap previews with the real consumer theme. |
| Structure | Recursive `DesyFolder` | Organize existing entries; do not create a flat parallel index. |
| Colors and treatments | `DesyColorEntry` | Swatches, gradients, and custom color widgets stay under `Atoms/Colors`. |
| Typography | `DesyTypographyEntry` | Resolve a real consumer text style and specimen. |
| Measurements | `DesyNumericEntry` | Use `kind`, `unit`, and `axis`; do not infer semantics from strings. |
| Motion and effects | Typed motion/effect entries | Keep the consumer-owned live specimen. |
| Components | `DesyComponent` | Build the production widget and declare optional contracts, states, and knobs. |
| Reusable variants | `DesyComponentInstance` | Store stable preset values; resolve through the owning component. |
| Component slots | `DesyComponentKnob` | Store legal registered instance IDs, never widget callbacks. |
| Routed tools | `DesyWorkspaceExtension` | Receive the same app-wide registry through a typed context. |
| Detail tools | `DesyDetailExtension` | Attach to a resolved component without creating navigation or registry state. |

## Good declarations

```dart
DesyNumericEntry.spacing(
  id: 'acme.space.content',
  name: 'Content gap',
  value: AcmeSpacing.content,
  description: 'Separates related fields and card content.',
)

DesyComponent(
  id: 'acme.button.primary',
  name: 'Primary button',
  source: 'lib/src/button.dart',
  preview: (context) => const AcmeButton(label: 'Continue'),
)
```

The IDs are stable, the value/widget remains consumer-owned, and Desy receives
only metadata it cannot derive.

## Reject these patterns

- A second `List<ComponentCard>` copied from `registry.allComponents`.
- A map such as `{'type': 'spacing', 'value': '16px'}` beside a typed numeric
  entry.
- A compact fake button built only for the catalogue.
- A persisted callback, widget object, or application state machine.
- Folder-name parsing to decide whether a number means spacing or radius.
- A direct Forui import in `desy_bench` or a Desy-owned extension.
