import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_card.dart';

/// Wires selected-day data into the weekly check-in hint card.
class DiaryWeeklyCheckInHintHost extends ConsumerWidget {
  /// Creates a diary weekly check-in hint host.
  const DiaryWeeklyCheckInHintHost({
    required this.viewModel,
    required this.selectedDay,
    required this.onContinue,
    required this.onOpenHealthTrends,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// Weekly check-in view model.
  final CalorieWeeklyCheckInViewModel viewModel;

  /// Selected diary day.
  final DateTime selectedDay;

  /// Continue action.
  final VoidCallback onContinue;

  /// Open health trends action.
  final VoidCallback onOpenHealthTrends;

  /// Toggle selected day skip state.
  final Future<void> Function({
    required DateTime selectedDay,
    required bool isSkipped,
  })
  onToggleSelectedDaySkipped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDayOverview = ref
        .watch(calorieWeekDayOverviewForDateProvider(selectedDay))
        .value;

    return DiaryWeeklyCheckInHintCard(
      viewModel: viewModel,
      selectedDay: selectedDay,
      selectedDayHasEntries: (selectedDayOverview?.entryCount ?? 0) > 0,
      onContinue: onContinue,
      onOpenHealthTrends: onOpenHealthTrends,
      onToggleSelectedDaySkipped: ({required isSkipped}) {
        return onToggleSelectedDaySkipped(
          selectedDay: selectedDay,
          isSkipped: isSkipped,
        );
      },
    );
  }
}
