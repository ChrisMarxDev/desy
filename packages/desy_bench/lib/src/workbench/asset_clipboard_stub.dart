// Internal fallback clipboard implementation.
// ignore_for_file: public_member_api_docs

import 'dart:typed_data';

Future<void> copyPngBytesToClipboard(Uint8List bytes) => throw UnsupportedError(
  'Copy image is currently available in a supported web browser.',
);
