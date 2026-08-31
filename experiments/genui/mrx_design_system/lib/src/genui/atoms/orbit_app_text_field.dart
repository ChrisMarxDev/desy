// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppTextField extends StatefulWidget {
  const OrbitAppTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
    this.placeholder,
    this.type = OrbitInputType.text,
    this.enabled = true,
  });
  final String label;
  final String value;
  final ValueChanged<String>? onChanged;
  final String? description;
  final String? placeholder;
  final OrbitInputType type;
  final bool enabled;
  @override
  State<OrbitAppTextField> createState() => _OrbitAppTextFieldState();
}

class _OrbitAppTextFieldState extends State<OrbitAppTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );
  @override
  void didUpdateWidget(OrbitAppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.label,
    child: OrbitAppStack(
      gap: OrbitTokens.spaceXs,
      children: [
        OrbitAppText(widget.label, role: OrbitTextRole.label),
        if (widget.description != null)
          OrbitAppText(widget.description!, role: OrbitTextRole.caption),
        OrbitTextArea(
          controller: _controller,
          hint: widget.placeholder ?? widget.label,
          enabled: widget.enabled,
          minLines: widget.type == OrbitInputType.multiline ? 3 : 1,
          maxLines: widget.type == OrbitInputType.multiline ? 6 : 1,
          onChanged: widget.onChanged,
        ),
      ],
    ),
  );
}
