import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Action row for the diary weekly check-in hint.
class DiaryWeeklyCheckInHintActions extends StatelessWidget {
  /// Creates diary weekly check-in hint actions.
  const DiaryWeeklyCheckInHintActions({
    required this.checkInData,
    required this.selectedDay,
    required this.selectedDayHasEntries,
    required this.onContinue,
    required this.onTrackMissingWeight,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Whether selected day has calorie entries.
  final bool selectedDayHasEntries;

  /// Continue action.
  final VoidCallback onContinue;

  /// Track missing weight action.
  final VoidCallback onTrackMissingWeight;

  /// Toggle selected day skip state.
  final Future<void> Function({required bool isSkipped})
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context) {
    final pending = checkInData.pendingWeeklyCheckIn;
    final skipDayData = _resolveSkippableDay(pending);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (pending != null) _ContinueButton(onPressed: onContinue),
        if (_canTrackMissingWeight(checkInData))
          _TrackMissingWeightButton(onPressed: onTrackMissingWeight),
        if (skipDayData != null)
          _SkipDayButton(
            selectedDayData: skipDayData,
            onToggleSelectedDaySkipped: onToggleSelectedDaySkipped,
          ),
      ],
    );
  }

  CalorieWeeklyCheckInWindowDay? _resolveSkippableDay(
    PendingCalorieGoalWeeklyCheckIn? pending,
  ) {
    if (pending == null ||
        selectedDay.isBefore(pending.windowStartDate) ||
        selectedDay.isAfter(pending.windowEndDate)) {
      return null;
    }
    final selectedDayData = checkInData.days
        .where((day) => DateUtils.isSameDay(day.day, selectedDay))
        .firstOrNull;
    if (selectedDayData == null ||
        (selectedDayHasEntries && !selectedDayData.isSkippedIntakeDay)) {
      return null;
    }
    return selectedDayData;
  }

  bool _canTrackMissingWeight(DiaryWeeklyCheckInData checkInData) {
    if (checkInData.missingWeightDays.isEmpty) {
      return false;
    }

    return switch (checkInData.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight => true,
      _ => false,
    };
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FilledButton(
      key: DiaryWeeklyCheckInCardKeys.continueButton,
      onPressed: onPressed,
      child: Text(l10n.caloriesWeeklyCheckInHintContinueAction),
    );
  }
}

class _TrackMissingWeightButton extends StatelessWidget {
  const _TrackMissingWeightButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton(
      key: DiaryWeeklyCheckInCardKeys.trackMissingWeightButton,
      onPressed: onPressed,
      child: Text(l10n.caloriesWeeklyCheckInTrackMissingWeightAction),
    );
  }
}

class _SkipDayButton extends StatelessWidget {
  const _SkipDayButton({
    required this.selectedDayData,
    required this.onToggleSelectedDaySkipped,
  });

  final CalorieWeeklyCheckInWindowDay selectedDayData;
  final Future<void> Function({required bool isSkipped})
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return OutlinedButton(
      key: DiaryWeeklyCheckInCardKeys.skipDayButton,
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
    );
  }
}
