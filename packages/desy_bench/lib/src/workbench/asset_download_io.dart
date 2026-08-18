// Internal native asset-save implementation.
// ignore_for_file: public_member_api_docs

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'asset_download.dart';

Future<DesyAssetSaveResult> saveDesyAsset({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  if (defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.macOS &&
      defaultTargetPlatform != TargetPlatform.windows) {
    throw UnsupportedError(
      'Asset download is currently available on desktop and web.',
    );
  }
  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null) return DesyAssetSaveResult.cancelled;
  await XFile.fromData(
    bytes,
    mimeType: mimeType,
    name: fileName,
  ).saveTo(location.path);
  return DesyAssetSaveResult.saved;
}
