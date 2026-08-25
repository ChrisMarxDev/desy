/// Experimental client for `codex app-server` over local stdio.
library;

export 'src/codex_app_server_client_stub.dart'
    if (dart.library.io) 'src/codex_app_server_client.dart';
