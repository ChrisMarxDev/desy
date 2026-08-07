import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Desy's accordion component.
typedef DesyAccordion = FAccordion;

/// One entry in a [DesyAccordion].
typedef DesyAccordionItem = FAccordionItem;

/// Desy's compact status badge.
typedef DesyBadge = FBadge;

/// Desy's action button.
typedef DesyButton = FButton;

/// Semantic Desy button variants supplied by the Forui foundation.
typedef DesyButtonVariant = FButtonVariant;

/// Desy's supported button sizes.
typedef DesyButtonSize = FButtonSizeVariant;

/// Desy's contained surface.
typedef DesyCard = FCard;

/// Desy's modal surface.
typedef DesyDialog = FDialog;

/// Presents a [DesyDialog] with Desy's consistent modal transition.
Future<T?> showDesyDialog<T>({
  required BuildContext context,
  required Widget Function(
    BuildContext context,
    FDialogStyle style,
    Animation<double> animation,
  )
  builder,
  bool useRootNavigator = false,
  bool barrierDismissible = true,
  String? barrierLabel,
}) => showFDialog<T>(
  context: context,
  builder: builder,
  useRootNavigator: useRootNavigator,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
);

/// Desy's workbench page scaffold.
typedef DesyScaffold = FScaffold;

/// Desy's continuous and discrete value slider.
typedef DesySlider = FSlider;

/// Playback and value ownership for a [DesySlider].
typedef DesySliderControl = FSliderControl;

/// The selected value exposed by a [DesySlider].
typedef DesySliderValue = FSliderValue;

/// Desy's typed single-selection control.
typedef DesySelect<T> = FSelect<T>;

/// State ownership for a [DesySelect].
typedef DesySelectControl<T> = FSelectControl<T>;

/// One option in a [DesySelect].
typedef DesySelectItem<T> = FSelectItem<T>;

/// Desy's persistent navigation surface.
typedef DesySidebar = FSidebar;

/// The Forui group primitive beneath Desy's typed sidebar sections.
typedef DesySidebarGroup = FSidebarGroup;

/// Scoped style changes for [DesySidebar].
typedef DesySidebarStyleDelta = FSidebarStyleDelta;

/// Scoped style changes for [DesySidebarGroup].
typedef DesySidebarGroupStyleDelta = FSidebarGroupStyleDelta;

/// Scoped style changes for a Desy sidebar item.
typedef DesySidebarItemStyleDelta = FSidebarItemStyleDelta;

/// Desy's boolean switch.
typedef DesySwitch = FSwitch;

/// Desy's tabbed surface.
typedef DesyTabs = FTabs;

/// One labelled page in [DesyTabs].
typedef DesyTabEntry = FTabEntry;

/// Desy's interactive or informational row.
typedef DesyTile = FTile;
