import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_line.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_ring.dart';

/// What the macros tile shows of one macro, ready to draw.
typedef DiaryMacroTileView = ({
  /// One-letter name.
  String letter,

  /// Full name.
  String label,

  /// Grams left, over, or eaten.
  String value,

  /// Eaten of target, or null when the value says it already.
  String? total,

  /// Color of the name.
  Color labelColor,

  /// Color of the value.
  Color valueColor,

  /// Eaten grams.
  double eaten,

  /// Counted planned grams.
  double planned,

  /// Target grams, or null on a pause day.
  double? target,

  /// Grams of a full line or ring without a target.
  double scale,

  /// Color of the eaten part.
  Color eatenColor,
});

/// The macros as three thin lines: side by side with their letters in one
/// row, stacked with their names in two.
class DiaryMacrosBarsLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.macros, required this.size, super.key});

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
        Row(
          spacing: AppSpacing.xs,
          children: [
            Flexible(child: _Name(name, color: macro.labelColor)),
            Expanded(child: _Value(macro)),
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

    if (size.rows == 1) {
      return Row(
        spacing: AppSpacing.sm,
        children: [
          for (final macro in macros)
            Expanded(child: bar(macro, _shortName(macro, size))),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final macro in macros) bar(macro, macro.label)],
    );
  }
}

/// The macros as three small rings with their letters inside; the values
/// sit beside them on a full row and under them on two rows.
class DiaryMacrosRingsLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.macros, required this.size, super.key});

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
      DiaryTileSize.s4x1 => Row(
        spacing: AppSpacing.xs,
        children: [
          ring(macro),
          Expanded(
            child: _Value(macro, alignment: AlignmentDirectional.centerStart),
          ),
        ],
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

/// The macros as three numbers with their names under them; two rows add
/// eaten of target.
class DiaryMacrosNumbersLayout extends StatelessWidget {
  /// Creates the layout.
  const new({required this.macros, required this.size, super.key});

  /// The three macros.
  final List<DiaryMacroTileView> macros;

  /// Size of the tile.
  final DiaryTileSize size;

  @override
  Widget build(BuildContext context) {
    final twoRows = size.rows == 2;
    return Row(
      spacing: AppSpacing.sm,
      children: [
        for (final macro in macros)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DiaryTileNumber(
                    macro.value,
                    color: macro.valueColor,
                    alignment: AlignmentDirectional.bottomStart,
                  ),
                ),
                DiaryTileCaption(
                  _shortName(macro, size),
                  color: macro.labelColor,
                ),
                if (twoRows && macro.total != null)
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
    return FittedBox(
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
    );
  }
}
