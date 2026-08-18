import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'desy_design_system_scope.dart';
import 'desy_visual_tokens.dart';

/// A reliable, native Flutter text editor for Desy-owned text entry.
///
/// The workbench deliberately centralizes text editing here instead of using
/// multiple field implementations. The underlying [TextField] retains Flutter
/// platform editing, selection, caret, and context-menu behaviour.
class DesyTextField extends StatefulWidget {
  /// Creates a native text field without decorative field chrome.
  const DesyTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.minLines,
  });

  /// An optional accessible label. It is never rendered as field chrome.
  final String? label;

  /// A short example or prompt shown for an empty field.
  final String? hintText;

  /// Validation guidance rendered by the native input decoration.
  final String? errorText;

  /// Optional icon before the editable text.
  final Widget? prefixIcon;

  /// Optional icon after the editable text.
  final Widget? suffixIcon;

  /// An optional externally controlled text value.
  final String? value;

  /// Called for each native editing update.
  final ValueChanged<String>? onChanged;

  /// Called after the platform submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Optional focus owner for workflows that move directly from selection to
  /// feedback entry.
  final FocusNode? focusNode;

  /// Whether this field receives focus when it appears.
  final bool autofocus;

  /// Whether editing is enabled.
  final bool enabled;

  /// The requested keyboard type.
  final TextInputType? keyboardType;

  /// The requested keyboard submit action.
  final TextInputAction? textInputAction;

  /// Horizontal alignment for entered text and its empty-state hint.
  final TextAlign textAlign;

  /// The maximum number of visible text lines.
  final int? maxLines;

  /// The minimum number of visible text lines.
  final int? minLines;

  @override
  State<DesyTextField> createState() => _DesyTextFieldState();
}

class _DesyTextFieldState extends State<DesyTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value ?? '',
  );

  @override
  void didUpdateWidget(covariant DesyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextValue = widget.value;
    if (nextValue == null || nextValue == _controller.text) return;

    _controller.value = TextEditingValue(
      text: nextValue,
      selection: TextSelection.collapsed(offset: nextValue.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final visual = colors.desy;
    final singleLine =
        widget.maxLines == 1 &&
        (widget.minLines == null || widget.minLines == 1);
    final standardBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesyDesignSystemTokens.radiusSm),
      borderSide: BorderSide(
        color: visual.divider,
        width: DesyDesignSystemTokens.hairline,
      ),
    );
    final focusedBorder = standardBorder.copyWith(
      borderSide: BorderSide(
        color: visual.signal,
        width: DesyDesignSystemTokens.hairline,
      ),
    );
    final errorBorder = standardBorder.copyWith(
      borderSide: BorderSide(
        color: colors.destructive,
        width: DesyDesignSystemTokens.hairline,
      ),
    );

    return Semantics(
      container: true,
      label: widget.label,
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          textAlign: widget.textAlign,
          textAlignVertical: TextAlignVertical.center,
          enableInteractiveSelection: true,
          style: context.theme.typography.body.sm.copyWith(
            color: colors.foreground,
            height: 1.25,
          ),
          cursorColor: visual.signal,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            isDense: true,
            hintText: widget.hintText,
            hintStyle: context.theme.typography.body.sm.copyWith(
              color: colors.mutedForeground,
              height: 1.25,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.suffixIcon,
            errorText: widget.errorText,
            contentPadding: EdgeInsets.symmetric(
              horizontal: DesyDesignSystemTokens.spaceMd,
              vertical: singleLine
                  ? DesyDesignSystemTokens.spaceMd
                  : DesyDesignSystemTokens.spaceSm,
            ),
            constraints: singleLine
                ? const BoxConstraints(minHeight: 44)
                : null,
            border: standardBorder,
            enabledBorder: standardBorder,
            disabledBorder: standardBorder,
            focusedBorder: focusedBorder,
            errorBorder: errorBorder,
            focusedErrorBorder: errorBorder,
            filled: true,
            fillColor: widget.enabled ? visual.panel : visual.panelSubtle,
          ),
        ),
      ),
    );
  }
}
