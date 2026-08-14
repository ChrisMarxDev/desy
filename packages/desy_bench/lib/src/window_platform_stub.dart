import 'window_controls.dart';

/// Does nothing when the host has no native desktop window API.
Future<void> prepareDesyPlatform() async {}

/// Provides no controls when the host has no native desktop window API.
DesyWindowControls? createDesyWindowControls() => null;
