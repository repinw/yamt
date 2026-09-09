import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/core/constants/app_layout_constants.dart';
import 'package:yamt/core/utils/date_utils.dart';
import 'package:yamt/core/widgets/app_ink_well.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/diary/presentation/diary_calendar_controller.dart';
import 'package:yamt/features/diary/presentation/widgets/diary_day_type_sheet.dart';

/// Interactive toggle button in the diary top chrome.
class DiaryDayTypeToggle extends ConsumerWidget {
  /// Creates the diary day type toggle.
  const DiaryDayTypeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(calorieGoalControllerProvider);
    final selectedDay = dateOnly(
      ref.watch(diaryCalendarControllerProvider).selectedDay,
    );

    final settings = settingsAsync.asData?.value;
    if (settings == null || !settings.hasGoal) {
      return const SizedBox.shrink();
    }

    final isPause = settings.isPauseDay(selectedDay);
    final isTraining = !isPause && settings.isTrainingDay(selectedDay);

    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final Color backgroundColor;
    final Color foregroundColor;
    final IconData icon;
    final String label;

    if (isPause) {
      backgroundColor = colors.secondaryContainer.withValues(alpha: 0.7);
      foregroundColor = colors.onSecondaryContainer;
      icon = Icons.pause_circle_filled_rounded;
      label = 'Pausentag';
    } else if (isTraining) {
      backgroundColor = colors.primaryContainer;
      foregroundColor = colors.onPrimaryContainer;
      icon = Icons.fitness_center_rounded;
      label = 'Training';
    } else {
      backgroundColor = colors.surfaceContainerHighest.withValues(alpha: 0.6);
      foregroundColor = colors.onSurfaceVariant;
      icon = Icons.weekend_rounded;
      label = 'Ruhetag';
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AppInkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => unawaited(
          showDiaryDayTypeSheet(
            context: context,
            ref: ref,
            selectedDay: selectedDay,
            settings: settings,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 16,
                color: foregroundColor.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
