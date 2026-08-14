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
    this.maxLines = 1,
    this.minLines,
  });

  /// An optional accessible label. It is never rendered as field chrome.
  final String? label;

  /// A short example or prompt shown for an empty field.
  final String? hintText;

  /// Accessible validation guidance. It is not rendered below the field.
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

  /// The maximum number of visible text lines.
  final int? maxLines;

  /// The minimum number of visible text lines.
  final int? minLines;

  @override
  State<DesyTextField> createState() => _DesyTextFieldState();
}

class _DesyTextFieldState extends State<DesyTextField> {
  bool _focused = false;

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
    final borderColor = widget.errorText != null
        ? colors.destructive
        : _focused
        ? visual.signal
        : visual.divider;

    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        container: true,
        label: widget.label,
        hint: widget.errorText,
        child: Focus(
          onFocusChange: (focused) {
            if (_focused == focused) return;
            setState(() => _focused = focused);
          },
          child: AnimatedContainer(
            duration: DesyDesignSystemTokens.navigationMotion,
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: widget.enabled ? visual.panel : visual.panelSubtle,
              border: Border.all(
                color: borderColor,
                width: _focused ? 1.5 : DesyDesignSystemTokens.hairline,
              ),
              borderRadius: BorderRadius.circular(
                DesyDesignSystemTokens.radiusSm,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: DesyDesignSystemTokens.spaceMd,
              vertical: DesyDesignSystemTokens.spaceSm,
            ),
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
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
                isCollapsed: true,
                hintText: widget.hintText,
                hintStyle: context.theme.typography.body.sm.copyWith(
                  color: colors.mutedForeground,
                  height: 1.25,
                ),
                prefixIcon: widget.prefixIcon,
                prefixIconConstraints: const BoxConstraints(),
                suffixIcon: widget.suffixIcon,
                suffixIconConstraints: const BoxConstraints(),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
