// Routes are internal workbench infrastructure, not consumer API.
// ignore_for_file: public_member_api_docs

/// Canonical, deep-linkable locations in a Desy workbench.
///
/// A folder remains a query value because the route must remain nestable.
/// Its value is the consumer-declared stable folder ID, never its display name.
abstract final class DesyWorkbenchRoutes {
  static const atlasPath = '/atlas';
  static const sketchSegment = 'sketch';
  static const sketchPath = '$atlasPath/$sketchSegment';
  static const themesPath = '/themes';
  static const showcasesPath = '/showcases';
  static const componentsPath = sketchPath;
  static const entriesPath = '/entries';
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

  static String workspaceExtension(String extensionId) =>
      '$workspacePath/${Uri.encodeComponent(extensionId)}';
}
