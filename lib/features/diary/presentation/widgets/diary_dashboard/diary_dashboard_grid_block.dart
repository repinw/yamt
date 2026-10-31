import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_packing.dart';

/// Cell sizes of the dashboard grid at one width.
@immutable
class DiaryDashboardMetrics {
  /// Metrics for a grid [width] wide at [textScaler].
  factory of(double width, TextScaler textScaler) {
    const gaps = AppDashboard.gap * (diaryDashboardColumns - 1);
    final cell = (width - gaps) / diaryDashboardColumns;
    final rowHeight = textScaler
        .clamp(maxScaleFactor: AppDashboard.maxRowTextScale)
        .scale(cell);
    return DiaryDashboardMetrics._(cell, rowHeight);
  }

  const new _(this.cellWidth, this.rowHeight);

  /// Width of one cell.
  final double cellWidth;

  /// Height of one row; it grows with the text scale.
  final double rowHeight;

  /// Width of [columns] cells with the gaps between them.
  double width(int columns) =>
      columns * cellWidth + (columns - 1) * AppDashboard.gap;

  /// Height of [rows] rows with the gaps between them.
  double height(int rows) => rows * rowHeight + (rows - 1) * AppDashboard.gap;

  /// Cells a drag of [span] from a tile's corner covers, as fractions.
  ({double columns, double rows}) cellsOf(Offset span) => (
    columns: (span.dx + AppDashboard.gap) / (cellWidth + AppDashboard.gap),
    rows: (span.dy + AppDashboard.gap) / (rowHeight + AppDashboard.gap),
  );
}

/// Tiles of fixed size in their cells; they slide when the layout changes.
class DiaryDashboardGridBlock extends StatelessWidget {
  /// Creates the block.
  const new({
    required this.block,
    required this.metrics,
    required this.slotBuilder,
    super.key,
  });

  /// The packed tiles.
  final DiaryGridBlock block;

  /// Cell sizes.
  final DiaryDashboardMetrics metrics;

  /// Builds the slot of one tile.
  final Widget Function(DiaryTilePlacement placement) slotBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: metrics.height(block.rows),
      child: Stack(
        children: [
          for (final packed in block.tiles)
            AnimatedPositionedDirectional(
              key: ValueKey(packed.placement.id),
              duration: AppDashboard.reflow,
              curve: Curves.easeOutCubic,
              start: packed.column * (metrics.cellWidth + AppDashboard.gap),
              top: packed.row * (metrics.rowHeight + AppDashboard.gap),
              width: metrics.width(packed.placement.size.columns),
              height: metrics.height(packed.placement.size.rows!),
              child: slotBuilder(packed.placement),
            ),
        ],
      ),
    );
  }
}
