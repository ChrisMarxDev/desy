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

  /// Select a precise point or widget on a canvas.
  static const IconData crosshair = FLucideIcons.crosshair;

  /// A registry folder.
  static const IconData folder = FLucideIcons.folder;

  /// A recursive file-browser hierarchy.
  static const IconData folderTree = FLucideIcons.folderTree;

  /// An image or visual asset.
  static const IconData image = FLucideIcons.image;

  /// Layered content or showcases.
  static const IconData layers = FLucideIcons.layers;

  /// A compact feedback or annotation action.
  static const IconData messageSquare = FLucideIcons.messageSquare;

  /// The catalogue Atlas.
  static const IconData layoutGrid = FLucideIcons.layoutGrid;

  /// Color foundations.
  static const IconData palette = FLucideIcons.palette;

  /// Pause an active preview timeline.
  static const IconData pause = FLucideIcons.pause;

  /// Hide the desktop navigation panel.
  static const IconData panelLeftClose = FLucideIcons.panelLeftClose;

  /// Show the desktop navigation panel.
  static const IconData panelLeftOpen = FLucideIcons.panelLeftOpen;

  /// Start or resume a preview timeline.
  static const IconData play = FLucideIcons.play;

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

  /// A warning that requires investigation.
  static const IconData triangleAlert = FLucideIcons.triangleAlert;

  /// Typography foundations.
  static const IconData type = FLucideIcons.type;

  /// Close or dismiss a compact surface.
  static const IconData x = FLucideIcons.x;

  /// Screenshot capture workspace.
  static const IconData camera = FLucideIcons.camera;
}
