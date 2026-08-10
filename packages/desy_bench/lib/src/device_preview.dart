import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

/// The real device profiles currently supported by Desy previews.
///
/// A profile owns immutable screen geometry. Workbench drag boxes may change
/// how large the completed device is displayed, but never these logical
/// dimensions or the media context delivered to the consumer widget.
enum DesyDevicePreset {
  /// Apple iPhone 15 Pro in portrait orientation.
  iPhone15Pro,

  /// Apple iPad Pro 11-inch in portrait orientation.
  iPadPro11,
}

/// Immutable geometry and presentation metadata for a [DesyDevicePreset].
extension DesyDevicePresetContract on DesyDevicePreset {
  /// Human-readable device name used consistently across Desy surfaces.
  String get label => switch (this) {
    DesyDevicePreset.iPhone15Pro => 'iPhone 15 Pro',
    DesyDevicePreset.iPadPro11 => 'iPad Pro 11',
  };

  /// Device Frame profile containing physical frame and screen geometry.
  DeviceInfo get device => switch (this) {
    DesyDevicePreset.iPhone15Pro => Devices.ios.iPhone15Pro,
    DesyDevicePreset.iPadPro11 => Devices.ios.iPadPro11Inches,
  };

  /// Fixed logical Flutter viewport supplied to the consumer widget.
  Size get screenSize => device.screenSize;

  /// Physical frame dimensions before Desy applies presentation scaling.
  Size get frameSize => device.frameSize;
}

/// Renders a real consumer widget inside an accurate, visible device frame.
///
/// The child always lays out using the device's logical screen size, pixel
/// ratio, platform, and safe-area values. The completed frame and its child
/// are then scaled down together to fit the available Desy surface. Desy does
/// not insert a [SafeArea] or scrolling behavior on the consumer's behalf.
class DesyDevicePreview extends StatelessWidget {
  /// Creates a fixed-geometry device preview.
  const DesyDevicePreview({
    super.key,
    required this.device,
    required this.child,
    this.alignment = Alignment.center,
  });

  /// Immutable device profile used for frame and media-query geometry.
  final DesyDevicePreset device;

  /// Real consumer content rendered as the device's screen.
  final Widget child;

  /// Placement when the available Desy surface is larger than the device.
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final profile = device.device;
    return Semantics(
      label: '${device.label} device preview',
      child: FittedBox(
        key: ValueKey('desy-device-fit-${device.name}'),
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: SizedBox(
          key: ValueKey('desy-device-frame-${device.name}'),
          width: profile.frameSize.width,
          height: profile.frameSize.height,
          child: DeviceFrame(device: profile, screen: child),
        ),
      ),
    );
  }
}

/// Coordinate conversions shared by device previews and functional artboards.
abstract final class DesyDeviceGeometry {
  /// Maps the device's physical screen bounds into a displayed frame [rect].
  static Rect screenRectInFrame(Rect rect, DesyDevicePreset preset) {
    final device = preset.device;
    final frameSize = device.frameSize;
    if (rect.width <= 0 || rect.height <= 0) {
      return Rect.fromLTWH(rect.left, rect.top, 0, 0);
    }
    final scale = _min(
      rect.width / frameSize.width,
      rect.height / frameSize.height,
    );
    final displayedFrame = Size(
      frameSize.width * scale,
      frameSize.height * scale,
    );
    final frameOrigin = Offset(
      rect.left + (rect.width - displayedFrame.width) / 2,
      rect.top + (rect.height - displayedFrame.height) / 2,
    );
    final screen = device.screenPath.getBounds();
    return Rect.fromLTWH(
      frameOrigin.dx + screen.left * scale,
      frameOrigin.dy + screen.top * scale,
      screen.width * scale,
      screen.height * scale,
    );
  }

  /// Locks a proposed frame resize to the device's physical aspect ratio.
  static Rect lockFrameAspect({
    required DesyDevicePreset preset,
    required Rect current,
    required Rect proposed,
    Rect? clampingRect,
  }) {
    final ratio = preset.frameSize.aspectRatio;
    final widthDriven =
        (proposed.width - current.width).abs() >
        (proposed.height - current.height).abs() * ratio;
    var width = widthDriven
        ? proposed.width.abs()
        : proposed.height.abs() * ratio;
    var height = width / ratio;
    final rightAnchored =
        (proposed.right - current.right).abs() <
        (proposed.left - current.left).abs();
    final bottomAnchored =
        (proposed.bottom - current.bottom).abs() <
        (proposed.top - current.top).abs();
    final bounds = clampingRect;
    if (bounds == null) {
      return Rect.fromLTWH(
        rightAnchored ? current.right - width : current.left,
        bottomAnchored ? current.bottom - height : current.top,
        width.isFinite && width > 0 ? width : 0,
        height.isFinite && height > 0 ? height : 0,
      );
    }
    if (bounds.width <= 0 || bounds.height <= 0) {
      return Rect.fromLTWH(bounds.left, bounds.top, 0, 0);
    }

    final stationaryX = (rightAnchored ? current.right : current.left)
        .clamp(bounds.left, bounds.right)
        .toDouble();
    final stationaryY = (bottomAnchored ? current.bottom : current.top)
        .clamp(bounds.top, bounds.bottom)
        .toDouble();
    final horizontalCapacity = rightAnchored
        ? stationaryX - bounds.left
        : bounds.right - stationaryX;
    final verticalCapacity = bottomAnchored
        ? stationaryY - bounds.top
        : bounds.bottom - stationaryY;
    final maximumWidth = _min(horizontalCapacity, verticalCapacity * ratio);
    width = width.clamp(0.0, maximumWidth).toDouble();
    height = width / ratio;
    return Rect.fromLTWH(
      rightAnchored ? stationaryX - width : stationaryX,
      bottomAnchored ? stationaryY - height : stationaryY,
      width,
      height,
    );
  }

  static double _min(double left, double right) => left < right ? left : right;
}
