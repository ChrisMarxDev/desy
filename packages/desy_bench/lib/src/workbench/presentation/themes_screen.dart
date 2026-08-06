// Internal workbench presentation.
// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:state_beacon/state_beacon.dart';

import '../../registry.dart';
import '../workbench_session.dart';

/// Chooses the one consumer theme used to wrap every live preview.
///
/// The selector exposes the available theme contexts together, but only one
/// can be active because a preview has exactly one inherited theme at a time.
class DesyThemesScreen extends StatelessWidget {
  const DesyThemesScreen({super.key, required this.session});

  final DesyWorkbenchSession session;

  @override
  Widget build(BuildContext context) {
    final activeIndex = session.activeThemeIndex.watch(context);
    final activeTheme = session.registry.themes[activeIndex];
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        Text('THEME', style: DefaultTextStyle.of(context).style),
        const SizedBox(height: 4),
        const Text('Preview context'),
        const SizedBox(height: 20),
        FCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: FSelect<int>.rich(
              key: const ValueKey('theme-select'),
              control: FSelectControl.lifted(
                value: activeIndex,
                onChange: (index) {
                  if (index != null) session.selectTheme(index);
                },
              ),
              label: const Text('Active theme'),
              description: const Text(
                'All component, token, and sketch previews use this consumer context.',
              ),
              format: (index) => session.registry.themes[index].name,
              children: [
                for (final (index, theme) in session.registry.themes.indexed)
                  FSelectItem.item(
                    key: ValueKey('theme-option-${theme.id}'),
                    value: index,
                    prefix: _ThemeSwatch(color: theme.previewBackgroundColor),
                    title: Text(theme.name),
                    subtitle: Text(
                      theme.description ?? 'Consumer preview theme.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ActiveThemeDetails(theme: activeTheme),
      ],
    );
  }
}

class _ActiveThemeDetails extends StatelessWidget {
  const _ActiveThemeDetails({required this.theme});

  final DesyTheme theme;

  @override
  Widget build(BuildContext context) => FCard(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ThemeSwatch(color: theme.previewBackgroundColor, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE PREVIEW CONTEXT'),
                const SizedBox(height: 4),
                Text(theme.name),
                if (theme.description case final description?) ...[
                  const SizedBox(height: 6),
                  Text(description),
                ],
                const SizedBox(height: 12),
                FBadge(
                  child: Text(
                    theme.previewBackgroundColor == null
                        ? 'System canvas background'
                        : 'Canvas ${_colorLabel(theme.previewBackgroundColor!)}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.color, this.size = 20});

  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color ?? const Color(0xfff4f4f5),
      borderRadius: BorderRadius.circular(size / 4),
      border: Border.all(color: const Color(0x26000000)),
    ),
    child: SizedBox(width: size, height: size),
  );
}

String _colorLabel(Color color) =>
    '#${(color.toARGB32() & 0x00ffffff).toRadixString(16).padLeft(6, '0').toUpperCase()}';
