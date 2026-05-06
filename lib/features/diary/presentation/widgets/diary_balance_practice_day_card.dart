part of 'diary_balance_card.dart';

/// Whether the diary balance card should show the pre-start practice state.
bool shouldShowDiaryBalancePracticeDayCard({
  required CalorieWeekOverview weekOverview,
  required DateTime selectedDay,
}) {
  final startDate = weekOverview.nextGoalStartDate;
  if (!weekOverview.goalStartsInFuture || startDate == null) {
    return false;
  }
  return normalizeDiaryDay(selectedDay).isBefore(normalizeDiaryDay(startDate));
}

/// Practice-day state shown before official Burn Week counting starts.
class DiaryBalancePracticeDayCard extends StatelessWidget {
  /// Creates a practice-day card.
  const DiaryBalancePracticeDayCard({
    required this.startDate,
    required this.futureGoalKcal,
    super.key,
  });

  /// First official counting day.
  final DateTime startDate;

  /// Goal that will become active on [startDate].
  final double? futureGoalKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dateFormat = DateFormat.yMMMd(localeName);
    final numberFormat = NumberFormat.decimalPattern(localeName);
    final colors = Theme.of(context).colorScheme;
    final futureGoalText = futureGoalKcal == null
        ? null
        : '${l10n.caloriesGoalLabel}: '
              '${numberFormat.format(futureGoalKcal!.round())} '
              '${l10n.caloriesUnitKcal}';

    return _DiaryBalanceShell(
      child: Column(
        key: DiaryBalanceCardKeys.practiceDay,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            color: colors.primary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.burnWeekPracticeDayTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.burnWeekPracticeDayMessage(dateFormat.format(startDate)),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (futureGoalText != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              futureGoalText,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
