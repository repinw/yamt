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
/// at every size of [sizes] and every mode of [modes]: a small size shows
/// less, never squeezed text. A wide tile brings its own frame and sets its
/// own height. Taps inside work as usual; a long press belongs to the grid.
@immutable
class DiaryDashboardTile {
  /// Creates the tile [id].
  const new({
    required this.id,
    required this.icon,
    required this.label,
    required this.sizes,
    required this.defaultSize,
    required this.modes,
    required this.builder,
    this.visibleByDefault = true,
  });

  /// Stable id, saved in the layout.
  final String id;

  /// Icon in the add sheet and the tile menu.
  final IconData icon;

  /// Name in the add sheet and the tile menu.
  final String Function(AppLocalizations l10n) label;

  /// Sizes the tile offers, smallest first.
  final List<DiaryTileSize> sizes;

  /// Size of a newly shown tile.
  final DiaryTileSize defaultSize;

  /// Display modes; the first is the default.
  final List<DiaryTileMode> modes;

  /// Whether the default layout shows the tile.
  final bool visibleByDefault;

  /// Builds the inside of the tile.
  final Widget Function(DiaryTileArgs args) builder;

  /// What the layout needs to know of the tile.
  DiaryTileSpec get spec => DiaryTileSpec(
    id: id,
    sizes: sizes,
    defaultSize: defaultSize,
    modes: [for (final mode in modes) mode.id],
    defaultMode: modes.first.id,
    visibleByDefault: visibleByDefault,
  );
}
