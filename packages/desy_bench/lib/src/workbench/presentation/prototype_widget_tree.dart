// Internal live prototype inspection presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:desy_design_system/desy_design_system.dart';

import '../workbench_annotation.dart';

/// A debug-derived view of one prototype's scoped widget hierarchy.
///
/// The tree owns no registry metadata and keeps live [Element] references only
/// for the current frame. After a hot reload it rebuilds from the new subtree.
class DesyPrototypeWidgetTree extends StatefulWidget {
  const DesyPrototypeWidgetTree({
    super.key,
    required this.prototypeId,
    required this.scopeKey,
  });

  final String prototypeId;
  final GlobalKey scopeKey;

  @override
  State<DesyPrototypeWidgetTree> createState() =>
      _DesyPrototypeWidgetTreeState();
}

class _DesyPrototypeWidgetTreeState extends State<DesyPrototypeWidgetTree> {
  List<_WidgetTreeNode> _roots = const [];

  @override
  void initState() {
    super.initState();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(DesyPrototypeWidgetTree oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scope = widget.scopeKey.currentContext;
      if (scope is! Element) return;
      setState(() => _roots = _collect(scope));
    });
  }

  List<_WidgetTreeNode> _collect(Element scope) {
    List<_WidgetTreeNode> visit(Element element) {
      final children = <_WidgetTreeNode>[];
      element.visitChildren((child) => children.addAll(visit(child)));
      if (element != scope && _isUseful(element.widget)) {
        return [
          _WidgetTreeNode(
            element: element,
            children: List.unmodifiable(children),
          ),
        ];
      }
      return children;
    }

    final roots = <_WidgetTreeNode>[];
    scope.visitChildren((child) => roots.addAll(visit(child)));
    return List.unmodifiable(roots);
  }

  bool _isUseful(Widget widget) =>
      debugIsWidgetLocalCreation(widget) &&
      widget is! Builder &&
      widget is! KeyedSubtree &&
      widget is! RepaintBoundary;

  @override
  Widget build(BuildContext context) {
    final host = DesyWorkbenchInspectionHost.maybeOf(context);
    final selected = host?.target;
    final selectedPrototype =
        selected?.inspectionContext?.artifactId == widget.prototypeId;
    return DecoratedBox(
      key: const ValueKey('prototype-widget-tree'),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.theme.colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesyDesignSystemTokens.spaceMd,
          vertical: DesyDesignSystemTokens.spaceSm,
        ),
        child: _roots.isEmpty
            ? Text(
                'No source widgets are available yet.',
                style: context.theme.typography.body.xs.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              )
            : ListView(
                key: const ValueKey('prototype-widget-tree-list'),
                children: [
                  for (final node in _roots)
                    _WidgetTreeRow(
                      node: node,
                      depth: 0,
                      selected:
                          selectedPrototype &&
                          selected?.widgetPath.endsWith(node.path) == true,
                      onSelect: host == null
                          ? null
                          : (node) => _select(node, host),
                    ),
                ],
              ),
      ),
    );
  }

  void _select(_WidgetTreeNode node, DesyWorkbenchInspectionHost host) {
    final renderObject = node.element.findRenderObject();
    if (renderObject == null) return;
    final bounds = host.controller.boundsFor(renderObject);
    if (bounds == null) return;
    final scope = _scopeFor(node.element);
    final context = scope?.widget is DesyWorkbenchInspectionScope
        ? (scope!.widget as DesyWorkbenchInspectionScope).context
        : null;
    host.onTargetSelected(
      DesyWorkbenchWidgetTarget(
        screenId: host.screenId,
        widgetType: node.element.widget.runtimeType.toString(),
        description: _describe(node.element.widget),
        widgetPath: node.path,
        bounds: bounds,
        sourceLocation: _sourceLocation(node.element),
        widgetKey: _key(node.element.widget.key),
        inspectionContext: context,
      ),
    );
  }

  Element? _scopeFor(Element element) {
    Element? scope;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is DesyWorkbenchInspectionScope) {
        scope = ancestor;
        return false;
      }
      return true;
    });
    return scope;
  }

  DesyWorkbenchSourceLocation? _sourceLocation(Element element) {
    DesyWorkbenchSourceLocation? result;
    assert(() {
      final service = WidgetInspectorService.instance;
      service.selection.currentElement = element;
      // ignore: invalid_use_of_visible_for_testing_member
      final delegate = InspectorSerializationDelegate(service: service);
      final json = element.toDiagnosticsNode().toJsonMap(delegate);
      final raw = json['creationLocation'];
      if (raw is Map<Object?, Object?>) {
        try {
          result = DesyWorkbenchSourceLocation.fromInspectorJson(raw);
        } on FormatException {
          result = null;
        }
      }
      return true;
    }());
    return result;
  }

  String? _key(Key? key) =>
      key is ValueKey<Object?> ? '${key.value}' : key?.toString();

  String _describe(Widget widget) => switch (widget) {
    Text(data: final data?) => 'Text("${_compact(data)}")',
    Text(textSpan: final span?) => 'Text("${_compact(span.toPlainText())}")',
    RichText(:final text) => 'RichText("${_compact(text.toPlainText())}")',
    _ => widget.toStringShort(),
  };

  String _compact(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 40 ? clean : '${clean.substring(0, 37)}…';
  }
}

class _WidgetTreeNode {
  const _WidgetTreeNode({required this.element, required this.children});

  final Element element;
  final List<_WidgetTreeNode> children;

  String get path {
    final segments = <String>[element.widget.runtimeType.toString()];
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is DesyWorkbenchInspectionScope) return false;
      if (debugIsWidgetLocalCreation(ancestor.widget)) {
        segments.add(ancestor.widget.runtimeType.toString());
      }
      return true;
    });
    return segments.reversed.join(' > ');
  }
}

class _WidgetTreeRow extends StatelessWidget {
  const _WidgetTreeRow({
    required this.node,
    required this.depth,
    required this.selected,
    required this.onSelect,
  });

  final _WidgetTreeNode node;
  final int depth;
  final bool selected;
  final ValueChanged<_WidgetTreeNode>? onSelect;

  @override
  Widget build(BuildContext context) {
    final label = _label(node.element.widget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Select $label',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSelect == null ? null : () => onSelect!(node),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: selected
                    ? context.theme.colors.desy.signal.withValues(alpha: .1)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesyDesignSystemTokens.spaceXs + depth * 16,
                  5,
                  DesyDesignSystemTokens.spaceXs,
                  5,
                ),
                child: Row(
                  children: [
                    Icon(
                      node.children.isEmpty
                          ? DesyIcons.component
                          : DesyIcons.layers,
                      size: 13,
                      color: context.theme.colors.mutedForeground,
                    ),
                    const SizedBox(width: DesyDesignSystemTokens.spaceXs),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.theme.typography.body.xs.copyWith(
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        for (final child in node.children)
          _WidgetTreeRow(
            node: child,
            depth: depth + 1,
            selected: selected,
            onSelect: onSelect,
          ),
      ],
    );
  }

  String _label(Widget widget) => switch (widget) {
    Text(data: final data?) => 'Text · ${_compact(data)}',
    Text(textSpan: final span?) => 'Text · ${_compact(span.toPlainText())}',
    _ => widget.runtimeType.toString(),
  };

  String _compact(String value) {
    final clean = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean.length <= 44 ? clean : '${clean.substring(0, 41)}…';
  }
}
