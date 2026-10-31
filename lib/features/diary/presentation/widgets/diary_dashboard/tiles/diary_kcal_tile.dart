import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_tiles.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_card_data_provider.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_budget_eaten_view_controller.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/models/diary_kcal_tile_view.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_kcal_texts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_kcal_tile_layouts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_load_error.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_tile_no_value.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The kcal left of the day, as the budget card's big number shows them.
const diaryKcalTile = DiaryDashboardTile(
  spec: diaryKcalTileSpec,
  icon: Icons.local_fire_department_outlined,
  label: _label,
  modes: [
    DiaryTileMode(
      id: DiaryTileModes.number,
      icon: Icons.pin_outlined,
      label: _numberLabel,
    ),
    DiaryTileMode(
      id: DiaryTileModes.bar,
      icon: Icons.linear_scale,
      label: _barLabel,
    ),
    DiaryTileMode(
      id: DiaryTileModes.ring,
      icon: Icons.data_usage,
      label: _ringLabel,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileKcal;

String _numberLabel(AppLocalizations l10n) => l10n.diaryDashboardKcalModeNumber;

String _barLabel(AppLocalizations l10n) => l10n.diaryDashboardKcalModeBar;

String _ringLabel(AppLocalizations l10n) => l10n.diaryDashboardKcalModeRing;

Widget _build(DiaryTileArgs args) => _KcalTile(args);

class _KcalTile extends ConsumerWidget {
  const new(this.args);

  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (DiaryTileLoadError.watchFailed(ref, args.day)) {
      return DiaryTileLoadError(size: args.size);
    }
    final data = ref.watch(diaryBudgetCardDataProvider(args.day));
    if (data == null) {
      return const DiaryTileNoValue();
    }
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final view = _view(
      context,
      data: data,
      showEaten: ref.watch(diaryBudgetEatenViewControllerProvider),
      numberFormat: numberFormat,
    );
    final content = DiaryKcalTileLayout(
      view: view,
      size: args.size,
      mode: args.mode,
    );

    final details = data.isPauseDay ? null : data.budgetDetails;
    if (details == null) return content;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => unawaited(
          showDiaryDailyBudgetDetailsSheet(
            context: context,
            data: details,
            numberFormat: numberFormat,
            plannedKcal: data.countsPlans ? data.countedPlannedKcal : null,
          ),
        ),
        child: content,
      ),
    );
  }
}

/// The kcal tile's values of [data], in the budget card's meaning.
DiaryKcalTileView _view(
  BuildContext context, {
  required DiaryBudgetCardData data,
  required bool showEaten,
  required NumberFormat numberFormat,
}) {
  final l10n = AppLocalizations.of(context)!;
  final colors = FoodLabelColors.of(context);
  final metrics = data.metrics;
  String kcal(double value) => numberFormat.format(value.round());

  if (data.isPauseDay) {
    final eaten = kcal(metrics.realEatenKcal);
    return (
      value: l10n.diaryBalancePauseDayValue,
      ringValue: eaten,
      caption: l10n.diaryBudgetPauseEaten(eaten),
      ringCaption: l10n.diaryBalancePauseDayValue,
      total: null,
      color: colors.muted,
      eaten: metrics.realEatenKcal,
      planned: data.countedPlannedKcal,
      target: null,
      scale: metrics.targetKcal,
      eatenColor: colors.muted,
      overColor: colors.muted,
      pace: null,
    );
  }

  final (:value, :unit, :color, amount: _) = diaryBudgetKcalTexts(
    context,
    data: data,
    showEaten: showEaten,
    numberFormat: numberFormat,
  );
  final caption = unit.replaceAll('\n', ' ');
  return (
    value: value,
    ringValue: value,
    caption: caption,
    ringCaption: caption,
    // The eaten view already says eaten of target.
    total: showEaten
        ? null
        : l10n.diaryBudgetKcalEatenOfTarget(
            kcal(metrics.eatenKcal + data.countedPlannedKcal),
            kcal(metrics.targetKcal),
          ),
    color: color,
    eaten: metrics.eatenKcal,
    planned: data.countedPlannedKcal,
    target: metrics.targetKcal,
    scale: metrics.targetKcal,
    eatenColor: data.isPlannedDay ? colors.plan : colors.accent,
    // Going over is the miss for every weight goal but gaining.
    overColor: data.overIsMiss
        ? Theme.of(context).colorScheme.error
        : colors.ink,
    pace: data.paceKcal,
  );
}
