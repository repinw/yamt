import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_watch.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_style.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_macros_tile_layouts.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Mode id of the macros tile: three thin lines.
const diaryMacrosTileBarsMode = 'bars';

/// Mode id of the macros tile: three small rings.
const diaryMacrosTileRingsMode = 'rings';

/// Mode id of the macros tile: three numbers.
const diaryMacrosTileNumbersMode = 'numbers';

/// Protein, carbs, and fat of the day against their targets, as the budget
/// card's macro column shows them.
const diaryMacrosTile = DiaryDashboardTile(
  id: 'macros',
  icon: Icons.pie_chart_outline,
  label: _label,
  sizes: [
    DiaryTileSize.s2x1,
    DiaryTileSize.s2x2,
    DiaryTileSize.s4x1,
    DiaryTileSize.s4x2,
  ],
  defaultSize: DiaryTileSize.s4x1,
  modes: [
    DiaryTileMode(
      id: diaryMacrosTileBarsMode,
      icon: Icons.view_headline,
      label: _barsLabel,
    ),
    DiaryTileMode(
      id: diaryMacrosTileRingsMode,
      icon: Icons.data_usage,
      label: _ringsLabel,
    ),
    DiaryTileMode(
      id: diaryMacrosTileNumbersMode,
      icon: Icons.pin_outlined,
      label: _numbersLabel,
    ),
  ],
  builder: _build,
  visibleByDefault: false,
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
    final data = watchDiaryBudgetCardData(ref, args.day);
    final showEaten = ref.watch(diaryBudgetEatenViewControllerProvider);
    if (data == null || data.macros.isEmpty) {
      return DiaryTileNumber('–', color: FoodLabelColors.of(context).muted);
    }
    final macros = [
      for (final macro in data.macros)
        _view(context, data: data, macro: macro, showEaten: showEaten),
    ];

    return switch (args.mode) {
      diaryMacrosTileRingsMode => DiaryMacrosRingsLayout(
        macros: macros,
        size: args.size,
      ),
      diaryMacrosTileNumbersMode => DiaryMacrosNumbersLayout(
        macros: macros,
        size: args.size,
      ),
      _ => DiaryMacrosBarsLayout(macros: macros, size: args.size),
    };
  }
}

/// The tile's values of [macro] of [data], in the budget card's meaning.
DiaryMacroTileView _view(
  BuildContext context, {
  required DiaryBudgetCardData data,
  required DiaryBudgetMacro macro,
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
        : diaryBudgetMacroTextColor(context, macroColor),
    valueColor: isPauseDay ? colors.muted : colors.ink,
    eaten: macro.eaten,
    planned: macro.planned,
    target: isPauseDay ? null : macro.target,
    scale: macro.target,
    eatenColor: isPauseDay
        ? colors.muted
        : data.isPlannedDay
        ? colors.plan
        : macroColor,
  );
}
