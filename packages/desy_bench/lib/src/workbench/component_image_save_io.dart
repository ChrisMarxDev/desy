// Internal native image-save implementation.
// ignore_for_file: public_member_api_docs

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'component_image_export.dart';

Future<DesyImageSaveResult> saveDesyImage(DesyExportedImage image) async {
  if (defaultTargetPlatform != TargetPlatform.linux &&
      defaultTargetPlatform != TargetPlatform.macOS &&
      defaultTargetPlatform != TargetPlatform.windows) {
    throw UnsupportedError(
      'Image export is currently available on desktop and web.',
    );
  }

  final location = await getSaveLocation(suggestedName: image.fileName);
  if (location == null) return DesyImageSaveResult.cancelled;
  final file = XFile.fromData(
    image.bytes,
    mimeType: 'image/png',
    name: image.fileName,
  );
  await file.saveTo(location.path);
  return DesyImageSaveResult.saved;
}
