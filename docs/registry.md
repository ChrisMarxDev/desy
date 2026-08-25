# Desy registry

`DesyRegistry` is the one consumer-owned declaration of a design system. It
contains the real themes, primitives, components, and optional explorations
that Desy displays. Desy derives navigation and tools from this declaration; do
not make a second catalogue, folder tree, or preview-only widget collection.

Import Desy from the package your app depends on:

```dart
import 'package:flutter/material.dart';
import 'package:desy_bench/desy_bench.dart';
```

## Start with a minimal registry

Only `name` and a non-empty `themes` list are required. A theme wrapper is how
Desy renders every preview under your application's real inherited theme.

```dart
final acmeRegistry = DesyRegistry(
  name: 'Acme Design System',
  themes: [
    DesyTheme(
      id: 'acme.theme.light',
      name: 'Light',
      wrap: (context, child) => Theme(
        data: ThemeData.light(),
        child: child,
      ),
    ),
  ],
);
```

The example highlights the minimum viable registry. In a real app, `wrap`
should apply your own theme scope, not construct a replacement theme for Desy.

## Registry parameters

All declaration lists are copied into immutable collections when the registry
is created. Add entries by rebuilding the registry in source, never by mutating
it at runtime.

| Parameter | Required | What it declares |
| --- | --- | --- |
| `name` | Yes | The human-readable design-system name. |
| `themes` | Yes | At least one `DesyTheme` wrapper for real consumer previews. |
| `identity` | No | A stable ID and compatibility version for a registry that crosses a process or repository boundary. |
| `systemProfile` | No | Authored Home context: purpose, principles, hero asset, and links. |
| `homePage` | No | A consumer-owned Home widget. Without it, Desy shows its derived overview. |
| `tokens` | No | Generic widget-returning token specimens. Prefer a typed atom lane when one fits. |
| `colors` | No | Literal semantic colors for the Colors board. |
| `fonts` | No | Real consumer text-style specimens for the Fonts board. |
| `measurements` | No | Typed numeric values for the Measurements board. |
| `icons` | No | Real Flutter icon glyphs for the Icons board. |
| `assets` | No | Packaged image assets for the Assets board. |
| `customAtoms` | No | Knobless, named real-widget instances for the Custom board. |
| `components` | No | Real reusable widgets in the derived component tree. |
| `prototypes` | No | Comparable, ordinary Flutter directions that are not durable components yet. |

The six typed atom lanes are Colors, Fonts, Icons, Measurements, Assets, and
Custom. Desy shows only non-empty lanes and omits Atoms entirely when none are
declared.

## Give the registry a portable identity

Use `identity` only when another capability needs to refer to the complete
registry outside its local workbench—for example, a portable catalog adapter.
The `id` and `version` are both non-empty, consumer-owned stable strings.

```dart
identity: const DesyRegistryIdentity(
  id: 'acme.design-system',
  version: '1.0.0',
),
```

This sample highlights identity. Local-only Desy use does not need one.

## Describe the system Home

`systemProfile` adds facts that Desy cannot infer. It is not another inventory:
the registry remains the source of components, atoms, and assets.

```dart
systemProfile: DesySystemProfile(
  id: 'acme.system-profile',
  summary: 'A calm, accessible system for account management.',
  purpose: 'Help customers complete financial tasks with confidence.',
  heroAssetId: 'acme.asset.hero',
  principles: const [
    DesySystemPrinciple(
      id: 'acme.principle.clarity',
      title: 'Make the next step clear',
      guidance: 'Use one primary action per decision.',
    ),
  ],
  links: [
    DesySystemLink(
      id: 'acme.link.source',
      label: 'Source',
      uri: Uri.parse('https://github.com/acme/app'),
      role: DesySystemLinkRole.source,
    ),
  ],
),
```

The example highlights authored system context. `heroAssetId` must reference
an ID in `assets`; Desy reports an unknown hero asset as a warning.

`homePage` is the optional alternative Home body. It receives the current build
context, including the selected consumer theme. Keep it focused on your system;
do not use it to maintain a parallel component list.

```dart
homePage: (context) => const AcmeSystemHome(),
```

## Wrap every preview in a real theme

Each `DesyTheme` has a stable `id`, displayed `name`, and required `wrap`
callback. `description` helps people choose a theme,
`previewBackgroundColor` sets the canvas behind previews, and `isDark` opts
Desy's own chrome into its dark treatment. `isDark` does not theme your widget:
`wrap` always remains responsible for that.

