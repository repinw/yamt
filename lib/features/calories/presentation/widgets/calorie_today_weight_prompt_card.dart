import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_health_trend_snapshot.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_health_weight_dialog.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/features/calories/provider/calorie_health_trend_provider.dart';
import 'package:yamt/features/calories/provider/'
    'calorie_today_weight_prompt_dismissal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/health/provider/'
    'manual_health_weight_entries_controller.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Optional diary prompt for adding today's body weight.
class CalorieTodayWeightPromptCard extends ConsumerWidget {
  /// Creates today's weight prompt card.
  const CalorieTodayWeightPromptCard({
    required this.selectedDay,
    required this.referenceNow,
    required this.weeklyCheckIn,
    super.key,
  });

  /// Currently selected diary day.
  final DateTime selectedDay;

  /// Reference timestamp used by the diary page.
  final DateTime referenceNow;

  /// Current weekly check-in state, used to avoid duplicate weight prompts.
  final CalorieWeeklyCheckInViewModel? weeklyCheckIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = normalizeDiaryDay(referenceNow);
    final normalizedSelectedDay = normalizeDiaryDay(selectedDay);
    if (!isSameDiaryDay(normalizedSelectedDay, today) ||
        _weeklyCheckInAlreadyAsksForWeight(weeklyCheckIn)) {
      return const SizedBox.shrink();
    }

    final dismissalController = ref.watch(
      calorieTodayWeightPromptDismissalControllerProvider.notifier,
    );
    ref.watch(calorieTodayWeightPromptDismissalControllerProvider);
    if (dismissalController.isDismissedForDay(today)) {
      return const SizedBox.shrink();
    }

    final snapshot = ref
        .watch(calorieHealthTrendSnapshotProvider)
        .asData
        ?.value;
    final todayPoint = snapshot == null ? null : _pointForDay(snapshot, today);
    if (todayPoint == null || todayPoint.weightKg != null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        key: CaloriesPageKeys.todayWeightPromptCard,
        color: colors.tertiaryContainer.withValues(alpha: 0.42),
        child: Padding(
          padding: AppInsets.card,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.monitor_weight_outlined, color: colors.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.caloriesTodayWeightPromptTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.caloriesTodayWeightPromptBody,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.tonalIcon(
                          key: CaloriesPageKeys.todayWeightPromptAddButton,
                          onPressed: () => unawaited(
                            _openWeightDialog(
                              context: context,
                              ref: ref,
                              day: today,
                            ),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: Text(
                            l10n.caloriesTodayWeightPromptAddAction,
                          ),
                        ),
                        TextButton(
                          key: CaloriesPageKeys.todayWeightPromptDismissButton,
                          onPressed: () => unawaited(
                            dismissalController.dismissForDay(today),
                          ),
                          child: Text(
                            l10n.caloriesTodayWeightPromptDismissAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openWeightDialog({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime day,
  }) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayLabel = DateFormat.yMMMd(locale).format(day);
    final controller = ref.read(
      manualHealthWeightEntriesControllerProvider.notifier,
    );

    return showCalorieHealthWeightDialog(
      context: context,
      dayLabel: dayLabel,
      initialWeightKg: null,
      hasManualWeight: false,
      onSaveWeight: (weightKg) async {
        final saved = await controller.saveEntry(day: day, weightKg: weightKg);
        ref
          ..invalidate(calorieHealthTrendSnapshotProvider)
          ..invalidate(calorieWeeklyCheckInViewModelProvider);
        return saved;
      },
      onClearWeight: () async => true,
    );
  }

  bool _weeklyCheckInAlreadyAsksForWeight(
    CalorieWeeklyCheckInViewModel? viewModel,
  ) {
    if (viewModel?.showDiaryHint != true) {
      return false;
    }
    if (viewModel!.missingWeightDays.isNotEmpty) {
      return true;
    }
    return switch (viewModel.blockedReason) {
      CalorieWeeklyCheckInBlockedReason.missingWindowStartWeight ||
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight ||
      CalorieWeeklyCheckInBlockedReason.unstableWeightData => true,
      _ => false,
    };
  }

  CalorieHealthTrendPoint? _pointForDay(
    CalorieHealthTrendSnapshot snapshot,
    DateTime day,
  ) {
    for (final point in snapshot.points) {
      if (isSameDiaryDay(point.day, day)) {
        return point;
      }
    }
    return null;
  }
}
