import 'package:desy_core/desy_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('workbench brightness defaults to light for every canvas color', () {
    const themes = [
      DesyTheme(id: 'unset', name: 'Unset', wrap: _wrap),
      DesyTheme(
        id: 'transparent',
        name: 'Transparent',
        wrap: _wrap,
        previewBackgroundColor: Color(0x00000000),
      ),
      DesyTheme(
        id: 'black-canvas',
        name: 'Black canvas',
        wrap: _wrap,
        previewBackgroundColor: Color(0xFF000000),
      ),
    ];

    for (final theme in themes) {
      expect(theme.isDark, isFalse, reason: theme.id);
      expect(theme.usesDarkWorkbench, isFalse, reason: theme.id);
    }
  });

  test('dark workbench chrome remains an explicit opt-in', () {
    const theme = DesyTheme(
      id: 'dark',
      name: 'Dark',
      wrap: _wrap,
      isDark: true,
    );

    expect(theme.isDark, isTrue);
    expect(theme.usesDarkWorkbench, isTrue);
  });
}

Widget _wrap(BuildContext context, Widget child) => child;
