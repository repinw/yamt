import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_mappers.dart';
import 'package:yamt/features/diary/application/diary_nutrition_bars_data.dart';
import 'package:yamt/features/diary/presentation/controllers/diary_day_dashboard_controller.dart';

part 'diary_food_log_feedback_controller.g.dart';

/// Feedback for one day's confirmed new entries.
class DiaryFoodLogFeedback {
  /// Creates feedback with optional freshly loaded daily context.
  const DiaryFoodLogFeedback({
    required this.entries,
    required this.startedAt,
    this.before,
    this.after,
  });

  /// Foods actually committed by the input session.
  final List<CalorieEntry> entries;

  /// Shared clock for visible daily bars and the floating card.
  final DateTime startedAt;

  /// Daily totals excluding the newly recorded IDs.
  final DiaryNutritionBarsData? before;

  /// Fresh totals containing the newly recorded IDs.
  final DiaryNutritionBarsData? after;

  /// Actual day chosen in the food editor.
  DateTime get day => normalizeDiaryDay(entries.first.loggedAt);

  /// Total calories of all newly logged entries.
  double get totalKcal =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalKcal);

  /// Total protein grams of all newly logged entries.
  double get totalProtein =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalProtein);

  /// Total carbs grams of all newly logged entries.
  double get totalCarbs =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalCarbs);

  /// Total fat grams of all newly logged entries.
  double get totalFat =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalFat);

  /// Starts this feedback when it reaches the front of the queue.
  DiaryFoodLogFeedback start() => DiaryFoodLogFeedback(
    entries: entries,
    startedAt: DateTime.now(),
    before: before,
    after: after,
  );
}

/// Transient presentation queue; nothing is replayed after app restart.
@riverpod
class DiaryFoodLogFeedbackController extends _$DiaryFoodLogFeedbackController {
  @override
  List<DiaryFoodLogFeedback> build() => const [];

  /// Resolves daily context without making successful logging depend on it.
  Future<void> enqueue(List<List<CalorieEntry>> groups) async {
    if (groups.isEmpty) return;
    final feedback = await Future.wait(groups.map(_loadFeedback));
    if (!ref.mounted) return;
    final wasEmpty = state.isEmpty;
    state = [...state, ...feedback];
    if (wasEmpty) state = [state.first.start(), ...state.skip(1)];
  }

  /// Dismisses only the card the user saw, without closing a newer one.
  void dismiss(DiaryFoodLogFeedback feedback) {
    if (state.isEmpty || !identical(state.first, feedback)) return;
    state = [if (state.length > 1) state[1].start(), ...state.skip(2)];
  }

  Future<DiaryFoodLogFeedback> _loadFeedback(List<CalorieEntry> entries) async {
    final day = normalizeDiaryDay(entries.first.loggedAt);
    DiaryNutritionBarsData? before;
    DiaryNutritionBarsData? after;
    try {
      await ref
          .read(diaryDayDashboardControllerProvider(day).notifier)
          .refreshAfterMutation()
          .timeout(const Duration(seconds: 2));
      if (!ref.mounted) {
        return DiaryFoodLogFeedback(
          entries: entries,
          startedAt: DateTime.now(),
        );
      }
      final dashboard = ref.read(diaryDayDashboardControllerProvider(day));
      final data = dashboard.data;
      final ids = entries.map((entry) => entry.id).toSet();
      final containsEntries =
          data != null &&
          ids.every(
            (id) => data.selectedDayEntries.any((entry) => entry.id == id),
          );
      if (containsEntries &&
          !dashboard.isFromCache &&
          dashboard.error == null) {
        after = data.nutritionBars;
        before = buildDiaryDashboardNutritionBars(
          data.selectedDayEntries
              .where((entry) => !ids.contains(entry.id))
              .toList(),
          0,
          macroTargets: after.goals,
        );
      }
    } on TimeoutException {
      // Saved amounts are still useful when the dashboard refresh times out.
    }
    return DiaryFoodLogFeedback(
      entries: List.unmodifiable(entries),
      startedAt: DateTime.now(),
      before: before,
      after: after,
    );
  }
}
