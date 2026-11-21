import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macro_text.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_caption.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_number_body.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_ring.dart';

/// The inside of the macros tile at [size] in display mode [mode].
class DiaryMacrosTileLayout extends StatelessWidget {
  /// Creates the layout of [macros].
  const new({
    required this.macros,
    required this.size,
    required this.mode,
    super.key,
  });

  /// The three macros.
  final List<DiaryMacroTileView> macros;

  /// Size of the tile.
  final DiaryTileSize size;

  /// Id of the display mode.
  final String mode;

  @override
  Widget build(BuildContext context) => switch (mode) {
    DiaryTileModes.rings => _RingsLayout(macros: macros, size: size),
    DiaryTileModes.numbers => _NumbersLayout(macros: macros, size: size),
    _ => _BarsLayout(macros: macros, size: size),
  };
}

/// The macros as three thin lines: side by side with their letters in one
/// row, stacked with their names in two.
class _BarsLayout extends StatelessWidget {
  const new({required this.macros, required this.size});

  /// The three macros.
  final List<DiaryMacroTileView> macros;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    final sideBySide = size.rows == 1;
    // Shrinks while the tile grows into its second row, and with very
    // large text.
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = sideBySide
            ? (constraints.maxWidth - 2 * AppSpacing.sm) / 3
            : constraints.maxWidth;
        final names = diaryMacroNames(
          context,
          macros,
          maxWidth: width * AppDashboard.macroNameShare,
          style: diaryMacroNameStyle(context),
          // Side by side, only a full row has room for the full names.
          allowFull: !sideBySide || size.columns == DiaryTileSize.s4x1.columns,
        );
        // At large text the names share one width, so the grams share one
        // room.
        final nameWidth = diaryMacroNameWidth(context, names);
        final valueWidth = diaryMacroValueWidth(context, macros);
        final bars = [
          for (final (index, macro) in macros.indexed)
            _Bar(
              macro: macro,
              name: names[index],
              nameMinWidth: nameWidth,
              nameMaxWidth: width * AppDashboard.macroNameShare,
              valueWidth: valueWidth,
            ),
        ];

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints.tightFor(width: constraints.maxWidth)
                .copyWith(minHeight: constraints.maxHeight),
            child: sideBySide
                ? Row(
                    spacing: AppSpacing.sm,
                    children: [for (final bar in bars) Expanded(child: bar)],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: bars,
                  ),
          ),
        );
      },
    );
  }
}

/// One macro's name and grams above its line.
class _Bar extends StatelessWidget {
  const new({
    required this.macro,
    required this.name,
    required this.nameMinWidth,
    required this.nameMaxWidth,
    required this.valueWidth,
  });

  final DiaryMacroTileView macro;
  final String name;

  /// Width of the widest name, or 0.
  final double nameMinWidth;

  /// The name keeps its width; the grams shrink into the rest.
  final double nameMaxWidth;

  /// The shared size of the grams.
  final double? valueWidth;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: AppSpacing.xxs,
    children: [
      Row(
        spacing: AppSpacing.xs,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: math.min(nameMinWidth, nameMaxWidth),
              maxWidth: nameMaxWidth,
            ),
            child: DiaryMacroName(
              name,
              label: macro.label,
              color: macro.labelColor,
            ),
          ),
          Expanded(child: DiaryMacroValue(macro, sharedWidth: valueWidth)),
        ],
      ),
      DiaryBudgetLine(
        eaten: macro.eaten,
        planned: macro.planned,
        target: macro.target,
        scaleKcal: macro.scale,
        compact: true,
        eatenColor: macro.eatenColor,
      ),
    ],
  );
}

/// The macros as three small rings with their letters inside; the values
/// sit beside them on a full row and under them on two rows.
class _RingsLayout extends StatelessWidget {
  const new({required this.macros, required this.size});

  /// The three macros.
  final List<DiaryMacroTileView> macros;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    final valueWidth = diaryMacroValueWidth(context, macros);
    Widget ring(DiaryMacroTileView macro) => DiaryTileRing(
      eaten: macro.eaten,
      planned: macro.planned,
      target: macro.target,
      scale: macro.scale,
      eatenColor: macro.eatenColor,
      stroke: AppDashboard.ringStrokeSmall,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: DiaryMacroName(
          macro.letter,
          label: macro.label,
          color: macro.labelColor,
        ),
      ),
    );

    Widget item(DiaryMacroTileView macro) => switch (size) {
      DiaryTileSize.s2x1 => Center(child: ring(macro)),
      DiaryTileSize.s4x1 => LayoutBuilder(
        builder: (context, constraints) => Row(
          spacing: AppSpacing.xs,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * AppDashboard.macroNameShare,
              ),
              child: ring(macro),
            ),
            Expanded(
              child: DiaryMacroValue(
                macro,
                sharedWidth: valueWidth,
                alignment: AlignmentDirectional.centerStart,
              ),
            ),
          ],
        ),
      ),
      _ => Column(
        spacing: AppSpacing.xxs,
        children: [
          Expanded(child: Center(child: ring(macro))),
          DiaryMacroValue(
            macro,
            sharedWidth: valueWidth,
            alignment: AlignmentDirectional.center,
          ),
        ],
      ),
    };

    return Row(
      spacing: AppSpacing.sm,
      children: [for (final macro in macros) Expanded(child: item(macro))],
    );
  }
}

/// The macros as three numbers with their names under them; two full-width
/// rows add eaten of target.
class _NumbersLayout extends StatelessWidget {
  const new({required this.macros, required this.size});

  /// The three macros.
  final List<DiaryMacroTileView> macros;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    // A third of two cells is too narrow for eaten of target.
    final withTotal = size == DiaryTileSize.s4x2;
    return LayoutBuilder(
      builder: (context, constraints) {
        final names = diaryMacroNames(
          context,
          macros,
          maxWidth: (constraints.maxWidth - 2 * AppSpacing.sm) / 3,
          style: DiaryTileCaption.styleOf(context),
          allowFull: size.columns == DiaryTileSize.s4x1.columns,
        );
        final valueWidth = DiaryTileNumber.sharedWidthOf(context, [
          for (final macro in macros) macro.value,
        ]);
        return Row(
          spacing: AppSpacing.sm,
          children: [
            for (final (index, macro) in macros.indexed)
              Expanded(
                child: DiaryTileNumberBody(
                  number: DiaryTileNumber(
                    macro.value,
                    sharedWidth: valueWidth,
                    color: macro.valueColor,
                    alignment: AlignmentDirectional.bottomStart,
                  ),
                  captions: [
                    DiaryTileCaption(
                      names[index],
                      color: macro.labelColor,
                      semanticsLabel: macro.label,
                    ),
                    if (withTotal && macro.total != null)
                      DiaryTileCaption(macro.total!, wholeOnly: true),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
