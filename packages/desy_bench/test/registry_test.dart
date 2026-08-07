import 'package:desy_bench/desy_bench.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('typed atom lanes are optional registry parameters', () {
    final registry = DesyRegistry(
      name: 'Typed atoms',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      fonts: [
        DesyTypographyEntry(
          id: 'type.body',
          name: 'Body',
          builder: (_, text) => Text(text),
        ),
      ],
    );

    expect(registry.fonts, hasLength(1));
    expect(registry.atomKinds, [DesyAtomKind.fonts]);
    expect(
      registry.entriesForAtom(DesyAtomKind.fonts).single.path,
      'Atoms / Fonts',
    );
    expect(registry.hasAtoms, isTrue);
    expect(() => registry.fonts.clear(), throwsUnsupportedError);
  });

  test('registry requires at least one consumer theme', () {
    expect(
      () => DesyRegistry(name: 'Empty', themes: const []),
      throwsAssertionError,
    );
  });

  test('theme retains the consumer wrapper', () {
    const theme = DesyTheme(
      id: 'sample.light',
      name: 'Sample light',
      wrap: _wrap,
    );

    expect(theme.id, 'sample.light');
  });

  test('asset entries retain typed image, GIF, video, and audio resources', () {
    const provider = AssetImage('assets/logo.png');
    const image = DesyAssetEntry.image(
      id: 'asset.logo',
      name: 'Logo',
      image: provider,
      semanticLabel: 'Company logo',
    );
    const gif = DesyAssetEntry.gif(
      id: 'asset.loading',
      name: 'Loading',
      image: AssetImage('assets/loading.gif'),
    );
    final video = DesyAssetEntry.video(
      id: 'asset.intro',
      name: 'Introduction',
      source: Uri.parse('assets/video/intro.mp4'),
    );
    final audio = DesyAssetEntry.audio(
      id: 'asset.confirmation',
      name: 'Confirmation',
      source: Uri.parse('assets/audio/confirmation.wav'),
    );

    expect(image.image, same(provider));
    expect(image.kind, DesyAssetKind.image);
    expect(image.semanticLabel, 'Company logo');
    expect(image.fit, BoxFit.contain);
    expect(gif.kind, DesyAssetKind.gif);
    expect(gif.image, isA<AssetImage>());
    expect(video.kind, DesyAssetKind.video);
    expect(video.displayValue, 'assets/video/intro.mp4');
    expect(audio.kind, DesyAssetKind.audio);
    expect(audio.group, 'Sounds');
  });

  testWidgets('icon entries resolve through the built-in Icons lane', (
    tester,
  ) async {
    const icon = DesyIconEntry(
      id: 'icon.anchor',
      name: 'Anchor',
      icon: IconData(0xe001),
      semanticLabel: 'Anchor point',
      value: 'AppIcons.anchor',
    );
    final registry = DesyRegistry(
      name: 'Icons',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      icons: const [icon],
    );

    expect(registry.allIcons, [icon]);
    expect(registry.resolve(icon.id)?.path, 'Atoms / Icons');
    expect(registry.resolve(icon.id)?.source, same(icon));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: icon.build),
      ),
    );
    final rendered = tester.widget<Icon>(find.byType(Icon));
    expect(rendered.icon, icon.icon);
    expect(rendered.semanticLabel, 'Anchor point');
    expect(rendered.size, isNull);
  });

  test('workspace extension builder does not require sidebar metadata', () {
    final extension = DesyWorkspaceExtension.builder(
      id: 'release-notes',
      name: 'Release notes',
      builder: (context, extension) => const SizedBox(),
    );

    expect(extension.icon, isNull);
    expect(extension.description, isNull);
  });

  test('component paths derive groups while effects stay registry-level', () {
    final registry = DesyRegistry(
      name: 'Nested',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      effects: [
        DesyEffectEntry.boxShadow(
          id: 'effect.status',
          name: 'Status shadow',
          shadows: [BoxShadow(blurRadius: 8)],
        ),
      ],
      components: [
        DesyComponent(
          id: 'status.badge',
          name: 'Status badge',
          path: '/feedback/status',
          preview: (_) => const SizedBox(),
        ),
      ],
    );

    expect(registry.allComponents.single.id, 'status.badge');
    expect(registry.allEffects.single.id, 'effect.status');
  });

  test('registry exposes showcases and resolved token entries', () {
    final registry = DesyRegistry(
      name: 'Nested',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      tokens: [
        DesyToken(
          id: 'brand',
          name: 'Brand',
          value: '#006B63',
          builder: (_) => const SizedBox(),
        ),
      ],
      showcases: [
        DesyShowcase(
          id: 'status-overview',
          name: 'Status overview',
          builder: (_) => const SizedBox(),
        ),
      ],
    );

    expect(registry.resolve('brand')?.path, 'Root');
    expect(registry.resolve('brand')?.folderIds, isEmpty);
    expect(registry.resolve('brand')?.routePath, isEmpty);
    expect(registry.allShowcases.single.id, 'status-overview');
  });

  test('component paths normalize equivalent slash syntax', () {
    final registry = DesyRegistry(
      name: 'Normalized paths',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyComponent(
          id: 'plain',
          name: 'Plain',
          path: 'input',
          preview: _emptyPreview,
        ),
        DesyComponent(
          id: 'slashed',
          name: 'Slashed',
          path: '/input/',
          preview: _emptyPreview,
        ),
        DesyComponent(
          id: 'nested',
          name: 'Nested',
          path: '//input//text//',
          preview: _emptyPreview,
        ),
      ],
    );

    expect(registry.resolve('plain')?.component?.path, '/input');
    expect(registry.resolve('slashed')?.component?.path, '/input');
    expect(registry.resolve('nested')?.component?.path, '/input/text');
    expect(registry.componentGroups.map((group) => group.path), ['/input']);
    expect(registry.componentGroups.single.children.single.path, '/input/text');
  });

  test('global ID validation includes artifacts and extensions', () {
    final registry = DesyRegistry(
      name: 'Duplicate IDs',
      themes: const [DesyTheme(id: 'shared', name: 'Same label', wrap: _wrap)],
      components: [
        DesyComponent(id: 'shared', name: 'Same label', preview: _emptyPreview),
      ],
    );

    expect(
      registry
          .validate(extensionIds: const ['shared'])
          .map((issue) => issue.id),
      ['shared', 'shared'],
    );
  });

  test('component path labels are derived from kebab case', () {
    final registry = DesyRegistry(
      name: 'Derived labels',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyComponent(
          id: 'primary-button',
          name: 'Primary button',
          path: '/form-controls/action-buttons',
          preview: _emptyPreview,
        ),
      ],
    );

    final entry = registry.resolve('primary-button')!;
    expect(entry.folderNames, ['Form controls', 'Action buttons']);
    expect(entry.path, 'Form controls / Action buttons');
  });

  test('component paths reject traversal and invalid segments', () {
    expect(
      () => DesyComponent(
        id: 'traversal',
        name: 'Traversal',
        path: '/input/../secret',
        preview: _emptyPreview,
      ),
      throwsArgumentError,
    );
    expect(
      () => DesyComponent(
        id: 'spaces',
        name: 'Spaces',
        path: '/Input fields',
        preview: _emptyPreview,
      ),
      throwsArgumentError,
    );
  });

  test('registry collections are unmodifiable', () {
    final registry = DesyRegistry(
      name: 'Immutable',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
    );

    expect(
      () => registry.themes.add(registry.themes.single),
      throwsUnsupportedError,
    );
    expect(
      () => registry.allEntries.add(
        DesyRegistryEntry(
          id: 'new',
          name: 'New',
          folderIds: const [],
          folderNames: const [],
          builder: _emptyPreview,
          source: 'new',
        ),
      ),
      throwsUnsupportedError,
    );
    expect(registry.hasAtoms, isFalse);
  });

  test('nested declaration collections are defensive immutable copies', () {
    final shadows = <BoxShadow>[const BoxShadow(blurRadius: 4)];
    final values = <String, Object>{'label': 'Initial'};
    final instances = <DesyComponentInstance>[
      DesyComponentInstance(id: 'icon', name: 'Icon'),
    ];
    final options = <String>['component.icon'];
    final properties = <DesyContractProperty>[
      const DesyContractProperty(name: 'label', type: 'String'),
    ];
    final effect = DesyEffectEntry.boxShadow(
      id: 'shadow',
      name: 'Shadow',
      shadows: shadows,
    );
    final knob = DesyComponentKnob(
      id: 'slot',
      name: 'Slot',
      initial: 'component.icon',
      options: options,
    );
    final contract = DesyComponentContract(properties: properties);
    final component = DesyComponent(
      id: 'component',
      name: 'Component',
      preview: _emptyPreview,
      knobs: [knob],
      instances: instances,
      scenarios: [
        DesyComponentScenario(
          id: 'default',
          name: 'Default',
          builder: _emptyPreview,
        ),
      ],
      contract: contract,
    );
    final knobValues = DesyKnobValues(values);

    shadows.clear();
    values['label'] = 'Changed';
    options.clear();
    instances.clear();
    properties.clear();

    expect(effect.shadows, hasLength(1));
    expect(knob.options, hasLength(1));
    expect(contract.properties, hasLength(1));
    expect(component.knobs, hasLength(1));
    expect(component.instances, hasLength(1));
    expect(component.scenarios, hasLength(1));
    expect(knobValues.string('label'), 'Initial');
    expect(() => effect.shadows.clear(), throwsUnsupportedError);
    expect(() => knob.options.clear(), throwsUnsupportedError);
    expect(() => contract.properties.clear(), throwsUnsupportedError);
    expect(() => component.scenarios.clear(), throwsUnsupportedError);
    expect(() => knobValues.entries.clear(), throwsUnsupportedError);
  });

  testWidgets('box-shadow effects decorate the supplied widget', (
    tester,
  ) async {
    final effect = DesyEffectEntry.boxShadow(
      id: 'effect.surface',
      name: 'Surface shadow',
      shadows: [BoxShadow(blurRadius: 12, offset: Offset(0, 4))],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => effect.apply(
            context,
            const SizedBox(key: ValueKey('effect-child')),
          ),
        ),
      ),
    );

    final decoration = tester.widget<DecoratedBox>(find.byType(DecoratedBox));
    final box = decoration.decoration as BoxDecoration;
    expect(box.boxShadow, effect.shadows);
    expect(find.byKey(const ValueKey('effect-child')), findsOneWidget);
  });

  test('numeric primitives retain their typed value and display unit', () {
    const entry = DesyNumericEntry(
      id: 'space.md',
      name: 'Component inset',
      value: 16,
    );

    expect(entry.displayValue, '16 dp');
  });

  test('component knobs expose stable registered instance IDs', () {
    final knob = DesyComponentKnob(
      id: 'trailing',
      name: 'Operational status',
      initial: 'status.clear',
      options: const ['status.clear'],
    );

    expect(knob.options.single, 'status.clear');
  });

  test('component knobs retain only their declared slot choices', () {
    final knob = DesyComponentKnob(
      id: 'trailing',
      name: 'Operational status',
      initial: 'status.clear',
      options: const ['status.clear'],
    );

    expect(knob.options, ['status.clear']);
    expect(knob.options, isNot(contains('button.publish')));
  });

  test('component knobs reject empty options and an undeclared initial ID', () {
    expect(
      () => DesyComponentKnob(
        id: 'slot',
        name: 'Slot',
        initial: 'status.clear',
        options: const [],
      ),
      throwsArgumentError,
    );
    expect(
      () => DesyComponentKnob(
        id: 'slot',
        name: 'Slot',
        initial: 'status.clear',
        options: const ['status.delayed'],
      ),
      throwsArgumentError,
    );
  });

  test('registry validation rejects unknown component-instance IDs', () {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      preview: _emptyPreview,
      knobs: [
        DesyComponentKnob(
          id: 'trailing',
          name: 'Trailing',
          initial: 'status.missing',
          options: const ['status.missing'],
        ),
      ],
    );
    final registry = DesyRegistry(
      name: 'Broken swap',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    final issue = registry.validate().single;
    expect(
      issue.message,
      contains('unknown component instance "status.missing"'),
    );
    expect(issue.severity, DesyRegistryValidationSeverity.warning);
  });

  test('registry validation rejects invalid instance knob settings', () {
    final component = DesyComponent(
      id: 'status',
      name: 'Status',
      preview: _emptyPreview,
      knobs: const [
        DesyBooleanKnob(id: 'enabled', name: 'Enabled', initial: true),
      ],
      buildWithKnobs: (context, values, _) => const SizedBox(),
      instances: [
        DesyComponentInstance(
          id: 'invalid',
          name: 'Invalid',
          knobValues: DesyKnobValues({'enabled': 'yes', 'unknown': true}),
        ),
      ],
    );
    final registry = DesyRegistry(
      name: 'Invalid settings',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    expect(
      registry.validate().map((issue) => issue.message),
      containsAll([
        contains('invalid value for knob "enabled"'),
        contains('sets unknown knob "unknown"'),
      ]),
    );
  });

  test('experimental catalogue export is derived without widget builders', () {
    final registry = DesyRegistry(
      name: 'Exported system',
      themes: [
        DesyTheme(id: 'light', name: 'Light', wrap: (_, child) => child),
      ],
      tokens: [
        DesyToken(
          id: 'color.brand',
          name: 'Brand',
          value: '#006B63',
          builder: (_) => const SizedBox(),
        ),
      ],
      icons: const [
        DesyIconEntry(
          id: 'icon.anchor',
          name: 'Anchor',
          icon: IconData(0xe001),
          value: 'AppIcons.anchor',
        ),
      ],
      components: [
        DesyComponent(
          id: 'button.primary',
          name: 'Primary button',
          preview: (_) => const SizedBox(),
          knobs: const [
            DesyStringKnob(id: 'label', name: 'Label', initial: 'Save'),
          ],
        ),
      ],
    );

    final export = DesyCatalogueExport(registry).toJson();
    final components = export['components']! as List<Object?>;
    final component = components.single! as Map<String, Object?>;

    expect(export['schemaVersion'], '0.1-experimental');
    final primitives = export['primitives']! as Map<String, Object?>;
    expect(primitives['icons'], [
      {
        'id': 'icon.anchor',
        'name': 'Anchor',
        'value': 'AppIcons.anchor',
        'codePoint': 0xe001,
        'fontFamily': null,
      },
    ]);
    expect(component['id'], 'button.primary');
    expect(component['knobs'], [
      {'id': 'label', 'name': 'Label', 'kind': 'string'},
    ]);
    expect(export.toString(), isNot(contains('Closure')));
  });

  testWidgets('component presets merge their values with knob defaults', (
    tester,
  ) async {
    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      preview: _emptyPreview,
      knobs: const [
        DesyStringKnob(id: 'label', name: 'Label', initial: 'Default'),
        DesyBooleanKnob(id: 'enabled', name: 'Enabled', initial: true),
      ],
      buildWithKnobs: _knobbedPreview,
      instances: [
        DesyComponentInstance(
          id: 'archived',
          name: 'Archived',
          knobValues: DesyKnobValues({'label': 'Archived', 'enabled': false}),
        ),
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) =>
              component.buildInstance(context, component.instances.single),
        ),
      ),
    );

    expect(find.text('Archived · false'), findsOneWidget);
  });

  test('registry resolves named instances through their owning component', () {
    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      preview: _emptyPreview,
      instances: [DesyComponentInstance(id: 'default', name: 'Default')],
    );
    final registry = DesyRegistry(
      name: 'Instances',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    final instance = registry.allComponentInstances.single;

    expect(instance.id, 'action.default');
    expect(instance.componentName, 'Action');
    final resolved = registry.resolveComponentInstance('action.default');
    expect(resolved?.id, instance.id);
    expect(resolved?.component, same(component));
    expect(resolved?.instance, same(instance.instance));
  });

  testWidgets('registry widget builder resolves an instance-swap ID', (
    tester,
  ) async {
    final status = DesyComponent(
      id: 'status',
      name: 'Status',
      preview: _emptyPreview,
      knobs: const [
        DesyStringKnob(id: 'label', name: 'Label', initial: 'Clear'),
      ],
      buildWithKnobs: (context, values, _) => Text(values.string('label')),
      instances: [
        DesyComponentInstance(
          id: 'delayed',
          name: 'Delayed',
          knobValues: DesyKnobValues({'label': 'Delayed'}),
        ),
      ],
    );
    final registry = DesyRegistry(
      name: 'Resolved swap',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [status],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) =>
              registry.widgetBuilder.build(context, 'status.delayed'),
        ),
      ),
    );

    expect(find.text('Delayed'), findsOneWidget);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;

Widget _emptyPreview(BuildContext context) => const SizedBox();

Widget _knobbedPreview(
  BuildContext context,
  DesyKnobValues values,
  DesyRegistryWidgetBuilder widgets,
) => Text('${values.string('label')} · ${values.boolean('enabled')}');