```dart
DesyTheme(
  id: 'acme.theme.dark',
  name: 'Dark',
  description: 'Low-light account-management surfaces.',
  previewBackgroundColor: const Color(0xFF101114),
  isDark: true,
  wrap: (context, child) => AcmeThemeScope.dark(child: child),
),
```

This sample highlights the dark-workbench opt-in. Do not select themes by
changing component constraints or by registering compact substitute widgets.

## Register typed atoms

Typed atom lanes let Desy provide a purpose-built board without inferring a
primitive's meaning from an ID or folder name.

### Colors

`DesyColorEntry` accepts a literal Flutter `Color`: `id`, `name`, and `color`
are required; `description` explains intended use. Gradients and other paint
recipes are not color entries.

```dart
colors: const [
  DesyColorEntry(
    id: 'acme.color.action',
    name: 'Action',
    color: Color(0xFF2457F5),
    description: 'Use for the primary action in a contained flow.',
  ),
],
```

This sample highlights a semantic solid color.

### Fonts

`DesyTypographyEntry` requires `id`, `name`, and `builder`. The builder renders
the supplied sample text using your real typography. `value`, `description`,
and `sample` are optional display guidance.

```dart
fonts: [
  DesyTypographyEntry(
    id: 'acme.type.title',
    name: 'Page title',
    value: '24 sp / 600',
    builder: (context, text) => Text(
      text,
      style: AcmeTypography.of(context).pageTitle,
    ),
  ),
],
```

This sample highlights a real consumer text-style specimen.

### Measurements

`DesyNumericEntry` requires `id`, `name`, and a numeric `value`. Use the
named constructors (`spacing`, `size`, `radius`, or `breakpoint`) when they
fit; they assign the semantic `kind` without string parsing. The general
constructor also accepts `unit`, `kind`, `axis`, `description`, and an optional
real-widget `builder`.

```dart
measurements: const [
  DesyNumericEntry.spacing(
    id: 'acme.space.content',
    name: 'Content gap',
    value: 16,
    description: 'Separates related fields and card content.',
  ),
],
```

This sample highlights the typed spacing constructor. Use `axis` for a spacing
or size that is only horizontal or vertical.

### Icons

`DesyIconEntry` requires `id`, `name`, and the real Flutter `IconData`.
`description`, source-facing `value`, `semanticLabel`, and `size` are optional.

```dart
icons: const [
  DesyIconEntry(
    id: 'acme.icon.add',
    name: 'Add',
    icon: Icons.add,
    semanticLabel: 'Add item',
  ),
],
```

This sample highlights the accessible icon label.

### Assets

`DesyAssetEntry` requires a stable `id`, download `fileName`, Flutter bundle
`assetKey`, and usage `description`. Declare the same `assetKey` in your app's
`pubspec.yaml`; Desy renders and exports that bundled asset.

```dart
assets: const [
  DesyAssetEntry(
    id: 'acme.asset.hero',
    fileName: 'account-hero.png',
    assetKey: 'assets/images/account-hero.png',
    description: 'Use on account overview introductions.',
  ),
],
```

This sample highlights the Flutter asset key.

### Custom atoms and generic tokens

Use `DesyCustomAtom` for a foundational visual that does not fit a typed lane.
It requires `id`, `name`, and at least one named real-widget `instance`; it has
no knobs. The first declared instance is the compact preview.

```dart
customAtoms: [
  DesyCustomAtom(
    id: 'acme.atom.status-strip',
    name: 'Status strip',
    instances: {
      'default': (_) => const AcmeStatusStrip(),
    },
  ),
],
```

This sample highlights a knobless custom atom. `tokens` remains available for
a generic widget-returning primitive, but it has no specialized atom board.
Prefer one of the typed lanes above whenever possible.

```dart
tokens: [
  DesyToken(
    id: 'acme.token.elevation.raised',
    name: 'Raised elevation',
    value: '4 dp',
    group: 'Elevation',
    builder: (_) => const AcmeRaisedSurface(),
  ),
],
```

This sample highlights a generic token specimen. `value`, `description`, and
`group` are optional display metadata; `builder` is required and must return
your real consumer widget.

## Register real components

