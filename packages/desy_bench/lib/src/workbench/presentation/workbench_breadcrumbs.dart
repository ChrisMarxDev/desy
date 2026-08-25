// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The shared inset for catalogue and detail-canvas location controls.
const desyWorkbenchCanvasInset = 12.0;

/// One location in a workbench breadcrumb trail.
class DesyWorkbenchBreadcrumb {
  const DesyWorkbenchBreadcrumb({required this.label, this.onOpen});

  final String label;
  final VoidCallback? onOpen;
}

/// The shared, compact location trail used across workbench catalogue pages.
class DesyWorkbenchBreadcrumbs extends StatefulWidget {
  const DesyWorkbenchBreadcrumbs({
    super.key,
    required this.segments,
    this.textKey,
  });

  final List<DesyWorkbenchBreadcrumb> segments;
  final Key? textKey;

  @override
  State<DesyWorkbenchBreadcrumbs> createState() =>
      _DesyWorkbenchBreadcrumbsState();
}

class _DesyWorkbenchBreadcrumbsState extends State<DesyWorkbenchBreadcrumbs> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void initState() {
    super.initState();
    _syncRecognizers();
  }

  @override
  void didUpdateWidget(covariant DesyWorkbenchBreadcrumbs oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRecognizers();
  }

  void _syncRecognizers() {
    while (_recognizers.length > widget.segments.length) {
      _recognizers.removeLast().dispose();
    }
    while (_recognizers.length < widget.segments.length) {
      _recognizers.add(TapGestureRecognizer());
    }
    for (final (index, segment) in widget.segments.indexed) {
      _recognizers[index].onTap = segment.onOpen;
    }
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final style = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: colors.mutedForeground);
    final linkStyle = style?.copyWith(
      color: colors.foreground,
      decoration: TextDecoration.underline,
      decorationColor: colors.mutedForeground,
    );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.secondary,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        label:
            'Breadcrumb: ${widget.segments.map((segment) => segment.label).join(' / ')}',
        container: true,
        explicitChildNodes: true,
        child: SelectableText.rich(
          key: widget.textKey,
          TextSpan(
            style: style,
            children: [
              for (final (index, segment) in widget.segments.indexed) ...[
                if (index > 0)
                  TextSpan(
                    text: widget.segments[index - 1].label.endsWith('/')
                        ? ' '
                        : ' / ',
                  ),
                TextSpan(
                  text: segment.label,
                  style: segment.onOpen == null ? style : linkStyle,
                  recognizer: segment.onOpen == null
                      ? null
                      : _recognizers[index],
                  mouseCursor: segment.onOpen == null
                      ? MouseCursor.defer
                      : SystemMouseCursors.click,
                  semanticsLabel: segment.onOpen == null
                      ? segment.label
                      : 'Open ${segment.label}',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
