import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/presentation/models/'
    'calorie_entry_create_args.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_meal_section_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/provider/calorie_week_overview_provider.dart';
import 'package:yamt/l10n/app_localizations.dart';

class CaloriesPage extends ConsumerWidget {
  const CaloriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(calorieEntriesControllerProvider, _logEntriesLoadErrorOnce);

    final l10n = AppLocalizations.of(context)!;
    final dayController = ref.read(calorieDayControllerProvider.notifier);
    final entriesController = ref.read(
      calorieEntriesControllerProvider.notifier,
    );
    final dayViewState = ref.watch(calorieDayViewDataProvider);
    final weekOverviewState = ref.watch(calorieWeekOverviewProvider);

    return dayViewState.when(
      data: (viewData) {
        final weekOverview =
            weekOverviewState.asData?.value ??
            _fallbackWeekOverview(goalKcal: viewData.goalKcal);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xl,
            140,
          ),
          children: <Widget>[
            CaloriesDayNavigationCard(
              days: weekOverview.days,
              selectedDay: viewData.selectedDay,
              onSelectDay: dayController.setDay,
              onPreviousDay: () => _goToPreviousVisibleDay(ref),
              onNextDay: () => _goToNextVisibleDay(ref),
            ),
            const SizedBox(height: AppSpacing.lg),
            CaloriesSummaryCard(
              consumedKcal: viewData.summary.totalKcal,
              goalKcal: viewData.goalKcal,
              remainingKcal: viewData.remainingKcal,
              progress: viewData.progress,
              totalProtein: viewData.summary.totalProtein,
              totalCarbs: viewData.summary.totalCarbs,
              totalFat: viewData.summary.totalFat,
              consumedLabel: l10n.caloriesConsumedLabel,
              goalLabel: l10n.caloriesGoalLabel,
              remainingLabel: l10n.caloriesRemainingLabel,
              proteinLabel: l10n.caloriesProteinLabel,
              carbsLabel: l10n.caloriesCarbsLabel,
              fatLabel: l10n.caloriesFatLabel,
            ),
            const SizedBox(height: AppSpacing.lg),
            _CaloriesWeekBufferCard(
              remainingKcal: weekOverview.remainingKcal,
              title: l10n.caloriesWeekBufferTitle,
              positiveMessage: l10n.caloriesWeekBufferRemaining(
                weekOverview.remainingKcal.round(),
              ),
              negativeMessage: l10n.caloriesWeekBufferOverspent(
                weekOverview.remainingKcal.abs().round(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            ...viewData.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                child: CaloriesMealSectionCard(
                  section: section,
                  title: _mealLabel(l10n, section.mealType),
                  emptyMessage: l10n.caloriesSectionEmptyState,
                  onAddEntry: () => _openCreateEntry(
                    context,
                    preselectedMealType: section.mealType,
                  ),
                  onTapEntry: (entry) {
                    context.push(AppRoutes.homeCaloriesEntryEditPath(entry.id));
                  },
                  onDeleteEntry: (entry) =>
                      _deleteEntry(context: context, ref: ref, entry: entry),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: SizedBox.square(
          dimension: AppSizes.inlineProgressIndicator,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.progressStrokeWidth,
          ),
        ),
      ),
      error: (error, stackTrace) {
        return Center(
          child: Padding(
            padding: AppInsets.pageLarge,
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: AppInsets.card,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.wifi_tethering_error_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.caloriesLoadFailed, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      key: CaloriesPageKeys.retryButton,
                      onPressed: () {
                        entriesController.refresh();
                        ref
                            .read(calorieGoalControllerProvider.notifier)
                            .refresh();
                      },
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.caloriesRetryAction),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _logEntriesLoadErrorOnce(
    AsyncValue<List<CalorieEntry>>? previous,
    AsyncValue<List<CalorieEntry>> next,
  ) {
    final nextError = next.asError;
    if (nextError == null) {
      return;
    }

    final previousError = previous?.asError;
    final sameError = identical(previousError?.error, nextError.error);
    final sameTrace = previousError?.stackTrace == nextError.stackTrace;
    if (sameError && sameTrace) {
      return;
    }

    developer.log(
      'Failed to load calorie entries.',
      name: 'CaloriesPage',
      error: nextError.error,
      stackTrace: nextError.stackTrace,
    );
  }

  String _mealLabel(AppLocalizations l10n, MealType mealType) {
    return switch (mealType) {
      MealType.breakfast => l10n.caloriesMealBreakfast,
      MealType.lunch => l10n.caloriesMealLunch,
      MealType.dinner => l10n.caloriesMealDinner,
      MealType.snack => l10n.caloriesMealSnack,
    };
  }

  Future<void> _deleteEntry({
    required BuildContext context,
    required WidgetRef ref,
    required CalorieEntry entry,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.caloriesDeleteEntryDialogTitle),
          content: Text(l10n.caloriesDeleteEntryDialogMessage(entry.name)),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(l10n.inventoryReceiptReviewCancelAction),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: Text(l10n.caloriesDeleteEntryConfirmAction),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await ref
        .read(calorieEntriesControllerProvider.notifier)
        .deleteEntry(entry.id);
    if (!context.mounted || deleted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(content: Text(l10n.caloriesDeleteFailed)));
  }
}

void _openCreateEntry(
  BuildContext context, {
  required MealType preselectedMealType,
}) {
  context.push(
    AppRoutes.homeCaloriesEntryCreate,
    extra: CalorieEntryCreateArgs(
      prefilledProfile: null,
      preselectedMealType: preselectedMealType,
    ),
  );
}

CalorieWeekOverview _fallbackWeekOverview({required double goalKcal}) {
  final visibleDays = buildDiaryVisibleDays();
  return CalorieWeekOverview(
    days: List<CalorieWeekDayOverview>.unmodifiable(
      visibleDays.map(
        (day) => CalorieWeekDayOverview(
          date: day,
          totalKcal: 0,
          goalKcal: goalKcal,
          entryCount: 0,
        ),
      ),
    ),
    totalConsumedKcal: 0,
    totalGoalKcal: goalKcal * visibleDays.length,
    remainingKcal: goalKcal * visibleDays.length,
  );
}

void _goToPreviousVisibleDay(WidgetRef ref) {
  final controller = ref.read(calorieDayControllerProvider.notifier);
  final selectedDay = ref.read(calorieDayControllerProvider);
  controller.setDay(previousDiaryVisibleDay(selectedDay));
}

void _goToNextVisibleDay(WidgetRef ref) {
  final controller = ref.read(calorieDayControllerProvider.notifier);
  final selectedDay = ref.read(calorieDayControllerProvider);
  controller.setDay(nextDiaryVisibleDay(selectedDay));
}

class _CaloriesWeekBufferCard extends StatelessWidget {
  const _CaloriesWeekBufferCard({
    required this.remainingKcal,
    required this.title,
    required this.positiveMessage,
    required this.negativeMessage,
  });

  final double remainingKcal;
  final String title;
  final String positiveMessage;
  final String negativeMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = remainingKcal < 0
        ? AppInventoryEditorial.warning
        : AppInventoryEditorial.primary;

    return DecoratedBox(
      key: CaloriesPageKeys.weekBufferCard,
      decoration: BoxDecoration(
        color: AppInventoryEditorial.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppInventoryEditorial.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Icon(Icons.savings_outlined, color: iconColor),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    remainingKcal < 0 ? negativeMessage : positiveMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
