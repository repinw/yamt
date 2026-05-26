import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_card.dart';

/// Wires selected-day data into the weekly check-in hint card.
class DiaryWeeklyCheckInHintHost extends ConsumerWidget {
  /// Creates a diary weekly check-in hint host.
  const DiaryWeeklyCheckInHintHost({
    required this.checkInData,
    required this.selectedDay,
    required this.onContinue,
    required this.onTrackMissingWeight,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// Weekly check-in data.
  final DiaryWeeklyCheckInData checkInData;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Continue action.
  final VoidCallback onContinue;

  /// Track missing weight action.
  final VoidCallback onTrackMissingWeight;

  /// Toggle selected day skip state.
  final Future<void> Function({
    required DateTime selectedDay,
    required bool isSkipped,
  })
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayHasEntries =
        ref
            .watch(
              diaryWeeklyCheckInSelectedDayHasEntriesProvider(selectedDay),
            )
            .value ??
        false;

    return DiaryWeeklyCheckInHintCard(
      checkInData: checkInData,
      selectedDay: selectedDay,
      selectedDayHasEntries: selectedDayHasEntries,
      onContinue: onContinue,
      onTrackMissingWeight: onTrackMissingWeight,
      onToggleSelectedDaySkipped: ({required isSkipped}) {
        return onToggleSelectedDaySkipped(
          selectedDay: selectedDay,
          isSkipped: isSkipped,
        );
      },
    );
  }
}
