// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:a2ui_core/a2ui_core.dart' as a2ui;
import 'package:desy_core/desy_core.dart';
import 'package:desy_genui/desy_genui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';
import 'package:mix/mix.dart';

import 'genui_backend.dart';
import 'orbit/orbit_registry.dart';
import 'orbit/orbit_theme.dart';

void main() => runApp(const DesyGenUiExampleApp());

/// Decides whether an emitted surface action should become an agent turn.
typedef GenUiActionPolicy = bool Function(GenUiAction action);

/// A desktop GenUI exploration workspace built solely from Orbit's consumer
/// design system. No Material control is used to render the experience.
class DesyGenUiExampleApp extends StatefulWidget {
  const DesyGenUiExampleApp({
    super.key,
    this.backend,
    this.shouldForwardAction,
  });

  final GenUiBackend? backend;
  final GenUiActionPolicy? shouldForwardAction;

  @override
  State<DesyGenUiExampleApp> createState() => _DesyGenUiExampleAppState();
}

class _DesyGenUiExampleAppState extends State<DesyGenUiExampleApp> {
  var _theme = OrbitThemeData.midnight;

  void _toggleTheme() {
    setState(() {
      _theme = _theme.isDark
          ? OrbitThemeData.daylight
          : OrbitThemeData.midnight;
    });
  }

  @override
  Widget build(BuildContext context) => WidgetsApp(
    color: _theme.colors.background,
    debugShowCheckedModeBanner: false,
    textStyle: TextStyle(
      color: _theme.colors.foreground,
      fontFamilyFallback: const ['Inter', 'SF Pro Text', 'Segoe UI', 'Arial'],
    ),
    pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ),
    home: OrbitTheme(
      data: _theme,
      child: _OrbitWorkspace(
        backend: widget.backend,
        shouldForwardAction: widget.shouldForwardAction,
        onToggleTheme: _toggleTheme,
      ),
    ),
  );
}

class _FocusComposerIntent extends Intent {
  const _FocusComposerIntent();
}

class _SendComposerIntent extends Intent {
  const _SendComposerIntent();
}

class _OrbitWorkspace extends StatefulWidget {
  const _OrbitWorkspace({
    required this.onToggleTheme,
    this.backend,
    this.shouldForwardAction,
  });

  final GenUiBackend? backend;
  final GenUiActionPolicy? shouldForwardAction;
  final VoidCallback onToggleTheme;

  @override
  State<_OrbitWorkspace> createState() => _OrbitWorkspaceState();
}

class _OrbitWorkspaceState extends State<_OrbitWorkspace> {
  static const _surfaceId = 'orbit-experiment';

