part of 'screenshot_builder_extension.dart';

// ignore_for_file: public_member_api_docs

const _unchanged = Object();

abstract class DesyScreenshotLayer {
  DesyScreenshotLayer({
    required this.id,
    required this.name,
    this.hidden = false,
  });

  final String id;
  final String name;
  final bool hidden;

  String get kindLabel;

  DesyScreenshotLayer copyWith({String? id, String? name, bool? hidden});
}

final class DesyScreenshotWidgetLayer extends DesyScreenshotLayer {
  DesyScreenshotWidgetLayer({
    required super.id,
    required super.name,
    required this.componentId,
    this.instanceId,
    required Map<String, Object> knobValues,
    super.hidden,
  }) : knobValues = Map.unmodifiable(knobValues);

  final String componentId;
  final String? instanceId;
  final Map<String, Object> knobValues;

  @override
  String get kindLabel => 'Widget';

  @override
  DesyScreenshotWidgetLayer copyWith({
    String? id,
    String? name,
    bool? hidden,
    String? componentId,
    String? instanceId,
    Map<String, Object>? knobValues,
  }) => DesyScreenshotWidgetLayer(
    id: id ?? this.id,
    name: name ?? this.name,
    componentId: componentId ?? this.componentId,
    instanceId: instanceId ?? this.instanceId,
    knobValues: knobValues ?? this.knobValues,
    hidden: hidden ?? this.hidden,
  );
}

final class DesyScreenshotImageLayer extends DesyScreenshotLayer {
  DesyScreenshotImageLayer({
    required super.id,
    required super.name,
    required this.bytes,
    super.hidden,
  });

  final Uint8List bytes;

  @override
  String get kindLabel => 'Image';

  @override
  DesyScreenshotImageLayer copyWith({String? id, String? name, bool? hidden}) =>
      DesyScreenshotImageLayer(
        id: id ?? this.id,
        name: name ?? this.name,
        bytes: bytes,
        hidden: hidden ?? this.hidden,
      );
}

final class DesyScreenshotTextLayer extends DesyScreenshotLayer {
  DesyScreenshotTextLayer({
    required super.id,
    required super.name,
    required this.text,
    this.typographyId,
    this.colorId,
    this.textAlign = TextAlign.start,
    super.hidden,
  });

  final String text;
  final String? typographyId;
  final String? colorId;
  final TextAlign textAlign;

  @override
  String get kindLabel => 'Text';

  @override
  DesyScreenshotTextLayer copyWith({
    String? id,
    String? name,
    bool? hidden,
    String? text,
    Object? typographyId = _unchanged,
    Object? colorId = _unchanged,
    TextAlign? textAlign,
  }) => DesyScreenshotTextLayer(
    id: id ?? this.id,
    name: name ?? this.name,
    text: text ?? this.text,
    typographyId: identical(typographyId, _unchanged)
        ? this.typographyId
        : typographyId as String?,
    colorId: identical(colorId, _unchanged) ? this.colorId : colorId as String?,
    textAlign: textAlign ?? this.textAlign,
    hidden: hidden ?? this.hidden,
  );
}

final class _ScreenshotMiscLayer extends DesyScreenshotLayer {
  _ScreenshotMiscLayer({
    required super.id,
    required super.name,
    required this.kind,
    super.hidden,
  });

  final _MiscWidgetKind kind;

  @override
  String get kindLabel => 'Misc';

  @override
  _ScreenshotMiscLayer copyWith({String? id, String? name, bool? hidden}) =>
      _ScreenshotMiscLayer(
        id: id ?? this.id,
        name: name ?? this.name,
        kind: kind,
        hidden: hidden ?? this.hidden,
      );
}
