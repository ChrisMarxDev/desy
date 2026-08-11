// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import 'workbench_router.dart';
import 'workbench_session.dart';
import 'annotation_workspace.dart';
import '../detail_extension.dart';
import '../registry.dart';
import '../workspace_extension.dart';
import '../window_controls.dart';

/// Desy's Forui workbench, driven directly by the consumer registry.
class DesyWorkbenchApp extends StatefulWidget {
  const DesyWorkbenchApp({
    super.key,
    required this.registry,
    this.extensions = const [],
    this.detailExtensions = const [],
    this.windowControls,
    this.annotations,
  });

  final DesyRegistry registry;
  final List<DesyWorkspaceExtension> extensions;
  final List<DesyDetailExtension> detailExtensions;
  final DesyWindowControls? windowControls;
  final DesyAnnotationWorkspace? annotations;

  @override
  State<DesyWorkbenchApp> createState() => _DesyWorkbenchAppState();
}

class _DesyWorkbenchAppState extends State<DesyWorkbenchApp> {
  DesyWorkbenchSession? _session;
  GoRouter? _router;
  FlutterError? _configurationError;
  late DesyRegistry _declaredRegistry;
  late List<DesyWorkspaceExtension> _declaredExtensions;
  late List<DesyDetailExtension> _declaredDetailExtensions;
  DesyWindowControls? _declaredWindowControls;
  DesyAnnotationWorkspace? _declaredAnnotations;

  @override
  void initState() {
    super.initState();
    _installRuntime(
      registry: widget.registry,
      extensions: widget.extensions,
      detailExtensions: widget.detailExtensions,
      windowControls: widget.windowControls,
      annotations: widget.annotations,
    );
  }

  @override
  void didUpdateWidget(covariant DesyWorkbenchApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_declarationsChanged) return;

