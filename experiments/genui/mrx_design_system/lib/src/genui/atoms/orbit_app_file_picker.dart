// ignore_for_file: public_member_api_docs

part of '../orbit_genui.dart';

class OrbitAppFilePicker extends StatefulWidget {
  const OrbitAppFilePicker({
    super.key,
    required this.label,
    this.acceptedTypes = const [],
    this.multiple = false,
    this.onChanged,
  });
  final String label;
  final List<String> acceptedTypes;
  final bool multiple;
  final ValueChanged<List<String>>? onChanged;
  @override
  State<OrbitAppFilePicker> createState() => _OrbitAppFilePickerState();
}

class _OrbitAppFilePickerState extends State<OrbitAppFilePicker> {
  var _loading = false;
  var _names = const <String>[];
  Future<void> _pick() async {
    setState(() => _loading = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: widget.multiple,
        type: widget.acceptedTypes.isEmpty ? FileType.any : FileType.custom,
        allowedExtensions: widget.acceptedTypes.isEmpty
            ? null
            : widget.acceptedTypes,
      );
      if (!mounted || result == null) return;
      setState(
        () => _names = result.files
            .map((file) => file.name)
            .toList(growable: false),
      );
      widget.onChanged?.call(_names);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => OrbitAppStack(
    gap: OrbitTokens.spaceSm,
    children: [
      OrbitAppButton(
        label: _loading ? 'Choosing file…' : widget.label,
        icon: 'add',
        loading: _loading,
        onPressed: _loading ? null : _pick,
      ),
      if (_names.isNotEmpty)
        OrbitAppText(_names.join(', '), role: OrbitTextRole.caption),
    ],
  );
}
