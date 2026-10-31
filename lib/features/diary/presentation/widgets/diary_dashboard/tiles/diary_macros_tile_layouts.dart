import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
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
    Widget bar(DiaryMacroTileView macro, String name) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xxs,
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Row(
            spacing: AppSpacing.xs,
            children: [
              // The name keeps its width; the grams shrink into the rest.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * AppDashboard.macroNameShare,
                ),
                child: _Name(name, color: macro.labelColor),
              ),
              Expanded(child: _Value(macro)),
            ],
          ),
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

    if (size.rows == 1) {
      return Row(
        spacing: AppSpacing.sm,
        children: [
          for (final macro in macros)
            Expanded(child: bar(macro, _shortName(macro, size))),
        ],
      );
    }
    // Shrinks while the tile grows into its second row, and with very
    // large text.
    return LayoutBuilder(
      builder: (context, constraints) => FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: constraints.maxWidth)
              .copyWith(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final macro in macros) bar(macro, macro.label)],
          ),
        ),
      ),
    );
  }
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
    Widget ring(DiaryMacroTileView macro) => DiaryTileRing(
      eaten: macro.eaten,
      planned: macro.planned,
      target: macro.target,
      scale: macro.scale,
      eatenColor: macro.eatenColor,
      stroke: AppDashboard.ringStrokeSmall,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _Name(macro.letter, color: macro.labelColor),
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
              child: _Value(macro, alignment: AlignmentDirectional.centerStart),
            ),
          ],
        ),
      ),
      _ => Column(
        spacing: AppSpacing.xxs,
        children: [
          Expanded(child: Center(child: ring(macro))),
          _Value(macro, alignment: AlignmentDirectional.center),
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
    return Row(
      spacing: AppSpacing.sm,
      children: [
        for (final macro in macros)
          Expanded(
            child: DiaryTileNumberBody(
              number: DiaryTileNumber(
                macro.value,
                color: macro.valueColor,
                alignment: AlignmentDirectional.bottomStart,
              ),
              captions: [
                DiaryTileCaption(
                  _shortName(macro, size),
                  color: macro.labelColor,
                ),
                if (withTotal && macro.total != null)
                  DiaryTileCaption(macro.total!),
              ],
            ),
          ),
      ],
    );
  }
}

/// The name that fits a third of a tile of [size]: the letter on two
/// cells, the full name on four.
String _shortName(DiaryMacroTileView macro, DiaryTileSize size) =>
    size.columns < DiaryTileSize.s4x1.columns ? macro.letter : macro.label;

/// Name or letter of a macro in its color.
class _Name extends StatelessWidget {
  const new(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontFamily: AppFonts.geist,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Grams of a macro, shrunk to fit.
class _Value extends StatelessWidget {
  const new(this.macro, {this.alignment = AlignmentDirectional.centerEnd});

  final DiaryMacroTileView macro;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    // Keeps the line height in a row: the fitted box alone would take the
    // height its aspect ratio gives the full row width.
    return Align(
      alignment: alignment,
      heightFactor: 1,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Text(
          macro.value,
          maxLines: 1,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: AppFonts.geist,
            fontWeight: FontWeight.w700,
            color: macro.valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
