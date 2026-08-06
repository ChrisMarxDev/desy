// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart' show TextSelectionThemeData, Theme;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import 'workbench_router.dart';
import 'workbench_session.dart';
import '../registry.dart';
import '../workspace_extension.dart';

/// Desy's Forui workbench, driven directly by the consumer registry.
class DesyWorkbenchApp extends StatefulWidget {
  const DesyWorkbenchApp({
    super.key,
    required this.registry,
    this.extensions = const [],
  });

  final DesyRegistry registry;
  final List<DesyWorkspaceExtension> extensions;

  @override
  State<DesyWorkbenchApp> createState() => _DesyWorkbenchAppState();
}

class _DesyWorkbenchAppState extends State<DesyWorkbenchApp> {
  late final DesyWorkbenchSession _session = DesyWorkbenchSession(
    registry: widget.registry,
    extensions: widget.extensions,
  );
  late final GoRouter _router = createDesyWorkbenchRouter(_session);

  @override
  void initState() {
    super.initState();
    final issues = widget.registry.validate(
      extensionIds: widget.extensions.map((extension) => extension.id),
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
    _router.dispose();
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeIndex = _session.activeThemeIndex.watch(context);
    final activeTheme = _session.registry.themes[activeThemeIndex];
    final desyTheme = activeTheme.usesDarkWorkbench
        ? FTheme.neutral.dark.desktop
        : FTheme.neutral.light.desktop;
    return WidgetsApp.router(
      debugShowCheckedModeBanner: false,
      color: desyTheme.colors.background,
      routerConfig: _router,
      supportedLocales: FLocalizations.supportedLocales,
      localizationsDelegates: const [...FLocalizations.localizationsDelegates],
      builder: (context, child) => Theme(
        // Some Flutter platform primitives still read [ThemeData]. Derive that
        // bridge from the Forui theme so no default Material palette can leak
        // into Desy-owned chrome.
        data: desyTheme.toApproximateMaterialTheme().copyWith(
          textSelectionTheme: TextSelectionThemeData(
            cursorColor: desyTheme.colors.primary,
            selectionColor: desyTheme.colors.primary.withValues(alpha: .28),
            selectionHandleColor: desyTheme.colors.primary,
          ),
        ),
        child: FTheme(
          data: desyTheme,
          child: FToaster(
            child: FTooltipGroup(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
  }
}