    final previousExtensions = _declaredExtensions;
    final extensions = List<DesyWorkspaceExtension>.unmodifiable(
      widget.extensions,
    );
    final detailExtensions = List<DesyDetailExtension>.unmodifiable(
      widget.detailExtensions,
    );
    try {
      _validateDeclarations(widget.registry, extensions, detailExtensions);
    } on FlutterError catch (error, stackTrace) {
      final shouldReport = _enterFailedConfiguration(
        registry: widget.registry,
        extensions: extensions,
        detailExtensions: detailExtensions,
        windowControls: widget.windowControls,
        annotations: widget.annotations,
        error: error,
      );
      if (shouldReport) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'desy_bench',
            context: ErrorDescription(
              'while updating DesyWorkbenchApp declarations',
            ),
          ),
        );
      }
      _disposeRemovedExtensions(previousExtensions: previousExtensions);
      return;
    }

    final previousSession = _session;
    final previousRouter = _router;
    _installRuntime(
      registry: widget.registry,
      extensions: extensions,
      detailExtensions: detailExtensions,
      windowControls: widget.windowControls,
      annotations: widget.annotations,
      validate: false,
    );
    previousRouter?.dispose();
    previousSession?.dispose();
    _disposeRemovedExtensions(previousExtensions: previousExtensions);
  }

  bool get _declarationsChanged =>
      !identical(widget.registry, _declaredRegistry) ||
      !_sameIdentityList(widget.extensions, _declaredExtensions) ||
      !_sameIdentityList(widget.detailExtensions, _declaredDetailExtensions) ||
      !identical(widget.windowControls, _declaredWindowControls) ||
      !identical(widget.annotations, _declaredAnnotations);

  void _installRuntime({
    required DesyRegistry registry,
    required List<DesyWorkspaceExtension> extensions,
    required List<DesyDetailExtension> detailExtensions,
    required DesyWindowControls? windowControls,
    required DesyAnnotationWorkspace? annotations,
    bool validate = true,
  }) {
    final extensionSnapshot = List<DesyWorkspaceExtension>.unmodifiable(
      extensions,
    );
    final detailExtensionSnapshot = List<DesyDetailExtension>.unmodifiable(
      detailExtensions,
    );
    if (validate) {
      _validateDeclarations(
        registry,
        extensionSnapshot,
        detailExtensionSnapshot,
      );
    }
    final session = DesyWorkbenchSession(
      registry: registry,
      extensions: extensionSnapshot,
      detailExtensions: detailExtensionSnapshot,
      annotations: annotations,
    );
    session.hydrateAnnotations();

    _declaredRegistry = registry;
    _declaredExtensions = extensionSnapshot;
    _declaredDetailExtensions = detailExtensionSnapshot;
    _declaredWindowControls = windowControls;
    _declaredAnnotations = annotations;
    _session = session;
    _router = createDesyWorkbenchRouter(
      session,
      windowControls: windowControls,
    );
    _configurationError = null;
  }

  bool _enterFailedConfiguration({
    required DesyRegistry registry,
    required List<DesyWorkspaceExtension> extensions,
    required List<DesyDetailExtension> detailExtensions,
    required DesyWindowControls? windowControls,
    required DesyAnnotationWorkspace? annotations,
    required FlutterError error,
  }) {
    final shouldReport = _configurationError?.toString() != error.toString();
    final previousSession = _session;
    final previousRouter = _router;
    _declaredRegistry = registry;
    _declaredExtensions = List.unmodifiable(extensions);
    _declaredDetailExtensions = List.unmodifiable(detailExtensions);
    _declaredWindowControls = windowControls;
    _declaredAnnotations = annotations;
    _session = null;
    _router = null;
    _configurationError = error;
    previousRouter?.dispose();
    previousSession?.dispose();
    return shouldReport;
  }

  void _validateDeclarations(
    DesyRegistry registry,
    List<DesyWorkspaceExtension> extensions,
    List<DesyDetailExtension> detailExtensions,
  ) {
    final issues = registry
        .validate(
          extensionIds: [
            ...extensions.map((extension) => extension.id),
            ...detailExtensions.map((extension) => extension.id),
          ],
        )
        .where(
          (issue) => issue.severity == DesyRegistryValidationSeverity.error,
        );
    if (issues.isNotEmpty) {
      final details = issues
          .map((issue) => '${issue.id}: ${issue.message}')
          .join('\n');
      throw FlutterError(
        'DesyWorkbenchApp cannot start because the registry declaration is invalid.\n'
        '$details',
      );
    }
  }

  void _disposeRemovedExtensions({
    required List<DesyWorkspaceExtension> previousExtensions,
  }) {
    for (final extension in previousExtensions) {
      if (!widget.extensions.any(
        (candidate) => identical(candidate, extension),
      )) {
        extension.dispose();
      }
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    _session?.dispose();
    for (final extension in _declaredExtensions) {
      extension.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configurationError = _configurationError;
    if (configurationError != null) {
      return _FailedWorkbenchConfiguration(registry: widget.registry);
    }

    final session = _session!;
    final router = _router!;
    final activeThemeIndex = session.activeThemeIndex.watch(context);
    final activeTheme = session.registry.themes[activeThemeIndex];
    final designSystemTheme = activeTheme.usesDarkWorkbench
        ? DesyDesignSystemTheme.dark
        : DesyDesignSystemTheme.light;
    final themeData = DesyDesignSystemFoundation.themeData(designSystemTheme);
    return WidgetsApp.router(
      debugShowCheckedModeBanner: false,
      color: themeData.colors.background,
      routerConfig: router,
      supportedLocales: DesyDesignSystemFoundation.supportedLocales,
      localizationsDelegates: DesyDesignSystemFoundation.localizationsDelegates,
      builder: (context, child) => _DesyWindowBackgroundSync(
        color: themeData.colors.background,
        onSetBackgroundColor: widget.windowControls?.onSetBackgroundColor,
        child: DesyDesignSystemScope(
          theme: designSystemTheme,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// Synchronizes a host-managed bezel with Desy's active workbench theme.
class _DesyWindowBackgroundSync extends StatefulWidget {
  const _DesyWindowBackgroundSync({
    required this.color,
    required this.onSetBackgroundColor,
    required this.child,
  });

  final Color color;
  final ValueChanged<Color>? onSetBackgroundColor;
  final Widget child;

  @override
  State<_DesyWindowBackgroundSync> createState() =>
      _DesyWindowBackgroundSyncState();
}

class _DesyWindowBackgroundSyncState extends State<_DesyWindowBackgroundSync> {
  Color? _appliedColor;
  ValueChanged<Color>? _appliedCallback;

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(covariant _DesyWindowBackgroundSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleSync();
  }

  void _scheduleSync() {
    final callback = widget.onSetBackgroundColor;
    final color = widget.color;
    if (callback == null ||
        (_appliedColor == color && identical(_appliedCallback, callback))) {
      return;
    }
    _appliedColor = color;
    _appliedCallback = callback;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          widget.color != color ||
          !identical(widget.onSetBackgroundColor, callback)) {
        return;
      }
      callback(color);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _FailedWorkbenchConfiguration extends StatelessWidget {
  const _FailedWorkbenchConfiguration({required this.registry});

  final DesyRegistry registry;

  @override
  Widget build(BuildContext context) {
    final activeTheme = registry.themes.first;
    final designSystemTheme = activeTheme.usesDarkWorkbench
        ? DesyDesignSystemTheme.dark
        : DesyDesignSystemTheme.light;
    final themeData = DesyDesignSystemFoundation.themeData(designSystemTheme);
    return WidgetsApp(
      debugShowCheckedModeBanner: false,
      color: themeData.colors.background,
      supportedLocales: DesyDesignSystemFoundation.supportedLocales,
      localizationsDelegates: DesyDesignSystemFoundation.localizationsDelegates,
      builder: (context, child) => DesyDesignSystemScope(
        theme: designSystemTheme,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Semantics(
              key: const ValueKey('workbench-configuration-error'),
              container: true,
              liveRegion: true,
              label: 'Desy Bench configuration could not be loaded',
              child: const DesyCard(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Desy Bench could not load this configuration. '
                    'Fix invalid registry declarations and try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

bool _sameIdentityList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (!identical(left[index], right[index])) return false;
  }
  return true;
}
