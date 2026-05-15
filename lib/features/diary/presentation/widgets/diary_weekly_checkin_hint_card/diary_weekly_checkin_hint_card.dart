import 'package:flutter/material.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_card_body.dart';

/// Defines diary weekly check-in hint card.
class DiaryWeeklyCheckInHintCard extends StatelessWidget {
  /// The diary weekly check-in hint card.
  const DiaryWeeklyCheckInHintCard({
    required this.checkInData,
    required this.selectedDay,
    required this.selectedDayHasEntries,
    required this.onContinue,
    required this.onOpenHealthTrends,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// Weekly check-in view model.
  final DiaryWeeklyCheckInData checkInData;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Whether selected day has calorie entries.
  final bool selectedDayHasEntries;

  /// Continue action.
  final VoidCallback onContinue;

  /// Open health trends action.
  final VoidCallback onOpenHealthTrends;

  /// Toggle selected day skip state.
  final Future<void> Function({required bool isSkipped})
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context) {
    if (!checkInData.showDiaryHint) {
      return const SizedBox.shrink();
    }

    return DiaryWeeklyCheckInHintCardBody(
      checkInData: checkInData,
      selectedDay: selectedDay,
      selectedDayHasEntries: selectedDayHasEntries,
      onContinue: onContinue,
      onOpenHealthTrends: onOpenHealthTrends,
      onToggleSelectedDaySkipped: onToggleSelectedDaySkipped,
    );
  }
}
