/// Flutter Widget Previewer specimens for Desy's dogfood design system.
///
/// These are intentionally a small comparison harness. The dogfood
/// `DesyRegistry` remains the catalogue's single declared inventory; each
/// preview below mounts a real exported widget in its real design-system theme.
library;

import 'package:desy_design_system/desy_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

/// Applies the normal Desy theme required by all light-mode component previews.
Widget desyLightPreviewWrapper(Widget child) => DesyDesignSystemThemeScope(
  theme: DesyDesignSystemTheme.light,
  child: _PreviewSurface(child: child),
);

/// Applies the normal Desy theme required by all dark-mode component previews.
Widget desyDarkPreviewWrapper(Widget child) => DesyDesignSystemThemeScope(
  theme: DesyDesignSystemTheme.dark,
  child: _PreviewSurface(child: child),
);

@Preview(
  group: 'Actions',
  name: 'Button states · light',
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Actions',
  name: 'Button states · dark',
  wrapper: desyDarkPreviewWrapper,
)
/// Renders the primary, outline, and disabled button states.
Widget desyButtonStatesPreview() => const Wrap(
  spacing: DesyDesignSystemTokens.spaceSm,
  runSpacing: DesyDesignSystemTokens.spaceSm,
  children: [
    DesyButton(onPress: _noop, child: Text('Inspect component')),
    DesyButton(
      onPress: _noop,
      variant: DesyButtonVariant.outline,
      child: Text('Open settings'),
    ),
    DesyButton(onPress: null, child: Text('Unavailable')),
  ],
);

@Preview(
  group: 'Inputs',
  name: 'Boolean controls · light',
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Inputs',
  name: 'Boolean controls · dark',
  wrapper: desyDarkPreviewWrapper,
)
/// Renders the checked checkbox and enabled switch states.
Widget desyBooleanControlsPreview() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: DesyDesignSystemTokens.spaceMd,
  children: [
    DesyCheckbox(
      value: true,
      onChanged: _ignoreBoolean,
      label: Text('Include implementation guidance'),
      description: Text('Shown beside component contracts.'),
    ),
    DesySwitch(
      value: true,
      onChange: _ignoreBoolean,
      label: Text('Annotation mode'),
    ),
  ],
);

@Preview(
  group: 'Inputs',
  name: 'Text field · light',
  size: Size(440, 148),
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Inputs',
  name: 'Text field · dark',
  size: Size(440, 148),
  wrapper: desyDarkPreviewWrapper,
)
/// Renders the native Desy text entry surface.
Widget desyTextFieldPreview() => const DesyTextField(
  label: 'Search components',
  hintText: 'Search by component or path',
);

@Preview(
  group: 'Inputs',
  name: 'Select · light',
  size: Size(360, 180),
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Inputs',
  name: 'Select · dark',
  size: Size(360, 180),
  wrapper: desyDarkPreviewWrapper,
)
/// Renders the controlled rich select with its real Desy theme.
Widget desySelectPreview() => DesySelect<DesyDesignSystemTheme>.rich(
  control: const DesySelectControl.lifted(
    value: DesyDesignSystemTheme.light,
    onChange: _ignoreTheme,
  ),
  format: (theme) => 'Workbench ${theme.name}',
  label: const Text('Preview theme'),
  description: const Text('The consumer theme wraps the production widget.'),
  children: const [
    DesySelectItem.item(
      value: DesyDesignSystemTheme.light,
      title: Text('Workbench light'),
    ),
    DesySelectItem.item(
      value: DesyDesignSystemTheme.dark,
      title: Text('Workbench dark'),
    ),
  ],
);

@Preview(
  group: 'Navigation',
  name: 'Tabs · light',
  size: Size(520, 260),
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Navigation',
  name: 'Tabs · dark',
  size: Size(520, 260),
  wrapper: desyDarkPreviewWrapper,
)
/// Renders a two-page production tab surface.
Widget desyTabsPreview() => const DesyTabs(
  children: [
    DesyTabEntry(
      label: Text('Overview'),
      child: Padding(
        padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text('The registry provides the component context.'),
      ),
    ),
    DesyTabEntry(
      label: Text('Contract'),
      child: Padding(
        padding: EdgeInsets.all(DesyDesignSystemTokens.spaceMd),
        child: Text('Properties, states, and accessibility guidance.'),
      ),
    ),
  ],
);

@Preview(
  group: 'Surfaces',
  name: 'Card · light',
  size: Size(420, 220),
  wrapper: desyLightPreviewWrapper,
)
@Preview(
  group: 'Surfaces',
  name: 'Card · dark',
  size: Size(420, 220),
  wrapper: desyDarkPreviewWrapper,
)
/// Renders a contained Desy surface with readable content rhythm.
Widget desyCardPreview() => const SizedBox(
  width: 360,
  child: DesyCard(
    child: Padding(
      padding: EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DesyDesignSystemTokens.spaceSm,
        children: [
          Text('Component contract'),
          Text('Preserve the consumer widget and its semantic context.'),
        ],
      ),
    ),
  ),
);

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).scaffoldBackgroundColor,
    child: Padding(
      padding: const EdgeInsets.all(DesyDesignSystemTokens.spaceLg),
      child: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
}

void _noop() {}

void _ignoreBoolean(bool _) {}

void _ignoreTheme(DesyDesignSystemTheme? _) {}
