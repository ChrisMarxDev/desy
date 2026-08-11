// Internal global keyboard support for the workbench.
// ignore_for_file: public_member_api_docs

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'workbench_navigation_tree.dart';
import 'workbench_routes.dart';

enum DesyWorkbenchTraversal { next, previous, firstChild, parent }

class DesyWorkbenchTraverseIntent extends Intent {
  const DesyWorkbenchTraverseIntent(this.direction);

  final DesyWorkbenchTraversal direction;
}

class DesyWorkbenchOpenIntent extends Intent {
  const DesyWorkbenchOpenIntent(this.location);

  final String location;
}

/// Central keyboard bindings for every ShellRoute descendant.
///
/// Modifier shortcuts leave native text editing alone while providing a stable
/// base for the command palette and richer registry-tree navigation later.
class DesyWorkbenchShortcuts extends StatelessWidget {
  const DesyWorkbenchShortcuts({
    super.key,
    required this.location,
    required this.tree,
    required this.onNavigate,
    required this.child,
  });

  final Uri location;
  final DesyWorkbenchNavigationTree tree;
  final ValueChanged<String> onNavigate;
  final Widget child;

  @override
  Widget build(BuildContext context) => Shortcuts(
    shortcuts: {
      const SingleActivator(LogicalKeyboardKey.digit1, meta: true):
          const DesyWorkbenchOpenIntent(DesyWorkbenchRoutes.atlasPath),
      const SingleActivator(LogicalKeyboardKey.digit1, control: true):
          const DesyWorkbenchOpenIntent(DesyWorkbenchRoutes.atlasPath),
      const SingleActivator(LogicalKeyboardKey.digit2, meta: true):
          const DesyWorkbenchOpenIntent(DesyWorkbenchRoutes.componentsPath),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true):
          const DesyWorkbenchOpenIntent(DesyWorkbenchRoutes.componentsPath),
      const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true):
          const DesyWorkbenchTraverseIntent(DesyWorkbenchTraversal.next),
      const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true):
          const DesyWorkbenchTraverseIntent(DesyWorkbenchTraversal.previous),
      const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
          const DesyWorkbenchTraverseIntent(DesyWorkbenchTraversal.firstChild),
      const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
          const DesyWorkbenchTraverseIntent(DesyWorkbenchTraversal.parent),
      const SingleActivator(LogicalKeyboardKey.escape):
          const DesyWorkbenchOpenIntent(DesyWorkbenchRoutes.atlasPath),
    },
    child: Actions(
      actions: {
        DesyWorkbenchOpenIntent: CallbackAction<DesyWorkbenchOpenIntent>(
          onInvoke: (intent) {
            onNavigate(intent.location);
            return null;
          },
        ),
        DesyWorkbenchTraverseIntent:
            CallbackAction<DesyWorkbenchTraverseIntent>(
              onInvoke: (intent) {
                final destination = switch (intent.direction) {
                  DesyWorkbenchTraversal.next => tree.adjacent(
                    location,
                    forward: true,
                  ),
                  DesyWorkbenchTraversal.previous => tree.adjacent(
                    location,
                    forward: false,
                  ),
                  DesyWorkbenchTraversal.firstChild => tree.firstChild(
                    location,
                  ),
                  DesyWorkbenchTraversal.parent => tree.parent(location),
                };
                if (destination != null) onNavigate(destination);
                return null;
              },
            ),
      },
      child: child,
    ),
  );
}
