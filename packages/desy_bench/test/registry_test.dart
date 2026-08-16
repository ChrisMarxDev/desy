import 'dart:convert';

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

  test(
    'color entries expose one literal color and derive their ARGB value',
    () {
      const color = DesyColorEntry(
        id: 'color.brand',
        name: 'Brand',
        color: Color(0x80123456),
      );

      final registry = DesyRegistry(
        name: 'Colors',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        colors: const [color],
      );

      expect(registry.allColors, [color]);
      expect(color.displayValue, '#80123456');
      expect(registry.resolve(color.id)?.value, '#80123456');
    },
  );

  test(
    'custom atoms are immutable named widget instances in one atom lane',
    () {
      final atom = DesyCustomAtom(
        id: 'brand.ribbon',
        name: 'Brand ribbon',
        instances: {
          'default': (_) => const SizedBox(),
          'quiet': (_) => const SizedBox(),
        },
      );
      final registry = DesyRegistry(
        name: 'Custom atom',
        themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
        customAtoms: [atom],
      );

      expect(registry.atomKinds, [DesyAtomKind.custom]);
      expect(registry.allCustomAtoms, [atom]);
      expect(registry.entriesForAtom(DesyAtomKind.custom).single.id, atom.id);
      expect(
        registry.entriesForAtom(DesyAtomKind.custom).single.value,
        'default',
      );
      expect(() => atom.instances.clear(), throwsUnsupportedError);
      expect(
        () => DesyCustomAtom(id: 'empty', name: 'Empty', instances: const {}),
        throwsArgumentError,
      );
    },
  );

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
    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.workbench,
    );
  });

  test('workspace extension can opt into a standalone screen', () {
    final extension = DesyWorkspaceExtension.builder(
      id: 'focused-tool',
      name: 'Focused tool',
      presentation: DesyWorkspaceExtensionPresentation.standalone,
      builder: (context, extension) => const SizedBox(),
    );

    expect(
      extension.presentation,
      DesyWorkspaceExtensionPresentation.standalone,
    );
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

  test('registry exposes resolved token entries', () {
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
    );

    expect(registry.resolve('brand')?.path, 'Root');
    expect(registry.resolve('brand')?.folderIds, isEmpty);
    expect(registry.resolve('brand')?.routePath, isEmpty);
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
    expect(
      () => component.contract!.properties.clear(),
      throwsUnsupportedError,
    );
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
      instances: (knobs) => {
        'default': [knobs.title('Activity')],
      },
    );

    final ids = component.knobDefinitions.map((d) => d.id).toList();
    expect(ids, ['title', 'enabled']);
    expect(component.instanceIds, ['default']);
    expect(
      component.knobDefinitions.where(
        (d) => d.kind == DesyKnobKind.widgetInstance,
      ),
      isEmpty,
    );
  });

  test('components may omit named instances', () {
    final component = DesyComponent(
      id: 'trail.summary',
      name: 'Summary',
      knobs: (k) => (label: k.string('label', initial: 'Summary')),
      build: (context, knobs) => Text(knobs.label.value),
    );

    expect(component.instanceIds, isEmpty);
    expect(component.defaultInstanceId, isNull);
    expect(component.valuesFor('default'), {'label': 'Summary'});
  });

  test('bound-record components retain typed literal color knobs', () {
    final component = DesyComponent(
      id: 'status.dot',
      name: 'Status dot',
      knobs: (k) => (color: k.color('color', initial: const Color(0xff118833))),
      build: (context, knobs) => ColoredBox(color: knobs.color.value),
      instances: (knobs) => {
        'warning': [knobs.color(const Color(0xffffaa00))],
      },
    );

    expect(component.knobDefinitions.single.kind, DesyKnobKind.color);
    expect(component.valuesFor('warning')['color'], const Color(0xffffaa00));
  });

  test('bound-record components retain typed DateTime knobs', () {
    final initial = DateTime.utc(2026, 8, 15, 9, 30);
    final delayed = DateTime.utc(2026, 8, 16, 14, 45);
    final component = DesyComponent(
      id: 'schedule.card',
      name: 'Schedule card',
      knobs: (k) => (startsAt: k.dateTime('startsAt', initial: initial)),
      build: (context, knobs) => Text(knobs.startsAt.value.toIso8601String()),
      instances: (knobs) => {
        'delayed': [knobs.startsAt(delayed)],
      },
    );

    expect(component.knobDefinitions.single.kind, DesyKnobKind.dateTime);
    expect(component.valuesFor('delayed')['startsAt'], delayed);
  });

  test('knob definitions freeze caller-owned option lists', () {
    final options = <String>['status.clear'];
    final definition = KnobDefinition<DesyInstanceId>(
      id: 'status',
      name: 'Status',
      kind: DesyKnobKind.widgetInstance,
      initial: const DesyInstanceId('status.clear'),
      options: options,
    );

    options.add('status.delayed');

    expect(definition.options, ['status.clear']);
    expect(
      () => definition.options.add('status.dropped'),
      throwsUnsupportedError,
    );
  });

  test('component declaration rejects duplicate widget-instance knob IDs', () {
    expect(
      () => DesyComponent(
        id: 'trail.tile',
        name: 'Tile',
        knobs: (k) => (
          leading: k.widgetInstance('slot', initial: 'status.clear'),
          trailing: k.widgetInstance('slot', initial: 'status.clear'),
        ),
        build: (context, knobs) => const SizedBox(),
        instances: (knobs) => const <String, List<KnobSettingBase>>{},
      ),
      throwsArgumentError,
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
      instances: (knobs) => {
        'default': [knobs.suffix('status.clear')],
      },
    );

    final suffix = component.knobDefinitions.firstWhere(
      (d) => d.id == 'suffix',
    );
    expect(suffix.kind, DesyKnobKind.widgetInstance);
    expect(component.referencesFor('default').single.value, 'status.clear');
  });

  testWidgets('surface-scoped instance IDs use the external child resolver', (
    tester,
  ) async {
    final leaf = DesyStaticComponent(
      id: 'status',
      name: 'Status',
      instances: {'clear': (_) => const Text('Registry child')},
    );
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) => (
        body: k.widgetInstance(
          'body',
          initial: 'status.clear',
          options: const ['status.clear'],
        ),
      ),
      build: (context, knobs) => knobs.body.widget,
      instances: (knobs) => {
        'default': [knobs.body('status.clear')],
      },
    );
    final registry = DesyRegistry(
      name: 'Surface composition',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [leaf, component],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => component.buildWithValues(
            context,
            const {'body': DesyInstanceId.surface('live-child')},
            widgets: DesyWidgetResolver.withSurfaceChildren(
              registry,
              buildSurfaceChild: (_, id) => Text('Surface $id'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Surface live-child'), findsOneWidget);
    expect(find.text('Registry child'), findsNothing);
  });

  test('registry validation rejects unknown component-instance references', () {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) =>
          (trailing: k.widgetInstance('trailing', initial: 'status.missing')),
      build: (context, knobs) => Text(knobs.trailing.value.value),
      instances: (knobs) => {
        'default': [knobs.trailing('status.missing')],
      },
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

  test('registry validation includes default widget-instance references', () {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) =>
          (trailing: k.widgetInstance('trailing', initial: 'status.missing')),
      build: (context, knobs) => knobs.trailing.widget,
      instances: (knobs) => const <String, List<KnobSettingBase>>{},
    );
    final registry = DesyRegistry(
      name: 'Broken default',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    final issue = registry.validate().single;

    expect(issue.id, 'status.missing');
    expect(issue.message, contains('default preview'));
    expect(issue.severity, DesyRegistryValidationSeverity.warning);
  });

  test(
    'component declaration rejects widget-instance values outside options',
    () {
      expect(
        () => DesyComponent(
          id: 'card',
          name: 'Card',
          knobs: (k) => (
            trailing: k.widgetInstance(
              'trailing',
              initial: 'status.clear',
              options: const ['status.clear'],
            ),
          ),
          build: (context, knobs) => knobs.trailing.widget,
          instances: (knobs) => {
            'delayed': [knobs.trailing('status.delayed')],
          },
        ),
        throwsArgumentError,
      );
    },
  );

  test('component declaration rejects duplicate widget-instance options', () {
    expect(
      () => DesyComponent(
        id: 'card',
        name: 'Card',
        knobs: (k) => (
          trailing: k.widgetInstance(
            'trailing',
            initial: 'status.clear',
            options: const ['status.clear', 'status.clear'],
          ),
        ),
        build: (context, knobs) => knobs.trailing.widget,
        instances: (knobs) => const <String, List<KnobSettingBase>>{},
      ),
      throwsArgumentError,
    );
  });

  test('registry validation includes every widget-instance option', () {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) => (
        trailing: k.widgetInstance(
          'trailing',
          initial: 'status.clear',
          options: const ['status.clear', 'status.missing'],
        ),
      ),
      build: (context, knobs) => knobs.trailing.widget,
      instances: (knobs) => const <String, List<KnobSettingBase>>{},
    );
    final registry = DesyRegistry(
      name: 'Broken option',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {'clear': _emptyPreview},
        ),
        component,
      ],
    );

    final issue = registry.validate().single;

    expect(issue.id, 'status.missing');
    expect(issue.message, contains('knob "trailing" option'));
  });

  test('component declaration rejects repeated overrides for one knob', () {
    expect(
      () => DesyComponent(
        id: 'card',
        name: 'Card',
        knobs: (k) => (title: k.string('title', initial: 'Activity')),
        build: (context, knobs) => Text(knobs.title.value),
        instances: (knobs) => {
          'runs': [knobs.title('Runs'), knobs.title('Running')],
        },
      ),
      throwsArgumentError,
    );
  });

  testWidgets('live knob values respect types and widget-instance options', (
    tester,
  ) async {
    final component = DesyComponent(
      id: 'card',
      name: 'Card',
      knobs: (k) => (
        title: k.string('title', initial: 'Activity'),
        trailing: k.widgetInstance(
          'trailing',
          initial: 'status.clear',
          options: const ['status.clear'],
        ),
      ),
      build: (context, knobs) => Text(knobs.title.value),
      instances: (knobs) => const <String, List<KnobSettingBase>>{},
    );
    final registry = DesyRegistry(
      name: 'Live values',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {'clear': _emptyPreview, 'delayed': _emptyPreview},
        ),
        component,
      ],
    );
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(key: ValueKey('context')),
      ),
    );
    final context = tester.element(find.byKey(const ValueKey('context')));

    expect(
      () => component.buildWithValues(context, const {
        'trailing': 'status.delayed',
      }, widgets: registry.widgetBuilder),
      throwsArgumentError,
    );
    expect(
      () => component.buildWithValues(context, const {
        'title': false,
      }, widgets: registry.widgetBuilder),
      throwsArgumentError,
    );
  });

  test('component declaration rejects overrides from another component', () {
    final other = DesyComponent(
      id: 'other',
      name: 'Other',
      knobs: (k) => (title: k.string('title', initial: 'x')),
      build: (context, knobs) => Text(knobs.title.value),
      instances: (knobs) => {
        'default': [knobs.title('x')],
      },
    );
    final foreignSetting = other.instances['default']!.single;

    expect(
      () => DesyComponent(
        id: 'card',
        name: 'Card',
        knobs: (k) => (body: k.string('body', initial: 'b')),
        build: (context, knobs) => Text(knobs.body.value),
        instances: (knobs) => {
          'default': [foreignSetting],
        },
      ),
      throwsArgumentError,
    );
  });

  test('experimental catalogue export is derived without widget builders', () {
    final registry = DesyRegistry(
      name: 'Exported system',
      catalogConfig: const DesyCatalogConfig(
        id: 'example.design-system',
        version: '1.0.0',
        description: 'Example agent catalogue.',
      ),
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
          knobs: (k) => (
            label: k.string(
              'label',
              name: 'Label',
              description: 'Visible button copy.',
              initial: 'Save',
            ),
            publishedAt: k.dateTime(
              'publishedAt',
              name: 'Published at',
              initial: DateTime.utc(2026, 8, 15, 9, 30),
            ),
            children: k.widgetInstances(
              'children',
              description: 'Ordered button adornments.',
            ),
            press: k.event('press', description: 'Activate the button.'),
          ),
          build: (context, knobs) => Text(knobs.label.value),
          instances: (knobs) => {
            'primary': [knobs.label('Save')],
          },
        ),
      ],
    );

    final export = DesyCatalogueExport(registry).toJson();
    final components = export['components']! as List<Object?>;
    final component = components.single! as Map<String, Object?>;

    expect(export['schemaVersion'], '0.2-experimental');
    expect(export['catalog'], {
      'id': 'example.design-system',
      'version': '1.0.0',
      'description': 'Example agent catalogue.',
    });
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
      {
        'id': 'label',
        'name': 'Label',
        'description': 'Visible button copy.',
        'kind': 'string',
        'initial': 'Save',
      },
      {
        'id': 'publishedAt',
        'name': 'Published at',
        'kind': 'date-time',
        'initial': '2026-08-15T09:30:00.000Z',
      },
      {
        'id': 'children',
        'name': 'Children',
        'description': 'Ordered button adornments.',
        'kind': 'component-instances',
        'initial': <Object>[],
      },
      {
        'id': 'press',
        'name': 'Press',
        'description': 'Activate the button.',
        'kind': 'event',
      },
    ]);
    expect(export.toString(), isNot(contains('Closure')));
    expect(() => jsonEncode(export), returnsNormally);
  });

  test('catalogue export is opt-in and honors component policy', () {
    final themes = const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)];
    final disabled = DesyRegistry(name: 'Local only', themes: themes);

    expect(DesyCatalogueExport(disabled).isEnabled, isFalse);
    expect(
      () => DesyCatalogueExport(disabled).toJson(),
      throwsA(isA<StateError>()),
    );

    final enabled = DesyRegistry(
      name: 'Agent ready',
      themes: themes,
      catalogConfig: const DesyCatalogConfig(id: 'agent-ready', version: '1'),
      components: [
        DesyStaticComponent(
          id: 'visible',
          name: 'Visible',
          instances: {'default': (_) => const SizedBox()},
        ),
        DesyStaticComponent(
          id: 'internal',
          name: 'Internal',
          catalogConfig: const DesyComponentCatalogConfig(include: false),
          instances: {'default': (_) => const SizedBox()},
        ),
      ],
    );

    final components =
        DesyCatalogueExport(enabled).toJson()['components']! as List<Object?>;
    expect(enabled.catalogComponents.map((component) => component.id), [
      'visible',
    ]);
    expect(components.map((item) => (item! as Map<String, Object?>)['id']), [
      'visible',
    ]);
  });

  testWidgets('multi-instance knobs resolve real widgets in selected order', (
    tester,
  ) async {
    final list = DesyComponent(
      id: 'status.list',
      name: 'Status list',
      knobs: (k) => (
        children: k.widgetInstances(
          'children',
          description: 'Ordered status tiles.',
          initial: const ['status.clear', 'status.delayed'],
          options: const ['status.clear', 'status.delayed'],
        ),
      ),
      build: (context, knobs) => Column(children: knobs.children.widgets),
      instances: (knobs) => {
        'default': [
          knobs.children(const ['status.delayed', 'status.clear']),
        ],
      },
    );
    final registry = DesyRegistry(
      name: 'Composition',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [
        DesyStaticComponent(
          id: 'status',
          name: 'Status',
          instances: {
            'clear': (_) => const Text('Clear'),
            'delayed': (_) => const Text('Delayed'),
          },
        ),
        list,
      ],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) =>
              list.buildInstance(context, 'default', registry.widgetBuilder),
        ),
      ),
    );

    expect(
      tester.widgetList<Text>(find.byType(Text)).map((text) => text.data),
      ['Delayed', 'Clear'],
    );
    expect(list.valuesFor('default')['children'], [
      'status.delayed',
      'status.clear',
    ]);
    expect(list.referencesFor('default').map((reference) => reference.value), [
      'status.delayed',
      'status.clear',
    ]);
  });

  testWidgets('event knobs forward optional payloads through the host', (
    tester,
  ) async {
    final host = _RecordingEventHost();
    final component = DesyComponent(
      id: 'composer',
      name: 'Composer',
      knobs: (k) => (
        submit: k.event(
          'submit',
          description: 'Send the current composer value.',
        ),
      ),
      build: (context, knobs) => GestureDetector(
        onTap: () => knobs.submit.emit({'text': 'Hello'}),
        child: const Text('Send'),
      ),
      instances: (knobs) => const {},
    );
    final registry = DesyRegistry(
      name: 'Events',
      themes: const [DesyTheme(id: 'light', name: 'Light', wrap: _wrap)],
      components: [component],
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(
          builder: (context) => component.buildWithValues(
            context,
            const {
              'submit': {'action': 'send-message'},
            },
            widgets: registry.widgetBuilder,
            events: host,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Send'));

    expect(host.invocations, hasLength(1));
    expect(host.invocations.single.knobId, 'submit');
    expect(host.invocations.single.action, {'action': 'send-message'});
    expect(host.invocations.single.payload, {'text': 'Hello'});
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
      instances: (knobs) => {
        'default': [knobs.label('Do it')],
      },
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
      instances: (knobs) => {
        'delayed': [knobs.label('Delayed')],
      },
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

final class _RecordingEventHost implements DesyEventHost {
  final List<DesyEventInvocation> invocations = [];

  @override
  void emit(DesyEventInvocation invocation) => invocations.add(invocation);
}

Widget _emptyPreview(BuildContext context) => const SizedBox();
