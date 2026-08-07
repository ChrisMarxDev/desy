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
        DesyStaticComponent(
          id: 'status.badge',
          name: 'Status badge',
          path: '/feedback/status',
          instances: {'default': (_) => const SizedBox()},
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
        DesyStaticComponent(
          id: 'plain',
          name: 'Plain',
          path: 'input',
          instances: {'default': _emptyPreview},
        ),
        DesyStaticComponent(
          id: 'slashed',
          name: 'Slashed',
          path: '/input/',
          instances: {'default': _emptyPreview},
        ),
        DesyStaticComponent(
          id: 'nested',
          name: 'Nested',
          path: '//input//text//',
          instances: {'default': _emptyPreview},
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
        DesyStaticComponent(
          id: 'shared',
          name: 'Same label',
          instances: {'default': _emptyPreview},
        ),
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
        DesyStaticComponent(
          id: 'primary-button',
          name: 'Primary button',
          path: '/form-controls/action-buttons',
          instances: {'default': _emptyPreview},
        ),
      ],
    );

    final entry = registry.resolve('primary-button')!;
    expect(entry.folderNames, ['Form controls', 'Action buttons']);
    expect(entry.path, 'Form controls / Action buttons');
  });

  test('component paths reject traversal and invalid segments', () {
    expect(
      () => DesyStaticComponent(
        id: 'traversal',
        name: 'Traversal',
        path: '/input/../secret',
        instances: {'default': _emptyPreview},
      ),
      throwsArgumentError,
    );
    expect(
      () => DesyStaticComponent(
        id: 'spaces',
        name: 'Spaces',
        path: '/Input fields',
        instances: {'default': _emptyPreview},
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
    final scenarios = <DesyComponentScenario>[
      DesyComponentScenario(
        id: 'default',
        name: 'Default',
        builder: _emptyPreview,
      ),
    ];
    final properties = <DesyContractProperty>[
      const DesyContractProperty(name: 'label', type: 'String'),
    ];
    final effect = DesyEffectEntry.boxShadow(
      id: 'shadow',
      name: 'Shadow',
      shadows: [BoxShadow(blurRadius: 4)],
    );
    final contract = DesyComponentContract(properties: properties);
    final component = DesyStaticComponent(
      id: 'component',
      name: 'Component',
      instances: {'default': _emptyPreview},
      scenarios: scenarios,
      contract: contract,
    );

    scenarios.clear();
    properties.clear();

    expect(component.scenarios, hasLength(1));
    expect(component.contract?.properties, hasLength(1));
    expect(() => effect.shadows.clear(), throwsUnsupportedError);
    expect(() => component.scenarios.clear(), throwsUnsupportedError);
    expect(() => component.contract!.properties.clear(), throwsUnsupportedError);
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

  test('bound-record components expose their declared knob schema', () {
    final component = DesyComponent(
      id: 'trail.activity',
      name: 'Activity',
      knobs: (k) => (
        title: k.string('title', initial: 'Activity'),
        enabled: k.boolean('enabled', initial: true),
      ),
      build: (context, knobs) => Text(knobs.title.value),
      instances: (knobs) => {'default': [knobs.title('Activity')]},
    );

    final ids = component.knobDefinitions.map((d) => d.id).toList();
    expect(ids, ['title', 'enabled']);
    expect(component.instanceIds, ['default']);
    expect(
      component.knobDefinitions
          .where((d) => d.kind == DesyKnobKind.widgetInstance),
      isEmpty,
    );
  });

  test('widget-instance knobs are typed registry references', () {
    final component = DesyComponent(
      id: 'trail.tile',
      name: 'Tile',
      knobs: (k) => (
        title: k.string('title', initial: 'Release channel'),
        suffix: k.widgetInstance('suffix', initial: 'status.delayed'),
      ),
      build: (context, knobs) =>
          Text('${knobs.title.value}:${knobs.suffix.value.value}'),
      instances: (knobs) => {'default': [knobs.suffix('status.clear')]},
    );

    final suffix = component.knobDefinitions.firstWhere(
      (d) => d.id == 'suffix',
    );
    expect(suffix.kind, DesyKnobKind.widgetInstance);
    expect(component.referencesFor('default').single.value, 'status.clear');
  });

  test('registry validation rejects unknown component-instance references', () {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) => (
        trailing: k.widgetInstance('trailing', initial: 'status.missing'),
      ),
      build: (context, knobs) => Text(knobs.trailing.value.value),
      instances: (knobs) => {'default': [knobs.trailing('status.missing')]},
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

  test('component declaration rejects overrides from another component', () {
    final other = DesyComponent(
      id: 'other',
      name: 'Other',
      knobs: (k) => (title: k.string('title', initial: 'x')),
      build: (context, knobs) => Text(knobs.title.value),
      instances: (knobs) => {'default': [knobs.title('x')]},
    );
    final foreignSetting = other.instances['default']!.single;

    expect(
      () => DesyComponent(
        id: 'card',
        name: 'Card',
        knobs: (k) => (body: k.string('body', initial: 'b')),
        build: (context, knobs) => Text(knobs.body.value),
        instances: (knobs) => {'default': [foreignSetting]},
      ),
      throwsArgumentError,
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
          knobs: (k) => (label: k.string('label', name: 'Label', initial: 'Save')),
          build: (context, knobs) => Text(knobs.label.value),
          instances: (knobs) => {'primary': [knobs.label('Save')]},
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

  testWidgets('named instances resolve through their bound record', (
    tester,
  ) async {
    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      knobs: (k) => (
        label: k.string('label', name: 'Label', initial: 'Default'),
        enabled: k.boolean('enabled', name: 'Enabled', initial: true),
      ),
      build: (context, knobs) =>
          Text('${knobs.label.value} · ${knobs.enabled.value}'),
      instances: (knobs) => {
        'archived': [knobs.label('Archived'), knobs.enabled(false)],
      },
    );
    final registry = DesyRegistry(
      name: 'Instances',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => component.buildInstance(
            context,
            'archived',
            registry.widgetBuilder,
          ),
        ),
      ),
    );

    expect(find.text('Archived · false'), findsOneWidget);
  });

  test('registry resolves named instances through their owning component', () {
    final component = DesyComponent(
      id: 'action',
      name: 'Action',
      knobs: (k) => (label: k.string('label', initial: 'Do it')),
      build: (context, knobs) => Text(knobs.label.value),
      instances: (knobs) => {'default': [knobs.label('Do it')]},
    );
    final registry = DesyRegistry(
      name: 'Instances',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    final instance = registry.allComponentInstances.single;

    expect(instance.id, 'action.default');
    expect(instance.componentName, 'Action');
    expect(instance.name, 'Default');
    final resolved = registry.resolveComponentInstance('action.default');
    expect(resolved?.id, instance.id);
    expect(resolved?.component, same(component));
    expect(resolved?.component, same(instance.component));
  });

  testWidgets('registry widget builder resolves an instance-swap ID', (
    tester,
  ) async {
    final status = DesyComponent(
      id: 'status',
      name: 'Status',
      knobs: (k) => (label: k.string('label', name: 'Label', initial: 'Clear')),
      build: (context, knobs) => Text(knobs.label.value),
      instances: (knobs) => {'delayed': [knobs.label('Delayed')]},
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
