// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import 'workbench_router.dart';
import 'workbench_session.dart';
import '../detail_extension.dart';
import '../registry.dart';
import '../workspace_extension.dart';

/// Desy's Forui workbench, driven directly by the consumer registry.
class DesyWorkbenchApp extends StatefulWidget {
  const DesyWorkbenchApp({
    super.key,
    required this.registry,
    this.extensions = const [],
    this.detailExtensions = const [],
  });

  final DesyRegistry registry;
  final List<DesyWorkspaceExtension> extensions;
  final List<DesyDetailExtension> detailExtensions;

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

  @override
  void initState() {
    super.initState();
    _installRuntime(
      registry: widget.registry,
      extensions: widget.extensions,
      detailExtensions: widget.detailExtensions,
    );
  }

  @override
  void didUpdateWidget(covariant DesyWorkbenchApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_declarationsChanged) return;

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
      return;
    }

    final previousSession = _session;
    final previousRouter = _router;
    _installRuntime(
      registry: widget.registry,
      extensions: extensions,
      detailExtensions: detailExtensions,
      validate: false,
    );
    previousRouter?.dispose();
    previousSession?.dispose();
  }

  bool get _declarationsChanged =>
      !identical(widget.registry, _declaredRegistry) ||
      !_sameIdentityList(widget.extensions, _declaredExtensions) ||
      !_sameIdentityList(widget.detailExtensions, _declaredDetailExtensions);

  void _installRuntime({
    required DesyRegistry registry,
    required List<DesyWorkspaceExtension> extensions,
    required List<DesyDetailExtension> detailExtensions,
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
    );

    _declaredRegistry = registry;
    _declaredExtensions = extensionSnapshot;
    _declaredDetailExtensions = detailExtensionSnapshot;
    _session = session;
    _router = createDesyWorkbenchRouter(session);
    _configurationError = null;
  }

  bool _enterFailedConfiguration({
    required DesyRegistry registry,
    required List<DesyWorkspaceExtension> extensions,
    required List<DesyDetailExtension> detailExtensions,
    required FlutterError error,
  }) {
    final shouldReport = _configurationError?.toString() != error.toString();
    final previousSession = _session;
    final previousRouter = _router;
    _declaredRegistry = registry;
    _declaredExtensions = List.unmodifiable(extensions);
    _declaredDetailExtensions = List.unmodifiable(detailExtensions);
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

  @override
  void dispose() {
    _router?.dispose();
    _session?.dispose();
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
      builder: (context, child) => DesyDesignSystemScope(
        theme: designSystemTheme,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
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
