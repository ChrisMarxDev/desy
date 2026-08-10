import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

const _captureInterval = Duration(milliseconds: 200);
const _frameDirectory = 'build/desy_ide_runtime';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _PreviewRuntimeApp());
}

class _PreviewRuntimeApp extends StatelessWidget {
  const _PreviewRuntimeApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: DesyDesignSystemFoundation.materialTheme(
      DesyDesignSystemTheme.light,
    ),
    home: const DesyDesignSystemScope(
      theme: DesyDesignSystemTheme.light,
      child: _LiveCapturedPreview(),
    ),
  );
}

class _LiveCapturedPreview extends StatefulWidget {
  const _LiveCapturedPreview();

  @override
  State<_LiveCapturedPreview> createState() => _LiveCapturedPreviewState();
}

class _LiveCapturedPreviewState extends State<_LiveCapturedPreview> {
  final _boundaryKey = GlobalKey();
  Timer? _captureTimer;
  var _capturing = false;
  var _sequence = 0;

  @override
  void initState() {
    super.initState();
    _captureTimer = Timer.periodic(_captureInterval, (_) => _scheduleCapture());
    _scheduleCapture();
  }

  @override
  void reassemble() {
    super.reassemble();
    stdout.writeln('[desy_ide_runtime] hot-reload-reassemble');
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    super.dispose();
  }

  void _scheduleCapture() {
    if (_capturing || !mounted) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureFrame());
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _captureFrame() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null || boundary.debugNeedsPaint || _capturing) {
      return;
    }

    _capturing = true;
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        return;
      }

      final sequence = ++_sequence;
      final output = File(
        '$_frameDirectory/frame_${sequence % 2}.png',
      ).absolute;
      await output.parent.create(recursive: true);
      await output.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      stdout.writeln(
        '[desy_ide_runtime] frame-ready '
        'sequence=$sequence path=${output.path}',
      );
    } finally {
      image.dispose();
      _capturing = false;
    }
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _boundaryKey, child: const _LiveWidget());
}

class _LiveWidget extends StatefulWidget {
  const _LiveWidget();

  @override
  State<_LiveWidget> createState() => _LiveWidgetState();
}

class _LiveWidgetState extends State<_LiveWidget> {
  Timer? _timer;
  var _tick = 0;
  var _pulse = false;

  String get _runtimeMarker => 'live-widget-hot-reloaded';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {
          _tick++;
          _pulse = !_pulse;
        });
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    stdout.writeln(
      '[desy_ide_runtime] build marker=$_runtimeMarker tick=$_tick',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return ColoredBox(
      color: colors.background,
      child: Center(
        child: SizedBox(
          width: 430,
          child: FCard(
            child: Padding(
              padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Live Flutter widget',
                          style: typography.display.sm,
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        width: _pulse ? 20 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceSm),
                  Text(
                    'This card is running in a separate Flutter engine.',
                    style: typography.body.md.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceLg),
                  Text(
                    _runtimeMarker,
                    style: typography.body.lg.copyWith(color: colors.primary),
                  ),
                  const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                  Text('Runtime tick: $_tick'),
                  const SizedBox(height: DesyDesignSystemTokens.spaceMd),
                  FButton(
                    mainAxisSize: MainAxisSize.min,
                    onPress: () => setState(() => _tick++),
                    child: const Text('Runtime-local interaction'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