`components` is one flat list. `path` is a validated slash path that Desy turns
into a file tree; it is never a second folder declaration. Paths use lowercase
kebab-case segments, such as `/inputs/text`; `/` is the root.

Use `DesyComponent` when a real widget has editable values. It requires `id`,
`name`, `knobs`, and `build`. The `knobs` callback declares the immutable typed
input record once, and `build` returns the production widget from that record.
For the full knob API, see [Knobs](knobs.md).

```dart
components: [
  DesyComponent(
    id: 'acme.button',
    name: 'Button',
    path: '/actions/buttons',
    knobs: (k) => (
      label: k.string('label', initial: 'Continue'),
    ),
    build: (context, knobs) => AcmeButton(label: knobs.label.value),
  ),
],
```

This sample highlights one typed knob flowing directly into the real widget.

`instances` supplies stable presets as knob overrides. They are not extra
widgets or another catalogue. The remaining optional component parameters are
`icon`, `description`, `category`, `accessibility`, `source`, `defaultSize`,
`contract`, and `scenarios`:

| Parameter | What it adds |
| --- | --- |
| `instances` | Named preset values for the same production builder. |
| `icon` | A navigation and component-picker icon. |
| `description` | Intent and usage guidance. |
| `category` | A consumer-facing category label; defaults to `Components`. |
| `accessibility` | A requirement reviewers should preserve. |
| `source` | The consumer source path used for navigation and review. |
| `defaultSize` | A recommended initial logical size on a composition canvas. |
| `contract` | Documented public properties, slots, and guidance. |
| `scenarios` | Named real-widget states beside the default preview. |

```dart
instances: (knobs) => {
  'primary': [knobs.label('Continue')],
  'destructive': [knobs.label('Delete account')],
},
```

This sample highlights preset overrides. A component instance resolves to the
stable ID `acme.button.primary` or `acme.button.destructive`.

Use `DesyStaticComponent` when the component has no editable inputs. It
requires `id`, `name`, and a map of named widget `instances`; it accepts the
same presentation metadata as `DesyComponent`, except for knobs and `build`.

```dart
DesyStaticComponent(
  id: 'acme.loading',
  name: 'Loading indicator',
  path: '/feedback',
  instances: {
    'default': (_) => const AcmeLoadingIndicator(),
  },
),
```

This sample highlights a component with a fixed real-widget instance.

Use `DesyAnimationComponent` only when the component itself needs a
workbench-controlled playback progress value. It has the same component
parameters as `DesyComponent`, plus required `duration`, `curve`, and an
animation-aware `builder`.

```dart
DesyAnimationComponent(
  id: 'acme.motion.card-enter',
  name: 'Card enter',
  path: '/motion',
  duration: const Duration(milliseconds: 180),
  curve: Curves.easeOutCubic,
  knobs: (_) {},
  builder: (context, knobs, progress) => AcmeEnteringCard(progress: progress),
),
```

This sample highlights Desy's ephemeral playback progress; it does not create
a separate motion inventory.

## Keep explorations beside the system

`prototypes` holds ordinary Flutter directions that help a team compare work
before promoting it to a durable component. A `DesyPrototypeSession` requires
an `id`, `name`, and non-empty `prototypes` list. Each `DesyPrototype` requires
an `id`, `name`, and real-widget `builder`; `description` and `canvasPlacement`
are optional.

```dart
prototypes: [
  DesyPrototypeSession(
    id: 'acme.prototype.checkout',
    name: 'Checkout directions',
    prototypes: [
      DesyPrototype(
        id: 'acme.prototype.checkout.one-column',
        name: 'One column',
        builder: (_) => const AcmeCheckoutOneColumn(),
      ),
    ],
  ),
],
```

This sample highlights a comparison session, not a persisted layout or a
production component declaration.

## Validate and run

All themes, profile entries, atoms, components, named instances, prototypes,
and extension IDs share one stable ID space. Desy validates duplicates and bad
component references without mutating your declaration. An unknown
widget-instance reference or Home hero asset is reported as a warning.

```dart
final issues = acmeRegistry.validate();
```

This sample highlights explicit validation. `DesyBenchApp` also validates the
registry when the workbench starts.

For a standalone catalogue, pass the one registry to the launcher:

```dart
void main() => runDesyBenchApp(registry: acmeRegistry);
```

This sample highlights the single app-wide access path. Extensions receive that
same registry from the workbench; they do not add a parallel registry.
