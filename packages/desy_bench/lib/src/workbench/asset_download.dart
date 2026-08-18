// Internal platform asset-save implementation.
// ignore_for_file: public_member_api_docs

export 'asset_download_io.dart'
    if (dart.library.js_interop) 'asset_download_web.dart';

enum DesyAssetSaveResult { saved, cancelled }
