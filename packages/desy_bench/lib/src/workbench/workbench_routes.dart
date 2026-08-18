// Routes are internal workbench infrastructure, not consumer API.
// ignore_for_file: public_member_api_docs

/// Canonical, deep-linkable locations in a Desy workbench.
///
/// A component group remains a query value because the route must be nestable.
/// Its value is the canonical component path, never its derived display label.
abstract final class DesyWorkbenchRoutes {
  static const homePath = '/home';
  static const atlasPath = '/atlas';
  static const canvasPath = '/canvas';
  static const sketchSegment = 'sketch';
  static const sketchPath = '$atlasPath/$sketchSegment';
  static const themesPath = '/themes';
  static const componentsPath = sketchPath;
  static const entriesPath = '/entries';
  static const prototypesPath = '/prototypes';
  static const workspacePath = '/workspace';

  static String atlas({String? folderId}) {
    if (folderId == null) return atlasPath;
    return Uri(
      path: atlasPath,
      queryParameters: {'folder': folderId},
    ).toString();
  }

  static String entry(String entryId) =>
      '$entriesPath/${Uri.encodeComponent(entryId)}';

  static String prototype(String sessionId) =>
      '$prototypesPath/${Uri.encodeComponent(sessionId)}';

  static String workspaceExtension(String extensionId) =>
      '$workspacePath/${Uri.encodeComponent(extensionId)}';
}
