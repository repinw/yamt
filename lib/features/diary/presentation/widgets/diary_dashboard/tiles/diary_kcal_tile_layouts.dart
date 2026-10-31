import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_kcal_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_ring.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The inside of the kcal tile at [size] in display mode [mode].
class DiaryKcalTileLayout extends StatelessWidget {
  /// Creates the layout of [view].
  const new({
    required this.view,
    required this.size,
    required this.mode,
    super.key,
  });

  /// Values of the tile.
  final DiaryKcalTileView view;

  /// Size of the tile.
  final DiaryTileSize size;

  /// Id of the display mode.
  final String mode;

  @override
  Widget build(BuildContext context) => switch (mode) {
    DiaryTileModes.bar => _BarLayout(view: view, size: size),
    DiaryTileModes.ring => _RingLayout(view: view, size: size),
    _ => _NumberLayout(view: view, size: size),
  };
}

/// The kcal tile as a number with its caption; one cell shows the number
/// alone, two rows add eaten of target.
class _NumberLayout extends StatelessWidget {
  const new({required this.view, required this.size});

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

    return DiaryTileNumberBody(
      number: number,
      captions: [
        DiaryTileCaption(view.caption),
        if (size.rows == 2 && view.total != null) DiaryTileCaption(view.total!),
      ],
    );
  }
}

/// The kcal tile as a number over the budget card's kcal line.
class _BarLayout extends StatelessWidget {
  const new({required this.view, required this.size});

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
          overColor: view.overColor,
          pace: view.pace,
        ),
      ],
    );
  }
}

/// The kcal tile as a ring of eaten against the target: one cell shows the
/// ring with the number inside, one row puts the number beside it (on two
/// cells with only the unit, or the pause day's word, under it), and two
/// rows the number inside a large ring.
class _RingLayout extends StatelessWidget {
  const new({required this.view, required this.size});

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
      overColor: view.overColor,
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
                // Beside the ring, two cells have room for the unit alone,
                // or for the pause day's word.
                DiaryTileCaption(
                  size == DiaryTileSize.s2x1 && view.target != null
                      ? AppLocalizations.of(context)!.caloriesUnitKcal
                      : view.ringCaption,
                ),
              ],
            ),
          ),
        ],
      ),
    };
  }
}
