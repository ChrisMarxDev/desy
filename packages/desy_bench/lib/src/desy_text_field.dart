import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// A reliable, native Flutter text editor for Desy-owned text entry.
///
/// The workbench deliberately centralizes text editing here instead of using
/// multiple field implementations. The underlying [TextField] retains Flutter
/// platform editing, selection, caret, and context-menu behaviour.
class DesyTextField extends StatefulWidget {
  /// Creates a native text field styled from the active Desy theme.
  const DesyTextField({
    super.key,
    this.label,
    this.hintText,
    this.errorText,
    this.value,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.minLines,
  });

  /// An optional persistent accessible label.
  final String? label;

  /// A short example or prompt shown for an empty field.
  final String? hintText;

  /// Inline validation guidance.
  final String? errorText;

  /// An optional externally controlled text value.
  ///
  /// When absent, this field keeps its own editing value. When supplied,
  /// updates made outside the field replace the current editing value without
  /// recreating the controller or losing selection during normal typing.
  final String? value;

  /// Called for each native editing update.
  final ValueChanged<String>? onChanged;

  /// Called after the platform submits the field.
  final ValueChanged<String>? onSubmitted;

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
    final errorColor = colors.destructive;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.border),
    );
    return Material(
      type: MaterialType.transparency,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        enableInteractiveSelection: true,
        cursorColor: colors.primary,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          isDense: true,
          labelText: widget.label,
          hintText: widget.hintText,
          errorText: widget.errorText,
          filled: true,
          fillColor: colors.secondary,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          enabledBorder: border,
          disabledBorder: border.copyWith(
            borderSide: BorderSide(color: colors.border.withValues(alpha: .55)),
          ),
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: errorColor),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: errorColor, width: 1.5),
          ),
          errorStyle: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: errorColor),
        ),
      ),
    );
  }
}
