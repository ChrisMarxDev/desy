// Internal workspace-extension host.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../workspace_extension.dart';
import '../../workspace_focus.dart';
import '../workbench_routes.dart';
import '../workbench_session.dart';

/// Rebuilds an extension screen with the current read-only Desy context.
class DesyWorkspaceExtensionScreen extends StatelessWidget {
  const DesyWorkspaceExtensionScreen({
    super.key,
    required this.session,
    required this.extension,
  });

  final DesyWorkbenchSession session;
  final DesyWorkspaceExtension extension;

  @override
  Widget build(BuildContext context) {
    // Observe the theme so extension output follows the same preview context
    // as Atlas, details, and sketching without receiving mutable session state.
    session.activeThemeIndex.watch(context);
    final annotations = session.workbenchAnnotations.watch(context);
    final pendingRequest = session.pendingAgentRequest.watch(context);
    final location = GoRouterState.of(context).uri;
    return extension.build(
      context,
      DesyWorkspaceExtensionContext(
        registry: session.registry,
        activeTheme: session.activeTheme,
        focus: DesyWorkspaceFocus.resolve(
          registry: session.registry,
          activeTheme: session.activeTheme,
          route: location.toString(),
        ),
        workbenchAnnotations: annotations,
        pendingAgentRequest: pendingRequest,
        onPendingAgentRequestConsumed: session.consumePendingAgentRequest,
        onExit: () => context.go(DesyWorkbenchRoutes.atlasPath),
      ),
    );
  }
}
