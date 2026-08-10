import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';

const _configuredProjectDirectory = String.fromEnvironment(
  'DESY_IDE_PROJECT_DIR',
);
const _frameLinePrefix = '[desy_ide_runtime] frame-ready ';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _DesyIdeHostApp());
}

class _DesyIdeHostApp extends StatelessWidget {
  const _DesyIdeHostApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Desy IDE',
    theme: DesyDesignSystemFoundation.materialTheme(
      DesyDesignSystemTheme.light,
    ),
    home: const DesyDesignSystemScope(
      theme: DesyDesignSystemTheme.light,
      child: _DesyIdeScreen(),
    ),
  );
}

class _DesyIdeScreen extends StatefulWidget {
  const _DesyIdeScreen();

  @override
  State<_DesyIdeScreen> createState() => _DesyIdeScreenState();
}

class _DesyIdeScreenState extends State<_DesyIdeScreen> {
  late final _RuntimeController _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = _RuntimeController(_resolveProjectDirectory())
      ..addListener(_handleRuntimeChange);
    unawaited(_runtime.start());
  }

  @override
  void dispose() {
    _runtime
      ..removeListener(_handleRuntimeChange)
      ..dispose();
    super.dispose();
  }

  void _handleRuntimeChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final running = _runtime.status == _RuntimeStatus.running;

    return ColoredBox(
      color: colors.background,
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Desy IDE', style: typography.display.xl2),
                      const SizedBox(height: DesyDesignSystemTokens.spaceXs),
                      Text(
                        'A macOS host displaying pixels from an isolated '
                        'Flutter runtime.',
                        style: typography.body.sm.copyWith(
                          color: colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                _RuntimeStatusBadge(status: _runtime.status),
                const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                FButton(
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  onPress: running ? _runtime.hotReload : null,
                  child: const Text('Hot reload'),
                ),
                const SizedBox(width: DesyDesignSystemTokens.spaceSm),
                FButton(
                  mainAxisSize: MainAxisSize.min,
                  onPress: () => unawaited(_runtime.restart()),
                  child: const Text('Restart runtime'),
                ),
              ],
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceLg),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: _PreviewPanel(runtime: _runtime)),
                  const SizedBox(width: DesyDesignSystemTokens.spaceMd),
                  SizedBox(
                    width: 330,
                    child: _RuntimeLogPanel(runtime: _runtime),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.runtime});

  final _RuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;
    final frame = runtime.frameBytes;

    return FCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Row(
              children: [
                Expanded(child: Text('Live widget', style: typography.body.lg)),
                Text(
                  frame == null
                      ? 'Waiting for first frame'
                      : 'Frame ${runtime.frameSequence} • 800 × 600',
                  style: typography.body.xs.copyWith(
                    color: colors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(color: colors.border, child: const SizedBox(height: 1)),
          Expanded(
            child: ColoredBox(
              color: colors.secondary,
              child: Padding(
                padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.background,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(
                          DesyDesignSystemTokens.radiusMd,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          DesyDesignSystemTokens.radiusMd,
                        ),
                        child: frame == null
                            ? Center(
                                child: Text(
                                  runtime.status.label,
                                  style: typography.body.sm.copyWith(
                                    color: colors.mutedForeground,
                                  ),
                                ),
                              )
                            : Image.memory(
                                frame,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                filterQuality: FilterQuality.high,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
            child: Text(
              'Live pixel stream from flutter_tester. Input forwarding is '
              'intentionally outside this slice.',
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuntimeLogPanel extends StatelessWidget {
  const _RuntimeLogPanel({required this.runtime});

  final _RuntimeController runtime;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FCard(
      child: Padding(
        padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Runtime', style: typography.body.lg),
            const SizedBox(height: DesyDesignSystemTokens.spaceSm),
            Text(
              runtime.projectDirectory,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.body.xs.copyWith(color: colors.mutedForeground),
            ),
            const SizedBox(height: DesyDesignSystemTokens.spaceMd),
            Expanded(
              child: ColoredBox(
                color: colors.secondary,
                child: Padding(
                  padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceSm),
                  child: SingleChildScrollView(
                    reverse: true,
                    child: SelectionArea(
                      child: Text(
                        runtime.logs.isEmpty
                            ? 'Starting Flutter runtime…'
                            : runtime.logs.join('\n'),
                        style: typography.body.xs.copyWith(
                          color: colors.foreground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuntimeStatusBadge extends StatelessWidget {
  const _RuntimeStatusBadge({required this.status});

  final _RuntimeStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final active = status == _RuntimeStatus.running;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: active ? colors.primary.withValues(alpha: .1) : colors.secondary,
        border: Border.all(color: active ? colors.primary : colors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: active ? colors.primary : colors.mutedForeground,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 7),
            ),
            const SizedBox(width: DesyDesignSystemTokens.spaceSm),
            Text(status.label),
          ],
        ),
      ),
    );
  }
}

enum _RuntimeStatus {
  stopped('Stopped'),
  starting('Starting runtime…'),
  running('Live'),
  stopping('Stopping…'),
  failed('Runtime failed');

  const _RuntimeStatus(this.label);

  final String label;
}

class _RuntimeController extends ChangeNotifier {
  _RuntimeController(this.projectDirectory);

  final String projectDirectory;
  final logs = <String>[];

  Process? _process;
  var status = _RuntimeStatus.stopped;
  Uint8List? frameBytes;
  var frameSequence = 0;
  var _disposed = false;

  Future<void> start() async {
    if (_process != null || _disposed) {
      return;
    }

    status = _RuntimeStatus.starting;
    _appendLog('Launching flutter_tester…');

    try {
      final process = await Process.start(
        'flutter',
        const [
          'run',
          '--show-test-device',
          '-d',
          'flutter-tester',
          '-t',
          'lib/preview_runtime_main.dart',
        ],
        workingDirectory: projectDirectory,
        runInShell: true,
      );
      if (_disposed) {
        process.kill();
        return;
      }

      _process = process;
      _appendLog('Runtime process ${process.pid} started.');
      process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleRuntimeLine);
      process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => _appendLog('stderr: $line'));
      unawaited(
        process.exitCode.then((code) {
          if (_process != process || _disposed) {
            return;
          }
          _process = null;
          status = code == 0 ? _RuntimeStatus.stopped : _RuntimeStatus.failed;
          _appendLog('Runtime exited with code $code.');
        }),
      );
    } on Object catch (error) {
      status = _RuntimeStatus.failed;
      _appendLog('Could not start runtime: $error');
    }
  }

  void hotReload() {
    final process = _process;
    if (process == null) {
      return;
    }
    _appendLog('Requesting hot reload…');
    process.stdin.writeln('r');
  }

  Future<void> restart() async {
    await stop();
    frameBytes = null;
    frameSequence = 0;
    await start();
  }

  Future<void> stop() async {
    final process = _process;
    if (process == null) {
      return;
    }

    status = _RuntimeStatus.stopping;
    _notify();
    process.stdin.writeln('q');
    try {
      await process.exitCode.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      process.kill();
      await process.exitCode;
    }
    if (_process == process) {
      _process = null;
      status = _RuntimeStatus.stopped;
      _notify();
    }
  }

  Future<void> _handleRuntimeLine(String line) async {
    if (line.startsWith(_frameLinePrefix)) {
      final fields = line.substring(_frameLinePrefix.length);
      final separator = fields.indexOf(' path=');
      if (!fields.startsWith('sequence=') || separator < 0) {
        return;
      }
      final sequence = int.tryParse(
        fields.substring('sequence='.length, separator),
      );
      final path = fields.substring(separator + ' path='.length);
      if (sequence == null || sequence <= frameSequence) {
        return;
      }

      try {
        final bytes = await File(path).readAsBytes();
        if (sequence <= frameSequence || _disposed) {
          return;
        }
        frameBytes = bytes;
        frameSequence = sequence;
        status = _RuntimeStatus.running;
        _notify();
      } on FileSystemException catch (error) {
        _appendLog('Could not read frame $sequence: ${error.message}');
      }
      return;
    }

    if (line.contains('Performing hot reload') ||
        line.contains('Reloaded ') ||
        line.contains('Launching ') ||
        line.contains('Dart VM Service') ||
        line.startsWith('[desy_ide_runtime]')) {
      _appendLog(line);
    }
  }

  void _appendLog(String line) {
    logs.add(line);
    if (logs.length > 80) {
      logs.removeRange(0, logs.length - 80);
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    final process = _process;
    _process = null;
    process?.stdin.writeln('q');
    super.dispose();
  }
}

String _resolveProjectDirectory() {
  if (_configuredProjectDirectory.isNotEmpty) {
    return _configuredProjectDirectory;
  }
  return Directory.current.absolute.path;
}
