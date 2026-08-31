import 'package:desy_core/desy_core.dart';
import 'package:flutter/widgets.dart';
import 'package:mrx_design_system/mrx_design_system.dart';

/// Orbit's single source of truth for Desy and local component prototyping.
final DesyRegistry orbitRegistry = DesyRegistry(
  name: 'Orbit',
  identity: const DesyRegistryIdentity(id: 'orbit', version: '0.1.0'),
  themes: [
    DesyTheme(
      id: OrbitThemeData.standard.id,
      name: OrbitThemeData.standard.name,
      description: 'The single dark Orbit theme used by every Orbit widget.',
      previewBackgroundColor: OrbitThemeData.standard.colors.background,
      isDark: true,
      wrap: (context, child) =>
          OrbitTheme(data: OrbitThemeData.standard, child: child),
    ),
  ],
  colors: [
    _color('background', 'Background', OrbitPalettes.standard.background),
    _color('foreground', 'Foreground', OrbitPalettes.standard.foreground),
    _color('card', 'Card', OrbitPalettes.standard.card),
    _color('primary', 'Primary', OrbitPalettes.standard.primary),
    _color('muted', 'Muted', OrbitPalettes.standard.muted),
    _color('border', 'Border', OrbitPalettes.standard.border),
    _color('destructive', 'Destructive', OrbitPalettes.standard.destructive),
    _color('success', 'Success', OrbitPalettes.standard.success),
    _color('warning', 'Warning', OrbitPalettes.standard.warning),
    _color('info', 'Info', OrbitPalettes.standard.info),
  ],
  measurements: const [
    DesyNumericEntry.spacing(
      id: 'orbit.space.content',
      name: 'Content gap',
      value: OrbitTokens.spaceMd,
      description: 'Default space between related controls and content.',
    ),
    DesyNumericEntry.radius(
      id: 'orbit.radius.surface',
      name: 'Surface radius',
      value: OrbitTokens.radiusLg,
      description: 'Default radius for Orbit cards and inputs.',
    ),
    DesyNumericEntry.spacing(
      id: 'orbit.space.control-height',
      name: 'Control height',
      value: OrbitTokens.controlHeight,
      description: 'Minimum height of a compact Orbit control.',
    ),
  ],
  components: [
    DesyStaticComponent(
      id: 'orbit.component.surface',
      name: 'Surface',
      path: '/layout',
      description: 'The default bordered container for Orbit content.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      defaultSize: const Size(360, 144),
      instances: {'default': (_) => const _SurfacePreview()},
    ),
    DesyStaticComponent(
      id: 'orbit.component.button',
      name: 'Button',
      path: '/actions',
      description: 'A labelled action with priority and state feedback.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      defaultSize: const Size(320, 84),
      instances: {
        'primary': (_) => OrbitButton(label: 'Continue', onPressed: () {}),
        'secondary': (_) => OrbitButton(
          label: 'Save draft',
          variant: OrbitButtonVariant.secondary,
          onPressed: () {},
        ),
        'destructive': (_) => OrbitButton(
          label: 'Discard',
          variant: OrbitButtonVariant.destructive,
          onPressed: () {},
        ),
      },
    ),
    DesyStaticComponent(
      id: 'orbit.component.icon-button',
      name: 'Icon button',
      path: '/actions',
      description: 'A compact labelled action represented by a glyph.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      defaultSize: const Size(88, 88),
      instances: {
        'add': (_) => OrbitIconButton(
          label: 'Add item',
          glyph: OrbitGlyphs.add,
          onPressed: () {},
        ),
      },
    ),
    DesyStaticComponent(
      id: 'orbit.component.badge',
      name: 'Badge',
      path: '/status',
      description: 'A compact semantic status label.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      instances: const {
        'success': _successBadgePreview,
        'warning': _warningBadgePreview,
      },
    ),
    DesyStaticComponent(
      id: 'orbit.component.progress',
      name: 'Progress',
      path: '/status',
      description: 'A determinate completion indicator.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      defaultSize: const Size(320, 56),
      instances: const {'default': _progressPreview},
    ),
    DesyStaticComponent(
      id: 'orbit.component.spinner',
      name: 'Spinner',
      path: '/status',
      description: 'An indeterminate progress indicator.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      instances: const {'default': _spinnerPreview},
    ),
    DesyStaticComponent(
      id: 'orbit.component.shortcut-label',
      name: 'Shortcut label',
      path: '/content',
      description: 'A compact keyboard shortcut treatment.',
      source: '../mrx_design_system/lib/src/orbit_theme.dart',
      instances: const {'default': _shortcutPreview},
    ),
    DesyStaticComponent(
      id: 'orbit.component.menu',
      name: 'Overflow menu',
      path: '/actions',
      description: 'An animated action menu with a bordered card surface.',
      source: '../mrx_design_system/lib/src/genui/atoms/orbit_app_menu.dart',
      instances: const {'default': _menuPreview},
    ),
    DesyStaticComponent(
      id: 'orbit.component.text-field',
      name: 'Text field',
      path: '/inputs',
      description: 'A native editable text field styled by the Orbit theme.',
      source:
          '../mrx_design_system/lib/src/genui/atoms/orbit_app_text_field.dart',
      defaultSize: const Size(360, 160),
      instances: {'default': (_) => const _TextFieldPreview()},
    ),
  ],
);

DesyColorEntry _color(String id, String name, Color color) =>
    DesyColorEntry(id: 'orbit.color.$id', name: name, color: color);

class _SurfacePreview extends StatelessWidget {
  const _SurfacePreview();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 360,
    child: OrbitSurface(child: Text('Surface content')),
  );
}

Widget _successBadgePreview(BuildContext context) => const OrbitBadge(
  label: 'Ready',
  tone: OrbitBadgeTone.success,
  glyph: OrbitGlyphs.check,
);

Widget _warningBadgePreview(BuildContext context) =>
    const OrbitBadge(label: 'Needs review', tone: OrbitBadgeTone.warning);

Widget _progressPreview(BuildContext context) =>
    const SizedBox(width: 320, child: OrbitProgress(value: 0.62));

Widget _spinnerPreview(BuildContext context) => const OrbitSpinner();

Widget _shortcutPreview(BuildContext context) => const OrbitShortcutLabel(
  keys: ['⌘', 'K'],
  semanticLabel: 'Open command menu',
);

Widget _menuPreview(BuildContext context) => const OrbitAppMenu(
  label: 'More actions',
  items: [
    OrbitMenuItem(label: 'Archive', onPressed: null),
    OrbitMenuItem(label: 'Delete', onPressed: null, destructive: true),
  ],
);

class _TextFieldPreview extends StatelessWidget {
  const _TextFieldPreview();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 360,
    child: OrbitAppTextField(
      label: 'Workspace name',
      value: '',
      placeholder: 'Name this workspace',
      onChanged: null,
    ),
  );
}
