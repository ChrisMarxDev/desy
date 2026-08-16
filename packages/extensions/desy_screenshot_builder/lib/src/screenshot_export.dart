// Internal PNG capture for the screenshot-builder extension.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

Future<Uint8List> captureDesyScreenshot(GlobalKey boundaryKey) async {
  final boundary = boundaryKey.currentContext?.findRenderObject();
  if (boundary is! RenderRepaintBoundary) {
    throw StateError('The screenshot canvas is not ready.');
  }
  if (boundary.debugNeedsPaint) {
    throw StateError('The screenshot canvas has not finished painting.');
  }
  if (boundary.size.isEmpty) {
    throw StateError('The screenshot canvas is empty.');
  }

  final image = await boundary.toImage(pixelRatio: 1);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw StateError('Flutter could not encode the screenshot as PNG.');
    }
    return Uint8List.fromList(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
  } finally {
    image.dispose();
  }
}

Future<String> saveDesyScreenshot(Uint8List bytes) =>
    FileSaver.instance.saveFile(
      name: 'desy-screenshot',
      bytes: bytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
