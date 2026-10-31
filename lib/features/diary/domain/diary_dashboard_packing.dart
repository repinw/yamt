import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';

/// A tile with its cell in a [DiaryGridBlock].
@immutable
class DiaryPackedTile {
  /// Places [placement] at [column] and [row] of its block.
  const new({required this.placement, required this.column, required this.row});

  /// The tile.
  final DiaryTilePlacement placement;

  /// First column, from 0.
  final int column;

  /// First row inside the block, from 0.
  final int row;

  @override
  bool operator ==(Object other) =>
      other is DiaryPackedTile &&
      other.placement == placement &&
      other.column == column &&
      other.row == row;

  @override
  int get hashCode => Object.hash(placement, column, row);

  @override
  String toString() => 'DiaryPackedTile(${placement.id} @ $column,$row)';
}

/// A run of the dashboard: cells of fixed size, or one wide tile.
@immutable
sealed class DiaryDashboardBlock {
  const new();
}

/// Tiles of fixed size packed into rows of [diaryDashboardColumns] cells.
final class DiaryGridBlock extends DiaryDashboardBlock {
  /// Creates the block.
  const new({required this.tiles, required this.rows});

  /// Tiles with their cells.
  final List<DiaryPackedTile> tiles;

  /// Rows the block spans.
  final int rows;

  @override
  bool operator ==(Object other) =>
      other is DiaryGridBlock &&
      other.rows == rows &&
      const ListEquality<DiaryPackedTile>().equals(other.tiles, tiles);

  @override
  int get hashCode =>
      Object.hash(rows, const ListEquality<DiaryPackedTile>().hash(tiles));
}

/// One full-width tile whose content sets its height.
final class DiaryWideBlock extends DiaryDashboardBlock {
  /// Creates the block.
  const new(this.placement);

  /// The tile.
  final DiaryTilePlacement placement;

  @override
  bool operator ==(Object other) =>
      other is DiaryWideBlock && other.placement == placement;

  @override
  int get hashCode => placement.hashCode;
}

/// Packs [tiles] in order into blocks. Each tile of fixed size takes the
/// first free cell from the top left where it fits, so a small tile fills a
/// gap that a wider one before it left. A wide tile ends the block before
/// it and starts a new one after it.
List<DiaryDashboardBlock> packDiaryDashboard(List<DiaryTilePlacement> tiles) {
  final blocks = <DiaryDashboardBlock>[];
  var run = <DiaryTilePlacement>[];
  void closeRun() {
    if (run.isNotEmpty) blocks.add(_packGrid(run));
    run = [];
  }

  for (final tile in tiles) {
    if (tile.size.isWide) {
      closeRun();
      blocks.add(DiaryWideBlock(tile));
    } else {
      run.add(tile);
    }
  }
  closeRun();
  return List.unmodifiable(blocks);
}

DiaryGridBlock _packGrid(List<DiaryTilePlacement> tiles) {
  final taken = <List<bool>>[];
  bool fits(int row, int column, int width, int height) {
    for (var r = row; r < row + height; r++) {
      if (r >= taken.length) return true;
      for (var c = column; c < column + width; c++) {
        if (taken[r][c]) return false;
      }
    }
    return true;
  }

  final packed = <DiaryPackedTile>[];
  for (final tile in tiles) {
    final width = tile.size.columns;
    final height = tile.size.rows!;
    for (var row = 0; ; row++) {
      final column = Iterable<int>.generate(diaryDashboardColumns - width + 1)
          .firstWhereOrNull((c) => fits(row, c, width, height));
      if (column == null) continue;
      while (taken.length < row + height) {
        taken.add(List.filled(diaryDashboardColumns, false));
      }
      for (var r = row; r < row + height; r++) {
        for (var c = column; c < column + width; c++) {
          taken[r][c] = true;
        }
      }
      packed.add(DiaryPackedTile(placement: tile, column: column, row: row));
      break;
    }
  }
  return DiaryGridBlock(tiles: List.unmodifiable(packed), rows: taken.length);
}

/// Rows a wide tile counts as when a drag picks the closest size.
const _wideSnapRows = 3;

/// The size of [sizes] closest to a drag that spans [columns] by [rows]
/// cells.
DiaryTileSize snapDiaryTileSize(
  List<DiaryTileSize> sizes,
  double columns,
  double rows,
) {
  double distance(DiaryTileSize size) {
    final dc = size.columns - columns;
    final dr = (size.rows ?? _wideSnapRows) - rows;
    return dc * dc + dr * dr;
  }

  return sizes.reduce((a, b) => distance(b) < distance(a) ? b : a);
}
