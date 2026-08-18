// Internal packaged asset handoff helpers.
// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:desy_core/desy_core.dart';
import 'package:flutter/services.dart';

import 'asset_clipboard.dart';
import 'asset_download.dart';

/// Copies a bundled raster asset as a real PNG image on supported browsers.
Future<void> copyDesyAssetImage(DesyAssetEntry asset) async {
  final bytes = await _load(asset);
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    try {
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('Could not encode the image as PNG.');
      await copyPngBytesToClipboard(png.buffer.asUint8List());
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

/// Downloads the original bytes of a bundled asset with its declared filename.
Future<DesyAssetSaveResult> downloadDesyAsset(DesyAssetEntry asset) async =>
    saveDesyAsset(
      bytes: await _load(asset),
      fileName: asset.fileName,
      mimeType: asset.mimeType,
    );

Future<Uint8List> _load(DesyAssetEntry asset) async {
  final data = await rootBundle.load(asset.assetKey);
  return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
}
