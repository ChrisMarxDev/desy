// Internal browser asset-save implementation.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

import 'asset_download.dart';

Future<DesyAssetSaveResult> saveDesyAsset({
  required Uint8List bytes,
  required String fileName,
  required String mimeType,
}) async {
  await XFile.fromData(
    bytes,
    mimeType: mimeType,
    name: fileName,
  ).saveTo(fileName);
  return DesyAssetSaveResult.saved;
}
