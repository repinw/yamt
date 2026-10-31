import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_ring.dart';

/// What the kcal tile shows, ready to draw.
typedef DiaryKcalTileView = ({
  /// Big number (or the pause day's word).
  String value,

  /// Number in the middle of the ring.
  String ringValue,

  /// What the big number means.
  String caption,

  /// What the ring's number means.
  String ringCaption,

  /// Eaten of target, or null when the caption says it already.
  String? total,

  /// Color of the number.
  Color color,

  /// Eaten kcal of the line and the ring.
  double eaten,

  /// Counted planned kcal of the line and the ring.
  double planned,

  /// Target kcal, or null on a pause day.
  double? target,

  /// Amount of a full line or ring without a target.
  double scale,

  /// Color of the eaten part of the line and the ring.
  Color eatenColor,
});

/// The kcal tile as a number with its caption; one cell shows the number
/// alone, two rows add eaten of target.
class DiaryKcalNumberLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.view, required this.size, super.key});

  /// Values of the tile.
  final DiaryKcalTileView view;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    final single = size == DiaryTileSize.s1x1;
    final number = DiaryTileNumber(
      view.value,
      color: view.color,
      alignment: single
          ? AlignmentDirectional.center
          : AlignmentDirectional.bottomStart,
    );
    if (single) return number;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: number),
        DiaryTileCaption(view.caption),
        if (size.rows == 2 && view.total != null) DiaryTileCaption(view.total!),
      ],
    );
  }
}

/// The kcal tile as a number over the budget card's kcal line.
class DiaryKcalBarLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.view, required this.size, super.key});

  /// Values of the tile.
  final DiaryKcalTileView view;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    final twoRows = size.rows == 2;
    final number = DiaryTileNumber(
      view.value,
      color: view.color,
      alignment: AlignmentDirectional.bottomStart,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: size == DiaryTileSize.s4x1
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: AppSpacing.sm,
                  children: [
                    Flexible(child: number),
                    Expanded(child: DiaryTileCaption(view.caption)),
                  ],
                )
              : number,
        ),
        if (twoRows) DiaryTileCaption(view.caption),
        const SizedBox(height: AppSpacing.xxs),
        DiaryBudgetLine(
          eaten: view.eaten,
          planned: view.planned,
          target: view.target,
          scaleKcal: view.scale,
          compact: !twoRows,
          eatenColor: view.eatenColor,
        ),
      ],
    );
  }
}

/// The kcal tile as a ring of eaten against the target: one cell shows the
/// ring with the number inside, one row puts the number beside it, and two
/// rows the number inside a large ring.
class DiaryKcalRingLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.view, required this.size, super.key});

  /// Values of the tile.
  final DiaryKcalTileView view;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    DiaryTileRing ring({Widget? child, double? stroke}) => DiaryTileRing(
      eaten: view.eaten,
      planned: view.planned,
      target: view.target,
      scale: view.scale,
      eatenColor: view.eatenColor,
      stroke: stroke ?? AppDashboard.ringStroke,
      child: child,
    );
    final number = DiaryTileNumber(
      view.ringValue,
      color: view.color,
      alignment: AlignmentDirectional.center,
    );

    return switch (size) {
      DiaryTileSize.s1x1 => Center(
        child: ring(child: number, stroke: AppDashboard.ringStrokeSmall),
      ),
      DiaryTileSize.s2x2 => Column(
        children: [
          Expanded(
            child: Center(child: ring(child: number)),
          ),
          const SizedBox(height: AppSpacing.xs),
          DiaryTileCaption(view.ringCaption),
        ],
      ),
      _ => Row(
        spacing: AppSpacing.sm,
        children: [
          ring(stroke: AppDashboard.ringStrokeSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DiaryTileNumber(
                    view.ringValue,
                    color: view.color,
                    alignment: AlignmentDirectional.bottomStart,
                  ),
                ),
                DiaryTileCaption(view.ringCaption),
              ],
            ),
          ),
        ],
      ),
    };
  }
}
