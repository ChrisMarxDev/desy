import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../desy_annotation.dart';

/// Collects one widget target from a consumer-owned element tree.
///
/// This class contains no overlay state or UI. Keeping traversal and metadata
/// extraction here makes the build-mode compromises independently reviewable.
class DesyWidgetTargetInspector {
  const DesyWidgetTargetInspector();

  /// Returns the smallest rendered target beneath [globalPosition].
  DesyWidgetTarget? inspect({
    required Element root,
    required RenderObject rootRenderObject,
    required Offset globalPosition,
  }) {
    final rootPosition = rootRenderObject is RenderBox
        ? rootRenderObject.globalToLocal(globalPosition)
        : globalPosition;
    ({Element element, RenderObject renderObject, Rect bounds, int depth})?
    bestHit;

    void visit(Element element, int depth) {
      final renderObject = element.findRenderObject();
      if (renderObject != null &&
          renderObject.attached &&
          renderObject != rootRenderObject &&
          !renderObject.semanticBounds.isEmpty) {
        final bounds = MatrixUtils.transformRect(
          renderObject.getTransformTo(rootRenderObject),
          renderObject.semanticBounds,
        );
        if (bounds.isFinite && bounds.contains(rootPosition)) {
          final projectElement = _nearestLocalElement(element, root);
          final current = bestHit;
          final area = bounds.width * bounds.height;
          final currentArea = current == null
              ? double.infinity
              : current.bounds.width * current.bounds.height;
          if (area < currentArea ||
              (area == currentArea && depth > (current?.depth ?? -1))) {
            bestHit = (
              element: projectElement,
              renderObject: renderObject,
              bounds: bounds,
              depth: depth,
            );
          }
        }
      }
      element.visitChildren((child) => visit(child, depth + 1));
    }

    root.visitChildren((child) => visit(child, 0));
    final hit = bestHit;
    if (hit == null) return null;
    return _createTarget(
      element: hit.element,
      renderObject: hit.renderObject,
      bounds: hit.bounds,
      root: root,
    );
  }

  DesyWidgetTarget _createTarget({
    required Element element,
    required RenderObject renderObject,
    required Rect bounds,
    required Element root,
  }) {
    final ancestry = _ancestry(element, root);
    final renderBox = renderObject is RenderBox ? renderObject : null;
    return DesyWidgetTarget(
      buildMode: _buildMode,
      widgetType: element.widget.runtimeType.toString(),
      description: _describeWidget(element.widget),
      widgetPath: ancestry.reversed.join(' > '),
      ancestorWidgetTypes: ancestry,
      stateType: element is StatefulElement
          ? element.state.runtimeType.toString()
          : null,
      renderObjectType: renderObject.runtimeType.toString(),
      bounds: bounds,
      paintBounds: renderObject.paintBounds,
      semanticBounds: renderObject.semanticBounds,
      renderSize: renderBox?.size,
      layoutConstraints: renderBox?.constraints.toString(),
      identitySignals: _identitySignals(element, root),
      diagnostics: _diagnostics(element.widget),
      sourceLocation: _sourceLocation(element),
      widgetKey: _describeKey(element.widget.key),
    );
  }

  DesyBuildMode get _buildMode {
    if (kReleaseMode) return DesyBuildMode.release;
    if (kProfileMode) return DesyBuildMode.profile;
    return DesyBuildMode.debug;
  }

