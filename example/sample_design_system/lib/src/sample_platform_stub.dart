/// No filesystem source root is available in a browser build.
String? get sampleSourceRoot => null;

/// Browser builds need no desktop window preparation.
Future<void> prepareSamplePlatform() async {}
