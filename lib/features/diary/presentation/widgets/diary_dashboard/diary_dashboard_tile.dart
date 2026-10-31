import 'package:material_ui/material_ui.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// What a tile builder gets: the day and how the user placed the tile.
@immutable
class DiaryTileArgs {
  /// Creates the arguments.
  const new({required this.day, required this.size, required this.mode});

  /// Normalized diary day of the page.
  final DateTime day;

  /// Size the tile has in the grid.
  final DiaryTileSize size;

  /// Id of the display mode the user picked.
  final String mode;
}

/// One display mode a tile offers, as the tile menu lists it.
@immutable
class DiaryTileMode {
  /// Creates the mode [id].
  const new({required this.id, required this.icon, required this.label});

  /// Stable id, saved in the layout.
  final String id;

  /// Icon in the tile menu.
  final IconData icon;

  /// Name in the tile menu.
  final String Function(AppLocalizations l10n) label;
}

/// A tile of the diary dashboard.
///
/// The grid gives a tile of fixed size a card frame with padding and the
/// exact size of its cells; [builder] fills the inside and must look right
/// at every size and every mode of [spec]: a small size shows less, never
/// squeezed text. A wide tile brings its own frame and sets its own height.
/// Taps inside work as usual; a long press belongs to the grid.
@immutable
class DiaryDashboardTile {
  /// Creates the tile of [spec].
  const new({
    required this.spec,
    required this.icon,
    required this.label,
    required this.modes,
    required this.builder,
  });

  /// What the layout knows of the tile: its id, sizes and modes.
  final DiaryTileSpec spec;

  /// Icon in the add sheet and the tile menu.
  final IconData icon;

  /// Name in the add sheet and the tile menu.
  final String Function(AppLocalizations l10n) label;

  /// How the tile menu shows the modes of [spec], in the same order.
  final List<DiaryTileMode> modes;

  /// Builds the inside of the tile.
  final Widget Function(DiaryTileArgs args) builder;

  /// Stable id, saved in the layout.
  String get id => spec.id;

  /// Sizes the tile offers, smallest first.
  List<DiaryTileSize> get sizes => spec.sizes;
}