  late final DesyGenUiCatalog compiled;
  late final SurfaceController controller;
  late final TextEditingController _promptController;
  late final FocusNode _composerFocusNode;
  late final bool _ownsBackend;
  GenUiBackend? _backend;
  StreamSubscription<ChatMessage>? _events;
  List<Map<String, Object?>> _activeComponents = _fixtureComponents;
  String? _submittedPrompt;
  String? _error;
  String _source = 'ORBIT FIXTURE';
  String _lastAction = 'No generated action yet.';
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    compiled = DesyGenUiCatalog.compile(orbitRegistry);
    controller = SurfaceController(catalogs: [compiled.catalog]);
    _promptController = TextEditingController(
      text: 'Show me the clearest next move for this workspace.',
    );
    _composerFocusNode = FocusNode(debugLabel: 'orbit-composer');
    _ownsBackend = widget.backend == null;
    _backend = widget.backend;
    _events = controller.onSubmit.listen((message) {
      final interaction = message.parts.first.asUiInteractionPart?.interaction;
      if (!mounted || interaction == null) return;
      _handleInteraction(interaction);
    });
    controller.handleMessage(
      a2ui.CreateSurfaceMessage(
        surfaceId: _surfaceId,
        catalogId: compiled.catalog.catalogId!,
      ),
    );
    _updateSurface(_fixtureComponents);
  }

  @override
  void dispose() {
    unawaited(_events?.cancel());
    if (_ownsBackend) _backend?.close();
    _promptController.dispose();
    _composerFocusNode.dispose();
    controller.dispose();
    super.dispose();
  }

  void _updateSurface(List<Map<String, Object?>> components) {
    _activeComponents = List.unmodifiable(
      components.map(
        (component) => Map<String, Object?>.unmodifiable(component),
      ),
    );
    controller.handleMessage(
      a2ui.UpdateComponentsMessage(
        surfaceId: _surfaceId,
        components: [
          for (final component in components)
            Map<String, dynamic>.from(component),
        ],
      ),
    );
  }

  void _handleInteraction(String interaction) {
    setState(() => _lastAction = interaction);
    final GenUiAction action;
    try {
      action = GenUiAction.fromInteraction(interaction);
    } on FormatException catch (error) {
      setState(
        () => _error = 'The generated action was invalid: ${error.message}',
      );
      return;
    }
    if (widget.shouldForwardAction?.call(action) == false) return;
    unawaited(
      _respond(
        GenUiActionTurn(action: action, currentSurface: _activeComponents),
      ),
    );
  }

  Future<void> _submit(String prompt) async {
    final normalized = prompt.trim();
    if (normalized.isEmpty || _isGenerating) return;
    await _respond(GenUiPromptTurn(normalized), submittedPrompt: normalized);
  }

  Future<void> _respond(GenUiTurn turn, {String? submittedPrompt}) async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _error = null;
      if (submittedPrompt != null) _submittedPrompt = submittedPrompt;
    });
    try {
      final backend = _backend ??= OpenAiGenUiBackend();
      final result = await backend.respond(turn: turn, catalog: compiled);
      if (!mounted) return;
      _updateSurface(result.components);
      setState(() => _source = '${result.model} · ${result.responseId}');
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _useSuggestion(String suggestion) {
    _promptController.value = TextEditingValue(
      text: suggestion,
      selection: TextSelection.collapsed(offset: suggestion.length),
    );
    _composerFocusNode.requestFocus();
  }

  void _startFresh() {
    setState(() {
      _submittedPrompt = null;
      _error = null;
      _source = 'ORBIT FIXTURE';
      _lastAction = 'No generated action yet.';
      _updateSurface(_fixtureComponents);
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSidebar = MediaQuery.sizeOf(context).width >= 960;
    final activeTheme = OrbitTheme.of(context);
    final registryTheme = orbitRegistry.themes.firstWhere(
      (theme) => theme.id == activeTheme.id,
    );
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _FocusComposerIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _FocusComposerIntent(),
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.keyK &&
              (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed)) {
            _composerFocusNode.requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            _FocusComposerIntent: CallbackAction<_FocusComposerIntent>(
              onInvoke: (_) {
                _composerFocusNode.requestFocus();
                return null;
              },
            ),
          },
          child: ColoredBox(
            color: activeTheme.colors.background,
            child: SafeArea(
              child: Row(
                children: [
                  if (showSidebar)
                    _OrbitSidebar(
                      onNewExperiment: _startFresh,
                      onToggleTheme: widget.onToggleTheme,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          catalogId:
                              compiled.catalog.catalogId ?? 'Orbit catalog',
                          generating: _isGenerating,
                          isDark: activeTheme.isDark,
                          onToggleTheme: widget.onToggleTheme,
                        ),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                            children: [
                              Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 760,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _Welcome(),
                                      const SizedBox(
                                        height: OrbitTokens.space2xl,
                                      ),
                                      if (_submittedPrompt
                                          case final prompt?) ...[
                                        _UserPrompt(text: prompt),
                                        const SizedBox(
                                          height: OrbitTokens.spaceXl,
                                        ),
                                      ],
                                      _AgentResponse(
                                        controller: controller,
                                        surfaceId: _surfaceId,
                                        loading: _isGenerating,
                                        error: _error,
                                        source: _source,
                                        lastAction: _lastAction,
                                        theme: registryTheme,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _PromptDock(
                          controller: _promptController,
                          focusNode: _composerFocusNode,
                          generating: _isGenerating,
                          onSubmit: _submit,
                          onSuggestion: _useSuggestion,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrbitSidebar extends StatelessWidget {
  const _OrbitSidebar({
    required this.onNewExperiment,
    required this.onToggleTheme,
  });

  final VoidCallback onNewExperiment;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 248,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: OrbitTheme.of(context).colors.card,
        border: Border(
          right: BorderSide(color: OrbitTheme.of(context).colors.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OrbitTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _OrbitMark(),
            const SizedBox(height: OrbitTokens.space2xl),
            OrbitButton(
              label: 'New experiment',
              onPressed: onNewExperiment,
              leading: const OrbitGlyph(OrbitGlyphs.add, size: 17),
              expand: true,
            ),
            const SizedBox(height: OrbitTokens.spaceXl),
            Text('WORKSPACE', style: OrbitType.overline(context)),
            const SizedBox(height: OrbitTokens.spaceSm),
            const _SidebarItem(
              glyph: OrbitGlyphs.sparkle,
              label: 'Agent room',
              selected: true,
            ),
            const _SidebarItem(glyph: OrbitGlyphs.grid, label: 'Components'),
            const _SidebarItem(
              glyph: OrbitGlyphs.activity,
              label: 'Experiments',
            ),
            const _SidebarItem(glyph: OrbitGlyphs.database, label: 'Sources'),
            const Spacer(),
            OrbitSurface(
              padding: const EdgeInsets.all(OrbitTokens.spaceSm),
              tone: OrbitSurfaceTone.muted,
              child: Row(
                children: [
                  const _OrbitAvatar(letter: 'O'),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Expanded(
                    child: Text(
                      'Orbit research',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OrbitType.label(context),
                    ),
                  ),
                  OrbitIconButton(
                    label: 'Switch theme',
                    glyph: OrbitGlyphs.command,
                    onPressed: onToggleTheme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _OrbitMark extends StatelessWidget {
  const _OrbitMark();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const _OrbitAvatar(letter: '✦', large: true),
      const SizedBox(width: OrbitTokens.spaceSm),
      Text(
        'ORBIT',
        style: OrbitType.heading(context).copyWith(letterSpacing: 1.8),
      ),
    ],
  );
}

class _OrbitAvatar extends StatelessWidget {
  const _OrbitAvatar({required this.letter, this.large = false});

  final String letter;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 34.0 : 28.0;
    return Box(
      style: BoxStyler()
          .color(OrbitTheme.of(context).colors.primary)
          .borderRounded(OrbitTokens.radiusMd),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(
            letter,
            style: OrbitType.label(context).copyWith(
              color: OrbitTheme.of(context).colors.primaryForeground,
              fontSize: large ? 15 : 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.glyph,
    required this.label,
    this.selected = false,
  });

  final String glyph;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: OrbitTokens.space2xs),
    child: OrbitSurface(
      tone: selected ? OrbitSurfaceTone.muted : OrbitSurfaceTone.transparent,
      border: false,
      radius: OrbitTokens.radiusMd,
      padding: const EdgeInsets.symmetric(
        horizontal: OrbitTokens.spaceSm,
        vertical: 10,
      ),
      child: Row(
        children: [
          OrbitGlyph(
            glyph,
            size: 16,
            color: selected
                ? OrbitTheme.of(context).colors.foreground
                : OrbitTheme.of(context).colors.mutedForeground,
          ),
          const SizedBox(width: OrbitTokens.spaceSm),
          Text(
            label,
            style: OrbitType.label(context).copyWith(
              color: selected
                  ? OrbitTheme.of(context).colors.foreground
                  : OrbitTheme.of(context).colors.mutedForeground,
            ),
          ),
        ],
      ),
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.catalogId,
    required this.generating,
    required this.isDark,
    required this.onToggleTheme,
  });

  final String catalogId;
  final bool generating;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: OrbitTheme.of(context).colors.border),
      ),
    ),
    child: SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: OrbitTokens.spaceLg),
        child: Row(
          children: [
            const OrbitGlyph(OrbitGlyphs.sparkle, size: 18),
            const SizedBox(width: OrbitTokens.spaceSm),
            Text('Agent room', style: OrbitType.title(context)),
            const SizedBox(width: OrbitTokens.spaceSm),
            Expanded(
              child: Text(
                catalogId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OrbitType.small(context),
              ),
            ),
            OrbitBadge(
              label: generating ? 'GENERATING' : 'CATALOG READY',
              tone: generating
                  ? OrbitBadgeTone.warning
                  : OrbitBadgeTone.success,
              glyph: generating ? OrbitGlyphs.activity : OrbitGlyphs.check,
            ),
            const SizedBox(width: OrbitTokens.spaceSm),
            OrbitIconButton(
              label: 'Use ${isDark ? 'light' : 'dark'} theme',
              glyph: isDark ? '☼' : '◐',
              onPressed: onToggleTheme,
            ),
          ],
        ),
      ),
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const OrbitBadge(
        label: 'GENUI EXPERIMENT',
        tone: OrbitBadgeTone.info,
        glyph: OrbitGlyphs.sparkle,
      ),
      const SizedBox(height: OrbitTokens.spaceLg),
      Text('Shape the next useful view.', style: OrbitType.display(context)),
      const SizedBox(height: OrbitTokens.spaceSm),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Text(
          'Ask Orbit for a decision-ready interface. Every reply is a live tree of real, registry-declared Flutter components.',
          style: OrbitType.body(
            context,
          ).copyWith(color: OrbitTheme.of(context).colors.mutedForeground),
        ),
      ),
    ],
  );
}

class _UserPrompt extends StatelessWidget {
  const _UserPrompt({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: OrbitSurface(
        tone: OrbitSurfaceTone.muted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OrbitBadge(label: 'YOU', tone: OrbitBadgeTone.neutral),
            const SizedBox(height: OrbitTokens.spaceSm),
            Text(text, style: OrbitType.body(context)),
          ],
        ),
      ),
    ),
  );
}

class _AgentResponse extends StatelessWidget {
  const _AgentResponse({
    required this.controller,
    required this.surfaceId,
    required this.loading,
    required this.error,
    required this.source,
    required this.lastAction,
    required this.theme,
  });

  final SurfaceController controller;
  final String surfaceId;
  final bool loading;
  final String? error;
  final String source;
  final String lastAction;
  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _OrbitAvatar(letter: '✦'),
            const SizedBox(width: OrbitTokens.spaceSm),
            Text('ORBIT AGENT', style: OrbitType.label(context)),
            const SizedBox(width: OrbitTokens.spaceSm),
            Expanded(
              child: Text(
                source,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OrbitType.small(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: OrbitTokens.spaceMd),
        if (loading) const _ThinkingTrace(),
        if (loading) const SizedBox(height: OrbitTokens.spaceMd),
        if (error case final error?)
          OrbitSurface(
            child: Text(
              error,
              style: OrbitType.body(
                context,
              ).copyWith(color: OrbitTheme.of(context).colors.destructive),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: DesyGenUiSurface(
              controller: controller,
              surfaceId: surfaceId,
              theme: theme,
            ),
          ),
        const SizedBox(height: OrbitTokens.spaceMd),
        _EventTrace(value: lastAction),
      ],
    ),
  );
}

class _ThinkingTrace extends StatelessWidget {
  const _ThinkingTrace();

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: OrbitTokens.spaceMd,
      vertical: OrbitTokens.spaceSm,
    ),
    child: Row(
      children: [
        OrbitSpinner(size: 16, color: OrbitTheme.of(context).colors.info),
        const SizedBox(width: OrbitTokens.spaceSm),
        Expanded(
          child: Text(
            'Orbit is composing a complete component graph…',
            style: OrbitType.small(context),
          ),
        ),
      ],
    ),
  );
}

class _EventTrace extends StatelessWidget {
  const _EventTrace({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) => OrbitSurface(
    padding: const EdgeInsets.symmetric(
      horizontal: OrbitTokens.spaceMd,
      vertical: OrbitTokens.spaceSm,
    ),
    tone: OrbitSurfaceTone.transparent,
    child: Row(
      children: [
        OrbitGlyph(
          OrbitGlyphs.activity,
          color: OrbitTheme.of(context).colors.warning,
          size: 15,
        ),
        const SizedBox(width: OrbitTokens.spaceSm),
        Text('LAST UI EVENT', style: OrbitType.overline(context)),
        const SizedBox(width: OrbitTokens.spaceSm),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OrbitType.small(context),
          ),
        ),
      ],
    ),
  );
}

class _PromptDock extends StatelessWidget {
  const _PromptDock({
    required this.controller,
    required this.focusNode,
    required this.generating,
    required this.onSubmit,
    required this.onSuggestion,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool generating;
  final ValueChanged<String> onSubmit;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: OrbitTheme.of(context).colors.background,
      border: Border(
        top: BorderSide(color: OrbitTheme.of(context).colors.border),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _Suggestion(
                      label: 'Summarize signals',
                      onTap: onSuggestion,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    _Suggestion(
                      label: 'Plan next actions',
                      onTap: onSuggestion,
                    ),
                    const SizedBox(width: OrbitTokens.spaceSm),
                    _Suggestion(label: 'Show task status', onTap: onSuggestion),
                  ],
                ),
              ),
              const SizedBox(height: OrbitTokens.spaceSm),
              Shortcuts(
                shortcuts: const <ShortcutActivator, Intent>{
                  SingleActivator(LogicalKeyboardKey.enter, control: true):
                      _SendComposerIntent(),
                  SingleActivator(LogicalKeyboardKey.enter, meta: true):
                      _SendComposerIntent(),
                },
                child: Actions(
                  actions: <Type, Action<Intent>>{
                    _SendComposerIntent: CallbackAction<_SendComposerIntent>(
                      onInvoke: (_) {
                        onSubmit(controller.text);
                        return null;
                      },
                    ),
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: OrbitTextArea(
                          controller: controller,
                          focusNode: focusNode,
                          enabled: !generating,
                          hint:
                              'Ask Orbit to compose a decision-ready interface…',
                        ),
                      ),
                      const SizedBox(width: OrbitTokens.spaceSm),
                      OrbitButton(
                        label: generating ? 'Working' : 'Generate',
                        onPressed: generating
                            ? null
                            : () => onSubmit(controller.text),
                        leading: generating
                            ? OrbitSpinner(
                                size: 14,
                                color: OrbitTheme.of(
                                  context,
                                ).colors.mutedForeground,
                              )
                            : const OrbitGlyph(OrbitGlyphs.send, size: 17),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: OrbitTokens.spaceXs),
              Row(
                children: [
                  Text(
                    'Ctrl/⌘ + Enter to generate',
                    style: OrbitType.small(context),
                  ),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Text('•', style: OrbitType.small(context)),
                  const SizedBox(width: OrbitTokens.spaceSm),
                  Text('Ctrl/⌘ + K to focus', style: OrbitType.small(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});

  final String label;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => OrbitButton(
    label: label,
    onPressed: () => onTap(label),
    variant: OrbitButtonVariant.secondary,
    compact: true,
    leading: const OrbitGlyph(OrbitGlyphs.add, size: 14),
  );
}

const _fixtureComponents = <Map<String, Object?>>[
  {
    'id': 'root',
    'component': 'orbit.component.stack',
    'children': ['signal', 'stats', 'recommendation', 'tasks', 'source'],
  },
  {
    'id': 'signal',
    'component': 'orbit.component.insight',
    'eyebrow': 'WORKSPACE SIGNAL',
    'title': 'Your GenUI experiment is ready for a real prompt',
    'detail':
        'Orbit is rendering its own consumer component catalog, not a simulated mock.',
    'metric': '10 blocks',
    'change': 'Catalog live',
    'tone': 'info',
  },
  {
    'id': 'stats',
    'component': 'orbit.component.metric-grid',
    'tiles': ['catalog', 'themes', 'actions'],
  },
  {
    'id': 'catalog',
    'component': 'orbit.component.metric-tile',
    'label': 'Components',
    'value': '10',
    'change': 'Registry declared',
    'tone': 'success',
  },
  {
    'id': 'themes',
    'component': 'orbit.component.metric-tile',
    'label': 'Themes',
    'value': '2',
    'change': 'Light + dark',
    'tone': 'info',
  },
  {
    'id': 'actions',
    'component': 'orbit.component.metric-tile',
    'label': 'Actions',
    'value': 'Live',
    'change': 'Structured events',
    'tone': 'warning',
  },
  {
    'id': 'recommendation',
    'component': 'orbit.component.recommendation',
    'title': 'Start by asking for a focused decision surface',
    'detail':
        'Try a recommendation, task plan, approval request, or compact performance summary.',
    'confidence': 0.92,
    'actionLabel': 'Generate a task plan',
    'onAction': {
      'event': {
        'name': 'generate_task_plan',
        'context': {'origin': 'fixture'},
      },
    },
  },
  {
    'id': 'tasks',
    'component': 'orbit.component.task-list',
    'title': 'What the demo proves',
    'rows': ['task-registry', 'task-render'],
  },
  {
    'id': 'task-registry',
    'component': 'orbit.component.task-row',
    'title': 'Compile the Orbit registry',
    'detail': 'Schemas and examples follow real widgets.',
    'state': 'done',
  },
  {
    'id': 'task-render',
    'component': 'orbit.component.task-row',
    'title': 'Replace this surface with agent output',
    'detail': 'The backend returns one complete A2UI tree.',
    'state': 'working',
  },
  {
    'id': 'source',
    'component': 'orbit.component.source',
    'title': 'Orbit GenUI registry',
    'detail': 'The local component source used to compile this response.',
    'meta': 'Local catalog · 10 components · 2 themes',
  },
];
