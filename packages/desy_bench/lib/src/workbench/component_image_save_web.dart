// Internal browser image-save implementation.
// ignore_for_file: public_member_api_docs

import 'package:file_selector/file_selector.dart';

import 'component_image_export.dart';

Future<DesyImageSaveResult> saveDesyImage(DesyExportedImage image) async {
  final file = XFile.fromData(
    image.bytes,
    mimeType: 'image/png',
    name: image.fileName,
  );
  // XFile ignores the path on web and triggers a browser download using name.
  await file.saveTo(image.fileName);
  return DesyImageSaveResult.saved;
}
