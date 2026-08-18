// Internal PNG capture for the screenshot-builder extension.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

Future<String> saveDesyScreenshot(Uint8List bytes) =>
    FileSaver.instance.saveFile(
      name: 'desy-screenshot',
      bytes: bytes,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
