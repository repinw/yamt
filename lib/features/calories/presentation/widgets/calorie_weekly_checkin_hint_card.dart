import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Defines calorie weekly check in hint card.
class CalorieWeeklyCheckInHintCard extends StatelessWidget {
  /// The calorie weekly check in hint card.
  const CalorieWeeklyCheckInHintCard({
    required this.viewModel,
    required this.selectedDay,
    required this.selectedDayHasEntries,
    required this.onContinue,
    required this.onOpenHealthTrends,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// The view model.
  final CalorieWeeklyCheckInViewModel viewModel;

  /// The selected day.
  final DateTime selectedDay;

  /// The selected day has entries.
  final bool selectedDayHasEntries;

  /// The on continue.
  final VoidCallback onContinue;

  /// The on open health trends.
  final VoidCallback onOpenHealthTrends;

  /// The on toggle selected day skipped.
  final Future<void> Function({required bool isSkipped})
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context) {
    if (!viewModel.showDiaryHint) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final pending = viewModel.pendingWeeklyCheckIn;
    final selectedDayData = viewModel.days
        .where((day) => DateUtils.isSameDay(day.day, selectedDay))
        .firstOrNull;
    final canOpenTrends = switch (viewModel.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight ||
      CalorieWeeklyCheckInBlockedReason.unstableWeightData => true,
      _ => false,
    };
    final showSkipAction =
        pending != null &&
        selectedDayData != null &&
        !selectedDay.isBefore(pending.windowStartDate) &&
        !selectedDay.isAfter(pending.windowEndDate) &&
        (!selectedDayHasEntries || selectedDayData.isSkippedIntakeDay);
    final title = _title(l10n);
    final body = _body(l10n, locale);

    return Card(
      key: CaloriesPageKeys.weeklyCheckInHintCard,
      color: colors.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(body),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: <Widget>[
                if (pending != null)
                  FilledButton(
                    key: CaloriesPageKeys.weeklyCheckInContinueButton,
                    onPressed: onContinue,
                    child: Text(l10n.caloriesWeeklyCheckInHintContinueAction),
                  ),
                if (canOpenTrends)
                  OutlinedButton(
                    key: CaloriesPageKeys.weeklyCheckInOpenTrendsButton,
                    onPressed: onOpenHealthTrends,
                    child: Text(
                      l10n.caloriesWeeklyCheckInOpenHealthTrendsAction,
                    ),
                  ),
                if (showSkipAction)
                  OutlinedButton(
                    key: CaloriesPageKeys.weeklyCheckInSkipDayButton,
                    onPressed: () {
                      unawaited(
                        onToggleSelectedDaySkipped(
                          isSkipped: !selectedDayData.isSkippedIntakeDay,
                        ),
                      );
                    },
                    child: Text(
                      selectedDayData.isSkippedIntakeDay
                          ? l10n.caloriesWeeklyCheckInUnskipDayAction
                          : l10n.caloriesWeeklyCheckInSkipDayAction,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    if (viewModel.hasPending) {
      return viewModel.isBlocked
          ? l10n.caloriesWeeklyCheckInHintBlockedTitle
          : l10n.caloriesWeeklyCheckInHintReadyTitle;
    }
    return switch (viewModel.freshness) {
      CalorieLearnedTdeeFreshness.urgent =>
        l10n.caloriesWeeklyCheckInHintUrgentTitle,
      _ => l10n.caloriesWeeklyCheckInHintStaleTitle,
    };
  }

  String _body(AppLocalizations l10n, String locale) {
    if (viewModel.hasPending) {
      final pending = viewModel.pendingWeeklyCheckIn;
      final baseMessage = viewModel.isBlocked
          ? _blockedMessage(l10n, locale)
          : l10n.caloriesWeeklyCheckInHintReadyBody;
      if (pending == null) {
        return baseMessage;
      }
      final rangeFormat = DateFormat.MMMd(locale);
      return '$baseMessage '
          '${rangeFormat.format(pending.windowStartDate)} - '
          '${rangeFormat.format(pending.windowEndDate)}.';
    }
    return switch (viewModel.freshness) {
      CalorieLearnedTdeeFreshness.urgent =>
        l10n.caloriesWeeklyCheckInHintUrgentBody,
      _ => l10n.caloriesWeeklyCheckInHintStaleBody,
    };
  }

  String _blockedMessage(
    AppLocalizations l10n,
    String locale,
  ) {
    final reason = viewModel.blockedReason;
    final pending = viewModel.pendingWeeklyCheckIn;
    final dateFormat = DateFormat.yMMMd(locale);
    final missingWeightDates = viewModel.missingWeightDays
        .map(dateFormat.format)
        .toList(growable: false);
    return switch (reason) {
      CalorieWeeklyCheckInBlockedReason.missingIntakeDays =>
        l10n.caloriesWeeklyCheckInBlockedMissingIntake,
      CalorieWeeklyCheckInBlockedReason.tooManyMissingIntakeDays =>
        l10n.caloriesWeeklyCheckInBlockedTooManyMissingIntake,
      CalorieWeeklyCheckInBlockedReason.skippedDayWithoutPriorAverage =>
        l10n.caloriesWeeklyCheckInBlockedSkippedWithoutAverage,
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight
          when missingWeightDates.length > 1 =>
        l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
          missingWeightDates.join(', '),
        ),
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight =>
        l10n.caloriesWeeklyCheckInBlockedMissingStartWeightOn(
          dateFormat.format(
            pending?.windowStartDate ?? viewModel.missingWeightDays.first,
          ),
        ),
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight
          when missingWeightDates.length > 1 =>
        l10n.caloriesWeeklyCheckInBlockedMissingWeightDates(
          missingWeightDates.join(', '),
        ),
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight =>
        l10n.caloriesWeeklyCheckInBlockedMissingEndWeightOn(
          dateFormat.format(
            pending?.windowEndDate ?? viewModel.missingWeightDays.last,
          ),
        ),
      CalorieWeeklyCheckInBlockedReason.unstableWeightData =>
        l10n.caloriesWeeklyCheckInBlockedUnstableWeight,
      null => l10n.caloriesWeeklyCheckInHintBlockedBody,
    };
  }
}

/// Defines calorie weekly check in success card.
class CalorieWeeklyCheckInSuccessCard extends StatelessWidget {
  /// The calorie weekly check in success card.
  const CalorieWeeklyCheckInSuccessCard({required this.goalKcal, super.key});

  /// The goal kcal.
  final double goalKcal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final numberFormat = NumberFormat.decimalPattern(locale);

    return Card(
      key: CaloriesPageKeys.weeklyCheckInSuccessCard,
      child: Padding(
        padding: AppInsets.card,
        child: Text(
          '${l10n.caloriesWeeklyCheckInAutoAdjustedHint} '
          '${numberFormat.format(goalKcal.round())} ${l10n.caloriesUnitKcal}.',
        ),
      ),
    );
  }
}
