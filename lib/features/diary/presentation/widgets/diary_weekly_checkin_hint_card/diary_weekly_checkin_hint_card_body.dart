import 'package:flutter/material.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_weekly_checkin_card_keys.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_actions.dart';
import 'package:yamt/features/diary/presentation/widgets/'
    'diary_weekly_checkin_hint_card/diary_weekly_checkin_hint_text.dart';

/// Card body for the diary weekly check-in hint.
class DiaryWeeklyCheckInHintCardBody extends StatelessWidget {
  /// Creates a diary weekly check-in hint body.
  const DiaryWeeklyCheckInHintCardBody({
    required this.viewModel,
    required this.selectedDay,
    required this.selectedDayHasEntries,
    required this.onContinue,
    required this.onOpenHealthTrends,
    required this.onToggleSelectedDaySkipped,
    super.key,
  });

  /// Weekly check-in view model.
  final CalorieWeeklyCheckInViewModel viewModel;

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
    final colors = Theme.of(context).colorScheme;

    return Card(
      key: DiaryWeeklyCheckInCardKeys.hintCard,
      color: colors.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: AppInsets.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DiaryWeeklyCheckInHintTitle(viewModel: viewModel),
            const SizedBox(height: AppSpacing.xs),
            DiaryWeeklyCheckInHintBody(viewModel: viewModel),
            const SizedBox(height: AppSpacing.md),
            DiaryWeeklyCheckInHintActions(
              viewModel: viewModel,
              selectedDay: selectedDay,
              selectedDayHasEntries: selectedDayHasEntries,
              onContinue: onContinue,
              onOpenHealthTrends: onOpenHealthTrends,
              onToggleSelectedDaySkipped: onToggleSelectedDaySkipped,
            ),
          ],
        ),
      ),
    );
  }
}
