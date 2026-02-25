import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yamt/core/constants/app_routes.dart';
import 'package:yamt/core/constants/app_ui_constants.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/calories/provider/calorie_day_controller.dart';
import 'package:yamt/features/calories/provider/calorie_entries_controller.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_day_navigation_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_meal_section_card.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_page_keys.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calories_summary_card.dart';
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
    final goalController = ref.read(calorieGoalControllerProvider.notifier);
    final dayViewState = ref.watch(calorieDayViewDataProvider);

    return dayViewState.when(
      data: (viewData) {
        return ListView(
          padding: AppInsets.page,
          children: <Widget>[
            CaloriesDayNavigationCard(
              dayLabel: _formatDayLabel(context, viewData.selectedDay),
              onPreviousDay: dayController.previousDay,
              onToday: dayController.goToToday,
              onNextDay: dayController.nextDay,
              previousDayTooltip: l10n.caloriesPreviousDayAction,
              todayLabel: l10n.caloriesTodayAction,
              nextDayTooltip: l10n.caloriesNextDayAction,
            ),
            const SizedBox(height: AppSpacing.md),
            CaloriesSummaryCard(
              consumedKcal: viewData.summary.totalKcal,
              goalKcal: viewData.goalKcal,
              remainingKcal: viewData.remainingKcal,
              progress: viewData.progress,
              totalProtein: viewData.summary.totalProtein,
              totalCarbs: viewData.summary.totalCarbs,
              totalFat: viewData.summary.totalFat,
              onSetGoal: () => _showSetGoalDialog(
                context: context,
                ref: ref,
                currentGoal: viewData.goalKcal,
              ),
              setGoalLabel: l10n.caloriesSetGoalAction,
              consumedLabel: l10n.caloriesConsumedLabel,
              goalLabel: l10n.caloriesGoalLabel,
              remainingLabel: l10n.caloriesRemainingLabel,
              proteinLabel: l10n.caloriesProteinLabel,
              carbsLabel: l10n.caloriesCarbsLabel,
              fatLabel: l10n.caloriesFatLabel,
            ),
            const SizedBox(height: AppSpacing.md),
            ...viewData.sections.map(
              (section) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: CaloriesMealSectionCard(
                  section: section,
                  title: _mealLabel(l10n, section.mealType),
                  emptyMessage: l10n.caloriesSectionEmptyState,
                  deleteTooltip: l10n.caloriesDeleteEntryAction,
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
                        goalController.refresh();
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

  String _formatDayLabel(BuildContext context, DateTime selectedDay) {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final today = DateTime.now();
    final isToday =
        selectedDay.year == today.year &&
        selectedDay.month == today.month &&
        selectedDay.day == today.day;

    final formattedDate = materialL10n.formatMediumDate(selectedDay);
    if (isToday) {
      return '${l10n.caloriesTodayTitle} · $formattedDate';
    }
    return formattedDate;
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

  Future<void> _showSetGoalDialog({
    required BuildContext context,
    required WidgetRef ref,
    required double currentGoal,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: currentGoal.toStringAsFixed(0),
    );
    double? parsedGoal;

    String? errorText;
    final action = await showDialog<_GoalDialogAction>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(l10n.caloriesGoalDialogTitle),
              content: TextField(
                key: CalorieGoalDialogKeys.valueField,
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.caloriesGoalFieldLabel,
                  errorText: errorText,
                ),
              ),
              actions: <Widget>[
                TextButton(
                  key: CalorieGoalDialogKeys.clearButton,
                  onPressed: () => context.pop(_GoalDialogAction.clear),
                  child: Text(l10n.caloriesGoalClearAction),
                ),
                TextButton(
                  onPressed: () => context.pop(_GoalDialogAction.cancel),
                  child: Text(l10n.inventoryReceiptReviewCancelAction),
                ),
                FilledButton(
                  key: CalorieGoalDialogKeys.saveButton,
                  onPressed: () {
                    final parsed = _parseDouble(controller.text);
                    if (parsed == null || parsed <= 0) {
                      setState(() {
                        errorText = l10n.caloriesGoalInvalidValue;
                      });
                      return;
                    }
                    parsedGoal = parsed;
                    context.pop(_GoalDialogAction.save);
                  },
                  child: Text(l10n.caloriesGoalSaveAction),
                ),
              ],
            );
          },
        );
      },
    );

    if (action == null || action == _GoalDialogAction.cancel) {
      return;
    }

    final goalController = ref.read(calorieGoalControllerProvider.notifier);
    final saved = switch (action) {
      _GoalDialogAction.clear => await goalController.clearGoal(),
      _GoalDialogAction.save => await goalController.setGoal(parsedGoal ?? 0),
      _GoalDialogAction.cancel => true,
    };

    if (!context.mounted || saved) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.caloriesGoalSaveFailed)),
    );
  }

  double? _parseDouble(String rawValue) {
    final normalized = rawValue.trim().replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}

enum _GoalDialogAction { cancel, save, clear }
