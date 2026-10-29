import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/constants/app_budget_card_constants.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/theme/app_fonts.dart';
import 'package:yamt/core/theme/food_label_colors.dart';
import 'package:yamt/features/diary/presentation/models/diary_budget_card_data.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_fade_in.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_kcal_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_ledger.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_macro_column.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_previous_day_button.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_toggle_row.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_view_chips.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_budget_card/diary_budget_week_strip.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The diary's daily budget: the kcal left next to the macros, the toggles
/// for details, plans and the day type, and with details the ledger and the
/// day types of the run week.
class DiaryBudgetCard extends StatelessWidget {
  /// Creates the card.
  const new({
    required this.data,
    required this.showDetails,
    required this.showEaten,
    required this.today,
    super.key,
  });

  /// Card data.
  final DiaryBudgetCardData data;

  /// Whether the details are open.
  final bool showDetails;

  /// Whether the numbers show what was eaten instead of what is left.
  final bool showEaten;

  /// Today, for the week strip.
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final colors = FoodLabelColors.of(context);

    return DecoratedBox(
      key: DiaryBudgetCardKeys.card,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      // The toggle row's last tap area reaches into the end padding.
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppBudgetCard.padding,
          AppBudgetCard.topPadding,
          AppBudgetCard.padding - AppBudgetCard.dayTypeHitOverhang,
          AppBudgetCard.padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppBudgetCard.sectionGap,
          children: [
            DiaryBudgetToggleRow(
              day: data.day,
              showViewSwitch: !data.isPauseDay,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: AppBudgetCard.dayTypeHitOverhang,
              ),
              // Opening the details grows the card smoothly downward.
              child: AnimatedSize(
                duration: AppDurations.compactMetricExpansion,
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _Body(
                  data: data,
                  showDetails: showDetails,
                  showEaten: showEaten,
                  today: today,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Everything of the card below the toggle row.
class _Body extends StatelessWidget {
  const new({
    required this.data,
    required this.showDetails,
    required this.showEaten,
    required this.today,
  });

  final DiaryBudgetCardData data;
  final bool showDetails;
  final bool showEaten;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    final weekStart = data.runWeekStart;
    final notCounting = data.notCounting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBudgetCard.sectionGap,
      children: [
        // Both columns start at the top, so the details only push down.
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppBudgetCard.columnGap,
          children: [
            Expanded(
              flex: AppBudgetCard.kcalColumnFlex,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  DiaryBudgetKcalColumn(
                    data: data,
                    showDetails: showDetails,
                    showEaten: showEaten,
                    numberFormat: numberFormat,
                  ),
                  DiaryBudgetViewChips(showAfterPlan: data.openPlans != null),
                ],
              ),
            ),
            Expanded(
              flex: AppBudgetCard.macroColumnFlex,
              child: DiaryBudgetMacroColumn(
                data: data,
                showDetails: showDetails,
                showEaten: showEaten,
                numberFormat: numberFormat,
              ),
            ),
          ],
        ),
        if (data.canClosePreviousDay && !data.isPauseDay)
          DiaryBudgetPreviousDayButton(
            day: data.day,
            isClosed: data.isPreviousDayClosed,
          ),
        if (showDetails) ...[
          DiaryBudgetFadeIn(
            order: 1,
            child: DiaryBudgetLedger(data: data, numberFormat: numberFormat),
          ),
          if (weekStart != null)
            DiaryBudgetFadeIn(
              order: 2,
              child: DiaryBudgetWeekStrip(
                weekStart: weekStart,
                selectedDay: data.day,
                today: today,
              ),
            ),
        ],
        if (notCounting != null) _NotCountingNote(notCounting),
      ],
    );
  }
}

/// Note of a practice day or a day after the run ended: tracking works, but
/// the day counts only from the start date.
class _NotCountingNote extends StatelessWidget {
  const new(this.notCounting);

  final DiaryBudgetNotCounting notCounting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = FoodLabelColors.of(context);
    final date = DateFormat.MEd(Localizations.localeOf(context).toLanguageTag())
        .format(notCounting.startDate);

    return DecoratedBox(
      key: DiaryBudgetCardKeys.notCountingNote,
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            Icon(
              Icons.spa_outlined,
              size: AppBudgetCard.chipIcon,
              color: colors.accentText,
            ),
            Expanded(
              child: Text(
                switch (notCounting) {
                  DiaryBudgetPracticeDay() => l10n.burnWeekPracticeDayBadge(
                    date,
                  ),
                  DiaryBudgetRunEnded() => l10n.diaryBudgetRunEndedNotice(date),
                },
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: AppFonts.geist,
                  fontWeight: FontWeight.w600,
                  color: colors.accentText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
