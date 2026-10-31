import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'diary_dashboard_layout.g.dart';

/// Number of columns of the diary dashboard grid.
const diaryDashboardColumns = 4;

/// A size a diary dashboard tile can take, in grid cells.
enum DiaryTileSize {
  /// One cell.
  s1x1(1, 1),

  /// Two cells side by side.
  s2x1(2, 1),

  /// Two by two cells.
  s2x2(2, 2),

  /// One full-width row.
  s4x1(4, 1),

  /// Two full-width rows.
  s4x2(4, 2),

  /// The full width at the height its content needs, such as the budget
  /// card.
  wide(4, null);

  new(this.columns, this.rows);

  /// Columns the tile spans.
  final int columns;

  /// Rows the tile spans, or null when its content sets the height.
  final int? rows;

  /// Whether the content sets the height.
  bool get isWide => rows == null;
}

/// What the dashboard needs to know of one tile kind to resolve a layout.
@immutable
class DiaryTileSpec {
  /// Creates the spec of tile [id].
  const new({
    required this.id,
    required this.sizes,
    required this.defaultSize,
    required this.modes,
    this.visibleByDefault = true,
  });

  /// Stable id, saved in the layout.
  final String id;

  /// Sizes the tile offers, smallest first.
  final List<DiaryTileSize> sizes;

  /// Size of a newly shown tile.
  final DiaryTileSize defaultSize;

  /// Ids of the display modes the tile offers; the first is the default.
  final List<String> modes;

  /// Whether the default layout shows the tile. Others start hidden.
  final bool visibleByDefault;

  /// Mode of a newly shown tile.
  String get defaultMode => modes.first;
}

/// One shown tile: which tile, at which size, in which mode.
@immutable
@JsonSerializable(checked: true)
class DiaryTilePlacement {
  /// Creates a placement.
  const new({required this.id, required this.size, required this.mode});

  /// The default placement of [spec].
  factory of(DiaryTileSpec spec) => DiaryTilePlacement(
    id: spec.id,
    size: spec.defaultSize,
    mode: spec.defaultMode,
  );

  /// Reads a saved placement.
  factory fromJson(Map<String, dynamic> json) =>
      _$DiaryTilePlacementFromJson(json);

  /// Writes the placement.
  Map<String, dynamic> toJson() => _$DiaryTilePlacementToJson(this);

  /// Tile id.
  final String id;

  /// Size of the tile.
  final DiaryTileSize size;

  /// Display mode id.
  final String mode;

  /// Copies the placement with a new size or mode.
  DiaryTilePlacement copyWith({DiaryTileSize? size, String? mode}) =>
      DiaryTilePlacement(
        id: id,
        size: size ?? this.size,
        mode: mode ?? this.mode,
      );

  @override
  bool operator ==(Object other) =>
      other is DiaryTilePlacement &&
      other.id == id &&
      other.size == size &&
      other.mode == mode;

  @override
  int get hashCode => Object.hash(id, size, mode);
}

/// The user's arrangement of the diary dashboard: the shown tiles in order
/// and the tiles the user hid.
///
/// A tile in neither list is new to the user; [resolve] sorts it in.
@immutable
@JsonSerializable(checked: true, explicitToJson: true)
class DiaryDashboardLayout {
  /// Creates a layout.
  const new({required this.tiles, required this.hidden});

  /// The layout of [catalog] before the user changed anything.
  factory initial(List<DiaryTileSpec> catalog) =>
      const DiaryDashboardLayout(tiles: [], hidden: []).resolve(catalog);

  /// Reads a saved layout.
  factory fromJson(Map<String, dynamic> json) =>
      _$DiaryDashboardLayoutFromJson(json);

  /// Writes the layout.
  Map<String, dynamic> toJson() => _$DiaryDashboardLayoutToJson(this);

  /// Shown tiles, in reading order.
  final List<DiaryTilePlacement> tiles;

  /// Ids of the tiles the user hid.
  final List<String> hidden;

  /// The layout against the tiles of [catalog]: drops tiles that no longer
  /// exist, fixes sizes and modes a tile no longer offers, and sorts in the
  /// tiles of [catalog] the layout does not know yet. A new tile shown by
  /// default goes right after the closest tile before it in [catalog].
  DiaryDashboardLayout resolve(List<DiaryTileSpec> catalog) {
    final specs = {for (final spec in catalog) spec.id: spec};
    final shown = <DiaryTilePlacement>[];
    for (final tile in tiles) {
      final spec = specs[tile.id];
      if (spec == null || shown.any((t) => t.id == tile.id)) continue;
      shown.add(
        tile.copyWith(
          size: spec.sizes.contains(tile.size) ? null : spec.defaultSize,
          mode: spec.modes.contains(tile.mode) ? null : spec.defaultMode,
        ),
      );
    }
    final hiddenIds = [
      for (final id in hidden.toSet())
        if (specs.containsKey(id) && !shown.any((t) => t.id == id)) id,
    ];
    for (final (index, spec) in catalog.indexed) {
      final known =
          shown.any((t) => t.id == spec.id) || hiddenIds.contains(spec.id);
      if (known) continue;
      if (!spec.visibleByDefault) {
        hiddenIds.add(spec.id);
        continue;
      }
      final before = catalog
          .take(index)
          .map((s) => shown.indexWhere((t) => t.id == s.id))
          .where((i) => i >= 0)
          .maxOrNull;
      shown.insert(
        before == null ? 0 : before + 1,
        DiaryTilePlacement.of(spec),
      );
    }
    return DiaryDashboardLayout(
      tiles: List.unmodifiable(shown),
      hidden: List.unmodifiable(hiddenIds),
    );
  }

  /// Moves tile [id] to [index] of the shown tiles.
  DiaryDashboardLayout move(String id, int index) {
    final from = tiles.indexWhere((t) => t.id == id);
    if (from < 0) return this;
    final next = [...tiles];
    final tile = next.removeAt(from);
    next.insert(index.clamp(0, next.length), tile);
    return DiaryDashboardLayout(tiles: List.unmodifiable(next), hidden: hidden);
  }

  /// Replaces the placement of the shown tile with the id of [placement].
  DiaryDashboardLayout update(DiaryTilePlacement placement) =>
      DiaryDashboardLayout(
        tiles: List.unmodifiable([
          for (final t in tiles)
            if (t.id == placement.id) placement else t,
        ]),
        hidden: hidden,
      );

  /// Hides tile [id].
  DiaryDashboardLayout hide(String id) => DiaryDashboardLayout(
    tiles: List.unmodifiable(tiles.where((t) => t.id != id)),
    hidden: List.unmodifiable({...hidden, id}),
  );

  /// Shows the hidden tile of [spec] at the end, at its default size.
  DiaryDashboardLayout show(DiaryTileSpec spec) => DiaryDashboardLayout(
    tiles: List.unmodifiable([
      ...tiles.where((t) => t.id != spec.id),
      DiaryTilePlacement.of(spec),
    ]),
    hidden: List.unmodifiable(hidden.where((id) => id != spec.id)),
  );

  @override
  bool operator ==(Object other) =>
      other is DiaryDashboardLayout &&
      const ListEquality<DiaryTilePlacement>().equals(other.tiles, tiles) &&
      const ListEquality<String>().equals(other.hidden, hidden);

  @override
  int get hashCode => Object.hash(
    const ListEquality<DiaryTilePlacement>().hash(tiles),
    const ListEquality<String>().hash(hidden),
  );
}
