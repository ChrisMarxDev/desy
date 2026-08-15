// Internal workbench image-export contract.
// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum DesyImageSaveResult { saved, cancelled }

@immutable
class DesyExportedImage {
  const DesyExportedImage({
    required this.bytes,
    required this.fileName,
    required this.logicalSize,
    required this.pixelRatio,
  });

  final Uint8List bytes;
  final String fileName;
  final Size logicalSize;
  final double pixelRatio;
}

typedef DesyImageSaver =
    Future<DesyImageSaveResult> Function(DesyExportedImage image);

typedef DesyImageExportAction =
    Future<DesyImageSaveResult> Function({
      required GlobalKey boundaryKey,
      required String fileName,
    });

class DesyComponentImageExporter {
  const DesyComponentImageExporter({
    required this.saveImage,
    this.pixelRatio = 2,
  }) : assert(pixelRatio > 0);

  final DesyImageSaver saveImage;
  final double pixelRatio;

  Future<DesyImageSaveResult> export({
    required GlobalKey boundaryKey,
    required String fileName,
  }) async {
    if (pixelRatio <= 0) {
      throw ArgumentError.value(pixelRatio, 'pixelRatio', 'Must be positive');
    }

    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('The active component is not ready to export.');
    }
    if (boundary.debugNeedsPaint) {
      throw StateError('The active component has not finished painting.');
    }
    if (boundary.size.isEmpty) {
      throw StateError('The active component has no visible bounds.');
    }

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('Flutter could not encode the component as PNG.');
      }
      final bytes = Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
      return saveImage(
        DesyExportedImage(
          bytes: bytes,
          fileName: fileName,
          logicalSize: boundary.size,
          pixelRatio: pixelRatio,
        ),
      );
    } finally {
      image.dispose();
    }
  }
}

String desyPngFileName({
  required String entryId,
  required String variantId,
  required String themeId,
  double pixelRatio = 2,
}) {
  final scale = pixelRatio == pixelRatio.roundToDouble()
      ? pixelRatio.round().toString()
      : pixelRatio.toStringAsFixed(1);
  return '${_fileSegment(entryId, fallback: 'component')}-'
      '${_fileSegment(variantId, fallback: 'default')}-'
      '${_fileSegment(themeId, fallback: 'theme')}@${scale}x.png';
}

String _fileSegment(String value, {required String fallback}) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  return normalized.isEmpty ? fallback : normalized;
}
