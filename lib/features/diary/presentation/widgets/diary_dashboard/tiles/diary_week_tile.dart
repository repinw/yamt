import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_dashboard_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/application/diary_today_provider.dart';
import 'package:yamt/features/diary/domain/diary_dashboard_layout.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_balance_card_provider.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_burn_week_card/diary_daily_budget_details_sheet.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_dashboard_tile.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/diary_tile_parts.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_dashboard/tiles/diary_week_tile_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The run week's balance: what the finished days of the run week saved or
/// went over, and the days the run still has.
const diaryWeekTile = DiaryDashboardTile(
  id: 'week',
  icon: Icons.calendar_view_week_outlined,
  label: _label,
  sizes: [DiaryTileSize.s2x1, DiaryTileSize.s4x1, DiaryTileSize.s4x2],
  defaultSize: DiaryTileSize.s2x1,
  modes: [
    DiaryTileMode(
      id: 'numbers',
      icon: Icons.numbers_rounded,
      label: _numbersLabel,
    ),
    DiaryTileMode(
      id: 'strip',
      icon: Icons.more_horiz_rounded,
      label: _stripLabel,
    ),
  ],
  builder: _build,
);

String _label(AppLocalizations l10n) => l10n.diaryDashboardTileWeek;

String _numbersLabel(AppLocalizations l10n) => l10n.diaryDashboardModeNumbers;

String _stripLabel(AppLocalizations l10n) => l10n.diaryDashboardModeStrip;

Widget _build(DiaryTileArgs args) => DiaryWeekTile(args: args);

/// Inside of the week tile.
class DiaryWeekTile extends ConsumerWidget {
  /// Creates the tile for [args].
  const new({required this.args, super.key});

  /// Day, size, and mode of the tile.
  final DiaryTileArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(diaryTodayProvider);
    final card = ref.watch(diaryBalanceCardProvider(args.day));
    final data = card == null
        ? null
        : DiaryBudgetCardData.from(card: card, today: today);
    final details = data?.notCounting == null ? data?.budgetDetails : null;
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final number = details == null
        ? const DiaryWeekTileNumber.empty()
        : DiaryWeekTileNumber(
            balanceKcal: details.totalCarryoverBeforeTodayKcal,
            daysLeft: details.remainingRunDays,
            numberFormat: numberFormat,
          );
    final weekStart = data?.runWeekStart;

    final content = switch (args.mode) {
      'strip' when data != null && weekStart != null => _strip(
        data: data,
        weekStart: weekStart,
        today: today,
        number: number,
      ),
      'strip' => const DiaryWeekTileNumber.empty(),
      _ => number,
    };
    if (details == null) {
      return content;
    }
    return AppInkWell(
      onTap: () => showDiaryDailyBudgetDetailsSheet(
        context: context,
        data: details,
        numberFormat: numberFormat,
      ),
      child: content,
    );
  }

  Widget _strip({
    required DiaryBudgetCardData data,
    required DateTime weekStart,
    required DateTime today,
    required Widget number,
  }) {
    final strip = DiaryWeekTileStrip(
      data: data,
      weekStart: weekStart,
      today: today,
    );
    return switch (args.size) {
      DiaryTileSize.s4x1 => Row(
        spacing: AppDashboard.weekNumberGap,
        children: [
          Expanded(child: number),
          Expanded(child: Center(child: strip)),
        ],
      ),
      DiaryTileSize.s4x2 => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Expanded(child: number),
          strip,
        ],
      ),
      _ => Center(child: strip),
    };
  }
}

/// The week balance as the big number with a caption of the days left, or
/// a muted dash while the day has no balance.
class DiaryWeekTileNumber extends StatelessWidget {
  /// Creates the number of [balanceKcal], positive when the run week saved.
  const new({
    required double this.balanceKcal,
    required int this.daysLeft,
    required NumberFormat this.numberFormat,
    super.key,
  });

  /// Creates the muted dash.
  const new empty({super.key})
    : balanceKcal = null,
      daysLeft = null,
      numberFormat = null;

  /// Saved (positive) or over (negative) kcal of the run week's finished
  /// days.
  final double? balanceKcal;

  /// Days left in the run, the selected day included.
  final int? daysLeft;

  /// Locale number format.
  final NumberFormat? numberFormat;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);
    final (balanceKcal, daysLeft, numberFormat) = (
      this.balanceKcal,
      this.daysLeft,
      this.numberFormat,
    );
    if (balanceKcal == null || daysLeft == null || numberFormat == null) {
      return DiaryTileNumber('–', color: colors.muted);
    }
    final l10n = AppLocalizations.of(context)!;
    final kcal = balanceKcal.round();
    final isOver = kcal < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: DiaryTileNumber(
            isOver
                ? l10n.diaryBudgetOverValue(numberFormat.format(-kcal))
                : numberFormat.format(kcal),
            unit: l10n.caloriesUnitKcal,
            color: isOver
                ? Theme.of(context).colorScheme.error
                : colors.accentText,
          ),
        ),
        DiaryTileCaption(
          isOver
              ? l10n.diaryWeekTileOverCaption(daysLeft)
              : l10n.diaryWeekTileLeftCaption(daysLeft),
        ),
      ],
    );
  }
}
