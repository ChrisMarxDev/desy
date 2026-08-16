// Desy routes are internal workbench infrastructure, not consumer API.
// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:desy_design_system/desy_design_system.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';
import 'package:url_launcher/url_launcher.dart';

import 'components_canvas/components_canvas_screen.dart';
import 'issue_report.dart';
import '../registry.dart';
import '../window_controls.dart';
import '../workspace_extension.dart';
import 'presentation/atlas_screen.dart';
import 'presentation/detail_screen.dart';
import 'presentation/measures_screen.dart';
import 'presentation/prototypes_screen.dart';
import 'presentation/themes_screen.dart';
import 'presentation/workbench_sidebar.dart';
import 'presentation/workspace_extension_screen.dart';
import 'workbench_routes.dart';
import 'workbench_session.dart';
import 'workbench_navigation_tree.dart';
import 'workbench_shortcuts.dart';
import 'workbench_annotation.dart';
import 'annotation_workspace.dart';
import 'widget_preview.dart';

/// Creates the router for one consumer-owned design system declaration.
///
/// The [ShellRoute] owns the permanent workbench scaffold. Detail routes only
/// replace the body, so navigation never removes the sidebar.
GoRouter createDesyWorkbenchRouter(
  DesyWorkbenchSession session, {
  DesyWindowControls? windowControls,
}) => GoRouter(
  initialLocation: DesyWorkbenchRoutes.atlasPath,
  routes: [
    GoRoute(path: '/', redirect: (_, _) => DesyWorkbenchRoutes.atlasPath),
    ShellRoute(
      builder: (context, state, child) => DesyWorkbenchShell(
        session: session,
        windowControls: windowControls,
        child: child,
      ),
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
          path: DesyWorkbenchRoutes.canvasPath,
          redirect: (_, _) => DesyWorkbenchRoutes.atlasPath,
        ),
        GoRoute(
          path: '${DesyWorkbenchRoutes.prototypesPath}/:sessionId',
          pageBuilder: (context, state) {
            final prototypeSession = session.registry.prototypeSession(
              Uri.decodeComponent(state.pathParameters['sessionId']!),
            );
            return _instantPage(
              state,
              prototypeSession == null
                  ? _UnknownEntryScreen(
                      onReturn: () => context.go(DesyWorkbenchRoutes.atlasPath),
                    )
                  : DesyPrototypesScreen(
                      session: session,
                      prototypeSession: prototypeSession,
                    ),
            );
          },
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
    this.windowControls,
    required this.child,
  });

  final DesyWorkbenchSession session;
  final DesyWindowControls? windowControls;
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
  var _inspectionActive = false;
  var _annotationInboxOpen = false;
  final _annotationFocusNode = FocusNode();
  DesyWorkbenchWidgetTarget? _annotationTarget;
  var _annotationDraft = '';
  final _inspectionController = DesyWorkbenchInspectionController();

  @override
  void dispose() {
    _annotationFocusNode.dispose();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.session.detachWorkbenchAnnotationsAfterReload();
  }

  void _selectAnnotationTarget(DesyWorkbenchWidgetTarget target) {
    setState(() {
      _annotationTarget = target;
      _annotationDraft = '';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _annotationFocusNode.requestFocus();
    });
  }

  void _toggleInspection() {
    setState(() {
      _inspectionActive = !_inspectionActive;
      if (!_inspectionActive) {
        _annotationTarget = null;
        _annotationDraft = '';
      }
    });
  }

  void _commitAnnotation() {
    final target = _annotationTarget;
    final comment = _annotationDraft.trim();
    if (target == null || comment.isEmpty) return;
    widget.session.addWorkbenchAnnotation(target: target, comment: comment);
    setState(() {
      _annotationTarget = null;
      _annotationDraft = '';
    });
    _annotationFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final activeThemeIndex = widget.session.activeThemeIndex.watch(context);
    final activeTheme = widget.session.registry.themes[activeThemeIndex];
    final annotations = widget.session.workbenchAnnotations.watch(context);
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
    final usesCanvasActionBar = location.path.startsWith(
      '${DesyWorkbenchRoutes.prototypesPath}/',
    );
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
          final colors = context.theme.colors;
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedContainer(
                    key: const ValueKey('workbench-sidebar-region'),
                    duration: _resizingSidebar
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: _sidebarVisible ? sidebarWidth : 0,
                    color: colors.desy.panel,
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.centerLeft,
                        minWidth: sidebarWidth,
                        maxWidth: sidebarWidth,
                        child: Column(
                          children: [
                            const SizedBox(
                              key: ValueKey('workbench-sidebar-top-reserve'),
                              height: DesyDesignSystemTokens.toolbarHeight,
                            ),
                            Expanded(
                              child: _AnimatedWorkbenchSidebar(
                                visible: _sidebarVisible,
                                child: DesyWorkbenchSidebar(
                                  session: widget.session,
                                  onOpenAnnotations: () => setState(
                                    () => _annotationInboxOpen = true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      key: const ValueKey('workbench-content-region'),
                      color: colors.background,
                      child: Column(
                        children: [
                          const SizedBox(
                            key: ValueKey('workbench-content-top-reserve'),
                            height: DesyDesignSystemTokens.toolbarHeight,
                          ),
                          SizedBox(
                            key: const ValueKey(
                              'workbench-content-top-divider',
                            ),
                            width: double.infinity,
                            height: DesyDesignSystemTokens.hairline,
                            child: ColoredBox(color: colors.border),
                          ),
                          Expanded(child: DesyScaffold(child: widget.child)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (_sidebarVisible)
                Positioned(
                  left:
                      sidebarWidth -
                      DesyDesignSystemTokens.resizeDividerHitSize / 2,
                  top: 0,
                  bottom: 0,
                  child: DesyResizeDivider(
                    key: const ValueKey('desktop-sidebar-resize-handle'),
                    axis: Axis.vertical,
                    value: sidebarWidth,
                    semanticsLabel: 'Resize registry sidebar',
                    onResizeStart: () =>
                        setState(() => _resizingSidebar = true),
                    onResize: (delta) => setState(
                      () => _sidebarWidth = (sidebarWidth + delta).clamp(
                        _minimumSidebarWidth,
                        maximumSidebarWidth,
                      ),
                    ),
                    onResizeEnd: () => setState(() => _resizingSidebar = false),
                  ),
                ),
              Positioned(
                left: 0,
                top: 0,
                right: 0,
                child: _RegistrySpineTopBar(
                  session: widget.session,
                  windowControls: widget.windowControls,
                  sidebarVisible: _sidebarVisible,
                  contentLeadingInset:
                      (_sidebarVisible ? sidebarWidth : 48) + 24,
                  onToggleSidebar: () =>
                      setState(() => _sidebarVisible = !_sidebarVisible),
                  inspecting: _inspectionActive,
                  showInspectionToggle: !usesCanvasActionBar,
                  onToggleInspection: _toggleInspection,
                  onReportIssue: () {
                    final platform = kIsWeb
                        ? 'web'
                        : defaultTargetPlatform.name;
                    unawaited(
                      launchUrl(
                        buildDesyIssueReportUri(
                          DesyIssueReportContext(
                            registryName: widget.session.registry.name,
                            themeName: activeTheme.name,
                            themeId: activeTheme.id,
                            route: location.toString(),
                            platform: platform,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );

    final inspectionLayer = _WorkbenchInspectionLayer(
      active: _inspectionActive,
      screenId: location.toString(),
      target: _annotationTarget,
      annotations: annotations,
      annotationDraft: _annotationDraft,
      focusNode: _annotationFocusNode,
      inspectionTopInset:
          DesyDesignSystemTokens.toolbarHeight +
          DesyDesignSystemTokens.hairline,
      inspectionLeftInset: _sidebarVisible ? _sidebarWidth : 0,
      inspectionBottomInset: usesCanvasActionBar ? 72 : 0,
      onTargetSelected: _selectAnnotationTarget,
      onDraftChanged: (value) => setState(() => _annotationDraft = value),
      onCommit: _commitAnnotation,
      onDeleteAnnotations: widget.session.removeWorkbenchAnnotations,
      onOpenAnnotationPage: (annotation) {
        setState(() => _annotationInboxOpen = false);
        context.go(annotation.target.screenId);
      },
      inboxOpen: _annotationInboxOpen,
      onCloseInbox: () => setState(() => _annotationInboxOpen = false),
      controller: _inspectionController,
      showAnnotationDock: true,
      child: scaffold,
    );
    return DesyWorkbenchInspectionHost(
      controller: _inspectionController,
      screenId: location.toString(),
      target: _annotationTarget,
      onTargetSelected: _selectAnnotationTarget,
      inspectionActive: _inspectionActive,
      onToggleInspection: _toggleInspection,
      child: DesyPreviewThemeScope(
        theme: activeTheme,
        // Native text fields retain their platform selection on every viewport.
        // Keep this decision viewport-stable: selection registration must not
        // change merely because a route changes.
        child: LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 640
              ? SelectionArea(child: inspectionLayer)
              : inspectionLayer,
        ),
      ),
    );
  }
}

/// The quiet desktop frame shared by every registry-backed workspace.
///
/// This layer paints no frame of its own. The shell row owns panel surfaces and
/// dividers; these controls simply float over its reserved top space.
class _RegistrySpineTopBar extends StatelessWidget {
  static const _edgeInset = 12.0;
  static const _controlGap = 16.0;

  const _RegistrySpineTopBar({
    required this.session,
    required this.windowControls,
    required this.sidebarVisible,
    required this.contentLeadingInset,
    required this.onToggleSidebar,
    required this.inspecting,
    required this.showInspectionToggle,
    required this.onToggleInspection,
    required this.onReportIssue,
  });

  final DesyWorkbenchSession session;
  final DesyWindowControls? windowControls;
  final bool sidebarVisible;
  final double contentLeadingInset;
  final VoidCallback onToggleSidebar;
  final bool inspecting;
  final bool showInspectionToggle;
  final VoidCallback onToggleInspection;
  final VoidCallback onReportIssue;

  @override
  Widget build(BuildContext context) {
    final themeIndex = session.activeThemeIndex.watch(context);
    return SizedBox(
      key: const ValueKey('registry-spine-top-bar'),
      height: DesyDesignSystemTokens.toolbarHeight,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: contentLeadingInset),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, animatedContentLeadingInset, _) =>
            CustomMultiChildLayout(
              delegate: _RegistrySpineTopBarLayoutDelegate(
                contentLeadingInset: animatedContentLeadingInset,
                controlGap: _controlGap,
              ),
              children: [
                LayoutId(
                  id: _RegistrySpineTopBarSlot.theme,
                  child: DesyCompactSelect<int>(
                    key: const ValueKey('top-bar-theme-select'),
                    value: themeIndex,
                    onChanged: session.selectTheme,
                    format: (index) => session.registry.themes[index].name,
                    semanticsLabel: 'Select preview theme',
                    size: DesyButtonSize.md,
                    items: [
                      for (final (index, option)
                          in session.registry.themes.indexed)
                        DesyCompactSelectItem(
                          key: ValueKey('top-bar-theme-${option.id}'),
                          value: index,
                        ),
                    ],
                  ),
                ),
                LayoutId(
                  id: _RegistrySpineTopBarSlot.leading,
                  child: Padding(
                    padding: const EdgeInsets.only(left: _edgeInset),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (windowControls case final controls?) ...[
                          _WorkbenchWindowControls(controls: controls),
                          const SizedBox(width: 28),
                        ],
                        DesyButton.icon(
                          key: const ValueKey('registry-spine-toggle-sidebar'),
                          size: DesyButtonSize.md,
                          variant: DesyButtonVariant.ghost,
                          semanticsLabel: sidebarVisible
                              ? 'Hide registry sidebar'
                              : 'Show registry sidebar',
                          semanticsTooltip: sidebarVisible
                              ? 'Hide registry sidebar'
                              : 'Show registry sidebar',
                          onPress: onToggleSidebar,
                          child: Icon(
                            sidebarVisible
                                ? DesyIcons.panelLeftClose
                                : DesyIcons.panelLeftOpen,
                            size: 17,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                LayoutId(
                  id: _RegistrySpineTopBarSlot.trailing,
                  child: Padding(
                    padding: const EdgeInsets.only(right: _edgeInset),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DesyButton.icon(
                          key: const ValueKey('registry-spine-report-issue'),
                          size: DesyButtonSize.md,
                          variant: DesyButtonVariant.ghost,
                          semanticsLabel: 'Report an issue',
                          semanticsTooltip: 'Report an issue on GitHub',
                          onPress: onReportIssue,
                          child: const Icon(DesyIcons.messageSquare, size: 16),
                        ),
                        if (showInspectionToggle) ...[
                          const SizedBox(width: 4),
                          DesyButton.icon(
                            key: const ValueKey(
                              'registry-spine-toggle-inspection',
                            ),
                            size: DesyButtonSize.md,
                            variant: inspecting
                                ? DesyButtonVariant.primary
                                : DesyButtonVariant.ghost,
                            semanticsLabel: inspecting
                                ? 'Stop inspecting widgets'
                                : 'Inspect widgets',
                            semanticsTooltip: inspecting
                                ? 'Stop inspecting widgets'
                                : 'Inspect widgets',
                            onPress: onToggleInspection,
                            child: const Icon(DesyIcons.crosshair, size: 16),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

enum _RegistrySpineTopBarSlot { leading, theme, trailing }

class _RegistrySpineTopBarLayoutDelegate extends MultiChildLayoutDelegate {
  _RegistrySpineTopBarLayoutDelegate({
    required this.contentLeadingInset,
    required this.controlGap,
  });

  final double contentLeadingInset;
  final double controlGap;

  @override
  void performLayout(Size size) {
    final childConstraints = BoxConstraints.loose(size);
    final leadingSize = layoutChild(
      _RegistrySpineTopBarSlot.leading,
      childConstraints,
    );
    positionChild(
      _RegistrySpineTopBarSlot.leading,
      Offset(0, (size.height - leadingSize.height) / 2),
    );

    final trailingSize = layoutChild(
      _RegistrySpineTopBarSlot.trailing,
      childConstraints,
    );
    positionChild(
      _RegistrySpineTopBarSlot.trailing,
      Offset(
        size.width - trailingSize.width,
        (size.height - trailingSize.height) / 2,
      ),
    );

    final safeThemeLeadingInset = leadingSize.width + controlGap;
    final themeLeadingInset = contentLeadingInset < safeThemeLeadingInset
        ? safeThemeLeadingInset
        : contentLeadingInset;
    final availableThemeWidth =
        size.width - themeLeadingInset - trailingSize.width - controlGap;
    final themeSize = layoutChild(
      _RegistrySpineTopBarSlot.theme,
      BoxConstraints.loose(
        Size(availableThemeWidth.clamp(0, size.width), size.height),
      ),
    );
    positionChild(
      _RegistrySpineTopBarSlot.theme,
      Offset(themeLeadingInset, (size.height - themeSize.height) / 2),
    );
  }

  @override
  bool shouldRelayout(_RegistrySpineTopBarLayoutDelegate oldDelegate) =>
      contentLeadingInset != oldDelegate.contentLeadingInset ||
      controlGap != oldDelegate.controlGap;
}

class _WorkbenchWindowControls extends StatelessWidget {
  const _WorkbenchWindowControls({required this.controls});

  final DesyWindowControls controls;

  @override
  Widget build(BuildContext context) {
    final fill = context.theme.colors.mutedForeground.withValues(alpha: .72);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WorkbenchWindowControl(
          key: const ValueKey('window-control-close'),
          indicatorKey: const ValueKey('window-control-close-indicator'),
          label: 'Close window',
          fill: fill,
          onPress: controls.onClose,
        ),
        _WorkbenchWindowControl(
          key: const ValueKey('window-control-minimize'),
          indicatorKey: const ValueKey('window-control-minimize-indicator'),
          label: 'Minimize window',
          fill: fill,
          onPress: controls.onMinimize,
        ),
        _WorkbenchWindowControl(
          key: const ValueKey('window-control-maximize'),
          indicatorKey: const ValueKey('window-control-maximize-indicator'),
          label: 'Maximize or restore window',
          fill: fill,
          onPress: controls.onToggleMaximize,
        ),
      ],
    );
  }
}

class _WorkbenchWindowControl extends StatelessWidget {
  const _WorkbenchWindowControl({
    super.key,
    required this.indicatorKey,
    required this.label,
    required this.fill,
    required this.onPress,
  });

  final Key indicatorKey;
  final String label;
  final Color fill;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context) => DesyButton.icon(
    size: DesyButtonSize.sm,
    variant: DesyButtonVariant.ghost,
    semanticsLabel: label,
    semanticsTooltip: label,
    onPress: onPress,
    child: DecoratedBox(
      key: indicatorKey,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      child: const SizedBox.square(dimension: 12),
    ),
  );
}

/// Shell-owned picker and feedback dock shared by every routed workbench
/// surface. It keeps live Flutter objects inside this ephemeral widget and
/// commits only serializable evidence to [DesyWorkbenchSession].
class _WorkbenchInspectionLayer extends StatefulWidget {
  const _WorkbenchInspectionLayer({
    required this.active,
    required this.screenId,
    required this.target,
    required this.annotations,
    required this.annotationDraft,
    required this.focusNode,
    required this.inspectionTopInset,
    required this.inspectionLeftInset,
    required this.inspectionBottomInset,
    required this.onTargetSelected,
    required this.onDraftChanged,
    required this.onCommit,
    required this.onDeleteAnnotations,
    required this.onOpenAnnotationPage,
    required this.inboxOpen,
    required this.onCloseInbox,
    required this.controller,
    required this.showAnnotationDock,
    required this.child,
  });

  final bool active;
  final String screenId;
  final DesyWorkbenchWidgetTarget? target;
  final List<DesyWorkbenchAnnotation> annotations;
  final String annotationDraft;
  final FocusNode focusNode;
  final double inspectionTopInset;
  final double inspectionLeftInset;
  final double inspectionBottomInset;
  final ValueChanged<DesyWorkbenchWidgetTarget> onTargetSelected;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onCommit;
  final ValueChanged<Iterable<int>> onDeleteAnnotations;
  final ValueChanged<DesyWorkbenchAnnotation> onOpenAnnotationPage;
  final bool inboxOpen;
  final VoidCallback onCloseInbox;
  final DesyWorkbenchInspectionController controller;
  final bool showAnnotationDock;
  final Widget child;

  @override
  State<_WorkbenchInspectionLayer> createState() =>
      _WorkbenchInspectionLayerState();
}

class _WorkbenchInspectionLayerState extends State<_WorkbenchInspectionLayer> {
  final _rootKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootContext = _rootKey.currentContext;
      if (mounted && rootContext != null) {
        widget.controller.registerRoot(rootContext);
      }
    });
  }

  @override
  void dispose() {
    final rootContext = _rootKey.currentContext;
    if (rootContext != null) widget.controller.clearRoot(rootContext);
    super.dispose();
  }

  void _selectAt(PointerDownEvent event) {
    final rootContext = _rootKey.currentContext;
    final root = rootContext?.findRenderObject();
    if (rootContext is! Element || root == null || !root.attached) return;
    final rootPosition = root is RenderBox
        ? root.globalToLocal(event.position)
        : event.localPosition;

    ({Element element, Rect bounds, int depth})? bestHit;
    void visit(Element element, int depth) {
      final renderObject = element.findRenderObject();
      if (renderObject != null &&
          renderObject.attached &&
          renderObject != root &&
          !renderObject.semanticBounds.isEmpty) {
        final bounds = MatrixUtils.transformRect(
          renderObject.getTransformTo(root),
          renderObject.semanticBounds,
        );
        if (bounds.isFinite && bounds.contains(rootPosition)) {
          final scope = _inspectionScope(element);
          // Desy chrome is intentionally outside an explicit content scope.
          // It must never become a feedback target merely because it occupies
          // pixels behind the global inspection overlay.
          if (scope != null) {
            final projectElement = _nearestProjectElement(element, scope);
            final current = bestHit;
            final area = bounds.width * bounds.height;
            final currentArea = current == null
                ? double.infinity
                : current.bounds.width * current.bounds.height;
            if (area < currentArea ||
                (area == currentArea && depth > (current?.depth ?? -1))) {
              bestHit = (element: projectElement, bounds: bounds, depth: depth);
            }
          }
        }
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    rootContext.visitChildren((child) => visit(child, 0));
    final hit = bestHit;
    if (hit == null) return;
    final element = hit.element;
    widget.onTargetSelected(
      DesyWorkbenchWidgetTarget(
        screenId: widget.screenId,
        widgetType: element.widget.runtimeType.toString(),
        description: _describeWidget(element.widget),
        widgetPath: _widgetPath(element),
        bounds: hit.bounds,
        sourceLocation: _sourceLocation(element),
        widgetKey: _describeKey(element.widget.key),
        inspectionContext: _inspectionContext(element),
      ),
    );
  }

  DesyWorkbenchInspectionContext? _inspectionContext(Element element) {
    final scope = _inspectionScope(element);
    return scope == null ? null : _scopeContext(scope);
  }

  Element? _inspectionScope(Element element) {
    Element? result;
    if (element.widget is DesyWorkbenchInspectionScope) return element;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is DesyWorkbenchInspectionScope) {
        result = ancestor;
        return false;
      }
      return true;
    });
    return result;
  }

  DesyWorkbenchInspectionContext? _scopeContext(Element element) {
    DesyWorkbenchInspectionContext? result;
    final widget = element.widget;
    if (widget is DesyWorkbenchInspectionScope) result = widget.context;
    return result;
  }

  Element _nearestProjectElement(Element element, Element root) {
    if (debugIsWidgetLocalCreation(element.widget)) return element;
    var result = element;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        result = ancestor;
        return false;
      }
      return true;
    });
    return result;
  }

  DesyWorkbenchSourceLocation? _sourceLocation(Element element) {
    DesyWorkbenchSourceLocation? result;
    assert(() {
      final service = WidgetInspectorService.instance;
      service.selection.currentElement = element;
      // Flutter exposes a widget's creation location through inspector
      // serialization. This debug-only picker intentionally uses that source.
      // ignore: invalid_use_of_visible_for_testing_member
      final delegate = InspectorSerializationDelegate(service: service);
      final serialized = element.toDiagnosticsNode().toJsonMap(delegate);
      final rawLocation = serialized['creationLocation'];
      if (rawLocation is Map<Object?, Object?>) {
        try {
          result = DesyWorkbenchSourceLocation.fromInspectorJson(rawLocation);
        } on FormatException {
          result = null;
        }
      }
      return true;
    }());
    return result;
  }

  String? _describeKey(Key? key) {
    if (key == null) return null;
    if (key is ValueKey<Object?>) return '${key.value}';
    return key.toString();
  }

  String _describeWidget(Widget widget) {
    final description = switch (widget) {
      Text(data: final data?) => 'Text("${_compact(data)}")',
      Text(textSpan: final span?) => 'Text("${_compact(span.toPlainText())}")',
      SelectableText(data: final data?) =>
        'SelectableText("${_compact(data)}")',
      RichText(:final text) => 'RichText("${_compact(text.toPlainText())}")',
      Semantics(:final properties) when properties.label != null =>
        'Semantics("${_compact(properties.label!)}")',
      Tooltip(:final message) when message != null =>
        'Tooltip("${_compact(message)}")',
      TextField(:final decoration)
          when decoration?.labelText != null || decoration?.hintText != null =>
        'TextField("${_compact(decoration?.labelText ?? decoration!.hintText!)}")',
      Icon(:final icon) when icon != null =>
        'Icon(U+${icon.codePoint.toRadixString(16).toUpperCase()})',
      _ => widget.toStringShort(),
    };
    return description;
  }

  String _compact(String value) {
    final escaped = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll('"', r'\"');
    return escaped.length <= 64 ? escaped : '${escaped.substring(0, 61)}…';
  }

  String _widgetPath(Element element) {
    final root = _rootKey.currentContext;
    final segments = <String>[element.widget.runtimeType.toString()];
    element.visitAncestorElements((ancestor) {
      if (ancestor == root) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        segments.add(ancestor.widget.runtimeType.toString());
      }
      return true;
    });
    final ordered = segments.reversed.toList(growable: false);
    final visible = ordered.length > 8
        ? ordered.sublist(ordered.length - 8)
        : ordered;
    return visible.join(' > ');
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final colors = context.theme.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RepaintBoundary(key: _rootKey, child: widget.child),
        if (target != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _WorkbenchSelectionOutlinePainter(
                  bounds: target.bounds,
                  color: colors.desy.signal,
                ),
              ),
            ),
          ),
        if (target != null)
          Positioned(
            left: target.bounds.left,
            top: target.bounds.top >= 26
                ? target.bounds.top - 26
                : target.bounds.top,
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('workbench-inspection-selection-label'),
                decoration: BoxDecoration(
                  color: colors.desy.signal,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Text(
                    target.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.desy.onSignal,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.active)
          Positioned(
            left: widget.inspectionLeftInset,
            top: widget.inspectionTopInset,
            right: 0,
            bottom: widget.inspectionBottomInset,
            child: Semantics(
              button: true,
              label: 'Select a widget to annotate',
              child: MouseRegion(
                cursor: SystemMouseCursors.precise,
                child: Listener(
                  key: const ValueKey('workbench-inspection-overlay'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _selectAt,
                ),
              ),
            ),
          ),
        if (widget.showAnnotationDock && target != null)
          Positioned(
            left: DesyDesignSystemTokens.spaceLg,
            right: DesyDesignSystemTokens.spaceLg,
            bottom: DesyDesignSystemTokens.spaceLg,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _WorkbenchAnnotationDock(
                  target: target,
                  draft: widget.annotationDraft,
                  focusNode: widget.focusNode,
                  onDraftChanged: widget.onDraftChanged,
                  onCommit: widget.onCommit,
                ),
              ),
            ),
          ),
        if (widget.inboxOpen)
          Positioned.fill(
            child: _WorkbenchAnnotationInbox(
              annotations: widget.annotations,
              onClose: widget.onCloseInbox,
              onDelete: widget.onDeleteAnnotations,
              onOpenPage: widget.onOpenAnnotationPage,
            ),
          ),
      ],
    );
  }
}

/// Full-screen local inbox. Export remains deliberately clipboard-first so
/// consumers can choose their own agent, file, GitHub, or task integration.
class _WorkbenchAnnotationInbox extends StatefulWidget {
  const _WorkbenchAnnotationInbox({
    required this.annotations,
    required this.onClose,
    required this.onDelete,
    required this.onOpenPage,
  });

  final List<DesyWorkbenchAnnotation> annotations;
  final VoidCallback onClose;
  final ValueChanged<Iterable<int>> onDelete;
  final ValueChanged<DesyWorkbenchAnnotation> onOpenPage;

  @override
  State<_WorkbenchAnnotationInbox> createState() =>
      _WorkbenchAnnotationInboxState();
}

class _WorkbenchAnnotationInboxState extends State<_WorkbenchAnnotationInbox> {
  final _selectedIds = <int>{};
  String? _message;

  @override
  void didUpdateWidget(_WorkbenchAnnotationInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _selectedIds.removeWhere(
      (id) => !widget.annotations.any((annotation) => annotation.id == id),
    );
  }

  Future<void> _copy() async {
    final selected = widget.annotations
        .where((annotation) => _selectedIds.contains(annotation.id))
        .toList(growable: false);
    if (selected.isEmpty) return;
    await Clipboard.setData(
      ClipboardData(text: DesyAnnotationBatch(selected).toMarkdown()),
    );
    if (mounted) {
      setState(() => _message = '${selected.length} annotations copied');
    }
  }

  void _delete() {
    if (_selectedIds.isEmpty) return;
    widget.onDelete(_selectedIds);
    setState(() {
      _selectedIds.clear();
      _message = 'Selected annotations deleted';
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    return Material(
      color: colors.foreground.withValues(alpha: .14),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1060, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceXl),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.background,
                border: Border.all(color: colors.border),
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusMd,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.foreground.withValues(alpha: .18),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  DesyDesignSystemTokens.radiusMd,
                ),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesyDesignSystemTokens.spaceXl,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: colors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text('Annotations', style: typography.display.sm),
                          const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                          _AnnotationCountBadge(
                            count: widget.annotations.length,
                          ),
                          const Spacer(),
                          DesyButton.icon(
                            key: const ValueKey(
                              'workbench-annotation-inbox-close',
                            ),
                            onPress: widget.onClose,
                            size: DesyButtonSize.sm,
                            semanticsLabel: 'Close annotations',
                            child: const Icon(DesyIcons.x, size: 16),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(64, 36, 64, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Review your feedback',
                              style: typography.body.lg,
                            ),
                            const SizedBox(
                              height: DesyDesignSystemTokens.spaceXs,
                            ),
                            Text(
                              'Notes remain available as you move through the workbench. Copy the chosen notes into any agent or task tool.',
                              style: typography.body.sm.copyWith(
                                color: colors.mutedForeground,
                              ),
                            ),
                            if (_message case final message?) ...[
                              const SizedBox(
                                height: DesyDesignSystemTokens.spaceMd,
                              ),
                              Text(
                                message,
                                style: typography.body.sm.copyWith(
                                  color: colors.desy.signal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(
                              height: DesyDesignSystemTokens.spaceLg,
                            ),
                            Expanded(
                              child: widget.annotations.isEmpty
                                  ? Center(
                                      child: Text(
                                        'No annotations yet. Turn on inspection and select real content to add one.',
                                        style: typography.body.sm.copyWith(
                                          color: colors.mutedForeground,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: widget.annotations.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(
                                            height:
                                                DesyDesignSystemTokens.spaceSm,
                                          ),
                                      itemBuilder: (context, index) {
                                        final annotation =
                                            widget.annotations[index];
                                        return _InboxAnnotationRow(
                                          annotation: annotation,
                                          selected: _selectedIds.contains(
                                            annotation.id,
                                          ),
                                          onSelected: (selected) => setState(
                                            () {
                                              if (selected) {
                                                _selectedIds.add(annotation.id);
                                              } else {
                                                _selectedIds.remove(
                                                  annotation.id,
                                                );
                                              }
                                            },
                                          ),
                                          onOpenPage: () =>
                                              widget.onOpenPage(annotation),
                                        );
                                      },
                                    ),
                            ),
                            const SizedBox(
                              height: DesyDesignSystemTokens.spaceMd,
                            ),
                            _AnnotationInboxActions(
                              selectedCount: _selectedIds.length,
                              onCopy: _selectedIds.isEmpty ? null : _copy,
                              onDelete: _selectedIds.isEmpty ? null : _delete,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnotationCountBadge extends StatelessWidget {
  const _AnnotationCountBadge({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: context.theme.colors.desy.signalSurface,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      '$count open',
      style: context.theme.typography.body.xs.copyWith(
        color: context.theme.colors.desy.signal,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _InboxAnnotationRow extends StatelessWidget {
  const _InboxAnnotationRow({
    required this.annotation,
    required this.selected,
    required this.onSelected,
    required this.onOpenPage,
  });
  final DesyWorkbenchAnnotation annotation;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onOpenPage;
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final target = annotation.target;
    final artifact = target.inspectionContext;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.desy.signalSurface : colors.background,
        border: Border.all(
          color: selected ? colors.desy.signalBorder : colors.border,
        ),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesyCheckbox(
              value: selected,
              onChanged: onSelected,
              label: const SizedBox.shrink(),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.displayLabel,
                    style: context.theme.typography.body.md,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    annotation.comment,
                    style: context.theme.typography.body.sm,
                  ),
                  const SizedBox(height: 8),
                  if (artifact != null)
                    Text(
                      '${artifact.kind}: ${artifact.label ?? artifact.artifactId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (target.sourceLocation case final source?)
                    Text(
                      source.reference,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.theme.typography.body.xs.copyWith(
                        color: colors.mutedForeground,
                        fontFamily: 'monospace',
                      ),
                    ),
                  Text(
                    'Page: ${target.screenId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.theme.typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
            DesyButton(
              onPress: onOpenPage,
              size: DesyButtonSize.sm,
              variant: DesyButtonVariant.ghost,
              mainAxisSize: MainAxisSize.min,
              child: const Text('Open page'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnotationInboxActions extends StatelessWidget {
  const _AnnotationInboxActions({
    required this.selectedCount,
    required this.onCopy,
    required this.onDelete,
  });
  final int selectedCount;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.theme.colors.desy.panelSubtle,
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
    ),
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
      child: Row(
        children: [
          Text(
            '$selectedCount selected',
            style: context.theme.typography.body.sm,
          ),
          const Spacer(),
          DesyButton(
            key: const ValueKey('workbench-annotation-delete'),
            onPress: onDelete,
            variant: DesyButtonVariant.destructive,
            size: DesyButtonSize.sm,
            mainAxisSize: MainAxisSize.min,
            child: const Text('Delete'),
          ),
          const SizedBox(width: DesyDesignSystemTokens.spaceSm),
          DesyButton(
            key: const ValueKey('workbench-annotation-copy'),
            onPress: onCopy,
            size: DesyButtonSize.sm,
            mainAxisSize: MainAxisSize.min,
            child: const Text('Copy'),
          ),
        ],
      ),
    ),
  );
}

class _WorkbenchAnnotationDock extends StatefulWidget {
  const _WorkbenchAnnotationDock({
    required this.target,
    required this.draft,
    required this.focusNode,
    required this.onDraftChanged,
    required this.onCommit,
  });

  final DesyWorkbenchWidgetTarget? target;
  final String draft;
  final FocusNode focusNode;
  final ValueChanged<String> onDraftChanged;
  final VoidCallback onCommit;

  @override
  State<_WorkbenchAnnotationDock> createState() =>
      _WorkbenchAnnotationDockState();
}

class _WorkbenchAnnotationDockState extends State<_WorkbenchAnnotationDock> {
  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final selectedTarget = widget.target;
    return DecoratedBox(
      key: const ValueKey('workbench-annotation-dock'),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusMd),
        boxShadow: [
          BoxShadow(
            color: colors.foreground.withValues(alpha: .1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Annotate ${selectedTarget?.displayLabel ?? ''}',
                    style: typography.body.sm.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (selectedTarget != null) ...[
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              DesyTextField(
                key: const ValueKey('workbench-annotation-input'),
                label: 'Feedback for ${selectedTarget.displayLabel}',
                hintText: 'What should change about this widget?',
                value: widget.draft,
                focusNode: widget.focusNode,
                minLines: 2,
                maxLines: 4,
                onChanged: widget.onDraftChanged,
              ),
              const SizedBox(height: DesyDesignSystemTokens.spaceSm),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: DesyButton(
                  key: const ValueKey('workbench-commit-annotation'),
                  size: DesyButtonSize.sm,
                  mainAxisSize: MainAxisSize.min,
                  onPress: widget.draft.trim().isEmpty ? null : widget.onCommit,
                  child: const Text('Commit annotation'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkbenchAnnotationItem extends StatefulWidget {
  const _WorkbenchAnnotationItem({required this.annotation});

  final DesyWorkbenchAnnotation annotation;

  @override
  State<_WorkbenchAnnotationItem> createState() =>
      _WorkbenchAnnotationItemState();
}

class _WorkbenchAnnotationItemState extends State<_WorkbenchAnnotationItem> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final annotation = widget.annotation;
    final target = annotation.target;
    return Semantics(
      button: true,
      label: _expanded
          ? 'Collapse annotation ${annotation.id}'
          : 'Expand annotation ${annotation.id}',
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesyDesignSystemTokens.spaceXs,
            vertical: DesyDesignSystemTokens.spaceXs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${target.widgetType}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: annotation.comment),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.body.xs,
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: colors.mutedForeground,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                Text(
                  target.inspectionContext == null
                      ? target.screenId
                      : '${target.inspectionContext!.kind}: '
                            '${target.inspectionContext!.label ?? target.inspectionContext!.artifactId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
                if (target.sourceLocation case final source?)
                  Text(
                    source.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                      fontFamily: 'monospace',
                    ),
                  )
                else
                  Text(
                    target.widgetPath,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.body.xs.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                if (annotation.attachment ==
                    DesyWorkbenchAnnotationAttachment.detached) ...[
                  const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                  Text(
                    'Needs reattachment after hot reload',
                    style: typography.body.xs.copyWith(
                      color: colors.desy.signal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkbenchSelectionOutlinePainter extends CustomPainter {
  const _WorkbenchSelectionOutlinePainter({
    required this.bounds,
    required this.color,
  });

  final Rect bounds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(bounds, Paint()..color = color.withValues(alpha: .18));
    canvas.drawRect(
      bounds,
      Paint()
        ..color = color.withValues(alpha: .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7,
    );
    canvas.drawRect(
      bounds.deflate(1.5),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _WorkbenchSelectionOutlinePainter oldDelegate) =>
      oldDelegate.bounds != bounds || oldDelegate.color != color;
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
        builder: (dialogContext, animation) => DesyDialog(
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
    inspectionContext: DesyWorkbenchInspectionContext(
      artifactId: widget.entry.id,
      kind: 'Registry entry',
      label: widget.entry.name,
    ),
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
