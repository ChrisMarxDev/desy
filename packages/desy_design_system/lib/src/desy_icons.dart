import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// The stable icon vocabulary used by Desy-owned workbench surfaces.
///
/// Consumer previews are not required to use these icons. Centralizing the
/// vocabulary prevents Desy packages from depending directly on Forui assets.
abstract final class DesyIcons {
  /// Navigate to a previous surface.
  static const IconData arrowLeft = FLucideIcons.arrowLeft;

  /// A collection of component instances.
  static const IconData boxes = FLucideIcons.boxes;

  /// A completed or selected state.
  static const IconData check = FLucideIcons.check;

  /// Expand downward.
  static const IconData chevronDown = FLucideIcons.chevronDown;

  /// Navigate to a child item.
  static const IconData chevronRight = FLucideIcons.chevronRight;

  /// A selectable value or swap action.
  static const IconData chevronsUpDown = FLucideIcons.chevronsUpDown;

  /// Collapse upward.
  static const IconData chevronUp = FLucideIcons.chevronUp;

  /// A generic registered component.
  static const IconData component = FLucideIcons.component;

  /// A registry folder.
  static const IconData folder = FLucideIcons.folder;

  /// An image or visual asset.
  static const IconData image = FLucideIcons.image;

  /// Layered content or showcases.
  static const IconData layers = FLucideIcons.layers;

  /// The catalogue Atlas.
  static const IconData layoutGrid = FLucideIcons.layoutGrid;

  /// Color foundations.
  static const IconData palette = FLucideIcons.palette;

  /// Hide the desktop navigation panel.
  static const IconData panelLeftClose = FLucideIcons.panelLeftClose;

  /// Show the desktop navigation panel.
  static const IconData panelLeftOpen = FLucideIcons.panelLeftOpen;

  /// Numeric measurements.
  static const IconData ruler = FLucideIcons.ruler;

  /// Icon and glyph foundations.
  static const IconData shapes = FLucideIcons.shapes;

  /// A phone preview bezel.
  static const IconData smartphone = FLucideIcons.smartphone;

  /// Motion, AI, or generative affordances.
  static const IconData sparkles = FLucideIcons.sparkles;

  /// A tablet preview bezel.
  static const IconData tablet = FLucideIcons.tablet;

  /// Typography foundations.
  static const IconData type = FLucideIcons.type;

  /// Screenshot capture workspace.
  static const IconData camera = FLucideIcons.camera;
}
