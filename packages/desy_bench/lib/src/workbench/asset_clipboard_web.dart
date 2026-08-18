// Internal browser clipboard implementation.
// ignore_for_file: public_member_api_docs

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Future<void> copyPngBytesToClipboard(Uint8List bytes) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final item = web.ClipboardItem({'image/png': blob}.jsify()! as JSObject);
  await web.window.navigator.clipboard.write([item].toJS).toDart;
}
