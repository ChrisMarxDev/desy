// Desy routes are internal workbench infrastructure, not consumer API.
// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import 'components_canvas/components_canvas_screen.dart';
import '../registry.dart';
import '../workspace_extension.dart';
import 'presentation/atlas_screen.dart';
import 'presentation/detail_screen.dart';
import 'presentation/measures_screen.dart';
import 'presentation/showcases_screen.dart';
import 'presentation/themes_screen.dart';
import 'presentation/workbench_sidebar.dart';
import 'presentation/workspace_extension_screen.dart';
import 'workbench_routes.dart';
import 'workbench_session.dart';
import 'workbench_navigation_tree.dart';
import 'workbench_shortcuts.dart';
import 'widget_preview.dart';

/// Creates the router for one consumer-owned design system declaration.
///
/// The [ShellRoute] owns the permanent workbench scaffold. Detail routes only
/// replace the body, so navigation never removes the sidebar.
GoRouter createDesyWorkbenchRouter(DesyWorkbenchSession session) => GoRouter(
  initialLocation: DesyWorkbenchRoutes.atlasPath,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => DesyWorkbenchRoutes.atlasPath),
    ShellRoute(
      builder: (context, state, child) =>
          DesyWorkbenchShell(session: session, child: child),
      routes: [
        GoRoute(
          path: DesyWorkbenchRoutes.atlasPath,
          pageBuilder: (context, state) {
            final folderId = state.uri.queryParameters['folder'];
            final atomKind = folderId == null
                ? null
                : session.registry.atomKindForId(folderId);
            if (atomKind == DesyAtomKind.measurements) {
              return _instantPage(
                state,
                DesyMeasuresScreen(
                  session: session,
                  measurements: session.registry.measurements,
                ),
              );
            }
            return _instantPage(
              state,
              DesyAtlasScreen(
                session: session,
                folderId: folderId,
                onOpen: (entry) {
                  session.prepareEntry(entry);
                  context.go(DesyWorkbenchRoutes.entry(entry.id));
                },
              ),
            );
          },
          routes: [
            GoRoute(
              path: DesyWorkbenchRoutes.sketchSegment,
              pageBuilder: (context, state) => _instantPage(
                state,
                DesyComponentsCanvas(
                  session: session,
                  onBack: () => context.go(DesyWorkbenchRoutes.atlasPath),
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: DesyWorkbenchRoutes.themesPath,
          pageBuilder: (context, state) =>
              _instantPage(state, DesyThemesScreen(session: session)),
        ),
        GoRoute(
          path: DesyWorkbenchRoutes.showcasesPath,
          pageBuilder: (context, state) =>
              _instantPage(state, DesyShowcasesScreen(session: session)),
        ),
        GoRoute(
          path: '${DesyWorkbenchRoutes.workspacePath}/:extensionId',
          pageBuilder: (context, state) {
            final id = Uri.decodeComponent(
              state.pathParameters['extensionId']!,
            );
            final extension = session.extensions
                .where((candidate) => candidate.id == id)
                .firstOrNull;
            return _instantPage(
              state,
              extension == null
                  ? _UnknownEntryScreen(
                      onReturn: () => context.go(DesyWorkbenchRoutes.atlasPath),
                    )
                  : DesyWorkspaceExtensionScreen(
                      session: session,
                      extension: extension,
                    ),
            );
          },
        ),
        GoRoute(
          path: '${DesyWorkbenchRoutes.entriesPath}/:entryId',
          pageBuilder: (context, state) {
            final entry = _entryFor(
              session.registry,
              Uri.decodeComponent(state.pathParameters['entryId']!),
            );
            if (entry == null) {
              return _instantPage(
                state,
                _UnknownEntryScreen(
                  onReturn: () => context.go(DesyWorkbenchRoutes.atlasPath),
                ),
              );
            }
            return _instantPage(
              state,
              _DesyDetailRouteScreen(
                key: ValueKey(entry.id),
                session: session,
                entry: entry,
              ),
            );
          },
        ),
      ],
    ),
  ],
);

/// Workbench navigation changes content immediately: it is a dense tool, not
/// an app flow where a page transition provides useful orientation.
NoTransitionPage<void> _instantPage(GoRouterState state, Widget child) =>
    NoTransitionPage<void>(key: state.pageKey, child: child);

DesyRegistryEntry? _entryFor(DesyRegistry registry, String id) =>
    registry.resolve(id);

DesyWorkspaceExtension? _workspaceExtensionFor(
  Uri location,
  List<DesyWorkspaceExtension> extensions,
) {
  final segments = location.pathSegments;
  if (segments.length != 2 || segments.first != 'workspace') return null;
  final id = Uri.decodeComponent(segments.last);
  return extensions.where((extension) => extension.id == id).firstOrNull;
}

/// The persistent Forui scaffold mounted by [ShellRoute].
class DesyWorkbenchShell extends StatefulWidget {
  const DesyWorkbenchShell({
    super.key,
    required this.session,
    required this.child,
  });

  final DesyWorkbenchSession session;
  final Widget child;

  @override
  State<DesyWorkbenchShell> createState() => _DesyWorkbenchShellState();
}

class _DesyWorkbenchShellState extends State<DesyWorkbenchShell> {
  static const _defaultSidebarWidth = 248.0;
  static const _minimumSidebarWidth = 200.0;
  static const _maximumSidebarWidth = 520.0;
  static const _minimumWorkspaceWidth = 320.0;

  var _sidebarVisible = true;
  var _sidebarWidth = _defaultSidebarWidth;
  var _resizingSidebar = false;

  @override
  Widget build(BuildContext context) {
    final activeThemeIndex = widget.session.activeThemeIndex.watch(context);
    final activeTheme = widget.session.registry.themes[activeThemeIndex];
    final location = GoRouterState.of(context).uri;
    final navigationTree = DesyWorkbenchNavigationTree.fromRegistry(
      widget.session.registry,
      extensions: widget.session.extensions,
    );
    final workspaceExtension = _workspaceExtensionFor(
      location,
      widget.session.extensions,
    );
    final standaloneExtension =
        workspaceExtension?.presentation ==
        DesyWorkspaceExtensionPresentation.standalone;
    final isSketch = location.path == DesyWorkbenchRoutes.sketchPath;
    final scaffold = DesyWorkbenchShortcuts(
      location: location,
      tree: navigationTree,
      onNavigate: context.go,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (standaloneExtension) {
            return DesyScaffold(
              key: const ValueKey('standalone-workspace-extension-shell'),
              child: widget.child,
            );
          }
          if (constraints.maxWidth < 640) {
            return SafeArea(
              child: DesyScaffold(
                header: isSketch
                    ? null
                    : _CompactWorkbenchHeader(
                        session: widget.session,
                        location: location,
                      ),
                child: widget.child,
              ),
            );
          }
          if (isSketch) {
            return DesyScaffold(child: widget.child);
          }
          final maximumSidebarWidth =
              (constraints.maxWidth - _minimumWorkspaceWidth).clamp(
                _minimumSidebarWidth,
                _maximumSidebarWidth,
              );
          final sidebarWidth = _sidebarWidth.clamp(
            _minimumSidebarWidth,
            maximumSidebarWidth,
          );
          return Row(
            children: [
              AnimatedContainer(
                duration: _resizingSidebar
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: _sidebarVisible ? sidebarWidth : 0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: sidebarWidth,
                    maxWidth: sidebarWidth,
                    child: _AnimatedWorkbenchSidebar(
                      visible: _sidebarVisible,
                      child: DesyWorkbenchSidebar(
                        session: widget.session,
                        onCollapse: () =>
                            setState(() => _sidebarVisible = false),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DesyScaffold(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: _sidebarVisible ? 0 : 48,
                              ),
                              child: widget.child,
                            ),
                            if (!_sidebarVisible)
                              Positioned(
                                top: 8,
                                left: 0,
                                child: _DesktopSidebarRestore(
                                  onRestore: () =>
                                      setState(() => _sidebarVisible = true),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_sidebarVisible)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _SidebarResizeHandle(
                          width: sidebarWidth,
                          onResizeStart: () =>
                              setState(() => _resizingSidebar = true),
                          onResize: (delta) => setState(
                            () => _sidebarWidth = (sidebarWidth + delta).clamp(
                              _minimumSidebarWidth,
                              maximumSidebarWidth,
                            ),
                          ),
                          onResizeEnd: () =>
                              setState(() => _resizingSidebar = false),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return DesyPreviewThemeScope(
      theme: activeTheme,
      // Native text fields retain their platform selection on every viewport.
      // Keep this decision viewport-stable: selection registration must not
      // change merely because a route changes.
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 640
            ? SelectionArea(child: scaffold)
            : scaffold,
      ),
    );
  }
}

class _SidebarResizeHandle extends StatefulWidget {
  const _SidebarResizeHandle({
    required this.width,
    required this.onResizeStart,
    required this.onResize,
    required this.onResizeEnd,
  });

  final double width;
  final VoidCallback onResizeStart;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;

  @override
  State<_SidebarResizeHandle> createState() => _SidebarResizeHandleState();
}

class _SidebarResizeHandleState extends State<_SidebarResizeHandle> {
  static const _keyboardStep = 24.0;

  final _focusNode = FocusNode(debugLabel: 'Sidebar resize handle');
  var _active = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _resize(double delta) => widget.onResize(delta);

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: 'Resize sidebar',
    value: '${widget.width.round()} pixels',
    increasedValue: '${(widget.width + _keyboardStep).round()} pixels',
    decreasedValue: '${(widget.width - _keyboardStep).round()} pixels',
    onIncrease: () => _resize(_keyboardStep),
    onDecrease: () => _resize(-_keyboardStep),
    child: Focus(
      focusNode: _focusNode,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          _resize(-_keyboardStep);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _resize(_keyboardStep);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() => _active = true),
        onExit: (_) => setState(() => _active = _focusNode.hasFocus),
        child: GestureDetector(
          key: const ValueKey('desktop-sidebar-resize-handle'),
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) {
            _focusNode.requestFocus();
            widget.onResizeStart();
            setState(() => _active = true);
          },
          onHorizontalDragUpdate: (details) => _resize(details.delta.dx),
          onHorizontalDragEnd: (_) {
            widget.onResizeEnd();
            setState(() => _active = _focusNode.hasFocus);
          },
          onHorizontalDragCancel: () {
            widget.onResizeEnd();
            setState(() => _active = _focusNode.hasFocus);
          },
          child: SizedBox(
            width: 8,
            child: Center(
              child: AnimatedContainer(
                key: const ValueKey('desktop-sidebar-resize-indicator'),
                duration: const Duration(milliseconds: 100),
                width: _active ? 1 : 0,
                color: context.theme.colors.border,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _DesktopSidebarRestore extends StatelessWidget {
  const _DesktopSidebarRestore({required this.onRestore});

  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) => DesyButton.icon(
    key: const ValueKey('desktop-sidebar-restore'),
    size: DesyButtonSize.sm,
    semanticsLabel: 'Show sidebar',
    semanticsTooltip: 'Show sidebar',
    onPress: onRestore,
    child: const Icon(DesyIcons.panelLeftOpen, size: 16),
  );
}

/// Keeps the sketch under the same [ShellRoute] while smoothly reclaiming the
/// desktop sidebar's width. Route content itself remains instant.
class _AnimatedWorkbenchSidebar extends StatelessWidget {
  const _AnimatedWorkbenchSidebar({required this.visible, required this.child});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    duration: const Duration(milliseconds: 180),
    curve: Curves.easeOutCubic,
    tween: Tween(end: visible ? 1 : 0),
    child: child,
    builder: (context, factor, child) => ClipRect(
      child: KeyedSubtree(
        key: const ValueKey('workbench-sidebar'),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: factor,
          child: IgnorePointer(ignoring: factor < 1, child: child),
        ),
      ),
    ),
  );
}

/// A compact, keyboard-accessible entry point to the same shell navigation.
///
/// On narrow devices an expanded desktop sidebar would leave no usable canvas.
/// The route shell remains the navigation owner; only its presentation changes.
class _CompactWorkbenchHeader extends StatelessWidget {
  const _CompactWorkbenchHeader({
    required this.session,
    required this.location,
  });

  final DesyWorkbenchSession session;
  final Uri location;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        const Expanded(child: Text('DESY BENCH')),
        DesyButton(
          variant: DesyButtonVariant.outline,
          size: DesyButtonSize.sm,
          onPress: () => _showNavigation(context),
          child: const Text('Navigate'),
        ),
      ],
    ),
  );

  Future<void> _showNavigation(BuildContext routerContext) =>
      showDesyDialog<void>(
        context: routerContext,
        builder: (dialogContext, _, animation) => DesyDialog(
          animation: animation,
          semanticsLabel: 'Workbench navigation',
          builder: (context, _) => SizedBox(
            width: 320,
            height: 560,
            child: DesyWorkbenchSidebar(
              session: session,
              location: location,
              onNavigate: (destination) {
                Navigator.of(dialogContext).pop();
                GoRouter.of(routerContext).go(destination);
              },
            ),
          ),
        ),
      );
}

/// Prepares detail-local state once when a deep link or user navigation opens
/// a component. The route remains the source of truth for which entry is open.
class _DesyDetailRouteScreen extends StatefulWidget {
  const _DesyDetailRouteScreen({
    super.key,
    required this.session,
    required this.entry,
  });

  final DesyWorkbenchSession session;
  final DesyRegistryEntry entry;

  @override
  State<_DesyDetailRouteScreen> createState() => _DesyDetailRouteScreenState();
}

class _DesyDetailRouteScreenState extends State<_DesyDetailRouteScreen> {
  @override
  void initState() {
    super.initState();
    widget.session.prepareEntry(widget.entry);
  }

  @override
  Widget build(BuildContext context) => DesyDetailScreen(
    session: widget.session,
    entry: widget.entry,
    onOpenFolder: (folderId) =>
        context.go(DesyWorkbenchRoutes.atlas(folderId: folderId)),
  );
}

class _UnknownEntryScreen extends StatelessWidget {
  const _UnknownEntryScreen({required this.onReturn});

  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) => Center(
    child: DesyButton(
      variant: DesyButtonVariant.outline,
      onPress: onReturn,
      child: const Text('Return to catalogue'),
    ),
  );
}