  Element _nearestLocalElement(Element element, Element root) {
    if (kReleaseMode) return element;
    if (debugIsWidgetLocalCreation(element.widget)) return element;
    var result = element;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        result = ancestor;
        return false;
      }
      return true;
    });
    return result;
  }

  DesySourceLocation? _sourceLocation(Element element) {
    if (!kDebugMode) return null;
    DesySourceLocation? result;
    assert(() {
      final service = WidgetInspectorService.instance;
      service.selection.currentElement = element;
      // Flutter exposes creationLocation through its inspector serialization.
      // ignore: invalid_use_of_visible_for_testing_member
      final delegate = InspectorSerializationDelegate(service: service);
      final serialized = element.toDiagnosticsNode().toJsonMap(delegate);
      final location = serialized['creationLocation'];
      if (location is Map<Object?, Object?>) {
        final file = location['file'];
        final line = location['line'];
        final column = location['column'];
        if (file is String && line is int && column is int) {
          result = DesySourceLocation(file: file, line: line, column: column);
        }
      }
      return true;
    }());
    return result;
  }

  List<String> _ancestry(Element element, Element root) {
    final types = <String>[element.widget.runtimeType.toString()];
    var visited = 0;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root || visited == 80) return false;
      visited++;
      final widget = ancestor.widget;
      final useful =
          kReleaseMode ||
          debugIsWidgetLocalCreation(widget) ||
          widget.key != null ||
          widget is Semantics;
      if (useful && types.length < 10) {
        types.add(widget.runtimeType.toString());
      }
      return true;
    });
    return types;
  }

  List<DesyWidgetSignal> _identitySignals(Element element, Element root) {
    final signals = <DesyWidgetSignal>[];
    final seen = <String>{};

    void add(DesyWidgetSignalKind kind, String? rawValue) {
      final value = rawValue?.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (value == null || value.isEmpty) return;
      final compact = value.length <= 160
          ? value
          : '${value.substring(0, 157)}…';
      if (!seen.add('${kind.name}:$compact')) return;
      signals.add(DesyWidgetSignal(kind: kind, value: compact));
    }

    void inspectWidget(Widget widget) {
      add(DesyWidgetSignalKind.key, _describeKey(widget.key));
      switch (widget) {
        case Text(data: final data?):
          add(DesyWidgetSignalKind.visibleText, data);
        case Text(textSpan: final span?):
          add(DesyWidgetSignalKind.visibleText, span.toPlainText());
        case RichText(:final text):
          add(DesyWidgetSignalKind.visibleText, text.toPlainText());
        case Semantics(:final properties):
          add(DesyWidgetSignalKind.semanticsIdentifier, properties.identifier);
          add(DesyWidgetSignalKind.semanticLabel, properties.label);
          add(DesyWidgetSignalKind.semanticValue, properties.value);
          add(DesyWidgetSignalKind.semanticHint, properties.hint);
        default:
          break;
      }
    }

    inspectWidget(element.widget);
    var visited = 0;
    element.visitAncestorElements((ancestor) {
      if (ancestor == root || visited == 80) return false;
      inspectWidget(ancestor.widget);
      visited++;
      return true;
    });
    return signals;
  }

  List<DesyWidgetDiagnostic> _diagnostics(Widget widget) {
    const blockedNames = {
      'controller',
      'focusNode',
      'onChanged',
      'onPressed',
      'onTap',
      'builder',
    };
    final result = <DesyWidgetDiagnostic>[];
    try {
      for (final property in widget.toDiagnosticsNode().getProperties()) {
        final name = property.name;
        if (name == null ||
            name.isEmpty ||
            blockedNames.contains(name) ||
            name.startsWith('on')) {
          continue;
        }
        final rawValue = property.toDescription().trim();
        if (rawValue.isEmpty || rawValue == 'null') continue;
        final value = rawValue.length <= 160
            ? rawValue
            : '${rawValue.substring(0, 157)}…';
        result.add(DesyWidgetDiagnostic(name: name, value: value));
        if (result.length == 16) break;
      }
    } on Object {
      return const [];
    }
    return result;
  }

  String? _describeKey(Key? key) {
    if (key == null || key is UniqueKey) return null;
    if (key is ValueKey<Object?>) return '${key.value}';
    if (key is ObjectKey) return '${key.value}';
    final description = key.toString();
    return description.contains('#') ? null : description;
  }

  String _describeWidget(Widget widget) => switch (widget) {
    Text(data: final data?) => 'Text("${_compact(data)}")',
    Text(textSpan: final span?) => 'Text("${_compact(span.toPlainText())}")',
    RichText(:final text) => 'RichText("${_compact(text.toPlainText())}")',
    Semantics(:final properties) when properties.label != null =>
      'Semantics("${_compact(properties.label!)}")',
    _ => widget.toStringShort(),
  };

  String _compact(String value) {
    final escaped = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .replaceAll('"', r'\"');
    return escaped.length <= 64 ? escaped : '${escaped.substring(0, 61)}…';
  }
}
