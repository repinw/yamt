import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/theme/metric_accent_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_card_data_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_macro_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Protein, carbs, and fat of the day against their targets, as the budget
/// card's macro column shows them.
const diaryMacrosTile = DiaryDashboardTile(
  spec: diaryMacrosTileSpec,
  icon: Icons.pie_chart_outline,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.bars,
      icon: Icons.view_headline,
      label: _barsLabel,
    ),
    DiaryTileMode(
      id: DiaryTileModes.rings,
      icon: Icons.data_usage,
      label: _ringsLabel,
    ),
    DiaryTileMode(
      id: DiaryTileModes.numbers,
      icon: Icons.pin_outlined,
      label: _numbersLabel,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileMacros;

String _barsLabel(AppLocalizations l10n) => l10n.diaryDashboardMacrosModeBars;

String _ringsLabel(AppLocalizations l10n) => l10n.diaryDashboardMacrosModeRings;

String _numbersLabel(AppLocalizations l10n) =>
    l10n.diaryDashboardMacrosModeNumbers;

Widget _build(DiaryTileArgs args) => _MacrosTile(args);

class _MacrosTile extends ConsumerWidget {
  const new(this.args);

  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DiaryTileLoadError.watchFailed(ref, args.day)) {
      return DiaryTileLoadError(size: args.size);
    }
    final data = ref.watch(diaryBudgetCardDataProvider(args.day));
    final showEaten = ref.watch(diaryBudgetEatenViewControllerProvider);
    if (data == null || data.macros.isEmpty) {
      return const DiaryTileNoValue();
    }
    // As the budget card: the lowest macro takes its color, all of them
    // when the user wants them colored, none on a pause or past day.
    final allColored =
        MetricAccentColors.of(context).allMacrosColored &&
        !data.isPauseDay &&
        !data.status.isPast;
    final macros = [
      for (final macro in data.macros)
        _view(
          context,
          data: data,
          macro: macro,
          isColored: allColored || macro.kind == data.lowestMacro,
          showEaten: showEaten,
        ),
    ];

    return DiaryMacrosTileLayout(
      macros: macros,
      size: args.size,
      mode: args.mode,
    );
  }
}

/// The tile's values of [macro] of [data], in the budget card's meaning.
DiaryMacroTileView _view(
  BuildContext context, {
  required DiaryBudgetCardData data,
  required DiaryBudgetMacro macro,
  required bool isColored,
  required bool showEaten,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colors = FoodLabelColors.of(context);
  final numberFormat = NumberFormat.decimalPattern(
    Localizations.localeOf(context).toLanguageTag(),
  );
  String grams(num value) => numberFormat.format(value.round());
  final macroColor = diaryBudgetMacroColor(context, macro.kind);
  final isPauseDay = data.isPauseDay;

  return (
    letter: switch (macro.kind) {
      DiaryBudgetMacroKind.protein => l10n.diaryDashboardMacroProteinShort,
      DiaryBudgetMacroKind.carbs => l10n.diaryDashboardMacroCarbsShort,
      DiaryBudgetMacroKind.fat => l10n.diaryDashboardMacroFatShort,
    },
    label: diaryBudgetMacroLabel(l10n, macro.kind),
    value: diaryBudgetMacroValue(
      l10n,
      macro,
      showEaten: showEaten,
      isPauseDay: isPauseDay,
      numberFormat: numberFormat,
    ),
    // The eaten view already shows the eaten grams.
    total: isPauseDay || showEaten
        ? null
        : l10n.diaryMacroEatenOfTarget(
            grams(macro.eaten + macro.planned),
            grams(macro.target),
          ),
    labelColor: isPauseDay
        ? colors.muted
        : isColored
        ? diaryBudgetMacroTextColor(context, macroColor)
        : colors.muted,
    valueColor: isPauseDay ? colors.muted : colors.ink,
    eaten: macro.eaten,
    planned: macro.planned,
    target: isPauseDay ? null : macro.target,
    scale: macro.target,
    eatenColor: isPauseDay
        ? colors.muted
        : data.isPlannedDay
        ? colors.plan
        : isColored
        ? macroColor
        : colors.ink,
  );
}
